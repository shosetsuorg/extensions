-- {"id":93082,"ver":"1.0.0","libVer":"1.0.0","author":"Doomsdayrs","dep":[]}
local baseURL = "https://www.nanomashin.online"

--- @param novelURL string @URL of novel
--- @param loadChapters boolean
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
	local novelInfo = NovelInfo()
	local document = GETDocument(baseURL .. novelURL)
	novelInfo:setTitle(document:selectFirst("h1.text-2xl"):text())
	novelInfo:setImageURL(baseURL .. document:selectFirst("img.object-contain"):attr("src"))
	novelInfo:setDescription(document:selectFirst("div.pt-6.pb-8"):selectFirst("div.pt-6.pb-8"):text())

	if loadChapters then
		local navBox = document:selectFirst("nav.flex")
		local chapters = {}

		--- @param chaptersDocument Document
		local function parseChapters(chaptersDocument)
			return map(chaptersDocument:select("article.space-y-2"), function(article)
				local c = NovelChapter()
				local titleElement = article:selectFirst("a")
				c:setTitle(titleElement:text())
				c:setLink(titleElement:attr("href"))
				c:setRelease(article:selectFirst("time"):text())
				return c
			end)
		end

		chapters = chapters + parseChapters(document)
		-- There is more chapters via pages
		if navBox ~= nil then
			local maxPage = tonumber(navBox:selectFirst("span"):text():gsub("%d of", ""))

			for page = 2, maxPage do
				local chaptersDocument = GETDocument(baseURL .. novelURL .. "/page/" .. page)
				chapters = chapters + parseChapters(chaptersDocument)
			end
		end

		local chaptersList = AsList(chapters)
		Reverse(chaptersList)
		novelInfo:setChapters(chaptersList)
	end
end

---@param v Element | Elements
local function text(v)
	return v:text()
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
	local d = GETDocument(baseURL .. "/" .. chapterURL)
	return table.concat(map(d:selectFirst("div.pt-10"):select("p"), text), "\n")
end


return {
	id = 93082,
	name = "NM Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NMTranslations.png",
	hasSearch = false,
	listings = {
		Listing("Projects", false, function()
			local d = GETDocument(baseURL .. "/projects")

			return map(d:select("div.p-4"), function(v)
				local lis = Novel()
				local title = v:selectFirst("h2.mb-3")

				lis:setTitle(title:text())
				lis:setLink(title:selectFirst("href"))

				local imageURL = v:selectFirst("img.object-cover")
				lis:setImageURL(baseURL .. imageURL:attr("src"))
				return lis
			end)
		end)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	--settings = {
	--  DropdownFilter(1, "Language", { "English", "Chinese" })
	--},
	--updateSetting = function(id, value)
	--	settings[id] = value
	--end
}