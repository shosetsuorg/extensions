-- {"id":-1,"version":"9.9.9","author":"","repo":""}

local baseURL = "TODO"

---@param page number @value
---@return string @url of said latest page
local function getLatestURL(page)
    -- TODO Complete
    return ""
end

---@param document Document @Jsoup document of the page with chapter text on it
---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getNovelPassage(document)
    -- TODO Complete
    return ""
end

---@param document Document @Jsoup document of the novel information page
---@return NovelInfo
local function parseNovel(document)
    local novelPage = NovelPage()
    -- TODO Complete
    return novelPage
end

---@param document Document @Jsoup document of the novel information page
---@param increment number @Page #
---@return NovelInfo
local function parseNovelI(document, increment)
    local novelPage = NovelPage()
    -- TODO Complete
    return novelPage
end

---@param url string @url of novel page
---@param increment number @which page
local function novelPageCombiner(url, increment)
    -- TODO Complete
    return ""
end

---@param document Document @Jsoup document of latest listing
---@return Array @Novel array list
local function parseLatest(document)
    -- TODO Complete
    return {}
end

---@param document Document @Jsoup document of search results
---@return Array @Novel array list
local function parseSearch(document)
    -- TODO Complete
    return {}
end

---@param query string @query to use
---@return string @url
local function getSearchString(query)
    -- TODO Complete
    return ""
end

return{
    id = -1,
    name = "DEFAULT",
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
