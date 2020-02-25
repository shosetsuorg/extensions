-- {"id":63,"version":"1.0.0","author":"Doomsdayrs","repo":""}

-- Site's novel passages are external

local baseURL = "https://www.fanmily.org"
local settings = {}
local pn = "&page_number="

local function setSettings(setting)
    settings = setting
end

local function parseSearchList(url)
    return map(GETDocument(url):selectFirst("div.book-list-info"):select("li"), function(e)
        local n = Novel()
        local img = e:selectFirst("div.book-img"):selectFirst("a")
        n:setImageURL(img:attr("style"):gsub("background-image: url(\"", ""):gsub("\");", ""))
        n:setLink(baseURL .. img:attr("href"))
        n:setTitle(e:selectFirst("div.book-context"):selectFirst("h4"):text())
        return n
    end)
end

--https://www.fanmily.org/search/list/?editor_choice=True&page_number=1
--- @param inc int @page of said
--- @return Novel[]
local function editorsChoiceList(inc)
    return parseSearchList("https://www.fanmily.org/search/list/?editor_choice=True&page_number=" .. inc)
end


--https://www.fanmily.org/search/list/?top=True&page_number=1
--- @param inc int @page of said
--- @return Novel[]
local function topList(inc)
    return parseSearchList("https://www.fanmily.org/search/list/?top=True&page_number=" .. inc)
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    -- TODO
    return ""
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    -- TODO
    return NovelInfo()
end

--- @param data table @Table of values. Always has "query"
--- @return Novel[]
local function search(data)
    local page = data.page == nil and 0 or data.page
    return parseSearchList("https://www.fanmily.org/search/list/?keywords=" .. data.query:gsub("+", "%2B"):gsub(" ", "+") .. "&page_number=" .. page)
end

return {
    id = -1,
    name = "FANmily",
    imageURL = "https://www.fanmily.org/s/images/fanmily_logo.png",
    listings = {
        Listing("Editors Choice", true, editorsChoiceList),
        Listing("Top List", true, topList)
    },

    -- Default functions that had to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    setSettings = setSettings
}
