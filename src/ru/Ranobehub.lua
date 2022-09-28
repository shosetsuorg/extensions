-- {"id":72,"ver":"1.0.1","libVer":"1.0.0","author":"Rider21","dep":["dkjson>=1.0.1"]}

local baseURL = "https://ranobehub.org"

local json = Require("dkjson")

local ORDER_BY_FILTER = 3
local ORDER_BY_TERMS = { "computed_rating", "last_chapter_at", "created_at", "name_rus", "views", "count_chapters", "count_of_symbols" }

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))
	local chap = doc:selectFirst("div.text:nth-child(1)")
	chap:select(".ads-desktop"):remove()
	chap:select("div.or:nth-child(1)"):remove()
	chap:select(".title-wrapper"):remove()
	chap:child(0):before("<h1>" .. doc:selectFirst("head > title"):text() .. "</h1>");

	--[[
	map(chap:select("img"), function(v)
		v:setAttribute("src", baseURL .. "/api/media/" .. v:attr("data-media-id"))
	end)
	]]

	return pageOfElem(chap, true)
end

local function parseNovel(novelURL, loadChapters)
	local response = json.GET(baseURL .. "/api/" .. novelURL)

	local novel = NovelInfo {
		title = response.data.names.rus or response.data.names.eng,
		genres = map(response.data.tags.genres, function(v) return v.names.rus or v.names.eng end),
		tags = map(response.data.tags.events, function(v) return v.names.rus or v.names.eng end),
		imageURL = response.data.posters.medium,
		description = Document(response.data.description):text(),
		authors = { response.data.authors[1].name_eng },
		status = NovelStatus(
			response.data.status.title == "Завершено" and 1 or
			response.data.status.title == "Заморожено" and 2 or
			response.data.status.title == "В процессе" and 0 or 3
		)
	}

	if loadChapters then
		local chapterJson = json.GET(baseURL .. "/api/" .. novelURL .. "/contents")
		local chapterList = {}
		local chapterOrder = 0
		for k1, volumes in ipairs(chapterJson.volumes) do
			for k2, v2 in ipairs(chapterJson.volumes[k1].chapters) do
				table.insert(chapterList, NovelChapter {
					title = "Том " .. volumes.num .. ": " .. v2.name,
					link = shrinkURL(v2.url),
					release = os.date("%Y-%m-%d %H:%M:%S", v2.changed_at),
					order = chapterOrder
				});
				chapterOrder = chapterOrder + 1
			end
		end
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

local function search(data)
	local response = json.GET(expandURL("api/fulltext/global?query=" .. data[QUERY]))
	local novels = {}

	for k, v in pairs(response) do
		if v.meta.key == "ranobe" then
			novels = map(v.data, function(v2)
				return Novel {
					title = v2.names.rus or v2.names.eng,
					link = "ranobe/" .. v2.id,
					imageURL = v2.image:gsub("/small", "/medium")
				}
			end)
		end
	end

	return novels
end

return {
	id = 72,
	name = "Ranobehub",
	baseURL = baseURL,

	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Ranobehub.png",
	chapterType = ChapterType.HTML,
	hasSearch = true,

	listings = {
		Listing("Novel List", true, function(data)
			local url = baseURL .. "/api/search?take=50&page=" .. data[PAGE]
			local orderBy = data[ORDER_BY_FILTER]

			if orderBy ~= nil then
				url = url .. "&sort=" .. ORDER_BY_TERMS[orderBy + 1]
			else
				url = url .. "&sort=computed_rating"
			end

			local d = json.GET(url)
			return map(d.resource, function(v)
				return Novel {
					title = v.names.rus or v.names.eng,
					link = "ranobe/" .. v.id,
					imageURL = v.poster.medium
				}
			end)
		end)
	},

	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", { "Рейтинг", "Дате обновления", "Дате добавления", "Название", "Просмотры", "Количеству глав", "объем перевода" }),
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	shrinkURL = shrinkURL,
	expandURL = expandURL,
}
