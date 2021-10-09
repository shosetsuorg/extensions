-- {"id":36833,"ver":"1.0.1","libVer":"1.0.0","author":"TechnoJo4","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://www.royalroad.com"
local qs = Require("url").querystring

local css = Require("CommonCSS").table

local function shrinkURL(url)
	return url:gsub("^.-royalroad%.com/?", "")
end

local function expandURL(url)
	return baseURL .. (url:sub(1, 1) == "/" and "" or "/") .. url
end

local function parseListing(doc)
	local results = doc:selectFirst(".fiction-list")

	return map(results:children(), function(v)
		local a = v:selectFirst(".fiction-title a")
		return Novel {
			title = a:text(),
			link = a:attr("href"):match("/fiction/(%d+)/.-"),
			imageURL = v:selectFirst("a img"):attr("src")
		}
	end)
end

local function listing(name, inc, url)
	url = expandURL(url)
	return Listing(name, inc, function(data)
		return parseListing(GETDocument(inc and (url.."?page="..data[PAGE]) or url))
	end)
end

return {
	id = 36833,
	name = "RoyalRoad",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/RoyalRoad.png",
	chapterType = ChapterType.HTML,

	listings = {
		listing("Best Rated", true, "fictions/best-rated"),
		listing("Trending", false, "fictions/trending"),
		listing("Ongoing", true, "fictions/active-popular"),
		listing("Complete", true, "fictions/complete"),
		listing("Popular Weekly", true, "fictions/weekly-popular"),
		listing("Latest Updates", true, "fictions/latest-updates"),
		listing("New Releases", true, "fictions/new-releases"),
		listing("Rising Stars", false, "fictions/rising-stars")
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(baseURL.."/fiction/"..url.."/a")

		local page = doc:selectFirst(".page-content-inner")
		local header = page:selectFirst(".fic-header")
		local title = header:selectFirst(".fic-title")
		local info = page:selectFirst(".fiction-info")
		local tags = info:selectFirst(".margin-bottom-10")

		local s = mapNotNil(tags:children(), function(v)
			local text = v:ownText()
			if text == "" or text ~= text:upper() then
				return
			end
			return text
		end)[1]

		s = s and ({
			ONGOING = NovelStatus.PUBLISHING,
			COMPLETED = NovelStatus.COMPLETED,
		})[s] or NovelStatus.UNKNOWN

		local text = function(v) return v:text() end
		local novel = NovelInfo {
			title = title:selectFirst("h1"):text(),
			imageURL = header:selectFirst("img"):attr("src"),
			description = info:selectFirst(".description .hidden-content"):text(),
			tags = map(tags:selectFirst(".tags"):select("a"), text),
			authors = { title:selectFirst("h4 a"):text() },
			status = s
		}

		if loadChapters then
			local i = 0
			novel:setChapters(AsList(map(doc:selectFirst("#chapters tbody"):children(), function(v)
				local a = v:selectFirst("a")
				i = i + 1
				return NovelChapter {
					order = i,
					title = a:text(),
					link = a:attr("href")
				}
			end)))
		end

		return novel
	end,

	getPassage = function(url)
		return pageOfElem(GETDocument(expandURL(url)):selectFirst(".chapter-content"), true, css)
	end,

	search = function(data)
		return parseListing(GETDocument(qs({
			title = data[QUERY]
		}, baseURL .. "/fictions/search")))
	end,
	isSearchIncrementing = false
}
