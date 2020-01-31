-- {"id":-1,"version":"9.9.9","author":"","repo":""}
---@deprecated

local baseURL = "https://creativenovels.com"

---@param _ number @value
---@return string @url of said latest page
local function getLatestURL(_)
    return "https://creativenovels.com"
end

---@param document Document @Jsoup document of the page with chapter text on it
---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getNovelPassage(document)
    return table.concat(map(document:selectFirst("div.entry-content.content"):select("p"), function(v)
        return v:text()
    end), "\n")
end

---@param document Document @Jsoup document of the novel information page
---@return NovelPage
local function parseNovel(document)
    local novelPage = NovelPage()
    novelPage:setTitle(document:selectFirst("div.e45344-16.x-text.bK_C"):text())
    novelPage:setImageURL(document:selectFirst("img.book_cover"):attr("src"))
    novelPage:setAuthors({ document:selectFirst("div.e45344-18.x-text.bK_C"):selectFirst("a"):text() })
    novelPage:setDescription(table.concat(map(document:selectFirst("div.novel_page_synopsis"):select("p"), function(v)
        return v:text()
    end)))
    print("GENRES")
    local gOrt = map(document:select("div.novel_tag_inner"), function(v)
        return v:text()
    end)
    novelPage:setGenres(gOrt)
    novelPage:setTags(gOrt)

    local value = 0
    print("CHAPTERS")
    local headers = HeadersBuilder():add("Accept", "*/*")
                                    :add("Referer", baseURL .. "/novel/" .. novelPage:getTitle():gsub("[^A-Za-z0-9]", ""))
                                    :add("TE", "Trailers")
                                    :add("Host", "creativenovels.com")
                                    :add("DNT", 1)
                                    :build()
    print(getResponse(POST("https://creativenovels.com/wp-admin/admin-ajax.php", headers, DEFAULT_BODY(), DEFAULT_CACHE_CONTROL())):body():string())
    --   novelPage:setNovelChapters(AsList(map(document:selectFirst("div.chapter_list_novel_page"):select("a"), function(v)
    --                             local c = NovelChapter()
    --                           c:setLink(v:attr("href"))
    --                         c:setOrder(value)
    --                       local data = v:selectFirst("div")
    --                     c:setRelease(data:attr("data-date"))
    --                   c:setTitle(data:text())
    --                 value = value + 1
    --               return c
    --         end)))
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
    return AsList(map(document:selectFirst("div.latest_releases"):select("div.url_sub"), function(v)
        local n = Novel()
        local data = v:selectFirst("div.novel_cover"):selectFirst("a")
        n:setTitle(v:select("div.novel_front"):text())
        n:setLink(data:attr("href"))
        n:setImageURL(data:select("img"):attr("src"))
        return n
    end))
end

---@param document Document @Jsoup document of search results
---@return Array @Novel array list
local function parseSearch(document)
    return AsList(map(document:selectFirst("div.x-main.full"):select("a.sub_browse_1a"), function(v)
        local n = Novel()
        n:setImageURL(v:select("div.cover_art"):select("img"):attr("src"))
        local url = v:attr("href")
        n:setLink(url)
        n:setTitle(url:gsub(baseURL .. "/novel/", ""):gsub("/", ""))
        return n
    end))
end

---@param query string @query to use
---@return string @url
local function getSearchString(query)
    return baseURL .. "/?s=" .. query:gsub("%+", "%2"):gsub(" ", "\\+")
end

return {
    id = 5,
    name = "CreativeNovels",
    imageURL = "https://img.creativenovels.com/images/uploads/2019/04/Creative-Novels-Fantasy1.png",
    genres = {},
    hasCloudFlare = false,
    latestOrder = Ordering(0),
    chapterOrder = Ordering(1),
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
