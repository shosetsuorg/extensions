-- {"id":3,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "https://yomou.syosetu.com"
local passageURL = "https://ncode.syosetu.com"


--- @param page number
--- @return string
local function getLatestURL(page)
    if page == 0 then page = 1 end
    return baseURL .. "/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=" .. page
end

--- @param document Document
--- @return string
local function getNovelPassage(document)
    local e = first(document:select("div"), function(v) return v:id() == "novel_contents" end)
    if not e then return "INVALID PARSING, CONTACT DEVELOPERS" end
    return table.concat(map(e:select("p"), function(v) return v:text() end), "\n"):gsub("<br>", "\n\n")
end

--- @param document Document
--- @return NovelInfo
local function parseNovel(document)
    local novelPage = NovelInfo()

    novelPage:setAuthors({ document:selectFirst("div.novel_writername"):text():gsub("作者：", "") })
    novelPage:setTitle(document:selectFirst("p.novel_title"):text())

    -- Description
    local e = first(document:select("div"), function(v) return v:id() == "novel_color" end)
    if e then
        novelPage:setDescription(e:text():gsub("<br>\n<br>", "\n"):gsub("<br>", "\n"))
    end

    -- Chapters
    novelPage:setChapters(AsList(map(document:select("dl.novel_sublist2"), function(v, i)
        local chap = NovelChapter()
        chap:setTitle(v:selectFirst("a"):text())
        chap:setLink(passageURL .. v:selectFirst("a"):attr("href"))
        chap:setRelease(v:selectFirst("dt.long_update"):text())
        chap:setOrder(i)
        return chap
    end)))


    return novelPage
end

--- @param document Document
--- @param increment number
--- @return NovelInfo
local function parseNovelI(document, increment)
    return parseNovel(document)
end

--- @param url string
--- @param increment number
local function novelPageCombiner(url, increment)
    return url
end

--- @param document Document
--- @return ArrayList
local function parseLatest(document)
    return AsList(map(document:select("div.searchkekka_box"), function(v)
        local novel = Novel()
        local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        return novel
    end))
end

--- @param document Document
--- @return ArrayList
local function parseSearch(document)
    return AsList(map(document:select("div.searchkekka_box"), function(v)
        local novel = Novel()
        local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        return novel
    end))
end

--- @param query string
--- @return string
local function getSearchString(query)
    return baseURL .. "/search.php?&word=" .. query:gsub("%+", "%2"):gsub(" ", "\\+")
end

return {
    id = 3,
    name = "Syosetsu",
    imageURL = "https://static.syosetu.com/view/images/common/logo_yomou.png",
    genres = {},
    hasCloudFlare = false,
    latestOrder = Ordering(0),
    chapterOrder = Ordering(0),
    isIncrementingChapterList = false,
    isIncrementingPassagePage = false,
    hasSearch = true,
    hasGenres = false,

    getLatestURL = getLatestURL,
    getNovelPassage = getNovelPassage,
    parseNovel = parseNovel,
    parseNovelI = parseNovelI,
    novelPageCombiner = novelPageCombiner,
    parseLatest = parseLatest,
    parseSearch = parseSearch,
    getSearchString = getSearchString
}
