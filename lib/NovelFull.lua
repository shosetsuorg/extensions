-- {"ver":"2.0.1","author":"TechnoJo4","dep":["url"]}

-- rename this if you ever figure out its real name

---@type fun(tbl: table , url: string): string
local qs = Require("url").querystring

local text = function(v)
	return v:text()
end

local defaults = {
	meta_offset = 1,
	ajax_hot = "/ajax/hot-novels",
	ajax_latest = "/ajax/latest-novels",
	ajax_chapters = "/ajax/chapter-option",
	appendURLToInfoImage = true,
	searchTitleSel = ".novel-title",

	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML
}

function defaults:search(data)
	-- search gives covers but they're in some weird aspect ratio
	local doc = GETDocument(qs({ keyword = data[QUERY] }, self.baseURL .. "/search"))
	local pager = doc:selectFirst(".pagination.pagination-sm")
	local pages = {
		map(doc:selectFirst("div." .. self.searchListSel):select("div.row"), function(v)
			local novel = Novel()
			novel:setImageURL(v:selectFirst("img.cover"):attr("src"))
			local d = v:selectFirst(self.searchTitleSel .. " a")
			novel:setLink(d:attr("href"))
			novel:setTitle(d:attr("title"))
			return novel
		end)
	}
	if pager then
		local last = pager:selectFirst("li.last:not(.disabled) a")
		if not last then
			last = pager:select("li a[data-page]")
			last = last:get(last:size())
		end
		last = tonumber(last:attr("data-page")) + 1

		for i = 2, last do
			pages[i] = map(GETDocument(qs({ s = data[QUERY],page = data[PAGE] }, self.baseURL .. "/search")):select(".novel-title a"),
					function(v)
						local novel = Novel()
						novel:setLink(self.shrinkURL(v:attr("href")))
						novel:setTitle(v:attr("title"))
						return novel
					end)
		end
	end

	return flatten(pages)
end

function defaults:getPassage(url)
	local htmlElement = GETDocument(self.baseURL..url):selectFirst("div#chapter-content")

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:removeAttr("style") -- Hopefully only temporary as a hotfix
	htmlElement:select("script"):remove()
	htmlElement:select("ins"):remove()
	htmlElement:select("div.ads"):remove()
	htmlElement:select("div[align=\"left\"]:last-child"):remove() -- Report error text

	return pageOfElem(htmlElement)
end

function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.baseURL..url)
	local info = NovelInfo()

	local elem = doc:selectFirst(".info"):children()
	info:setTitle(doc:selectFirst("h3.title"):text())

	local meta_offset = elem:size() < 3 and self.meta_offset or 0

	info:setArtists(map(elem:get(meta_offset):select("a"), text))
	info:setGenres(map(elem:get(meta_offset + 1):select("a"), text))
	info:setStatus(NovelStatus(elem:get(meta_offset + 3):select("a"):text() == "Completed" and 1 or 0))

	info:setImageURL((self.appendURLToInfoImage and self.baseURL or "") .. doc:selectFirst("div.book img"):attr("src"))
	info:setDescription(table.concat(map(doc:select("div.desc-text p"), text), "\n"))

	if loadChapters then
		local id = doc:selectFirst("div[data-novel-id]"):attr("data-novel-id")
		local i = 0
		info:setChapters(AsList(map(
				GETDocument(qs({ novelId = id,currentChapterId = "" }, self.ajax_base .. self.ajax_chapters)):selectFirst("select"):children(),
				function(v)
					local chap = NovelChapter()
					chap:setLink(self.shrinkURL(v:attr("value")))
					chap:setTitle(v:text())
					chap:setOrder(i)
					i = i + 1
					return chap
				end)))
	end

	return info
end

---@param url string
function defaults:shrinkURL(url)
	return url:gsub(self.baseURL, "")
end

---@param url string
function defaults:expandURL(url)
	return self.baseURL .. url
end

return function(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })
	_self["baseURL"] = baseURL
	if not _self["ajax_base"] then
		_self["ajax_base"] = baseURL
	end
	_self["listings"] = {
		Listing("Hot", false, function()
			return map(GETDocument(_self.ajax_base .. _self.ajax_hot):select("div.item a"), function(v)
				local novel = Novel()
				novel:setImageURL(baseURL .. v:selectFirst("img"):attr("src"))
				novel:setTitle(v:attr("title"))
				novel:setLink(v:attr("href"))
				return novel
			end)
		end),
		Listing("Latest", false, function()
			return map(GETDocument(_self.ajax_base .. _self.ajax_latest):select("div.row .col-title a"), function(v)
				local novel = Novel()
				novel:setTitle(v:text())
				novel:setLink(v:attr("href"))
				return novel
			end)
		end)
	}
	return _self
end
