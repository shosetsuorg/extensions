-- {"version":"1.2.0","author":"TechnoJo4"}
--- @author Doomsdayrs

local text = function(v)
    return v:text()
end

local settings = {}

local defaults = {
    latestNovelSel = "div.col-12.col-md-6",
    searchNovelSel = "div.c-tabs-item__content",
    novelListingURLPath = "novel",
    novelPageTitleSel = "h3",

    hasCloudFlare = false,
    hasSearch = true
}

---@param page int @increment
function defaults:latest(data, page)
    print(data)
    return self.parse(GETDocument(self.___baseURL .. "/" .. self.novelListingURLPath .. "/page/" .. page .. "/?m_orderby=latest"))
end

function defaults:search(data)
    local query = data[QUERY]
    return self.parse(GETDocument(self.___baseURL .. "/?s=" .. query:gsub("%+", "%2"):gsub(" ", "+") .. "&post_type=wp-manga"), true)
end

---@param url string
---@return string
function defaults:getPassage(url)
    return table.concat(map(GETDocument(url):select("div.text-left p"), text), "\n")
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
    local doc = GETDocument(url)
    local info = NovelInfo()
    info:setImageURL(doc:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"))
    info:setTitle(doc:selectFirst(self.novelPageTitleSel):text())
    info:setDescription(doc:selectFirst("p"):text())

    -- Info
    local elements = doc:selectFirst("div.post-content"):select("div.post-content_item")

    -- authors
    info:setAuthors(map(elements:get(3):select("a"), text))
    -- artists
    info:setArtists(map(elements:get(4):select("a"), text))
    -- genres
    info:setGenres(map(elements:get(5):select("a"), text))

    -- sorry for this extremely long line
    info:setStatus(NovelStatus((
            doc:selectFirst("div.post-status"):select("div.post-content_item"):get(1)
               :select("div.summary-content"):text() == "OnGoing") and 0 or 1))

    -- Chapters
    if loadChapters then
        local e = doc:select("li.wp-manga-chapter")
        local a = e:size()
        local l = AsList(map(e, function(v)
            local c = NovelChapter()
            c:setLink(v:selectFirst("a"):attr("href"))
            c:setTitle(v:selectFirst("a"):text())

            local i = v:selectFirst("i")
            c:setRelease(i and i:text() or v:selectFirst("img[alt]"):attr("alt"))
            c:setOrder(a)
            a = a - 1
            return c
        end))
        Reverse(l)
        info:setChapters(l)
    end

    return info
end

---@param doc Document
---@param search boolean
function defaults:parse(doc, search)
    return map(doc:select(search and self.searchNovelSel or self.latestNovelSel), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setLink(data:attr("href"))
        local tit = data:attr("title")
        if tit == "" then
            tit = data:text()
        end
        novel:setTitle(tit)
        local e = data:selectFirst("img")
        if e then
            novel:setImageURL(e:attr("src"))
        end
        return novel
    end)
end

return function(baseURL, _self)
    _self = setmetatable(_self or {}, { __index = function(_, k)
        local d = defaults[k]
        return (type(d) == "function" and wrap(_self, d) or d)
    end })
    _self["searchFilters"] = {
        DropdownFilter("Order by", { "Relevance", "Latest", "A-Z", "Rating", "Trending", "Most Views", "New" }),
        TextFilter("Author"),
        TextFilter("Artist"),
        TextFilter("Year of Release"),
        FilterGroup("Status", {
            CheckboxFilter("Completed"),
            CheckboxFilter("Ongoing"),
            CheckboxFilter("Canceled"),
            CheckboxFilter("On Hold")
        }),
        FilterGroup("Genres", map(_self.genres, function(v) return CheckboxFilter(v) end))
    }
    _self["___baseURL"] = baseURL
    _self["listings"] = { Listing("default",{}, true, _self.latest) }
    _self["updateSetting"] = function(id, value)
        settings[id] = value
    end
    return _self
end
