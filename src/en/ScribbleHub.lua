-- {"id":86802,"ver":"1.0.1","libVer":"1.0.0","author":"TechnoJo4","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://www.scribblehub.com"
local qs = Require("url").querystring

local css = Require("CommonCSS").table

local function shrinkURL(url)
	return url:gsub("^.-scribblehub%.com/?", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local default_order = {
	[1] = 2, -- Popularity -> Weekly
	[2] = 4, -- Favorites -> All Time
	[3] = 2, -- Activity -> Weekly
	[4] = 2, -- Readers -> Weekly
	[5] = 1, -- Rising -> Daily
}

local FILTER_SORT = 2
local FILTER_ORDER = 3

local MTYPE = MediaType("application/x-www-form-urlencoded; charset=UTF-8")
local USERAGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0"
local HEADERS = HeadersBuilder():add("User-Agent", USERAGENT):build()

local function parse(doc)
	return map(doc:selectFirst("#page"):select(".wi_fic_wrap .search_main_box"), function(v)
		local t = v:selectFirst(".search_body .search_title a")
		return Novel {
			title = t:text(),
			link = t:attr("href"):match("/series/(%d+)"),
			imageURL = v:selectFirst(".search_img img"):attr("src")
		}
	end)
end

local function GETDoc(url)
	return RequestDocument(GET(url, HEADERS))
end

return {
	id = 86802,
	name = "ScribbleHub",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ScribbleHub.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novels", false, function(data)
			local sort = data[FILTER_SORT] and data[FILTER_SORT] + 1 or 1
			local order = data[FILTER_ORDER]
							and data[FILTER_ORDER] + 1
							or default_order[sort]

			return parse(GETDoc(qs({
				sort = sort, order = order
			}, baseURL .. "/series-ranking/")))
		end)
	},

	searchFilters = {
		DropdownFilter(FILTER_SORT, "Sort by", { "Popularity", "Favorites", "Activity", "Readers", "Rising" }),
		DropdownFilter(FILTER_ORDER, "Order", { "Daily", "Weekly", "Monthly", "All Time" })
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDoc(baseURL.."/series/"..url.."/a/")
		local wrap = doc:selectFirst(".wi_fic_wrap")
		local novel = wrap:selectFirst(".novel-container")
		local r = wrap:selectFirst(".wi-fic_r-content")
		local s = r:selectFirst(".copyright ul"):children()
		s = s:get(s:size() - 1):children()
		s = s:get(s:size() - 1)
		s = s:ownText()
		if s:match("Ongoing") then
			s = NovelStatus.PUBLISHING
		elseif s:match("Complete") then
			s = NovelStatus.COMPLETED
		elseif s:match("Hiatus") then
			s = NovelStatus.PAUSED
		else
			s = NovelStatus.UNKNOWN
		end

		local text = function(v) return v:text() end
		local info = NovelInfo {
			title = novel:selectFirst(".fic_title"):text(),
			imageURL = novel:selectFirst(".novel-cover img"):attr("src"),
			description = wrap:selectFirst(".wi_fic_desc"):text(),
			genres = map(wrap:selectFirst(".wi_fic_genre"):select("a"), text),
			tags = map(wrap:selectFirst(".wi_fic_showtags"):select("a"), text),
			authors = { r:selectFirst("div[property=author] .auth_name_fic"):text() },
			status = s
		}

		if loadChapters then
			local body = RequestBody("action=wi_getreleases_pagination&pagenum=-1&mypostid="..url, MTYPE)
			local cdoc = RequestDocument(POST("https://www.scribblehub.com/wp-admin/admin-ajax.php", HEADERS, body))
			local chapters = AsList(map(cdoc:selectFirst("ol"):select("li"), function(v, i)
				local a = v:selectFirst("a")
				return NovelChapter {
					order = v:attr("order"),
					title = a:text(),
					link = shrinkURL(a:attr("href"))
				}
			end))
			Reverse(chapters)
			info:setChapters(chapters)
		end

		return info
	end,

	getPassage = function(url)
		local chap = GETDoc(expandURL(url)):getElementById("main read chapter")
		local title = chap:selectFirst(".chapter-title"):text()
		chap = chap:getElementById("chp_raw")

		-- remove empty <p> tags
		local toRemove = {}
		chap:traverse(NodeVisitor(function(v)
			if v:tagName() == "p" and v:text() == "" then
				toRemove[#toRemove+1] = v
			end
			if v:hasAttr("border") then
				v:removeAttr("border")
			end
		end, nil, true))
		for _,v in pairs(toRemove) do
			v:remove()
		end

		-- Chapter title inserted before chapter text
		chap:child(0):before("<h1>" .. title .. "</h1>");

		return pageOfElem(chap, false, css)
	end,

	search = function(data)
		return parse(GETDoc(qs({
			s = data[QUERY], post_type = "fictionposts"
		}, baseURL .. "/")))
	end,
	isSearchIncrementing = false
}
