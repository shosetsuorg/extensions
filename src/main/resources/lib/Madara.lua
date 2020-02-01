-- {"version":"1.0.0","author":"TechnoJo4"}
--- @author Doomsdayrs
--- @version 1.2.0

local defaults = {
    latestNovelSel = "div.col-12.col-md-6",
    novelListingURLPath = "novel",
    novelPageTitleSel = "h3",

    hasCloudFlare = false,
    latestOrder = Ordering(0),
    chapterOrder = Ordering(0),
    isIncrementingChapterList = false,
    isIncrementingPassagePage = false,
    hasSearch = true,
    hasGenres = false
}

---@return string
function defaults:getLatestURL(page)
    return self.___baseURL .. "/" .. self.novelListingURLPath .. "/page/" .. page .. "/?m_orderby=latest"
end

---@param document Document
---@return string
function defaults:getNovelPassage(document)
    return table.concat(map(document:select("div.text-left p"), function(v)
        return v:text()
    end), "\n")
end

---@param document Document
---@return NovelInfo
function defaults:parseNovel(document)
    local novelPage = NovelInfo()
    novelPage:setImageURL(document:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"))
    novelPage:setTitle(document:selectFirst(self.novelPageTitleSel):text())
    novelPage:setDescription(document:selectFirst("p"):text())

    -- Info
    local elements = document:selectFirst("div.post-content"):select("div.post-content_item")

    -- authors
    novelPage:setAuthors(map(elements:get(3):select("a"), function(v)
        return v:text()
    end))
    -- artists
    novelPage:setArtists(map(elements:get(4):select("a"), function(v)
        return v:text()
    end))
    -- genres
    novelPage:setGenres(map(elements:get(5):select("a"), function(v)
        return v:text()
    end))

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

        local i = v:selectFirst("i")
        c:setRelease(i and i:text() or v:selectFirst("img[alt]"):attr("alt"))

        c:setOrder(a)
        a = a - 1
        return c
    end))
    Reverse(l)
    novelPage:setChapters(l)

    return novelPage
end

---@param document Document
---@return NovelInfo
function defaults:parseNovelI(document, increment)
    return self.parseNovel(document)
end

function defaults:novelPageCombiner(url, increment)
    return url
end

---@param doc Document
function defaults:parseLatest(doc)
    return AsList(map(doc:select(self.latestNovelSel), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        local img = data:selectFirst("img")
        if img then
            novel:setImageURL(img:attr("src"))
        end
        return novel
    end))
end

---@param doc Document
function defaults:parseSearch(doc)
    return AsList(map(doc:select("div.c-tabs-item__content"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        novel:setImageURL(data:selectFirst("img"):attr("src"))
        return novel
    end))
end

---@param query string
function defaults:getSearchString(query)
    return self.___baseURL .. "/?s=" .. query:gsub("%+", "%2"):gsub(" ", "+") .. "&post_type=wp-manga"
end

return function(baseURL, _self)
    _self = _self or {}
    _self["___baseURL"] = baseURL
    return setmetatable(_self, { __index = function(self, k)
        local d = defaults[k]
        return (type(d) == "function" and wrap(_self, d) or d)
    end })
end
