-- {"id":911,"ver":"1.0.0","libVer":"1.0.0","author":"TechnoJo4","dep":["url>=1.0.0","dkjson>=1.0.0"]}

local baseURL = "https://creativenovels.com"
local ajaxURL = "https://creativenovels.com/wp-admin/admin-ajax.php"

---@type fun(table, string): string
local qs = Require("url").querystring
---@type dkjson
local json = Require("dkjson")

local function shrinkURL(url, key)
	if key == KEY_NOVEL_URL then
		return url:gsub(baseURL .. "/novel/", "")
	elseif key == KEY_CHAPTER_URL then
		return url:gsub(baseURL .. "/", "")
	end
end

---@param doc Document
local function getSecurity(doc, type)
	local data = first(doc:select("script"), function(v)
		local t = v:html()
		return (t:find("CDATA") ~= nil and t:find(type) ~= nil)
	end):html():match(type .. " *= *(%b{})")
	return json.decode(data)
end

---@param url string
local function getPassage(url)
	return table.concat(map(
			GETDocument(baseURL.."/"..url):selectFirst("div.entry-content.content"):select("p"),
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
local function parseNovel(url, lc)
	local doc = GETDocument(baseURL.."/novel/"..url)
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
				chap:setLink(shrinkURL(chap_url, KEY_CHAPTER_URL))
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
	shrinkURL = shrinkURL,
	expandURL = function(url, key)
		if key == KEY_NOVEL_URL then
			return baseURL .. "/novel/" .. url
		elseif key == KEY_CHAPTER_URL then
			return baseURL .. "/" .. url
		end
	end,
	listings = {
		Listing("Popular", true, function(data)
			local page = data[PAGE]
			local doc = GETDocument(baseURL .. "/browse-new/?sb=rank")
			local dat = getSecurity(doc, "search_results")
			local url = qs({
				action = "search_results", sb = "rank",
				view_id = page,
				security = dat.security,
				gref = "", sta = ""
			}, ajaxURL)
			local res = Request(GET(url)):body():string()

			if page == 1 then
				return map(Document(res):select(".main_library_holder"), function(v)
					local novel = Novel()
					novel:setLink(shrinkURL(v:selectFirst("a"):attr("href"), KEY_NOVEL_URL))
					novel:setTitle(v:selectFirst(".library_title a"):text())
					novel:setImageURL(v:selectFirst("img"):attr("src"))
					return novel
				end)
			else
				local novels = {}
				assert(res:sub(1, 15) == "success.define.", res:sub(1, 15))

				for novelData in res:sub(16):gmatch("(.-)%.data%.") do
					local novel = Novel()
					local iter = novelData:gmatch("(.-)%.in%.")
					novel:setTitle(iter())
					iter()
					iter() -- views, reads
					novel:setImageURL(iter())
					novel:setLink(shrinkURL(iter(), KEY_NOVEL_URL))
					novels[#novels + 1] = novel
				end

				return novels
			end
		end)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
}
