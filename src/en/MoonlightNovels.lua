-- {"id":4305,"ver":"1.1.0","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://moonlightnovels.com"

local encode = Require("url").encode

local text = function(v)
	return v:text()
end


local function shrinkURL(url)
	return url:gsub("^.-moonlightnovels%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function parseListing(url)
	local doc = GETDocument(expandURL(url))
	local data = doc:selectFirst("#content")
	return mapNotNil(data:select(".is-layout-flow.wp-block-query li"), function(v)
		local a = v:selectFirst("h2"):selectFirst("a")
		if a ~= nil and string.find(a:attr("href"), "/novels/") then
			return Novel {
				title = a:text(),
				link = shrinkURL(a:attr("href")),
				imageURL = v:selectFirst("img"):attr("data-orig-file")
			}
		end
	end)
end

local function getChapterList(content)
	local chapterList = content:selectFirst(".elementor-section.elementor-top-section:nth-last-child(1)"):select("article.elementor-post")
	local chapters = (mapNotNil(chapterList, function(v, i)
		local a = v:selectFirst("a")
		return NovelChapter {
			order = i,
			title = a:text(),
			link = shrinkURL(a:attr("href")),
		}
	end))
	return chapters
end

local function parseNovel(novelURL, loadChapters)
	local doc = GETDocument(expandURL(novelURL))
	local content = doc:selectFirst("#content")
	local topSection = content:selectFirst(".elementor-section.elementor-top-section")
	local description = topSection:selectFirst(".elementor-section:nth-last-child(1)"):selectFirst(".elementor-widget-container")
	local novelInfo = map(topSection:selectFirst(".elementor-section:nth-child(2)"):select("p"), function(v)
		return v
	end)

	local info = NovelInfo {
		title = topSection:selectFirst("h2"):text(),
		imageURL = topSection:selectFirst("img"):attr("data-orig-file"),
		description = table.concat(map(description:select("p"), text), '\n'),
		artists = { novelInfo[1]:text():gsub("Author: ", "") },
		genres = map(novelInfo[3]:select("a"), text),
		status = ({
			Dropped = NovelStatus.PAUSED,
			Completed = NovelStatus.COMPLETED,
			Ongoing = NovelStatus.PUBLISHING
		})[novelInfo[#novelInfo-1]:text():gsub("Status: ", "")],
	}
	
	if loadChapters then
		local chapters = {}
		chapters[#chapters+1] = getChapterList(content)
		local hasChapterPages = content:selectFirst("a.page-numbers")
		if hasChapterPages ~= nil then
			-- Removing the next button and looping throught the numbered page links
			content:select("a.next.page-numbers"):remove()
			map(content:select("a.page-numbers"), function(v)
				doc = GETDocument(v:attr("href"))
				content = doc:selectFirst("#content")
				chapters[#chapters+1] = getChapterList(content)
			end)
		end
		local chapterList = AsList(flatten(chapters))
		info:setChapters(chapterList)
	end
	return info
end

local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))
	local title = doc:selectFirst("figcaption")
	local chap = doc:selectFirst(".elementor-section.elementor-top-section:nth-child(2) .elementor-widget-container")
	if title == nil then
		title = doc:selectFirst("h2")
	end
	title = title:text()
	chap:child(0):before("<h1>" .. title .. "</h1>")
	return pageOfElem(chap, true)
end

local function getHotListing(data) 
	local url = "/hot-novels/?query-99-page=" ..data[PAGE]
	return parseListing(url)
end

local function getCompletedListing(data) 
	local url = "/completed/?query-99-page=" ..data[PAGE]
	return parseListing(url)
end

local function getOrderListing(data) 
	local url = "/all-novels/?query-99-page=" ..data[PAGE]
	return parseListing(url)
end

local function getSearch(data)
	local url = "/page/"..data[PAGE] .."/" .. "?s=" .. data[QUERY] .. "&id=91472"
	return parseListing(url)
end

return {
	id = 4305,
	name = "MoonlightNovels",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Readhive.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Hot Novels", true, getHotListing),
		Listing("Completed", true, getCompletedListing),
		Listing("Alphabetical Order", true, getOrderListing)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	
	-- Website has intentially broken their search function (Thus Disabled)
	hasSearch = false,
	isSearchIncrementing = true,
	search = getSearch,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
