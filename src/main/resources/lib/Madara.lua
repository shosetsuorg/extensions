-- {"version":"1.2.0","author":"TechnoJo4","dep":["url"]}

local url = Require("url")
local text = function(v)
	return v:text()
end

local genres_map = {}
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
	return self.parse(GETDocument(self.baseURL .. "/" .. self.novelListingURLPath .. "/page/" .. page .. "/?m_orderby=latest"))
end

--- @param table table
------@return string
function defaults:createSearchString(table)
	local query = table[QUERY]
	local orderBy = table[1]
	local author = table[2]
	local artist = table[3]
	local release = table[4]
	local stati = table[5]

	local url = self.baseURL .. "/?s=" .. url.encode(query) .. "&post_type=wp-manga" ..
			"&author=" .. url.encode(author) ..
			"&artist=" .. url.encode(artist) ..
			"&release=" .. url.encode(release)

	url = url .. "&m_orderby=" .. ({
		[0] = "relevance",
		[1] = "latest",
		[2] = "alphabet",
		[3] = "rating",
		[4] = "trending",
		[5] = "views",
		[6] = "new-manga"
	})[orderBy]

	if stati ~= nil then
		if stati[0] then
			url = url .. "&status[]=end"
		end
		if stati[1] then
			url = url .. "&status[]=on-going"
		end
		if stati[2] then
			url = url .. "&status[]=canceled"
		end
		if stati[3] then
			url = url .. "&status[]=on-hold"
		end
	end

	local genres = table[6]
	if genres ~= nil then
		for i = 0, rawlen(genres_map) do
			if genres[i] then
				url = url .. "&genre[]=" .. genres_map[i]
			end
		end
	end
	url = self.appendToSearchURL(url, table)
	return url
end

---@param string string
---@param table table
---@return string
function defaults:appendToSearchURL(string, table)
	return string
end

---@param table table
---@return table
function defaults:appendToSearchFilters(table)
	return table
end

function defaults:search(data)
	local url = self.createSearchString(data)
	return self.parse(GETDocument(url), true)
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
	local keyID = 0;
	local filters = {
		DropdownFilter("Order by", { "Relevance", "Latest", "A-Z", "Rating", "Trending", "Most Views", "New" }), -- 1`
		TextFilter("Author"), -- 2
		TextFilter("Artist"), -- 3
		TextFilter("Year of Release"), -- 4
		FilterGroup("Status", { -- 5
			CheckboxFilter("Completed"), -- 1
			CheckboxFilter("Ongoing"), -- 2
			CheckboxFilter("Canceled"), -- 3
			CheckboxFilter("On Hold") -- 4
		}),
		FilterGroup("Genres", map(_self.genres, function(v, k)
			genres_map[keyID] = v:getName():lower():match("(%a+)")
			k = k + 1
			return CheckboxFilter(v)
		end)) -- 6
	}
	filters = _self.appendToSearchFilters(filters)
	_self["searchFilters"] = filters
	_self["baseURL"] = baseURL
	_self["listings"] = {
		Listing("default", {}, true, _self.latest)
	}
	_self["updateSetting"] = function(id, value)
		settings[id] = value
	end
	return _self
end
