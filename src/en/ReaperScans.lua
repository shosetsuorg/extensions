-- {"id":4223,"ver":"2.0.0","libVer":"1.0.0","author":"Doomsdayrs"}

local baseURL = "https://reaperscans.com"

local function shrinkURL(url)
	return url:match(baseURL .. "/novels/(.+)/")
end

local function expandURL(url)
	return baseURL .. "/novels/" .. url
end

local function getPassage(chapterURL)
	local url = baseURL .. "/" .. chapterURL
	local document = GETDocument(url)
	local htmlElement = document:selectFirst("section.p-2")

	return pageOfElem(htmlElement, true)
end

local function parseNovel(novelURL)
	local url = baseURL .. "/" .. novelURL
	local document = GETDocument(url):selectFirst("article.post")
	local novelInfo = NovelInfo()
	
	local headerNChapters = document:selectFirst("div.p-2.space-y-4")
	
	-- Header
	local headerElement = headerNChapters:selectFirst("div.mx-auto")

	local titleElement = headerNChapters:selectFirst("h1")
	novelInfo:setTitle(titleElement:text())

	local imageElement = headerElement:selectFirst("img")
	novelInfo:setImageURL(imageElement:attr("src"))
	
	-- About	
	local aboutElement = document:selectFirst("div.lg\:col-span-1")

	local descriptionElement = aboutElement:selectFirst("p")
	novelInfo:setDescription(descriptionElement:text():gsub("<br>","\n"))
		
	local otherElements = document:selectFirst("dl.mt-2"):select("dd")
	
	local languageElement = otherElements[0]
	novelInfo:setLanguage(languageElement:text())

	local statusElement = otherElements[1]
	local status = statusElement:text()
	novelInfo:setStatus(NovelStatus(status == "Completed" and 1 or status == "Ongoing" and 0 or 3))

	-- Chapters
	local chaptersBoxElement = headerNChapters:selectFirst("pb-4"):selectFirst("ul")

	local pages = 0
	pages = chaptersBoxElement:selectFirst("div.releative.z-0"):select("button"):size()
	
	-- After the following loop, this array will contain a list of chapters reversed.
	local chapterElements = {}
	chapterElements.concat(chaptersBoxElement:select("li"))
	
	for page = 0, pages, 1
	do
		document = GETDocument(url .. "?page=" .. page):selectFirst("article.post")
		headerNChapters = document:selectFirst("div.p-2.space-y-4")
		chaptersBoxElement = headerNChapters:selectFirst("pb-4"):selectFirst("ul")
		chapterElements.concat(chaptersBoxElement:select("li"))
	end

	local count = 0
	local chapters = map(
		chapterElements,
		function(chapter)
			local c = NovelChapter()
			c:setTitle(chapter:selectFirst("p"):text())
			c:setLink(chapter:selectFirst("a"):attr("href"))
			
			-- count the chapters
			count = count + 1
			return c
		end
	)
	chapters = map(
		chapters,
		function(chapter)
			chapter:setOrder(count)
			count = count - 1
			return chapter
		end
	)
	Reverse(chapters)
	novelInfo:setChapters(chapters)	
	
	return novelInfo
end

return {
	id = 4223,
	name = "Reaper Scans",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ReaperScans.png",
	hasSearch = true,
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Latest", true, function(data)
			local url = baseURL .. "/latest/novels"

			local d = GETDocument(url)

			return map(d:select("div.relative.flex.space-x-2"), function(v)
				local lis = Novel()
				lis:setImageURL(v:selectFirst("img"):attr("src"))
				local title = v:selectFirst("p.text-sm"):selectFirst("a")
				lis:setLink(shrinkURL(title:attr("href")))
				lis:setTitle(title:text())
				return lis
			end)
		end),
		Listing("All", true, function(data)
			local url = baseURL .. "/novels"

			local d = GETDocument(url)

			return map(d:select("li.col-span-1"), function(v)
				local lis = Novel()
				lis:setImageURL(v:selectFirst("img"):attr("src"))
				local title = v:selectFirst("p.text-sm")
				lis:setLink(shrinkURL(title:attr("href")))
				lis:setTitle(title:text())
				return lis
			end)
		end),
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	hasSearch = false
	--search = search
}
