-- {"id":5,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "https://bestlightnovel.com"


---@param o Elements
---@param f fun(v:Element):any
---@return table
local function map(o, f)
    local t = {}
    for i=1, o:size() do
        t[i] = f(o:get(i-1))
    end
    return t
end

---@return string
local function getLatestURL(page)
    return baseURL .. "/novel_list?type=latest&category=all&state=all&page=" .. (page <= 0 and 1 or page)
end

---@param document Document
---@return string
local function getNovelPassage(document)
    local e = document:selectFirst("div.vung_doc"):select("p")
    if e:size() == 0 then return "NOT YET TRANSLATED" end
    return table.concat(map(e, function(v) return v:text() end), "\n")
end

---@param document Document
---@return NovelPage
local function parseNovel(document)
    local novelPage = NovelPage()
    -- Image
    novelPage:setImageURL(document:selectFirst("div.truyen_info_left"):selectFirst("img"):attr("src"))

    -- Bulk data
    do
        local elements = document:selectFirst("ul.truyen_info_right"):select("li")
        novelPage:setTitle(elements:get(0):selectFirst("h1"):text())

        -- Authors
        novelPage:setAuthors(map(elements:get(1):select("a"), function(v) return v:text() end))
        -- Genres
        novelPage:setGenres(map(elements:get(2):select("a"), function(v) return v:text() end))
        -- Status
        local s = elements:get(3):select("a"):text()
        novelPage:setStatus(NovelStatus(
                s == "ongoing" and 0 or
                        (s == "completed" and 1 or 3)
        ))
    end

    -- Description
    do
        local elements = document:selectFirst("div.entry-header"):select("div")
        for i = 0, elements:size() - 1, 1 do
            local div = elements:get(i)
            if div:id() == "noidungm" then
                novelPage:setDescription(div:text():gsub("<br>", "\n"))
                break end
        end
    end

    -- Chapters
    local chapters = document:selectFirst("div.chapter-list"):select("div.row")
    local a = chapters:size()
    local c = AsList(map(chapters, function(v)
        local chap = NovelChapter()
        local e = v:select("span")
        local titLink = e:get(0):selectFirst("a")
        chap:setTitle(titLink:attr("title"):gsub(novelPage:getTitle(), ""):match("^%s*(.-)%s*$"))
        chap:setLink(titLink:attr("href"))
        chap:setRelease(e:get(1):text())
        chap:setOrder(a)
        a = a - 1
        return chap
    end))
    Reverse(c)
    novelPage:setNovelChapters((c))

    return novelPage
end

---@param document Document
---@return NovelPage
local function parseNovelI(document, increment)
    return parseNovel(document)
end

local function novelPageCombiner(url, increment) return url end

---@param doc Document
local function parseLatest(doc)
    return AsList(map(doc:select("div.update_item.list_category"), function(v)
        local novel = Novel()
        local e = v:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(v:selectFirst("img"):attr("src"))
        return novel
    end))
end

---@param doc Document
local function parseSearch(doc)
    return AsList(map(doc:select("div.update_item.list_category"), function(v)
        local novel = Novel()
        local e = v:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(v:selectFirst("img"):attr("src"))
        return novel
    end))
end

---@param query string
local function getSearchString(query)
    return baseURL .. "/search_novels/" .. query:gsub(" ", "_")
end

return {
    id = 5,
    name = "BestLightNovel",
    imageURL = "",
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
