-- {"id":4303,"ver":"1.1.3","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://www.novelhold.com"

-- Filter Keys & Values
local STATUS_FILTER = 2
local STATUS_VALUES = { "All", "Ongoing", "Completed" }
local STATUS_TERMS = { "", "active", "completed" }
local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Latest Update", "Most Views", "Month Views", "Week Views", "New" }
local ORDER_BY_TERMS = { "updatetime", "hits", "month_hits", "rating", "inputtime" }
local GENRE_FILTER = 4
local GENRE_VALUES = { 
  "All",
  "Romance",
  "Fantasy",
  "Action",
  "Modern",
  "CEO",
  "Romantic",
  "Adult",
  "Drama",
  "Urban",
  "Historical",
  "Harem",
  "Game",
  "Xianxia",
  "Josei",
  "Adventure",
  "Mature"
}

local searchFilters = {
	DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES),
	DropdownFilter(STATUS_FILTER, "Status", STATUS_VALUES),
	DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES)
}

local encode = Require("url").encode

local text = function(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-novelhold%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getPassage(chapterURL)
	local chap = GETDocument(expandURL(chapterURL)):selectFirst(".main")
	local title = chap:selectFirst("h1"):text()
	chap = chap:selectFirst("#content")
	-- This is for the sake of consistant styling
	chap:select("br:nth-child(even)"):remove()
	chap = tostring(chap):gsub('<div', '<p'):gsub('</div', '</p'):gsub('<br>', '</p><p>')
	chap = Document(chap):selectFirst('body')
	-- Adds Chapter Title
	chap:child(0):before("<h1>" .. title .. "</h1>")
	return pageOfElem(chap, true)
end

local function parseNovel(novelURL, loadChapters)
	local content = GETDocument(expandURL(novelURL)):selectFirst(".main")
	local details = content:selectFirst(".detail")
	-- Note: "：" the colon space character is a special unicode for some reason. 
	local info = NovelInfo {
		title = details:selectFirst("h1"):text(),
		imageURL = details:selectFirst("img"):attr("src"),
		status = ({
			Completed = NovelStatus.COMPLETED,
			Active = NovelStatus.PUBLISHING
		})[details:child(5):text():gsub("^.-Status%：", "")],
		description = table.concat(map(content:selectFirst('.content'):select("p"), text), '\n'),
		authors = { details:child(2):text():gsub("^.-Author%：", "") },
		genres = { details:child(4):text():gsub("^.-Genre%：", "") },
	}

	if loadChapters then
		local chapters = (map(content:selectFirst('#morelist'):select("dd"), function(v, i)
			local a = v:selectFirst("a")
			return NovelChapter {
				order = i,
				title = a:text(),
				link = shrinkURL(a:attr("href")),
			}
		end))
		info:setChapters(AsList(chapters))
	end
	return info
end

local function parseListing(listingURL)
	local doc = GETDocument(listingURL)
	return map(doc:select(".library li"), function(v)
		local a = v:selectFirst("a.bookname")
		return Novel {
			title = a:text(),
			link = shrinkURL(a:attr("href")),
			imageURL = v:selectFirst("img"):attr("src")
		}
	end)
end

local function getSearch(data)
	local query = data[QUERY]
	local page = data[PAGE]
	local url = "/index.php?s=so&module=book&keyword=" .. query .. "&page=" .. page
	return parseListing(expandURL(url))
end

local function getListing(data)
	-- Filters only work with the listing, their search does not support them.
	local page = data[PAGE] 
	local genre = data[GENRE_FILTER]
	local status = data[STATUS_FILTER]
	local orderBy = data[ORDER_BY_FILTER]

	local genreValue = ""
	if genre ~= nil and genre ~= 0 then
		genreValue = GENRE_VALUES[genre+1]:lower()
	end
	local statusValue = ""
	if status ~= nil then
		statusValue = STATUS_TERMS[status+1]
	end
	local orderByValue = ""
	if orderBy ~= nil then
		orderByValue = ORDER_BY_TERMS[orderBy+1]
	end

	local url = "/search-" .. genreValue .. "-" .. statusValue .. "-" .. orderByValue .. "-" .. page .. ".html"
	return parseListing(expandURL(url))
end

return {
	id = 4303,
	name = "Mylovenovel",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Mylovenovel.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Latest", true, getListing)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	
	hasSearch = true,
	isSearchIncrementing = true,
	search = getSearch,
	searchFilters = searchFilters,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
