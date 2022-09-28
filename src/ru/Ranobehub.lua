-- {"id":72,"ver":"1.0.1","libVer":"1.0.0","author":"Rider21","dep":["dkjson>=1.0.1"]}

local baseURL = "https://ranobehub.org"

local json = Require("dkjson")

local ORDER_BY_FILTER = 3
local ORDER_BY_TERMS = { "computed_rating", "last_chapter_at", "created_at", "name_rus", "views", "count_chapters",
	"count_of_symbols" }

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))
	local html = doc:selectFirst("div.text:nth-child(1)")
	doc:select(".ads-desktop"):remove()
	return pageOfElem(html)
end

local function parseNovel(novelURL, loadChapters)
	local response = json.GET(baseURL .. "/api/" .. novelURL)

	local novel = NovelInfo {
		title = response.data.names.rus,
		genres = map(response.data.tags.genres, function(v) return v.names.rus end),
		tags = map(response.data.tags.events, function(v) return v.names.rus end),
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
					title = v2.name,
					link = shrinkURL(v2.url),
					release = tonumber(v2.changed_at) * 1000,
					order = chapterOrder
				});
				chapterOrder = chapterOrder + 1
			end
		end
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

local function search(filters)
	return {}
end

return {
	id = 72,
	name = "Ranobehub",
	baseURL = baseURL,

	-- Optional values to change
	imageURL = "https://ranobehub.org/favicon.png",
	hasSearch = true,

	-- Must have at least one value
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
					title = v.names.rus,
					link = "ranobe/" .. v.id,
					imageURL = v.poster.medium
				}
			end)
		end)
	},

	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", {"Рейтинг", "Дате обновления", "Дате добавления", "Название", "Просмотры", "Количеству глав", "объем перевода" }),
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	shrinkURL = shrinkURL,
	expandURL = expandURL,
}
