-- {"id":4223,"ver":"2.0.0","libVer":"1.0.0","author":"Doomsdayrs"}

local baseURL = "https://reaperscans.com"

local function shrinkURL(url)
	return url:match(baseURL .. "/novels/(.+)/")
end

local function expandURL(url)
	return baseURL .. "/novels/" .. url
end

local function getPassage(){
}

local parseNovel(){
}

return {
	id = 4223,
	name = "MTLNovel",
	baseURL = baseURL,
	imageURl imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ReaperScans.png",
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
	search = search
}
