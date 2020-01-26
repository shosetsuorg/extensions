local defaults = {
    genres = {},
    hasCloudFlare = false,
    latestOrder = Ordering(0),
    chapterOrder = Ordering(0),
    isIncrementingChapterList = false,
    isIncrementingPassagePage = false,
    hasSearch = true,
    hasGenres = false,
    imageURL = "https://247truyen.com/themes/home/images/favicon.png",
    novelListPath = "novel_list",
    novelSearchPath = "search_novels"
}

---@return string
function defaults:getLatestURL(page)
    return self.___baseURL.."/"..self.novelListPath.."?type=latest&category=all&state=all&page=" .. (page <= 0 and 1 or page)
end

---@param document Document
---@return string
function defaults:getNovelPassage(document)
    local e = document:selectFirst("div.vung_doc"):select("p")
    if e:size() == 0 then return "NOT YET TRANSLATED" end
    return table.concat(map(e, function(v) return v:text() end), "\n")
end

---@param document Document
---@return NovelPage
function defaults:parseNovel(document)
    local novelPage = NovelPage()
    -- Image
    novelPage:setImageURL(document:selectFirst("div.truyen_info_left"):selectFirst("img"):attr("src"))

    -- Bulk data
    do
        local elements = document:selectFirst("ul.truyen_info_right"):select("li")
        novelPage:setTitle(elements:get(0):selectFirst("h1"):text())

        -- Authors
        novelPage:setAuthors(map(elements:get(1):select("a"), function(v) return v:text() end))
        -- Genres
        novelPage:setGenres(map(elements:get(2):select("a"), function(v) return v:text() end))
        -- Status
        local s = elements:get(3):select("a"):text()
        novelPage:setStatus(NovelStatus(
                s == "ongoing" and 0 or
                        (s == "completed" and 1 or 3)
        ))
    end

    -- Description
    novelPage:setDescription(first(
            document:selectFirst("div.entry-header"):select("div"),
            function(v) return v:id() == "noidungm" end)
            :text():gsub("<br>", "\n"))


    -- Chapters
    local chapters = document:selectFirst("div.chapter-list"):select("div.row")
    local a = chapters:size()
    local c = AsList(map(chapters, function(v)
        local chap = NovelChapter()
        local e = v:select("span")
        local titLink = e:get(0):selectFirst("a")
        chap:setTitle(titLink:attr("title"):gsub(novelPage:getTitle(), ""):match("^%s*(.-)%s*$"))
        chap:setLink(titLink:attr("href"))
        chap:setRelease(e:get(1):text())
        chap:setOrder(a)
        a = a - 1
        return chap
    end))
    Reverse(c)
    novelPage:setNovelChapters((c))

    return novelPage
end

---@param document Document
---@return NovelPage
function defaults:parseNovelI(document, increment)
    return self.parseNovel(document)
end

function defaults:novelPageCombiner(url, increment) return url end

---@param doc Document
function defaults:parseLatest(doc)
    return AsList(map(doc:select("div.update_item.list_category"), function(v)
        local novel = Novel()
        local e = v:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(v:selectFirst("img"):attr("src"))
        return novel
    end))
end

---@param doc Document
function defaults:parseSearch(doc)
    return AsList(map(doc:select("div.update_item.list_category"), function(v)
        local novel = Novel()
        local e = v:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(v:selectFirst("img"):attr("src"))
        return novel
    end))
end

---@param query string
function defaults:getSearchString(query)
    return self.___baseURL .. "/"..self.novelSearchPath.."/" .. query:gsub(" ", "_")
end

return function(baseURL, _self)
    _self = _self or {}
    _self["___baseURL"] = baseURL
    return setmetatable(_self, { __index = function(_, k)
        local d = defaults[k]
        return (type(d) == "function" and wrap(_self, d) or d)
    end })
end
