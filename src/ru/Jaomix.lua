-- {"id":74,"ver":"1.0.1","libVer":"1.0.0","author":"Rider21","dep":["url>=1.0.1"]}

local baseURL = "https://jaomix.ru"

local qs = Require("url").querystring

local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Дате добавления", "Имя", "Просмотры", "Дате обновления" }
local ORDER_BY_TERMS = { "new", "alphabet", "count", "upd" }

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local function getSearch(data)
	local url = qs({
		search = data[0] or "", --data[QUERY]
		sortby = ORDER_BY_TERMS[data[ORDER_BY_FILTER] + 1],
		page = data[PAGE]
	}, baseURL .. "/")
	local d = GETDocument(url)

	return map(d:select("div.one > div > div > a"), function(v)
		return Novel {
			title = v:attr("title"),
			link = shrinkURL(v:attr("href")),
			imageURL = v:select("img"):attr("src")
		}
	end)
end

local function getPassage(chapterURL)
	local chap = GETDocument(baseURL .. chapterURL)
		:selectFirst('.entry-content')
	chap:select(".adblock-service"):remove()

	return pageOfElem(chap, true)
end

local function parseNovel(novelURL, loadChapters)
	local d = GETDocument(expandURL(novelURL))

	local novel = NovelInfo {
		title = d:select('h1[itemprop="name"]'):text(),
		imageURL = d:select(".img-book > img"):attr("src"),
		description = d:select("#desc-tab"):text(),
	}

	if loadChapters then
		local chapterList = {}
		local chapterHtml = d
		local termid = d:select('div[class="like-but"]'):attr('id')
		local order = tonumber(d:selectFirst('div.columns-toc:nth-child(1) h2'):text():match("%d+") or "5000")
		local page = RequestDocument(
			POST(baseURL .. "/wp-admin/admin-ajax.php", nil,
				FormBodyBuilder()
				:add("action", "toc")
				:add("selectall", termid)
				:build()
			)
		):select("select > option"):size()

		for i = 1, page do
			if i > 1 then
				chapterHtml = RequestDocument(
					POST(baseURL .. "/wp-admin/admin-ajax.php", nil,
						FormBodyBuilder()
						:add("action", "toc")
						:add("page", i)
						:add("selectall", termid):build()
					)
				)
			end

			map(chapterHtml:select("div.columns-toc div.title"), function(v)
				table.insert(chapterList, NovelChapter {
					title = v:select("h2"):text(),
					link = v:select("a"):attr("href"),
					release = v:select("time"):text(),
					order = order
				})
				order = order - 1
			end)
		end
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

return {
	id = 74,
	name = "Jaomix.ru",
	baseURL = baseURL,
	imageURL = "https://jaomix.ru/wp-content/uploads/2019/08/cropped-logo-2.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novel List", true, function(data)
			return getSearch(data)
		end)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,

	hasSearch = true,
	isSearchIncrementing = true,
	search = getSearch,
	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", ORDER_BY_VALUES),
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,
}
