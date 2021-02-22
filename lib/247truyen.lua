-- {"ver":"1.1.2","author":"TechnoJo4"}

local defaults = {
	hasSearch = true,
	hasCloudFlare = false,
	imageURL = "https://bestlightnovel.com/themes/home/images/favicon.png",
	novelListPath = "novel_list",
	novelSearchPath = "search_novels",
	novelListingTitleClass = ".nowrap",
	shrinkURLNovel = "novel_"
}

---@return table
function defaults:latest(data)
	return self.parse(GETDocument(
			self.___baseURL .. "/" .. self.novelListPath .. "?type=latest&category=all&state=all&page=" .. data[PAGE]
	))
end

---@return table
function defaults:search(data)
	return self.parse(GETDocument(self.___baseURL ..
			"/" .. self.novelSearchPath ..
			"/" .. data[QUERY]:gsub(" ", "_") ..
			"?page=" .. data[PAGE] or "1"))
end

---@param url string
---@return string
function defaults:getPassage(url)
	local doc = GETDocument(self.___baseURL.."/"..self.shrinkURLNovel..url)
	local e = doc:selectFirst("div.vung_doc")
			:select("p")
	if e:size() == 0 then
		return "NOT YET TRANSLATED"
	end
	return table.concat(map(e, function(v)
		return v:text()
	end), "\n")
end

---@param url string
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))
	local info = NovelInfo()

	-- Image
	info:setImageURL(doc:selectFirst("div.truyen_info_left"):selectFirst("img"):attr("src"))

	-- Bulk data
	do
		local elements = doc:selectFirst("ul.truyen_info_right"):select("li")
		info:setTitle(elements:get(0):selectFirst("h1"):text())

		-- Authors
		info:setAuthors(map(elements:get(1):select("a"), function(v)
			return v:text()
		end))
		-- Genres
		info:setGenres(map(elements:get(2):select("a"), function(v)
			return v:text()
		end))
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
			function(v)
				return v:id() == "noidungm"
			end)
			:text():gsub("<br>", "\n"))

	-- Chapters
	if loadChapters then
		local chapters = doc:selectFirst("div.chapter-list"):select("div.row")
		local a = chapters:size()
		local c = AsList(map(chapters, function(v)
			local e = v:select("span")
			local titLink = e:get(0):selectFirst("a")
			local chap = NovelChapter {
				title = titLink:attr("title"):gsub(info:getTitle(), ""):match("^%s*(.-)%s*$"),
				release = e:get(1):text(),
				link = self.shrinkURL(titLink:attr("href")),
				order = a
			}
			a = a - 1
			return chap
		end))
		Reverse(c)
		info:setChapters(c)
	end

	return info
end

---@param doc Document
---@return table
function defaults:parse(doc)
	return map(doc:select("div.update_item.list_category"), function(v)
		local e = v:selectFirst("h3" .. self.novelListingTitleClass):selectFirst("a")
		return Novel {
			title = e:attr("title"),
			link = self.shrinkURL(e:attr("href")),
			imageURL = v:selectFirst("img"):attr("src")
		}
	end)
end

---@param url string
function defaults:shrinkURL(url)
	return url:gsub(self.___baseURL .. "/" .. self.shrinkURLNovel .. "", "")
end

---@param url string
function defaults:expandURL(url)
	return self.___baseURL .. "/" .. self.shrinkURLNovel .. "" .. url
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })
	_self["___baseURL"] = baseURL
	_self["listings"] = {
		Listing("Latest", true, _self.latest)
	}
	return _self
end
