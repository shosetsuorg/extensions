-- {"ver":"2.0.1","author":"TechnoJo4","dep":["url"]}

local encode = Require("url").encode
local text = function(v)
	return v:text()
end

local settings = {}

local defaults = {
	latestNovelSel = "div.col-12.col-md-6",
	searchNovelSel = "div.c-tabs-item__content",
	novelListingURLPath = "novel",
	novelPageTitleSel = "h3",
	shrinkURLNovel = "novel",
	searchHasOper = false, -- is AND/OR operation selector present?
	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML,
	ajaxUrl = "/wp-admin/admin-ajax.php",
	--- To load chapters for a novel, another request must be made
	doubleLoadChapters = false
}

local ORDER_BY_FILTER_EXT = { "Relevance", "Latest", "A-Z", "Rating", "Trending", "Most Views", "New" }
local ORDER_BY_FILTER_KEY = 2
local AUTHOR_FILTER_KEY = 3
local ARTIST_FILTER_KEY = 4
local RELEASE_FILTER_KEY = 5
local STATUS_FILTER_KEY_COMPLETED = 6
local STATUS_FILTER_KEY_ONGOING = 7
local STATUS_FILTER_KEY_CANCELED = 8
local STATUS_FILTER_KEY_ON_HOLD = 9

function defaults:latest(data)
	return self.parse(GETDocument(self.baseURL .. "/" .. self.novelListingURLPath .. "/page/" .. data[PAGE] .. "/?m_orderby=latest"))
end

---@param tbl table
---@return string
function defaults:createSearchString(tbl)
	local query = tbl[QUERY]
	local orderBy = tbl[ORDER_BY_FILTER_KEY]
	local author = tbl[AUTHOR_FILTER_KEY]
	local artist = tbl[ARTIST_FILTER_KEY]
	local release = tbl[RELEASE_FILTER_KEY]

	local url = self.baseURL .. "/?s=" .. encode(query) .. "&post_type=wp-manga" ..
			"&author=" .. encode(author) ..
			"&artist=" .. encode(artist) ..
			"&release=" .. encode(release)

	if orderBy ~= nil then
		url = url .. "&m_orderby=" .. ({
			[0] = "relevance",
			[1] = "latest",
			[2] = "alphabet",
			[3] = "rating",
			[4] = "trending",
			[5] = "views",
			[6] = "new-manga"
		})[orderBy]
	end
	if tbl[STATUS_FILTER_KEY_COMPLETED] then
		url = url .. "&status[]=end"
	end
	if tbl[STATUS_FILTER_KEY_ONGOING] then
		url = url .. "&status[]=on-going"
	end
	if tbl[STATUS_FILTER_KEY_CANCELED] then
		url = url .. "&status[]=canceled"
	end
	if tbl[STATUS_FILTER_KEY_ON_HOLD] then
		url = url .. "&status[]=on-hold"
	end
	for key, value in pairs(self.genres_map) do
		if tbl[key] then
			url = url .. "&genre[]=" .. value
		end
	end

	if self.searchHasOper then
		url = url .. "&op=" .. (tbl[self.searchOperId] and "0" or "1")
	end

	return self.appendToSearchURL(url, tbl)
end

---@param str string
---@param tbl table
---@return string
function defaults:appendToSearchURL(str, tbl)
	return str
end

---@param tbl table
---@return table
function defaults:appendToSearchFilters(tbl)
	return tbl
end

function defaults:search(data)
	local url = self.createSearchString(data)
	return self.parse(GETDocument(url), true)
end

---@param url string
---@return string
function defaults:getPassage(url)
	local htmlElement = GETDocument(self.expandURL(url)):selectFirst("div.text-left")

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:removeAttr("style") -- Hopefully only temporary as a hotfix
	htmlElement:select("div.lnbad-tag"):remove() -- LightNovelBastion text size

	return pageOfElem(htmlElement)
end

local function img_src(e)
	local srcset = e:attr("data-srcset")

	if srcset ~= "" then
		-- get largest image
		local max, max_url = 0, ""

		for url, size in srcset:gmatch("(http.-) (%d+)w") do
			print("URL: " .. url)
			if tonumber(size) > max then
				max = tonumber(size)
				max_url = url
			end
		end

		return max_url
	end
	return e:attr("src")
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))

	local elements = doc:selectFirst("div.post-content"):select("div.post-content_item")
	local info = NovelInfo {
		description = doc:selectFirst("p"):text(),
		authors = map(elements:get(3):select("a"), text),
		artists = map(elements:get(4):select("a"), text),
		genres = map(elements:get(5):select("a"), text),
		title = doc:selectFirst(self.novelPageTitleSel):text(),
		imageURL = img_src(doc:selectFirst("div.summary_image"):selectFirst("img.img-responsive")),
		status = doc:selectFirst("div.post-status"):select("div.post-content_item"):get(0)
		            :select("div.summary-content"):text() == "OnGoing"
				and NovelStatus.PUBLISHING or NovelStatus.COMPLETED
	}

	-- Chapters
	-- Overrides `doc` if self.doubleLoadChapters is true
	if loadChapters then
		if self.doubleLoadChapters then
			local button = doc:selectFirst("a.wp-manga-action-button")
			local id = button:attr("data-post")

			doc = RequestDocument(
					POST(self.baseURL .. self.ajaxUrl, nil,
							FormBodyBuilder()
									:add("action", "manga_get_chapters")
									:add("manga", id):build())
			)
		end

		local e = doc:select("li.wp-manga-chapter")
		local a = e:size()
		local l = AsList(map(e, function(v)
			local c = NovelChapter()
			c:setLink(self.shrinkURL(v:selectFirst("a"):attr("href")))
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
		novel:setLink(self.shrinkURL(data:attr("href")))
		local tit = data:attr("title")
		if tit == "" then
			tit = data:text()
		end
		novel:setTitle(tit)
		local e = data:selectFirst("img")
		if e then
			novel:setImageURL(img_src(e))
		end
		return novel
	end)
end

function defaults:expandURL(url)
	return self.baseURL .. "/" .. self.shrinkURLNovel .. "/" .. url
end

function defaults:shrinkURL(url)
	return url:gsub("https?://.-/" .. self.shrinkURLNovel .. "/", "")
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })

	_self.genres_map = {}
	local keyID = 100
	local filters = {
		DropdownFilter(ORDER_BY_FILTER_KEY, "Order by", ORDER_BY_FILTER_EXT),
		TextFilter(AUTHOR_FILTER_KEY, "Author"),
		TextFilter(ARTIST_FILTER_KEY, "Artist"),
		TextFilter(RELEASE_FILTER_KEY, "Year of Release"),
		FilterGroup("Status", {
			CheckboxFilter(STATUS_FILTER_KEY_COMPLETED, "Completed"),
			CheckboxFilter(STATUS_FILTER_KEY_ONGOING, "Ongoing"),
			CheckboxFilter(STATUS_FILTER_KEY_CANCELED, "Canceled"),
			CheckboxFilter(STATUS_FILTER_KEY_ON_HOLD, "On Hold")
		}),
		FilterGroup("Genres", map(_self.genres, function(v, k)
			keyID = keyID + 1
			_self.genres_map[keyID] = k or v:lower():gsub(" ", "-")
			return CheckboxFilter(keyID, v)
		end)) -- 6
	}

	if _self.searchHasOper then
		keyID = keyID + 1
		_self.searchOperId = keyID
		filters[#filters + 1] = DropdownFilter(keyID, "Genres Condition", { "OR (any of selected)", "AND (all selected)" })
	end

	filters = _self.appendToSearchFilters(filters)
	_self["searchFilters"] = filters
	_self["baseURL"] = baseURL
	_self["listings"] = { Listing("Default", true, _self.latest) }
	_self["updateSetting"] = function(id, value)
		settings[id] = value
	end

	return _self
end
