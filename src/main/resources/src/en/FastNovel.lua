-- {"id":258,"version":"0.1.3","author":"Doomsdayrs","repo":""}

local baseURL = "https://fastnovel.net"

---@param page number @value
---@return string @url of said latest page
local function getLatestURL(page)
    return "https://fastnovel.net/list/latest.html?page=" .. page
end

---@param document Document @Jsoup document of the page with chapter text on it
---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getNovelPassage(document)
    return table.concat(map(document:select("div.box-player"):select("p"), function(v)
        return v:text()
    end), "\n")
end

---@param document Document @Jsoup document of the novel information page
---@return NovelPage
local function parseNovel(document)
    local novelPage = NovelPage()

    novelPage:setImageURL(document:selectFirst("div.book-cover"):attr("data-original"))
    novelPage:setTitle(document:selectFirst("h1.name"):text())
    novelPage:setDescription(table.concat(map(document:select("div.film-content"):select("p"), function(v)
        return v:text()
    end), "\n"))

    local elements = document:selectFirst("ul.meta-data"):select("li")
    novelPage:setAuthors(map(elements:get(0):select("a"),
            function(v)
                return v:text()
            end))
    novelPage:setGenres(map(elements:get(1):select("a"), function(v)
        return v:text()
    end))

    novelPage:setStatus(NovelStatus(
            elements:get(2):selectFirst("strong"):text():match("Completed") and 1 or 0
    ))

    -- chapters
    local volumeName = ""
    local chapterIndex = 0
    local chapters = AsList(map2flat(
            document:selectFirst("div.block-film"):select("div.book"),
            function(element)
                volumeName = element:selectFirst("div.title"):selectFirst("a.accordion-toggle"):text()
                return element:select("li")
            end,
            function(element)
                local chapter = NovelChapter()
                local data = element:selectFirst("a.chapter")
                chapter:setTitle(volumeName .. " " .. data:text())
                chapter:setLink(baseURL .. data:attr("href"))
                chapter:setOrder(chapterIndex)
                chapterIndex = chapterIndex + 1
                return chapter
            end))

    novelPage:setNovelChapters(chapters)
    return novelPage
end

---@param document Document @Jsoup document of the novel information page
---@param _ number @Page #
---@return NovelPage
local function parseNovelI(document, _)
    return parseNovel(document)
end

---@param url string @url of novel page
---@param _ number @which page
local function novelPageCombiner(url, _)
    return url
end

---@param document Document @Jsoup document of latest listing
---@return Array @Novel array list
local function parseLatest(document)
    return AsList(map(document:selectFirst("ul.list-film"):select("li.film-item"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setLink(baseURL .. data:attr("href"))
        novel:setTitle(data:attr("title"))
        novel:setImageURL(data:selectFirst("div.img"):attr("data-original"))
        return novel
    end))
end

---@param document Document @Jsoup document of search results
---@return Array @Novel array list
local function parseSearch(document)
    return AsList(map(document:select("ul.list-film"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setLink(baseURL .. data:attr("href"))
        novel:setTitle(data:attr("title"))
        novel:setImageURL(data:selectFirst("div.img"):attr("data-original"))
        return novel
    end))
end

---@param query string @query to use
---@return string @url
local function getSearchString(query)
    return baseURL .. "/search/" .. query:gsub(" ", "%%20")
end

return {
    id = 258,
    name = "FastNovel",
    imageURL = "https://fastnovel.net/skin/images/logo.png",
    genres = {},
    hasCloudFlare = false,
    latestOrder = Ordering(1),
    chapterOrder = Ordering(0),
    isIncrementingChapterList = false,
    isIncrementingPassagePage = false,
    hasSearch = true,
    hasGenres = true,

    getLatestURL = getLatestURL,
    getNovelPassage = getNovelPassage,
    parseNovel = parseNovel,
    parseNovelI = parseNovelI,
    novelPageCombiner = novelPageCombiner,
    parseLatest = parseLatest,
    parseSearch = parseSearch,
    getSearchString = getSearchString
}
