-- {"id":2,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "https://boxnovel.com"

local function map(o, f)
    local t = {}
    for i=1, o:size() do
        t[i] = f(o:get(i-1))
    end
    return t
end

--- @param page number @value
--- @return string @url of said latest page
local function getLatestURL(page)
    return baseURL .. "/novel/page/" .. page .. "/?m_orderby=latest"
end

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
local function getNovelPassage(document)
    return table.concat(map(document:select("div.text-left"):select("p"), function(v) v:text() end), "\n"):gsub("</?p>", "")
end

--- @param document Document @Jsoup document of the novel information page
--- @return NovelPage @java object
local function parseNovel(document)
    local novelPage = NovelPage()
    novelPage:setImageURL(document:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"))
    novelPage:setTitle(document:selectFirst("h3"):text())
    novelPage:setDescription(document:selectFirst("p"):text())

    -- Info
    local elements = document:selectFirst("div.post-content"):select("div.post-content_item")

    -- authors
    novelPage:setAuthors(map(elements:get(3):select("a"), function(v) return v:text() end))
    -- artists
    novelPage:setArtists(map(elements:get(4):select("a"), function(v) return v:text() end))
    -- genres
    novelPage:setGenres(map(elements:get(5):select("a"), function(v) return v:text() end))

    -- sorry for this extremely long line
    novelPage:setStatus(NovelStatus((
            document:selectFirst("div.post-status"):select("div.post-content_item"):get(1)
                    :select("div.summary-content"):text() == "OnGoing") and 0 or 1))

    -- Chapters
    local e = document:select("li.wp-manga-chapter")
    local a = e:size()
    local l = AsList(map(e, function(v)
        local c = NovelChapter()
        c:setLink(v:selectFirst("a"):attr("href"))
        c:setTitle(v:selectFirst("a"):text())
        c:setRelease(v:selectFirst("i"):text())
        c:setOrder(a)
        a = a - 1
        return c
    end))
    Reverse(l)
    novelPage:setNovelChapters(l)

    return novelPage
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelPage @java object
local function parseNovelI(document, increment)
    return parseNovel(document)
end

--- @param url string @url of novel page
--- @param increment number @which page
local function novelPageCombiner(url, increment)
    return url
end

--- @param document Document @Jsoup document of latest listing
--- @return Array @Novel array list
local function parseLatest(document)
    return AsList(map(document:select("div.col-xs-12.col-md-6"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        novel:setImageURL(data:selectFirst("img"):attr("src"))
        return novel
    end))
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
local function parseSearch(document)
    return AsList(map(document:select("div.c-tabs-item__content"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        novel:setImageURL(data:selectFirst("img"):attr("src"))
        return novel
    end))
end

--- @param query string @query to use
--- @return string @url
local function getSearchString(query)
    return baseURL .. "/?s=" .. query:gsub("%+", "%2"):gsub(" ", "+") .. "&post_type=wp-manga"
end

return {
    id = 2,
    name = "BoxNovel",
    imageURL = "https://boxnovel.com/wp-content/uploads/2018/04/BoxNovel-1.png",
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
