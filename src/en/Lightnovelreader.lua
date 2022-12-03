-- {"id":7619416,"ver":"1.0.0","libVer":"1.0.0","author":"AbhiTheModder","dep":[]}

local baseURL = "https://lightnovelreader.me"

local function shrinkURL(url)
  return url:gsub(baseURL, "")
end

local function expandURL(url)
  return baseURL .. url
end

local function parseNovels(doc)
  return map(doc:selectFirst(".categoryItems ul"):select("> li"), function(el)
    local title = el:selectFirst(".category-name"):selectFirst("a")
    local image = el:selectFirst(".category-image"):selectFirst("img")
    return Novel {
      title = title:text(),
      link = title:attr("href"),
      imageURL = image:attr("src")
    }
  end)
end

return {
	id = 7619416,
	name = "LightNovelReader",
	baseURL = baseURL,
	imageURL = "https://lightnovelreader.me/assets/new/images/logo.png",
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Top Rated", true, function(data)
			return parseNovels(GETDocument(expandURL("/ranking/top-rated/" .. data[PAGE])))
		end)
	},

	getPassage = function(chapterURL)
		local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst("#chapterText")

		-- Remove/modify unwanted HTML elements to get a clean webpage.
		htmlElement:select("center"):remove()

		return pageOfElem(htmlElement, true)
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(expandURL(novelURL))

    local main = doc:selectFirst(".container > .row > div > .row")
		local details = main:selectFirst(".novels-detail")
    local description = main:selectFirst("> :nth-child(5) > div")

		local info = NovelInfo {
			title = doc:selectFirst("novel-title"):text(),
			imageURL = expandURL(details:selectFirst(".novels-detail-left img"):attr("src")),
			description = table.concat(map(description:select("p"), text), "\n"),
			genres = map(details:selectFirst(".novels-detail-right > ul > li:nth-child(3) > .novels-detail-right-in-right"):select("a"), text),
			authors = map(details:selectFirst(".novels-detail-right > ul > li:nth-child(6) > .novels-detail-right-in-right"):select("a"), text),
		}

		if loadChapters then
			local chapter_list = doc:selectFirst(".novel-detail-chapters li > a")
			local curOrder = 0

			info:setChapters(
				AsList(
					map(chapter_list, function(a)
						curOrder = curOrder + 1
						return NovelChapter {
							order = curOrder,
							title = a:text(),
							link = shrinkURL(a:attr("href")),
						}
					end)
				)
			)
		end

		return info
	end,

	hasSearch = true,
	isSearchIncrementing = false,
	search = function(data)
    local req = Request(GET(baseURL .. "/search/autocomplete/dataType-json&query="..data[QUERY], {Accept = "application/json"}))

    local decodedJson = json.decode(req:getBody())

    -- Get novels from the JSON.
    local novels = {}
    for _, n in ipairs(decodedJson.results) do
        novels[#novels + 1] = Novel {
            title = n.original_title,
            link = shrinkURL(n.link),
            imageURL = n.image
        }
    end

		return novels
	end,
}

