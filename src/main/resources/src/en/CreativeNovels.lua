-- {"id":911,"version":"1.0.0","author":"TechnoJo4","repo":""}

local baseURL = "https://creativenovels.com"
local ajaxURL = "https://creativenovels.com/wp-admin/admin-ajax.php"

local settings = {}

---@type fun(table, string): string
local qs = Require("url").querystring
---@type dkjson
local json = Require("dkjson")

---@param doc Document
local function getSecurity(doc, type)
	local data = first(doc:select("script"), function(v)
		local t = v:html()
		return (t:find("CDATA") ~= nil and t:find(type) ~= nil)
	end):html():match(type .. " *= *(%b{})")
	return json.decode(data)
end

local function setSettings(setting)
	settings = setting
end

---@param url string
local function getPassage(url)
	return table.concat(map(
			GETDocument(url):selectFirst("div.entry-content.content"):select("p"),
			function(v)
				return v:text()
			end), "\n")
end

local statuses = {
	["Ongoing"] = 0,
	["Completed"] = 1,
	["Hiatus"] = 2
}

---@param url string
---@param lc boolean @Load Chapters
---@param report fun(status: string): void
local function parseNovel(url, lc, report)
	local doc = GETDocument(url)
	local info = NovelInfo()

	info:setImageURL(doc:selectFirst("img.book_cover"):attr("src"))

	local infobar = doc:selectFirst(".x-bar-content:has(.x-hide-sm.x-hide-xs) .x-bar-container:has(.read_library)")
	info:setTitle(infobar:children():get(1):text())
	info:setGenres({ infobar:selectFirst(".genre_novel"):text() })
	info:setAuthors({ infobar:selectFirst(".x-text-headline + div a"):text() })
	info:setStatus(NovelStatus(statuses[infobar:selectFirst(".novel_status"):text()] or 3))
	info:setTags(map(doc:select(".novel_tag_inner"), function(v)
		return v:text()
	end))

	if lc then
		local data = getSecurity(doc, "chapter_list_summon")
		assert(data.security)

		data = Request(POST(ajaxURL, nil,
				FormBodyBuilder()
						:add("action", "crn_chapter_list")
						:add("view_id", doc:selectFirst("#chapter_list_novel_page"):attr("class"))
						:add("s", data.security):build())):body():string()

		assert(data:sub(1, 15) == "success.define.")
		local iter = data:sub(16):gmatch("(.-)%.e?n?d?_?data%.")

		local i = 1
		local chapters = {}

		while true do
			local chap_url = iter()
			if not chap_url then
				break
			end
			local title = iter():gsub("&#8211;", "–")
			local release = iter()
			if iter() == "available" then
				local chap = NovelChapter()
				chap:setLink(chap_url)
				chap:setTitle(title)
				chap:setRelease(release)
				chap:setOrder(i)
				i = i + 1
				chapters[#chapters + 1] = chap
			end
		end

		info:setChapters(AsList(chapters))
	end

	return info
end

return {
	id = 911,
	name = "Creative Novels",
	baseURL = baseURL,
	imageURL = "https://img.creativenovels.com/images/uploads/2019/04/Creative-Novels-Fantasy1.png",
	hasSearch = false,
	---@param url string
	---@param key int
	shrinkURL = function(url, key)
		if (key == 1) then
			-- N
			return url:gsub(baseURL .. "/novel/", "")
		elseif (key == 2) then
			-- C
			return url:gsub(baseURL .. "/", "")
		end
	end,
	---@param url string
	---@param key int
	expandURL = function(url, key)
		if (key == 1) then
			-- N
			return baseURL .. "/novel/" .. url
		elseif (key == 2) then
			-- C
			return baseURL .. "/" .. url
		end
	end,
	listings = {
		Listing("Popular", true, function(data, page)
			local doc = GETDocument(baseURL .. "/browse-new/?sb=rank")
			local dat = getSecurity(doc, "search_results")
			local url = qs({
				action = "search_results",sb = "rank",
				view_id = page,security = dat.security,
				gref = "",sta = "",
			}, ajaxURL)
			local data = Request(GET(url)):body():string()

			if page == 1 then
				return map(Document(data):select(".main_library_holder"), function(v)
					local novel = Novel()
					novel:setLink(v:selectFirst("a"):attr("href"))
					novel:setTitle(v:selectFirst(".library_title a"):text())
					novel:setImageURL(v:selectFirst("img"):attr("src"))
					return novel
				end)
			else
				local novels = {}
				assert(data:sub(1, 15) == "success.define.", data:sub(1, 15))

				for novelData in data:sub(16):gmatch("(.-)%.data%.") do
					local novel = Novel()
					local iter = novelData:gmatch("(.-)%.in%.")
					novel:setTitle(iter())
					iter()
					iter() -- views, reads
					novel:setImageURL(iter())
					novel:setLink(iter())
					novels[#novels + 1] = novel
				end

				return novels
			end
		end)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = function()
	end,
	updateSetting = function()
	end
}