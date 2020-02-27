-- {"id":573,"version":"1.0.0","author":"Doomsdayrs","repo":""}

local baseURL = "https://www.mtlnovel.com"
local settings = {
    orderr = 0,
    sta = 0,
    lang = 0
}

local function setSettings(setting)
    settings = setting
end

local ob = { [0] = "date", [1] = "name", [2] = "rating", [3] = "view" }
local o = { [0] = "desc", [1] = "asc" }
local s = { [0] = "all", [1] = "completed", [2] = "ongoing" }
local la = { [0] = "en", [1] = "cn" }

---
---@param page int
---@param orderBy int @0=Date;1=Name;2=Rating;3=View
---@param order int @0=descending;@1=ascending
---@param status int @0=All;1=Completed;2=Ongoing;
--- @return Novel[]
local function searchList(page, orderBy, order, status)
    orderBy = ob[orderBy]
    order = o[order]
    status = s[status]
    local d = GETDocument(baseURL .. "/novel-list/?orderby=" .. orderBy .. "&order=" .. order .. "&status=" .. status .. "&pg=" .. page)
    return map(d:select("div.box.wide"), function(v)
        local lis = Novel()
        lis:setImageURL(v:selectFirst("amp-img.list-img"):selectFirst("amp-img.list-img"):attr("src"))
        local title = v:selectFirst("a.list-title")
        lis:setLink(title:attr("href"):match(baseURL .. "/(.+)/"))
        lis:setTitle(title:attr("aria-label"))
        return lis
    end)
end

--- @return Novel[]
local function getByDate(page)
    return searchList(page, 0, settings.orderr, settings.sta)
end

--- @return Novel[]
local function getByName(page)
    return searchList(page, 1, settings.orderr == 0 and 1 or 0, settings.sta)
end

--- @return Novel[]
local function getByRating(page)
    return searchList(page, 2, settings.orderr, settings.sta)
end

--- @return Novel[]
local function getByView(page)
    return searchList(page, 3, settings.orderr, settings.sta)
end

---@param element Element
---@return Elements
local function getDetailE(element)
    return element:select("td"):get(2)
end

---@param element Element
---@return string
local function getDetail(element)
    return getDetailE(element):text()
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. "/" .. novelURL
    local d = GETDocument(url):selectFirst("article.post")
    local n = NovelInfo()
    n:setTitle(d:selectFirst("h1.entry-title"):text())
    n:setImageURL(d:selectFirst("amp-img.main-tmb"):selectFirst("amp-img.main-tmb"):attr("src"))
    n:setDescription(table.concat(map(d:selectFirst("div.desc"):select("p"), function(v)
        return v:text()
    end)))

    local details = d:selectFirst("table.info"):select("tr")
    local titles = {}

    titles[1] = getDetail(details:get(0))
    titles[2] = getDetail(details:get(1))
    n:setAlternativeTitles(titles)

    local sta = getDetailE(details:get(2)):selectFirst("a"):text()
    n:setStatus(NovelStatus(sta == "Completed" and 1 or sta == "Ongoing" and 0 or 3))

    n:setAuthors({ getDetail(details:get(3)) })

    n:setGenres(map(getDetailE(details:get(6)):select("a"), function(v)
        return v:text()
    end))

    n:setTags(map(getDetailE(details:get(10)):select("a"), function(v)
        return v:text()
    end))

    d = GETDocument(url .. "/chapter-list/")
    local chapters = d:selectFirst("div.ch-list"):select("a")
    local count = chapters:size()

    local chaptersList = AsList(map(chapters, function(v)
        local c = NovelChapter()
        c:setTitle(v:text():gsub("<strong>", ""):gsub("</strong>", " "))
        c:setLink(v:attr("href"):match(baseURL .. "/(.+)/"))
        c:setOrder(count)
        count = count - 1
        return c
    end))

    Reverse(chaptersList)
    n:setChapters(chaptersList)
    return n
end

--- Does not have
--- @return Novel[]
local function search(data)
    return {}
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local d = GETDocument(baseURL .. "/" .. chapterURL)
    return table.concat(map(d:selectFirst("div.post-content"):select("p." ..la[settings.lang]), function(v)
        v:text()
    end), "\n")
end

return {
    id = 573,
    name = "MTLNovel",
    baseURL = baseURL,
    imageURL = (baseURL .. "/wp-content/themes/mtlnovel/images/logo32.png"),
    hasSearch = false,
    listings = {
        Listing("Date", true, getByDate),
        Listing("Name", true, getByName),
        Listing("Rating", true, getByRating),
        Listing("View", true, getByView)
    },

    -- Default functions that had to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    settings = settings,
    setSettings = setSettings
}
