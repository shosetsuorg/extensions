-- {"id":3,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "https://yomou.syosetu.com"
local passageURL = "https://ncode.syosetu.com"

local function map(o, f)
    local t = {}
    for i=1, o:size() do
        t[i] = f(o:get(i-1), i)
    end
    return t
end
local function first(o, f)
    for i=1, o:size() do
        local v = o:get(i-1)
        if f(v) then return v end
    end
end


--- @return boolean
function isIncrementingChapterList()
    return false
end

--- @return boolean
function isIncrementingPassagePage()
    return false
end

--- @return Ordering
function chapterOrder()
    return Ordering(0)
end

--- @return Ordering
function latestOrder()
    return Ordering(0)
end

--- @return boolean
function hasCloudFlare()
    return false
end

--- @return boolean
function hasSearch()
    return true
end

--- @return boolean
function hasGenres()
    return false
end

--- @return Array @Array<NovelGenre>
function genres()
    return {}
end

--- @return number @ID
function getID()
    return 3
end

--- @return string @name of site
function getName()
    return "Syosetsu"
end

--- @return string @image url of site
function getImageURL()
    return "https://static.syosetu.com/view/images/common/logo_yomou.png"
end

--- @param page number @value
--- @return string @url of said latest page
function getLatestURL(page)
    if page == 0 then page = 1 end
    return baseURL .. "/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=" .. page
end

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    local e = first(document:select("div"), function(v) return v:id() == "novel_contents" end)
    if not e then return "INVALID PARSING, CONTACT DEVELOPERS" end
    return table.concat(map(e:select("p"), function(v) return v:text() end), "\n"):gsub("<br>", "\n\n")
end

--- @param document Document @Jsoup document of the novel information page
--- @return NovelPage @java object
function parseNovel(document)
    local novelPage = NovelPage()

    novelPage:setAuthors({ document:selectFirst("div.novel_writername"):text():gsub("作者：", "") })
    novelPage:setTitle(document:selectFirst("p.novel_title"):text())

    -- Description
    local e = first(document:select("div"), function(v) return v:id() == "novel_color" end)
    if e then
        novelPage:setDescription(e:text():gsub("<br>\n<br>", "\n"):gsub("<br>", "\n"))
    end

    -- Chapters
    novelPage:setNovelChapters(AsList(map(document:select("dl.novel_sublist2"), function(v, i)
        local chap = NovelChapter()
        chap:setTitle(v:selectFirst("a"):text())
        chap:setLink(passageURL .. v:selectFirst("a"):attr("href"))
        chap:setRelease(v:selectFirst("dt.long_update"):text())
        chap:setOrder(i)
        return chap
    end)))


    return novelPage
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelPage @java object
function parseNovelI(document, increment)
    return parseNovel(document)
end


--- @param url string       url of novel page
--- @param increment number which page
function novelPageCombiner(url, increment)
    return url
end

--- @param document Document @Jsoup document of latest listing
--- @return Array @Novel array list
function parseLatest(document)
    return AsList(map(document:select("div.searchkekka_box"), function(v)
        local novel = Novel()
        local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        return novel
    end))
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
function parseSearch(document)
    return AsList(map(document:select("div.searchkekka_box"), function(v)
        local novel = Novel()
        local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        return novel
    end))
end

--- @param query string @query to use
--- @return string @url
function getSearchString(query)
    return baseURL .. "/search.php?&word=" .. query:gsub("%+", "%2"):gsub(" ", "\\+")
end