-- {"id":573,"version":"1.0.1","author":"Doomsdayrs","repo":""}

local baseURL = "https://www.mtlnovel.com"
local settings = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
}

---@type fun(table, string): string
local qs = Require("url").querystring
local function setSettings(setting) settings = setting end
local function text(v) return v:text() end

---@param element Element
---@return Elements
local function getDetailE(element) return element:select("td"):get(2) end

---@param element Element
---@return string
local function getDetail(element) return text(getDetailE(element)) end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. "/" .. novelURL
    local d = GETDocument(url):selectFirst("article.post")
    local n = NovelInfo()
    n:setTitle(d:selectFirst("h1.entry-title"):text())
    n:setImageURL(d:selectFirst("amp-img.main-tmb"):selectFirst("amp-img.main-tmb"):attr("src"))
    n:setDescription(table.concat(map(d:selectFirst("div.desc"):select("p"), text)))

    local details = d:selectFirst("table.info"):select("tr")

    n:setAlternativeTitles({ getDetail(details:get(0)), getDetail(details:get(1)) })

    local sta = getDetailE(details:get(2)):selectFirst("a"):text()
    n:setStatus(NovelStatus(sta == "Completed" and 1 or sta == "Ongoing" and 0 or 3))

    n:setAuthors({ getDetail(details:get(3)) })
    n:setGenres(map(getDetailE(details:get(6)):select("a"), text))
    n:setTags(map(getDetailE(details:get(10)):select("a"), text))

    d = GETDocument(url .. "/chapter-list/")

    local chapters = d:selectFirst("div.ch-list"):select("a")
    local count = chapters:size()
    local chaptersList = AsList(map(chapters, function(v)
        local c = NovelChapter()
        c:setTitle(v:text():gsub("<strong>", ""):gsub("</strong>", " "))
        c:setLink(v:attr("href"):match(baseURL.."/(.+)/?$"))
        c:setOrder(count)
        count = count - 1
        return c
    end))

    Reverse(chaptersList)
    n:setChapters(chaptersList)
    return n
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local d = GETDocument(baseURL .. "/" .. chapterURL)
    return table.concat(map(d:selectFirst("div.post-content"):select(({[0]="p.en", "p.cn"})[settings.lang]), text), "\n")
end

local function makeListing(listing)
    return function(page)
        local d = GETDocument(baseURL.."/novel-list/"..
                "?orderby="..listing..
                "&order="..({[0]="desc", "asc" })[settings.order]..
                "&status="..({[0]="all", "completed", "ongoing"})[settings.status]..
                "&pg="..page)
        return map(d:select("div.box.wide"), function(v)
            local lis = Novel()
            lis:setImageURL(v:selectFirst("amp-img.list-img"):selectFirst("amp-img.list-img"):attr("src"))
            local title = v:selectFirst("a.list-title")
            lis:setLink(title:attr("href"):match(baseURL .. "/(.+)/"))
            lis:setTitle(title:attr("aria-label"))
            return lis
        end)
    end
end

return {
    id = 573,
    name = "MTLNovel",
    baseURL = baseURL,
    imageURL = baseURL .. "/wp-content/themes/mtlnovel/images/logo32.png",
    hasSearch = false,
    listings = {
        Listing("Date", true, {
            DropdownFilter(2, "Order", { "Descending", "Ascending" }),
            DropdownFilter(3, "Status", { "All", "Completed", "Ongoing" })
        }, makeListing("date")),
        Listing("Name", true, {}, makeListing("name")),
        Listing("Rating", true, {}, makeListing("rating")),
        Listing("Views", true, {}, makeListing("view"))
    },

    getPassage = getPassage,
    parseNovel = parseNovel,
    search = function() end,
    settings = settings,
    setSettings = setSettings
}
