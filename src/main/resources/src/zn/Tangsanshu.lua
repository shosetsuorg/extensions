-- {"id":234,"version":"1.0.0","author":"Doomsdayrs","repo":""}

local baseURL = "http://www.tangsanshu.com"

local settings = {}

local function setSettings(setting)
    settings = setting
end

---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getPassage(url)
    return GETDocument(url):selectFirst("div.showtxt"):html():gsub("<br ?/?>", "\n"):gsub("\n+", "\n"):gsub("&nbsp;", "")
end

---@return NovelInfo
local function parseNovel(url, loadChapters)
    local novelPage = NovelInfo()
    local document = GETDocument(url)
    -- Info

    local info = document:selectFirst("div.info")
    novelPage:setTitle(info:selectFirst("h2"):text())
    novelPage:setImageURL(baseURL .. info:selectFirst("img"):attr("src"))

    local items = info:selectFirst("div.small"):select("span")

    novelPage:setAuthors({ items:get(0):text():gsub("作者：", "") })

    novelPage:setGenres({ items:get(1):text():gsub("分类：", ""):gsub("小说", "") })

    local status = items:get(2):text():gsub("状态：", "")
    novelPage:setStatus(NovelStatus(status == "完本" and 1 or status == "连载中" and 0 or 3))
    novelPage:setDescription(info:selectFirst("div.intro"):text():gsub("<span>简介：</span>", ""):gsub("<br>", "\n"))

    -- NovelChapters
    if loadChapters then
        local found = false
        local i = 0
        novelPage:setChapters(AsList(mapNotNil(document:selectFirst("div.listmain"):selectFirst("dl"):children(), function(v)
            if found then
                local chapter = NovelChapter()
                chapter:setOrder(i)
                local data = v:selectFirst("a")
                chapter:setTitle(data:text())
                chapter:setLink(baseURL .. data:attr("href"))
                i = i + 1
                return chapter
            else
                if v:text():match("正文卷") then
                    found = true
                end
                return nil
            end
        end)))
    end
    return novelPage
end

---@return Array @Novel array list
local function latest()
    local document = GETDocument(baseURL)
    return map(document:selectFirst("div.up"):selectFirst("div.l"):select("li"), function(v)
        local novel = Novel()
        local data = v:selectFirst("span.s2"):selectFirst("a")
        novel:setTitle(data:text())
        novel:setLink(baseURL .. data:attr("href"))
        return novel
    end)
end

--- @param data table @Table of values. Always has "query"
---@return Array @Novel array list
local function search(data)
    document = GETDocument(baseURL .. "/s.php?ie=utf-8&q=" .. data.query:gsub("+", "%2B"):gsub(" ", "+"))
    return map(document:select("div.bookbox"), function(v)
        local novel = Novel()
        local data = document:selectFirst("h4.bookname"):selectFirst("a")
        novel:setTitle(data:text())
        novel:setLink(baseURL .. data:attr("href"))
        novel:setImageURL(baseURL .. document:selectFirst("a"):attr("href"))
    end)
end


return {
    id = 234,
    name = "Tangsanshu",
    imageURL = "http://www.tangsanshu.com/images/logo.png",
    hasCloudFlare = false,
    hasSearch = true,
    listings = {
        Listing("Latest", false, latest)
    },
    -- Default functions that had to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    setSettings = setSettings
}