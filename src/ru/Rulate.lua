-- {"id":70,"ver":"1.0.0","libVer":"1.0.0","author":"Rider21"}

local baseURL = "https://tl.rulate.ru"

local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = {
	"По степени готовности", --ID: 0
	"По названию на языке оригинала", --ID: 1
	"По названию на языке перевода", --ID: 2
	"По дате создания", --ID: 3
	"По дате последней активности", --ID: 4
	"По просмотрам", --ID: 5
	"По рейтингу", --ID: 6
	"По кол-ву переведённых глав", --ID: 7
	"По кол-ву лайков", --ID: 8
	"Случайно", --ID: 9
	"По кол-ву страниц", --ID: 10
	"По кол-ву бесплатных глав", --ID: 11
	"По кол-ву рецензий", --ID: 12
	"По кол-ву в закладках", --ID: 13
	"По кол-ву в избранном", --ID: 14
}

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getSearch(data)
	local url = baseURL .. "/search?"

	if data[0] then --search
		url = url .. "t=" .. data[0] .. "&"
	end

	url = url .. "cat=2&sort=" .. data[ORDER_BY_FILTER] .. "&Book_page=" .. data[PAGE]

	local d = GETDocument(url)
	return map(d:select(".search-results li"), function(v)
		return Novel {
			title = v:select("p > a"):text(),
			link = v:select("p > a"):attr("href"),
			imageURL = baseURL .. v:select("img"):attr("src")
		}
	end)
end

local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))
	local chap = doc:selectFirst(".content-text")
	chap:child(0):before("<h1>" .. doc:select(".chapter_select > select > option[selected]"):text() .. "</h1>");

	map(chap:select("img"), function(v)
		if string.sub(v:attr("src"), 0, 1) == "/" then
			v:attr("src", baseURL .. v:attr("src"))
		elseif string.sub(v:attr("data-src"), 0, 1) == "/" then
			v:attr("src", baseURL .. v:attr("data-src"))
		elseif string.match(v:attr("data-src"), "[a-z]*://[^ >,;]*") then
			v:attr("src", v:attr("data-src"))
		end
	end)
	return pageOfElem(chap)
end

local function parseNovel(novelURL, loadChapters)
	local d = GETDocument(expandURL(novelURL))

	local novel = NovelInfo {
		title = d:select(".span8 > h1"):text(),
		imageURL = baseURL .. d:select(".slick > div > img"):attr("src"),
		description = d:select("#Info > div:nth-child(3)"):text(),
	}

	map(d:select(".span5 > p"), function(v)
		local str = v:select("strong"):text()
		if str == "Автор:" then
			novel:setAuthors({ v:select("em > a"):text():gsub("Автор: ", "") })
		elseif str == "Выпуск:" then
			local status = v:select("em"):text()
			novel:setStatus(NovelStatus(
					status == "завершён" and 1 or
					status == "продолжается" and 0 or 3
				)
			)
		elseif str == "Жанры:" then
			novel:setGenres(map(v:select("em > a"), function(genres) return genres:text() end))
		elseif str == "Тэги:" then
			novel:setTags(map(v:select("em > a"), function(tags) return tags:text() end))
		end
	end)

	if loadChapters then
		local order = -1
		local chapterList = mapNotNil(d:select("tr.chapter_row"), function(v)
			local releaseDate = v:select("td > span"):attr("title")
			order = order + 1
			if v:select('td > span[class="disabled"]'):size() > 0 or releaseDate == "" then
				return nil
			end
			return NovelChapter {
				title = v:selectFirst("td > a"):text(),
				link = v:selectFirst("td > a"):attr("href"),
				release = releaseDate,
				order = order
			}
		end)
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

return {
	id = 70,
	name = "Rulate",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Rulate.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novel List", true, function(data)
			return getSearch(data)
		end)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,

	hasSearch = false,
	isSearchIncrementing = true,
	search = getSearch,
	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", ORDER_BY_VALUES),
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
