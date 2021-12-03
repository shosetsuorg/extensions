-- {"id":36833,"ver":"1.0.6","libVer":"1.0.0","author":"TechnoJo4","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://www.royalroad.com"
local qs = Require("url").querystring

local css = Require("CommonCSS").table

local KEYWORD_FILTER_KEY = 099
local AUTHOR_FILTER_KEY = 100
local GENRES_FILTER_EXT = {"Action", "Adventure", "Comedy", "Contemporary", "Drama", "Fantasy", "Historical", "Horror", "Mystery", "Psychological", "Romance", "Satire", "Sci-fi", "Short Story", "Tragedy"}
local GENRES_FILTER_KEY = 200
local GENRES_FILTER_INT = { --individual, start from 1 to match ext
	[201]="action",
	[202]="adventure",
	[203]="comedy",
	[204]="contemporary",
	[205]="drama",
	[206]="fantasy",
	[207]="historical",
	[208]="horror",
	[209]="mystery",
	[210]="psychological",
	[211]="romance",
	[212]="satire",
	[213]="sci_fi",
	[214]="one_shot",
	[215]="tragedy",
}
local TAGS_FILTER_EXT = {"Anti-Hero Lead", "Artificial Intelligence", "Attractive MC", "Cyberpunk", "Dungeon", "Dystopia", "Female Lead", "First Contact", "GameLit", "Gender Bender", "Genetically Engineered", "Grimdark", "Hard Sci-fi", "Harem", "High Fantasy", "LitRPG", "Loop", "Low Fantasy", "Magic", "Male Lead", "Martial Arts", "Multiple Lead Characters", "Mythos", "Non-Human lead", "Portal Fantasy / Isekai", "Post Apocalyptic", "Progression", "Reader interactive", "Reincarnation", "Ruling Class", "School Life", "Secret Identity", "Slice of Life", "Soft Sci-fi", "Space Opera", "Sports", "Steampunk", "Strategy", "Strong Lead", "Super Heroes", "Supernatural", "Technologically Engineered", "Time Travel", "Urban Fantasy", "Villainous Lead", "Virtual Reality", "War and Military", "Wuxia", "Xianxia"}
local TAGS_FILTER_KEY = 300
local TAGS_FILTER_INT = { --individual, start from 1 to match ext
	[301]="anti-hero_lead",
	[302]="attractive-mc",
	[303]="cyberpunk",
	[304]="dungeon",
	[305]="Dystopia",
	[306]="female_lead",
	[307]="gamelit",
	[308]="gender_bender",
	[309]="Genetically_Engineered",
	[310]="grimdark",
	[311]="Hard_Sci_fi",
	[312]="harem",
	[313]="high_fantasy",
	[314]="litrpg",
	[315]="Loop",
	[316]="low_fantasy",
	[317]="magic",
	[318]="male_lead",
	[319]="martial_arts",
	[320]="mutliple_lead",
	[321]="mythos",
	[322]="non-human_lead",
	[323]="summoned_hero",
	[324]="post_apocalyptic",
	[325]="Progression",
	[326]="reader_interactive",
	[327]="reincarnation",
	[328]="ruling_class",
	[329]="school_life",
	[330]="secret_identity",
	[331]="slice_of_life",
	[332]="Soft_Sci_fi",
	[333]="space_opera",
	[334]="sports",
	[335]="steampunk",
	[336]="strategy",
	[337]="strong_lead",
	[338]="super_heroes",
	[339]="supernatural",
	[340]="Time_Travel",
	[341]="urban_fantasy",
	[342]="villainous_lead",
	[343]="virtual_reality",
	[344]="war_and_military",
	[345]="wuxia",
	[346]="xianxia",
}
local CONTENT_WARNINGS_FILTER_EXT = {"Profanity", "Sexual Content", "Gore", "Traumatising content"}
local CONTENT_WARNINGS_FILTER_KEY = 400
local CONTENT_WARNINGS_FILTER_INT = { --individual, start from 1 to match ext
	[401]="profanity",
	[402]="sexuality",
	[403]="gore",
	[404]="traumatising",
}
local PAGES_MIN_FILTER_KEY = 500
local PAGES_MAX_FILTER_KEY = 501
local RATING_MIN_FILTER_KEY = 502
local RATING_MAX_FILTER_KEY = 503
local STATUS_FILTER_EXT = {"ALL", "COMPLETED", "DROPPED", "ONGOING", "HIATUS", "STUB"}
local STATUS_FILTER_KEY = 600
local STATUS_FILTER_INT = { --individual, start from 1 to match ext
	[601]="ALL",
	[602]="COMPLETED",
	[603]="DROPPED",
	[604]="ONGOING",
	[605]="HIATUS",
	[606]="STUB",
}
local ORDER_BY_FILTER_EXT = {"Relevance", "Popularity", "Average Rating", "Last Update", "Release Date", "Followers", "Number of Pages", "Views", "Title"}
local ORDER_BY_FILTER_KEY = 700
local ORDER_BY_FILTER_INT = { --dropdown, start from 0
	[0]="relevance",
	[1]="popularity",
	[2]="rating",
	[3]="last_update",
	[4]="release_date",
	[5]="followers",
	[6]="length",
	[7]="views",
	[8]="title",
}
local ORDER_FILTER_KEY = 800
local TYPE_FILTER_EXT = {"All", "Fan Fiction", "Original"}
local TYPE_FILTER_KEY = 900
local TYPE_FILTER_INT = { --dropdown, start from 0
	[0]="all",
	[1]="fanfiction",
	[2]="original",
}

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

local function triquery(data, filter_int, int)
	return (data[int] and (data[int]==2 and "&tagsRemove" or "&tagsAdd=")..filter_int[int] or "")
end
local function triquerymulti(data, filter_int, start_, end_)
	local q=""
	for int = start_,end_,1
	do
		q =q.. triquery(data, filter_int, int)
	end
	return q
end
local function trifiltermulti(offset, filter_ext, end_)
	local f={}
	for int = 1,end_,1
	do
		if TriStateFilter then
			table.insert(f, TriStateFilter(offset+int, filter_ext[int]))
		else
			table.insert(f, CheckboxFilter(offset+int, filter_ext[int]))
		end
	end
	return f
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
		local novel_type = type_status_genrestags:selectFirst(".label")
		local genres_tags = type_status_genrestags:selectFirst(".tags")
		local content_warnings = info:selectFirst(".text-center")

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

		local function tablecontains(t, e)
			for _, v in ipairs(t) do
				if e == v then
					return true
				end
			end
			return false
		end

		local genres = {}
		local tags = {}
		table.insert(tags, novel_type:text())
		mapNotNil(genres_tags:select("a"), function(a)
			local genre_tag = a:text()
			if tablecontains(GENRES_FILTER_EXT, genre_tag) then
				table.insert(genres, genre_tag)
			else
				table.insert(tags, genre_tag)
			end
		end)
		mapNotNil(content_warnings:select("li"), function(cw)
			table.insert(tags, cw:text())
		end)

		local text = function(v) return v:text() end
		local novel = NovelInfo {
			title = title:selectFirst("h1"):text(),
			imageURL = header:selectFirst("img"):attr("src"),
			description = info:selectFirst(".description .hidden-content"):text(),
			genres = genres,
			tags = tags,
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

	--search = function(data)
	--	return parseListing(GETDocument(qs({
	--		title = data[QUERY]
	--	}, baseURL .. "/fictions/search")))
	--end,
	search = function(data)
--https://www.royalroad.com/fictions/search?title=world&minPages=&maxPages=&minRating=&maxRating=&dir=asc
		--return parseListing(GETDocument(qs({
		return parseListing(GETDocument(baseURL .. "/fictions/search" ..
			string.gsub("?"..
				(data[QUERY]~="" and "&tile="..data[QUERY] or "")..
				(data[AUTHOR_FILTER_KEY]~="" and "&keyword="..data[KEYWORD_FILTER_KEY] or "")..
				(data[AUTHOR_FILTER_KEY]~="" and "&author="..data[AUTHOR_FILTER_KEY] or "")..
				triquerymulti(data, GENRES_FILTER_INT, 201, 215)..
				triquerymulti(data, TAGS_FILTER_INT, 301, 346)..
				triquerymulti(data, CONTENT_WARNINGS_FILTER_INT, 401, 404)..
				(data[PAGES_MIN_FILTER_KEY ]~="" and "&minPages=" ..data[PAGES_MIN_FILTER_KEY ] or "")..
				(data[PAGES_MAX_FILTER_KEY ]~="" and "&maxPages=" ..data[PAGES_MAX_FILTER_KEY ] or "")..
				(data[RATING_MIN_FILTER_KEY]~="" and "&minRating="..data[RATING_MIN_FILTER_KEY] or "")..
				(data[RATING_MAX_FILTER_KEY]~="" and "&maxRating="..data[RATING_MAX_FILTER_KEY] or "")..
				(data[600] and "&status="..STATUS_FILTER_INT[600] or "")..
				(data[601] and "&status="..STATUS_FILTER_INT[601] or "")..
				(data[602] and "&status="..STATUS_FILTER_INT[602] or "")..
				(data[603] and "&status="..STATUS_FILTER_INT[603] or "")..
				(data[604] and "&status="..STATUS_FILTER_INT[604] or "")..
				(data[605] and "&status="..STATUS_FILTER_INT[605] or "")..
				(data[ORDER_BY_FILTER_KEY]~=0 and "&orderBy="..ORDER_BY_FILTER_INT[data[ORDER_BY_FILTER_KEY]] or "")..
				(data[ORDER_FILTER_KEY] and "&dir=asc" or "")..
				(data[TYPE_FILTER_KEY]~=0 and "&type="..TYPE_FILTER_INT[data[TYPE_FILTER_KEY]] or "")
			, "?&", "?")
		))
		--}, baseURL .. "/fictions/search")))
	end,
	isSearchIncrementing = false,
	searchFilters = {
		TextFilter(KEYWORD_FILTER_KEY, "Keyword (title or description)"),
		TextFilter(AUTHOR_FILTER_KEY, "Author name"),
		FilterGroup("Genres", trifiltermulti(200, GENRES_FILTER_EXT, 15)),
		FilterGroup("Additional Tags", trifiltermulti(300, TAGS_FILTER_EXT, 46)),
		FilterGroup("Content Warnings", trifiltermulti(400, CONTENT_WARNINGS_FILTER_EXT, 4)),
		TextFilter(PAGES_MIN_FILTER_KEY, "Number of Pages min 0"), --todo number slider/selector
		TextFilter(PAGES_MAX_FILTER_KEY, "Number of Pages max 20000"),
		TextFilter(RATING_MIN_FILTER_KEY, "Rating min 0.0"),
		TextFilter(RATING_MAX_FILTER_KEY, "Rating max 5.0"),
		FilterGroup("Status", {
			CheckboxFilter(701, STATUS_FILTER_EXT[01]),
			CheckboxFilter(702, STATUS_FILTER_EXT[02]),
			CheckboxFilter(703, STATUS_FILTER_EXT[03]),
			CheckboxFilter(704, STATUS_FILTER_EXT[04]),
			CheckboxFilter(705, STATUS_FILTER_EXT[05]),
			CheckboxFilter(706, STATUS_FILTER_EXT[06]),
		}),
		DropdownFilter(ORDER_BY_FILTER_KEY, "Order by", ORDER_BY_FILTER_EXT),
		SwitchFilter(ORDER_FILTER_KEY, "Descending / Ascending"),
		DropdownFilter(TYPE_FILTER_KEY, "Type", TYPE_FILTER_EXT),
	},
}
