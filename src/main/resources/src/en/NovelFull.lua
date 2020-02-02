-- {"id":1,"version":"1.2.4","author":"Doomsdayrs","repo":""}

local baseURL = "http://novelfull.com"
local settings = {}

local function setSettings(setting)
    settings = setting
end

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

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
local function getPassage(chapterURL)
    return table.concat(map(GETDocument(chapterURL):select("div.chapter-c"):select("p"), function(v)
        return v:text()
    end), "\n")
end

--- @param url string @url of novel page
--- @param increment number @which page
local function novelPageCombiner(url, increment)
    return (increment > 1 and (url .. "?page=" .. increment) or url)
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelInfo
local function parseNovel(novelURL)
    local novelPage = NovelInfo()
    local document = GETDocument(novelURL)

    -- Initial
    novelPage:setImageURL(baseURL .. document:selectFirst("div.book"):selectFirst("img"):attr("src"))
    -- max page
    local lastPageURL = document:selectFirst("ul.pagination.pagination-sm"):selectFirst("li.last"):select("a"):attr("href")

    local max = lastPageURL ~= "" and tonumber(lastPageURL:match("%?page=(%d+)&per%-page=")) or 1

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

    local completeChapters = List()
    local order = 0
    for increment = 1, max do
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
                    chap:setOrder(order)
                    order = order + 1
                    return chap
                end))
        completeChapters:addAll(chapters)
        if increment ~= max then
            document = GETDocument(novelPageCombiner(novelURL, increment + 1))
        end
    end

    -- formats chapters
    novelPage:setChapters(completeChapters)

    return novelPage
end

--- @return Array @Novel array list
local function parseLatest(page)
    return map2flat(GETDocument(baseURL .. "/latest-release-novel?page=" .. page):select("div.container"), function(v)
        if v:id() == "list-page" then
            return v:select("div.row")
        end
    end, function(v)
        return stripListing(v:select("div"), Novel())
    end)
end

--- @return Array @Novel array list
local function search(data)
    return map2flat(GETDocument(baseURL .. "/search?keyword=" .. data.query:gsub(" ", "%%20")):select("div.container"), function(v)
        if v:id() == "list-page" then
            return v:select("div.row")
        end
    end, function(v)
        return stripListing(v:select("div"), Novel())
    end)
end

return {
    id = 1,
    name = "NovelFull",
    imageURL = "",
    hasCloudFlare = false,
    hasSearch = true,
    listings = {
        Listing("Latest", true, parseLatest)
    },

    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    setSettings = setSettings
}
