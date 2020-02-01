-- {"version":"1.1.0","author":"TechnoJo4"}

local defaults = {
    hasSearch = true,
    hasCloudFlare = false,
    imageURL = "https://247truyen.com/themes/home/images/favicon.png",
    novelListPath = "novel_list",
    novelSearchPath = "search_novels"
}

---@param page int @increment
function defaults:latest(page)
    return self.parse(GETDocument(self.___baseURL.."/"..self.novelListPath.."?type=latest&category=all&state=all&page=" .. (page <= 0 and 1 or page)))
end

function defaults:search(data)
    local query = data.query
    return self.parse(GETDocument(self.___baseURL .. "/"..self.novelSearchPath.."/" .. query:gsub(" ", "_")))
end

---@param url string
---@return string
function defaults:getPassage(url)
    local doc = GETDocument(url)
    local e = doc:selectFirst("div.vung_doc"):select("p")
    if e:size() == 0 then return "NOT YET TRANSLATED" end
    return table.concat(map(e, function(v) return v:text() end), "\n")
end

---@param url string
---@return NovelInfo
function defaults:parseNovel(url)
    local doc = GETDocument(url)
    local info = NovelInfo()

    -- Image
    info:setImageURL(doc:selectFirst("div.truyen_info_left"):selectFirst("img"):attr("src"))

    -- Bulk data
    do
        local elements = doc:selectFirst("ul.truyen_info_right"):select("li")
        info:setTitle(elements:get(0):selectFirst("h1"):text())

        -- Authors
        info:setAuthors(map(elements:get(1):select("a"), function(v) return v:text() end))
        -- Genres
        info:setGenres(map(elements:get(2):select("a"), function(v) return v:text() end))
        -- Status
        local s = elements:get(3):select("a"):text()
        info:setStatus(NovelStatus(
                s == "ongoing" and 0 or
                        (s == "completed" and 1 or 3)
        ))
    end

    -- Description
    info:setDescription(first(
            doc:selectFirst("div.entry-header"):select("div"),
            function(v) return v:id() == "noidungm" end)
            :text():gsub("<br>", "\n"))

    -- Chapters
    local chapters = doc:selectFirst("div.chapter-list"):select("div.row")
    local a = chapters:size()
    local c = AsList(map(chapters, function(v)
        local chap = NovelChapter()
        local e = v:select("span")
        local titLink = e:get(0):selectFirst("a")
        chap:setTitle(titLink:attr("title"):gsub(info:getTitle(), ""):match("^%s*(.-)%s*$"))
        chap:setLink(titLink:attr("href"))
        chap:setRelease(e:get(1):text())
        chap:setOrder(a)
        a = a - 1
        return chap
    end))
    Reverse(c)
    info:setChapters(c)

    return info
end

---@param doc Document
function defaults:parse(doc)
    return map(doc:select("div.update_item.list_category"), function(v)
        local novel = Novel()
        local e = v:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(v:selectFirst("img"):attr("src"))
        return novel
    end)
end

return function(baseURL, _self)
    _self = setmetatable(_self or {}, {__index = function(_, k)
        local d = defaults[k]
        return (type(d) == "function" and wrap(_self, d) or d)
    end})
    _self["___baseURL"] = baseURL
    _self["listings"] = {
        Listing("Latest", true, _self.latest)
    }
    return _self
end
