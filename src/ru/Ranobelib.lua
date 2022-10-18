-- {"id":73,"ver":"1.0.1","libVer":"1.0.0","author":"Rider21","dep":["url>=1.0.0","dkjson>=1.0.1"]}

local baseURL = "https://ranobelib.me"

local json = Require("dkjson")
local qs = Require("url").querystring

local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Рейтинг", "Названию (A-Z)", "Просмотрам", "Дате добавления", "Дате обновления", "Количеству глав" }
local ORDER_BY_TERMS = { "rate", "name", "views", "created_at", "last_chapter_at", "chap_count" }

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local function getPassage(chapterURL)
	local doc = GETDocument(baseURL .. chapterURL)
	local chap = doc:selectFirst(".reader-container")

	map(chap:select("img"), function(v)
		if not string.match(v:attr("src") or v:attr("data-src"), "[a-z]*://[^ >,;]*") then
			v:attr("src", baseURL .. (v:attr("src") or v:attr("data-src")))
		end
	end)
	return pageOfElem(chap)
end

local function parseNovel(novelURL, loadChapters)
	local d = GETDocument(expandURL(novelURL))
	local response = json.decode(d:selectFirst("head > script"):html():sub(19, -277))

	local novel = NovelInfo {
		title = response.manga.rusName or response.manga.engName or response.manga.name,
		genres = map(d:select("a.media-tag-item"), function(v) return v:text() end),
		imageURL = d:select(".media-sidebar__cover > img"):attr("src"),
		description = d:select(".media-description__text"):text(),
		status = NovelStatus(response.manga.status)
	}
	
	if loadChapters then
		local chapters = map(response.chapters.list, function(v, i)
			return NovelChapter {
				order = tonumber(v.chapter_number),
				release = v.chapter_created_at,
				title = "Том " .. v.chapter_volume .." Глава ".. v.chapter_number .." ".. v.chapter_name,
				link = "/" .. response.manga.slug .. "/v" .. v.chapter_volume .. "/c" .. v.chapter_number,
			}
		end)
		novel:setChapters(AsList(chapters))
	end
	return novel
end

return {
	id = 73,
	name = "Ranobelib",
	baseURL = baseURL,
	imageURL = "https://ranobelib.me/icons/android-icon-192x192.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novel List", true, function(data)
			local d = GETDocument(qs({ 
				sort = ORDER_BY_TERMS[data[ORDER_BY_FILTER] + 1], 
				page = data[PAGE] 
			}, baseURL .. "/manga-list"))

			return map(d:select("div.media-card-wrap > a"), function(v)
				return Novel {
					title = v:select("h3"):text(),
					link = shrinkURL(v:attr("href")),
					imageURL = baseURL .. v:attr("data-src")
				}
			end)
		end)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,

	hasSearch = false,
	isSearchIncrementing = false,
	--search = getSearch,
	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", ORDER_BY_VALUES),
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,
}
