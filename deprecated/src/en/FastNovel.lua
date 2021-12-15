-- {"id":258,"ver":"1.0.2","libVer":"1.0.0","author":"Doomsdayrs","dep":["url>=1.0.0"]}
-- TODO IMPORTANT: Some text paragraphs of a chapter get decoded via JavaScript. Removal due to those missing paragraphs, which are not obvious to the user.

local baseURL = "https://fastnovel.net"
local encode = Require("url").encode
local settings = {}

local function setSettings(setting)
	settings = setting
end

---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getPassage(url)
	return table.concat(map(GETDocument(baseURL .. url):select("div.box-player"):select("p"), function(v)
		return v:text()
	end), "\n")
end

---@param url string
---@return NovelInfo
local function parseNovel(url)
	local novelPage = NovelInfo()
	local document = GETDocument(baseURL .. url)

	novelPage:setImageURL(document:selectFirst("div.book-cover"):attr("data-original"))
	novelPage:setTitle(document:selectFirst("h1.name"):text())
	novelPage:setDescription(table.concat(map(document:select("div.film-content"):select("p"), function(v)
		return v:text()
	end), "\n"))

	local elements = document:selectFirst("ul.meta-data"):select("li")
	novelPage:setAuthors(map(elements:get(0):select("a"),
			function(v)
				return v:text()
			end))
	novelPage:setGenres(map(elements:get(1):select("a"), function(v)
		return v:text()
	end))

	novelPage:setStatus(NovelStatus(
			elements:get(2):selectFirst("strong"):text():match("Completed") and 1 or 0
	))

	-- chapters
	local volumeName = ""
	local chapterIndex = 0
	local chapters = AsList(map2flat(
			document:selectFirst("div.block-film"):select("div.book"),
			function(element)
				volumeName = element:selectFirst("div.title"):selectFirst("a.accordion-toggle"):text()
				return element:select("li")
			end,
			function(element)
				local chapter = NovelChapter()
				local data = element:selectFirst("a.chapter")
				chapter:setTitle(volumeName .. " " .. data:text())
				chapter:setLink(data:attr("href"))
				chapter:setOrder(chapterIndex)
				chapterIndex = chapterIndex + 1
				return chapter
			end))

	novelPage:setChapters(chapters)
	return novelPage
end

---@return table @Novel array list
local function parseLatest(data)
	return map(GETDocument(baseURL .. "/list/latest.html?page=" .. data[PAGE]):selectFirst("ul.list-film"):select("li.film-item"), function(v)
		local novel = Novel()
		local elem = v:selectFirst("a")
		novel:setLink(elem:attr("href"))
		novel:setTitle(elem:attr("title"))
		novel:setImageURL(elem:selectFirst("div.img"):attr("data-original"))
		return novel
	end)
end

---@return table @Novel array list
local function search(data)
	return map(GETDocument(baseURL .. "/search/" .. encode(data[QUERY])):select("ul.list-film"), function(v)
		local novel = Novel()
		local novelData = v:selectFirst("a")
		novel:setLink(novelData:attr("href"))
		novel:setTitle(novelData:attr("title"))
		novel:setImageURL(novelData:selectFirst("div.img"):attr("data-original"))
		return novel
	end)
end

return {
	id = 258,
	name = "FastNovel",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/FastNovel.png",
	listings = {
		Listing("Latest", true, parseLatest)
	},
	---@param url string
	shrinkURL = function(url)
		return url:gsub(baseURL .. "/", "")
	end,
	---@param url string
	---@param key int
	expandURL = function(url, key)
		return baseURL .. "/" .. url
	end,
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	isSearchIncrementing = false,
}
