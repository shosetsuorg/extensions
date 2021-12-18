-- {"ver":"2.3.2","author":"TechnoJo4","dep":["url"]}

local encode = Require("url").encode
local text = function(v)
	return v:text()
end

local settings = {}

local defaults = {
	latestNovelSel = "div.col-12.col-md-6",
	searchNovelSel = "div.c-tabs-item__content",
	novelListingURLPath = "novel",
	novelPageTitleSel = "div.post-title",
	shrinkURLNovel = "novel",
	searchHasOper = false, -- is AND/OR operation selector present?
	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML,
	-- If chaptersScriptLoaded is true, then a ajax request has to be made to get the chapter list.
	-- Otherwise the chapter list is already loaded when loading the novel overview.
	chaptersScriptLoaded = true,
	chaptersListSelector= "li.wp-manga-chapter",
	-- If ajaxUsesFormData is true, then a POST request will be send to baseURL/ajaxFormDataUrl.
	-- Otherwise to baseURL/shrinkURLNovel/novelurl/ajaxSeriesUrl .
	ajaxUsesFormData = false,
	ajaxFormDataUrl = "/wp-admin/admin-ajax.php",
	ajaxSeriesUrl = "ajax/chapters/"
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
	local page = tbl[PAGE]
	local orderBy = tbl[ORDER_BY_FILTER_KEY]
	local author = tbl[AUTHOR_FILTER_KEY]
	local artist = tbl[ARTIST_FILTER_KEY]
	local release = tbl[RELEASE_FILTER_KEY]

	local url = self.baseURL .. "/page/" .. page ..
			"/?s=" .. encode(query) .. "&post_type=wp-manga" ..
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
	local htmlElement = GETDocument(self.expandURL(url)):selectFirst("div.c-blog-post")
	local title = htmlElement:selectFirst("ol.breadcrumb li.active"):text()
	htmlElement = htmlElement:selectFirst("div.text-left")
	-- Chapter title inserted before chapter text
	htmlElement:child(0):before("<h1>" .. title .. "</h1>");

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:select("div.lnbad-tag"):remove() -- LightNovelBastion text size
	htmlElement:select("i.icon.j_open_para_comment.j_para_comment_count"):remove() -- BoxNovel, VipNovel numbers

	return pageOfElem(htmlElement, true)
end

---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
local function img_src(image_element)
	-- Different extensions have the image(s) saved in different attributes. Not even uniformly for one extension.
	-- Partially this comes down to script loading the pictures. Therefore, scour for a picture in the default HTML page.

	-- Check data-srcset:
	local srcset = image_element:attr("data-srcset")
	if srcset ~= "" then
		-- Get the largest image.
		local max_size, max_url = 0, ""
		for url, size in srcset:gmatch("(http.-) (%d+)w") do
			if tonumber(size) > max_size then
				max_size = tonumber(size)
				max_url = url
			end
		end
		return max_url
	end

	-- Check data-src:
	srcset = image_element:attr("data-src")
	if srcset ~= "" then
		return srcset
	end

	-- Default to src (the most likely place to be loaded via script):
	return image_element:attr("src")
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))
	local content = doc:selectFirst("div.post-content")

	-- Removing HOT or NEW from title.
	local titleElement = doc:selectFirst(self.novelPageTitleSel)
	titleElement:select("span"):remove()

	-- Temporarily saves a Jsoup selection for repeated use. Initial value used for status.
	local selectedContent = doc:selectFirst("div.post-status"):select("div.post-content_item")

	local info = NovelInfo {
		description = table.concat(map(doc:selectFirst("div.summary__content"):select("p"), text), "\n"),
		title = titleElement:text(),
		imageURL = img_src(doc:selectFirst("div.summary_image"):selectFirst("img.img-responsive")),
		status = ({
					OnGoing = NovelStatus.PUBLISHING,
					Completed = NovelStatus.COMPLETED,
					Canceled = NovelStatus.PAUSED,
					["On Hold"] = NovelStatus.PAUSED,
					Ongoing = NovelStatus.PUBLISHING -- Never spotted, but better safe than sorry.
				-- If there is a 'Release' content item then it comes before the 'Status'.
				-- Therefore, select last content item.
				})[selectedContent:get(selectedContent:size()-1):select("div.summary-content"):text()]
	}
	-- Not every Novel has an guaranteed author, artist or genres (looking at you NovelTrench).
	selectedContent = content:selectFirst("div.author-content")
	if selectedContent ~= nil then
		info:setAuthors( map(selectedContent:select("a"), text) )
	end
	selectedContent = content:selectFirst("div.artist-content")
	if selectedContent ~= nil then
		info:setArtists( map(selectedContent:select("a"), text) )
	end
	selectedContent = content:selectFirst("div.genres-content")
	if selectedContent ~= nil then
		info:setGenres( map(selectedContent:select("a"), text) )
	end

	-- Chapters
	-- Overrides `doc` if self.chaptersScriptLoaded is true.
	if loadChapters then
		if self.chaptersScriptLoaded then
			if self.ajaxUsesFormData then
				-- Old method.
				local button = doc:selectFirst("a.wp-manga-action-button")
				local id = button:attr("data-post")

				doc = RequestDocument(
						POST(self.baseURL .. self.ajaxFormDataUrl, nil,
								FormBodyBuilder()
										:add("action", "manga_get_chapters")
										:add("manga", id):build())
				)
			else
				-- Used by BoxNovel, Foxaholic, NovelTrench, LightNovelHeaven, VipNovel and WoopRead.
				doc = RequestDocument(
						POST(self.baseURL .. "/" .. self.shrinkURLNovel .. "/" .. url .. self.ajaxSeriesUrl,
								nil, nil)
				)
			end
		end

		local chapterList = doc:select(self.chaptersListSelector)
		local chapterOrder = chapterList:size()
		local novelList = AsList(map(chapterList, function(v)
			chapterOrder = chapterOrder - 1
			return NovelChapter{
				title = v:selectFirst("a"):text(),
				link = self.shrinkURL(v:selectFirst("a"):attr("href")),
				release = v:selectFirst("span.chapter-release-date"):text(),
				order = chapterOrder
			}
		end))
		Reverse(novelList)
		info:setChapters(novelList)
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

	_self["isSearchIncrementing"] = true
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
