-- {"id":573,"ver":"2.0.0","libVer":"1.0.0","author":"Doomsdayrs","dep":["url>=1.0.0"]}

local baseURL = "https://www.mtlnovel.com"
local settings = { [1] = 0 }

local ORDER_BYS_INT = { [0] = "date",[1] = "name",[2] = "rating",[3] = "view" }
local ORDER_BYS_KEY = 102

local ORDERS_INT = { [0] = "desc",[1] = "asc" }
local ORDERS_KEY = 103

local STATUES_INT = { [0] = "all",[1] = "completed",[2] = "ongoing" }
local STATUSES_KEY = 104

local function shrinkURL(url)
	return url:gsub("^.-mtlnovel%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

---@type fun(table, string): string
local qs = Require("url").querystring

---@param v Element | Elements
local function text(v)
	return v:text()
end

---@param element Element
---@return Elements
local function getDetailE(element)
	return element:select("td"):get(2)
end

---@param element Element
---@return string
local function getDetail(element)
	return text(getDetailE(element))
end

local function search(data)
	local query = data[QUERY]
	if query ~= nil then
		query = ""
	end
	local m = MediaType("multipart/form-data; boundary=----aWhhdGVrb3RsaW4K")
	local body = RequestBody("------aWhhdGVrb3RsaW4K\r\nContent-Disposition: form-data; name=\"s\"\r\n\r\n" .. data[QUERY] .. "\r\n------aWhhdGVrb3RsaW4K--\r\n", m)
	local doc = RequestDocument(POST(baseURL, nil, body))
	return map(doc:select("div.search-results > div.box"),
			function(v)
				return Novel {
					link = v:selectFirst("a"):attr("href"):match(baseURL .. "/(.+)/"),
					title = v:selectFirst(".list-title"):text(),
					imageURL = v:selectFirst(".list-img"):attr("src")
				}
			end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
	local url = baseURL .. "/" .. novelURL
	local document = GETDocument(url):selectFirst("article.post")
	local n = NovelInfo()
	n:setTitle(document:selectFirst("h1.entry-title"):text())
	n:setImageURL(document:selectFirst("amp-img.main-tmb"):selectFirst("amp-img.main-tmb"):attr("src"))
	n:setDescription(table.concat(map(document:selectFirst("div.desc"):select("p"), text), "\n"))

	local details = document:selectFirst("table.info"):select("tr")
	local details2 = document:select("table.info"):get(1):select("tr")

	n:setAlternativeTitles({ getDetail(details:get(0)),getDetail(details:get(1)) })

	local sta = getDetailE(details:get(2)):selectFirst("a"):text()
	n:setStatus(NovelStatus(sta == "Completed" and 1 or sta == "Ongoing" and 0 or 3))

	n:setAuthors({ getDetail(details:get(3)) })
	n:setGenres(map(getDetailE(details2:get(0)):select("a"), text))
	n:setTags(map(getDetailE(details2:get(5)):select("a"), text))

	document = GETDocument(url .. "/chapter-list/")

	local chapterBox = document:selectFirst("div.ch-list")
	if chapterBox ~= nil then
		local chapters = chapterBox:select("a.ch-link")
		local count = chapters:size()
		local chaptersList = AsList(map(chapters, function(v)
			local c = NovelChapter()
			c:setTitle(v:text():gsub("<strong>", ""):gsub("</strong>", " "))
			c:setLink(v:attr("href"):match(baseURL .. "/(.+)/?$"))
			c:setOrder(count)
			count = count - 1
			return c
		end))
		Reverse(chaptersList)
		n:setChapters(chaptersList)
	end
	return n
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
	local htmlElement = GETDocument(baseURL .. "/" .. chapterURL):selectFirst("article.post")
	local title = htmlElement:selectFirst("span.current-crumb"):text()
	htmlElement = htmlElement:selectFirst("div.par")
	-- Chapter title inserted before chapter text
	htmlElement:child(0):before("<h1>" .. title .. "</h1>");

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:select("div.ads"):remove()

	return pageOfElem(htmlElement, true)
end

return {
	id = 573,
	name = "MTLNovel",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/MTLNovel.png",
	hasSearch = true,
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Novel List", true, function(data)
			local d = GETDocument(baseURL .. "/novel-list/" ..
					"?orderby=" .. ORDER_BYS_INT[data[ORDER_BYS_KEY]] ..
					"&order=" .. ORDERS_INT[data[ORDERS_KEY]] ..
					"&status=" .. STATUES_INT[data[STATUSES_KEY]] ..
					"&pg=" .. data[PAGE])
			return map(d:select("div.box.wide"), function(v)
				local lis = Novel()
				lis:setImageURL(v:selectFirst("amp-img.list-img"):selectFirst("amp-img.list-img"):attr("src"))
				local title = v:selectFirst("a.list-title")
				lis:setLink(title:attr("href"):match(baseURL .. "/(.+)/"))
				lis:setTitle(title:attr("aria-label"))
				return lis
			end)
		end)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	--settings = {
		--  DropdownFilter(1, "Language", { "English", "Chinese" })
	--},
	searchFilters = {
		DropdownFilter(ORDER_BYS_KEY, "Order by", { "Date","Name","Rating","Views" }),
		DropdownFilter(ORDERS_KEY, "Order", { "Descending","Ascending" }),
		DropdownFilter(STATUSES_KEY, "Status", { "All","Completed","Ongoing" })
	},
	--updateSetting = function(id, value)
	--	settings[id] = value
	--end
	search = search
}
