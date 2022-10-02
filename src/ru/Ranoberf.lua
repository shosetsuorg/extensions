-- {"id":71,"ver":"1.0.1","libVer":"1.0.0","author":"Rider21","dep":["dkjson>=1.0.1"]}

local baseURL = "https://ранобэ.рф"

local json = Require("dkjson")

local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Рейтинг", "Дате обновления", "Дате добавления", "Законченные" }
local ORDER_BY_TERMS = { "popular", "lastPublishedChapter", "new", "completed" }

local PAIDCHAPTERSHOW_KEY = 1
local settings = {
	[PAIDCHAPTERSHOW_KEY] = false,
}

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local function getSearch(data)
	local query = data[QUERY]
	local url = "v3/books?filter[or][0][title][like]=" .. query .. "&filter[or][1][titleEn][like]="
		.. query .. "&filter[or][2][fullTitle][like]=" .. query .. "&expand=verticalImage"
	local response = json.GET(expandURL(url))
	return map(response["items"], function(v)
		return Novel {
			title = v.title,
			link = v.slug,
			imageURL = baseURL .. v.verticalImage.url
		}
	end)
end

local function getPassage(chapterURL)
	local doc = GETDocument(baseURL .. chapterURL)
	local response = json.decode(doc:selectFirst("#__NEXT_DATA__"):html())
	local chap = Document(response.props.pageProps.chapter.content.text)
	chap:child(0):before("<h1>" .. response.props.pageProps.chapter.title .. "</h1>");

	map(chap:select("img"), function(v)
		if not string.match(v:attr("src") or v:attr("data-src"), "[a-z]*://[^ >,;]*") then
			v:attr("src", baseURL .. (v:attr("src") or v:attr("data-src")))
		end
	end)

	return pageOfElem(chap)
end

local function parseNovel(novelURL, loadChapters)
	local d = GETDocument(expandURL(novelURL))
	local response = json.decode(d:selectFirst("#__NEXT_DATA__"):html())

	local novel = NovelInfo {
		title = response.props.pageProps.book.title,
		genres = map(response.props.pageProps.book.genres, function(v) return v.title end),
		imageURL = baseURL .. response.props.pageProps.book.verticalImage.url,
		description = Document(response.props.pageProps.book.description):text(),
		authors = { response.props.pageProps.book.author },
		status = NovelStatus(
			response.props.pageProps.book.status == "completed" and 1 or
			response.props.pageProps.book.status == "pause" and 2 or
			response.props.pageProps.book.status == "active" and 0 or 3
		)
	}

	if loadChapters then
		local chapterList = {}
		for k, v in pairs(response.props.pageProps.book.chapters) do
			if not v.isDonate or v.isUserPaid or settings[PAIDCHAPTERSHOW_KEY] then
				table.insert(chapterList, NovelChapter {
					title = v.title,
					link = v.url,
					release = v.publishedAt,
					order = #response.props.pageProps.book.chapters - k
				});
			end
		end
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

return {
	id = 71,
	name = "РанобэРФ",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Ranoberf.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novel List", true, function(data)
			local orderBy = data[ORDER_BY_FILTER]

			if orderBy ~= nil then
				orderBy = ORDER_BY_TERMS[orderBy + 1]
			else
				orderBy = "popular"
			end

			local d = GETDocument(baseURL .. "/books" .. "?order=" .. orderBy .. "&page=" .. data[PAGE])
			local response = json.decode(d:selectFirst("#__NEXT_DATA__"):html())
			return map(response.props.pageProps.totalData.items, function(v)
				return Novel {
					title = v.title,
					link = v.slug,
					imageURL = baseURL .. v.verticalImage.url
				}
			end)
		end)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,

	hasSearch = true,
	isSearchIncrementing = false,
	search = getSearch,
	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", ORDER_BY_VALUES),
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	settings = {
		SwitchFilter(PAIDCHAPTERSHOW_KEY, "Показывать не купленные главы"),
	},
	setSettings = function(s)
		settings = s
	end,
	updateSetting = function(id, value)
		settings[id] = value
	end,
}
