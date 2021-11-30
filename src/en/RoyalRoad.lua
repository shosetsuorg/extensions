-- {"id":36833,"ver":"1.0.3","libVer":"1.0.0","author":"TechnoJo4","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

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
		local type_status_genrestags = info:selectFirst(".margin-bottom-10")
		local novel_type = type_status_genrestags:select(":nth-child(1)")
		local genres_tags = type_status_genrestags:selectFirst(".tags")

		local s = mapNotNil(type_status_genrestags:select(":nth-child(2)"), function(v)
			local text = v:ownText()
			if text == "" or text ~= text:upper() then
				return
			end
			return text
		end)[1]

		s = s and ({
			COMPLETED = NovelStatus.COMPLETED,
			--DROPPED = NovelStatus.DROPPED,
			ONGOING = NovelStatus.PUBLISHING,
			HIATUS = NovelStatus.PAUSED,
			--STUB = NovelStatus.STUB,
		})[s] or NovelStatus.UNKNOWN

		local text = function(v) return v:text() end
		local novel = NovelInfo {
			title = title:selectFirst("h1"):text(),
			imageURL = header:selectFirst("img"):attr("src"),
			description = info:selectFirst(".description .hidden-content"):text(),
			--genres = map(genres_tags:select("a"), text), --TODO: filter IN genres
			tags = map(genres_tags:select("a"), text), --TODO: add novel_type, filter NOT IN genres
			authors = { title:selectFirst("h4 a"):text() },
			status = s
		}

		if loadChapters then
			local i = 0
			novel:setChapters(AsList(map(doc:selectFirst("#chapters tbody"):children(), function(v)
				local a = v:selectFirst("a")
				local a_time = v:selectFirst("time")
				i = i + 1
				return NovelChapter {
					order = i,
					title = a:text(),
					link = a:attr("href"),
					release = (a_time and (a_time:attr("title") or a_time:attr("unixtime") or v:selectLast("a"):text())) or nil
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
