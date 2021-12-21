-- {"id":4302,"ver":"1.0.10","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://travistranslations.com"

-- Filter Keys & Values
local STATUS_FILTER = 2
local STATUS_VALUES = { "All", "Ongoing", "Completed" }
local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Latest Update", "Recently Added", "Popular", "Rating", "A-Z" }
local ORDER_BY_TERMS = { "update", "new", "popular", "rating", "az" }
local TYPE_FILTER = 4
local TYPE_VALUES = { 
	"Light Novel", 
	"Novel", 
	"Original Novel", 
	"Web Novel" 
}
local LANGUAGE_FILTER = 8
local LANGUAGE_VALUES = { 
	"Chinese", 
	"Japanese",
	"Korean" 
}
local GENRE_FILTER = 50
local GENRE_VALUES = { 
	"Action",
	"Adult",
	"Adventure",
	"BL",
	"Comedy",
	"Drama",
	"Ecchi",
	"Fantasy",
	"Harem",
	"Historical",
	"Horror",
	"Josei",
	"Martial Arts",
	"Mature",
	"Mecha",
	"Mystery",
	"Psychological",
	"Romance",
	"Romance",
	"Sci-Fi",
	"Seinen",
	"Shoujo",
	"Shoujo Ai",
	"Shounen",
	"Shounen Ai",
	"Slice of Life",
	"Smut",
	"Sports",
	"Supernatural",
	"Tragedy",
	"Xianxia",
	"Xuanhuan",
	"Yaoi",
	"Yuri",
 }

local searchFilters = {
	DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES),
	DropdownFilter(STATUS_FILTER, "Status", STATUS_VALUES),
	FilterGroup("Type", map(TYPE_VALUES, function(v,i) 
		local KEY_ID = TYPE_FILTER + i
		return CheckboxFilter(KEY_ID, v)
	end)),
	FilterGroup("Language", map(LANGUAGE_VALUES, function(v,i) 
		local KEY_ID = LANGUAGE_FILTER + i
		return CheckboxFilter(KEY_ID, v)
	end)),
	FilterGroup("Genre", map(GENRE_VALUES, function(v,i) 
		local KEY_ID = GENRE_FILTER + i
		return CheckboxFilter(KEY_ID, v)
	end))
}

local encode = Require("url").encode

local text = function(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-travistranslations%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getPassage(chapterURL)
	local content = GETDocument(expandURL(chapterURL)):selectFirst("main#primary")
	-- Removes the title and makes it an H1 for consistant custom CSS.
	local title = content:selectFirst("h2"):text()
	local chap = content:selectFirst(".reader-content")
	chap:child(0):before("<h1>" .. title .. "</h1>")
	-- Remove empty <p> tags
	local toRemove = {}
	chap:traverse(NodeVisitor(function(v)
		if v:tagName() == "p" and v:text() == "" then
			toRemove[#toRemove+1] = v
		end
		if v:hasAttr("border") then
			v:removeAttr("border")
		end
	end, nil, true))
	for _,v in pairs(toRemove) do
		v:remove()
	end
	return pageOfElem(chap, true)
end

local function parseNovel(novelURL, loadChapters)
	local doc = GETDocument(baseURL .. novelURL)
	local content = doc:selectFirst("main#primary")

	local info = NovelInfo {
		title = content:selectFirst("h1#heading"):attr("title"),
		imageURL = "https:" .. content:selectFirst("img"):attr("data-src"),
		status = ({
			Completed = NovelStatus.COMPLETED,
			Ongoing = NovelStatus.PUBLISHING
		})[content:selectFirst(".grid.grid-cols-2.gap-3.my-2"):child(3):selectFirst("strong"):text()],
		description = table.concat(map(doc:selectFirst('div[property="description"]'):select("p"), text), '\n'),
		artists = { "Translator: Travis Translations" },
		genres = map(content:selectFirst("ul.space-x-1.space-y-2"):select("a"), text),
		tags = map(content:selectFirst("ul.flex.flex-wrap.my-2"):select("a"), text)
	}

	if loadChapters then
		local chapters = (map(content:selectFirst('div[x-show="tab === \'toc\'"]'):select("li"), function(v, i)
			-- This is to ignore the premium chapter, those have a lock icon in their anchor.
			local firstPremChapter = v:selectFirst("i.i-lock")
			if firstPremChapter ~= nil then return end
			
			local a = v:selectFirst("a")
			return NovelChapter {
				order = i,
				title = a:child(0):text(),
				link = shrinkURL(a:attr("href")),
				release = a:child(1):text()
			}
		end))

		info:setChapters(AsList(chapters))
	end
	return info
end

local function parseListing(listingURL)
	local doc = GETDocument(listingURL)
	return map(doc:select("li.group"), function(v)
		local a = v:selectFirst("a")
		return Novel {
			title = a:attr("title"),
			link = shrinkURL(a:attr("href")),
			imageURL = "https:" .. v:selectFirst("img"):attr("data-src")
		}
	end)
end

local function getSearch(data)
	local query = data[QUERY]
	local page = data[PAGE] + 1
	local status = data[STATUS_FILTER]
	local orderBy = data[ORDER_BY_FILTER]

	local url = "/all-series/page/" ..page.. "/?"
	if query ~= nil then
		url = url .. "search=" .. encode(query)
	end
	if status ~= nil then
		url = url .. "&status=" .. STATUS_VALUES[status+1]:lower()
	end
	map(TYPE_VALUES, function(v, i)
		local KEY_ID = TYPE_FILTER + i
		if data[KEY_ID] then
			url = url .. "&type%5B%5D=" .. v:lower():gsub(" ", "-")
		end
	end)
	map(LANGUAGE_VALUES, function(v, i)
		local KEY_ID = LANGUAGE_FILTER + i
		if data[KEY_ID] then
			url = url .. "&language%5B%5D=" .. v:lower():gsub(" ", "-")
		end
	end)
	map(GENRE_VALUES, function(v, i)
		local KEY_ID = GENRE_FILTER + i
		if data[KEY_ID] then
			url = url .. "&genre%5B%5D=" .. v:lower():gsub(" ", "-")
		end
	end)
	if orderBy ~= nil then
		url = url .. "&orderby=" .. ORDER_BY_TERMS[orderBy+1]
	end
	local docURL = expandURL(url)
	return parseListing(docURL)
end

local function getListing(data)
	return getSearch(data)
end

return {
	id = 4302,
	name = "Travis Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/TravisTranslations.png",
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
