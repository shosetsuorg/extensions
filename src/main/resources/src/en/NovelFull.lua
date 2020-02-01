-- {"id":1,"version":"1.2.4","author":"Doomsdayrs","repo":""}

local baseURL = "http://novelfull.com"

---@param elements Elements
---@param novel Novel
local function stripListing(elements, novel)
    local col = elements:get(0)
    local image = col:selectFirst("img")
    if image then
        novel:setImageURL(baseURL .. image:attr("src"))
    end

    local header = col:selectFirst("h3")
    if header then
        local titleLink = header:selectFirst("a")
        novel:setTitle(titleLink:attr("title"))
        novel:setLink(baseURL .. titleLink:attr("href"))
    end

    return novel
end

--- @param page number @value
--- @return string @url of said latest page
local function getLatestURL(page)
    print(baseURL, page)
    return baseURL .. "/latest-release-novel?page=" .. page
end

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
local function getNovelPassage(document)
    return table.concat(map(document:select("div.chapter-c"):select("p"), function(v)
        return v:text()
    end), "\n")
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelInfo
local function parseNovelI(document, increment)
    print("LUA: Starting")
    local novelPage = NovelPage()
    novelPage:setImageURL(baseURL .. document:selectFirst("div.book"):selectFirst("img"):attr("src"))

    -- max page
    local lastPageURL = document:selectFirst("ul.pagination.pagination-sm"):selectFirst("li.last"):select("a"):attr("href")
    novelPage:setMaxChapterPage(lastPageURL ~= ""
            and tonumber(lastPageURL:match("%?page=(%d+)&per%-page="))
            or increment)

    -- title, description
    local titleDesc = document:selectFirst("div.col-xs-12.col-sm-8.col-md-8.desc")
    novelPage:setTitle(titleDesc:selectFirst("h3"):text())
    novelPage:setDescription(table.concat(map(titleDesc:selectFirst("div.desc-text"):select("p"), function(v)
        return v:text()
    end), "\n"))

    -- set information
    local elements = document:selectFirst("div.info"):select("div.info"):select("div")
    novelPage:setAuthors(map(elements:get(1):select("a"), function(v)
        return v:text()
    end))
    novelPage:setGenres(map(elements:get(2):select("a"), function(v)
        return v:text()
    end))
    novelPage:setStatus(NovelStatus(
            elements:get(4):select("a"):text() == "Completed" and 1 or 0
    ))

    -- formats chapters
    local a = (increment - 1) * 50
    local chapters = AsList(map2flat(document:select("ul.list-chapter"),
            function(v)
                return v:select("li")
            end, function(v)
                local chap = NovelChapter()
                local data = v:selectFirst("a")
                local link = data:attr("href")
                if link then
                    chap:setLink(baseURL .. link)
                end
                chap:setTitle(data:attr("title"))
                chap:setOrder(a)
                a = a - 1
                return chap
            end))

    novelPage:setNovelChapters(chapters)

    return novelPage
end

--- @param document Document @Jsoup document of the novel information page
--- @return NovelInfo
local function parseNovel(document)
    return parseNovelI(document, 1)
end

--- @param url string @url of novel page
--- @param increment number @which page
local function novelPageCombiner(url, increment)
    return (increment > 1 and (url .. "?page=" .. increment) or url)
end

--- @param document Document @Jsoup document of latest listing
--- @return Array @Novel array list
local function parseLatest(document)
    return AsList(map2flat(document:select("div.container"), function(v)
        if v:id() == "list-page" then
            return v:select("div.row")
        end
    end, function(v)
        return stripListing(v:select("div"), Novel())
    end))
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
local function parseSearch(document)
    return AsList(map2flat(document:select("div.container"), function(v)
        if v:id() == "list-page" then
            return v:select("div.row")
        end
    end, function(v)
        return stripListing(v:select("div"), Novel())
    end))
end

--- @param query string @query to use
--- @return string @url
local function getSearchString(query)
    return baseURL .. "/search?keyword=" .. query:gsub(" ", "%%20")
end

return {
    id = 1,
    name = "NovelFull",
    imageURL = "",
    genres = {},
    hasCloudFlare = false,
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
