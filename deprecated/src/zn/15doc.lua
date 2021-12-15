-- {"id":163,"ver":"1.0.2","libVer":"1.0.0","author":"Doomsdayrs"}
-- Outputed novelURLs are it's novel IDs
-- Outputed chapterURLs are novelID/chapterID

local baseURL = "http://www.15doc.com"

---@param url string
---@return table
local function parse(url)
	local doc = GETDocument(url)
	return map(doc:selectFirst("ul.item-con"):select("li"), function(v)
		v = v:selectFirst("a")
		local novelListing = Novel()
		novelListing:setTitle(v:text())
		local l = v:attr("href"):gsub(baseURL .. "/info/", ""):gsub(".htm", "")
		novelListing:setLink(l)
		print(novelListing)
		return novelListing
	end)
end

local t = baseURL .. "/top/"
local tF = "/1.htm"

--- 最近更新
--- @return Novel[] | table
local function getByLastUpdate()
	return parse(t .. "lastupdate" .. tF)
end

--- 最新入库
--- @return Novel[] | table
local function getByPostDate()
	return parse(t .. "postdate" .. tF)
end

--- 总排行榜
--- @return Novel[] | table
local function getByAllVisit()
	return parse(t .. "allvisit" .. tF)
end

local fileD = baseURL .. "/files/article/html/"

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
	return GETDocument(fileD .. chapterURL):selectFirst("div.inner"):select("div"):get(1):text()
end

local function parseChapters(novelURL)
	local count = -1;
	return map(GETDocument(fileD .. novelURL .. "/index.html"):selectFirst("dl.chapterlist"):select("dd"), function(v)
		v = v:selectFirst("a")
		if v ~= nil then
			count = count + 1
			return NovelChapter {
				link = novelURL .. "/" .. v:attr("href"),
				title = v:text(),
				order = count
			}
		end
	end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
	local d = GETDocument(baseURL .. "/info/" .. novelURL .. ".htm"):selectFirst("div.details")
	local n = NovelInfo()
	if d ~= nil then
		n:setImageURL(d:selectFirst("img"):attr("src"))
		d = d:selectFirst("div.book-info")

		local ti = d:selectFirst("div.book-title")
		n:setTitle(ti:selectFirst("h1"):text())
		n:setAuthors({ ti:selectFirst("em"):text():gsub("作者：", "") })
		n:setDescription(d:selectFirst("p.book-intro"):text():gsub("<br>", "\n"))
		n:setLanguage("zn")
		-- Ask tecno for help on status
		-- local stats = split(d:selectFirst("p.book-stats"), "\&nbsp;\&nbsp;")

		n:setChapters(AsList(parseChapters(novelURL)))
	end
	return n
end

return {
	id = 163,
	name = "15doc",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/15doc.png",
	hasSearch = false,
	listings = {
		Listing("最近更新", false, getByLastUpdate),
		Listing("最新入库", false, getByPostDate),
		Listing("总排行榜", false, getByAllVisit)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,
}
