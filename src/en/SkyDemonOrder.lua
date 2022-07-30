-- {"id":93082,"ver":"3.0.0","libVer":"1.0.0","author":"MechTechnology"}
local baseURL = "https://skydemonorder.com/"

local function text(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-skydemonorder%.com/?", "")
end

local function expandURL(url)
	return baseURL .. url
end

return {
	id = 93082,
	name = "Sky Demon Order",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/SkyDemonOrder.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,
	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Projects", false, function()
			local doc = GETDocument(baseURL)
			return map(doc:select("a.transform.rounded-xl"), function(v)
				return Novel {
					title = v:selectFirst("h3"):text(),
					link = shrinkURL(v:attr("href")),
					imageURL = v:selectFirst("img"):attr("src"),
				}
			end)
		end)
	},

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(expandURL(url))
		local info = NovelInfo {
			title = doc:selectFirst("header h1"):text(),
			imageURL = doc:selectFirst("main img"):attr("src"),
			description = doc:selectFirst(".font-l.prose"):text(),
		}

		if loadChapters then
			--- @param novelDoc Document
			local function parseChapters(novelDoc)
				return mapNotNil(novelDoc:selectFirst("section:last-child"):select(".flex.items-center a"), function(v)
					return NovelChapter {
						title = v:text(),
						link = shrinkURL(v:attr("href")),
					}
				end)
			end

			local chapters = { parseChapters(doc) }
			chapters = flatten(chapters)

			local o = 1
			for i = #chapters, 1, -1 do
				chapters[i]:setOrder(o)
				o = o + 1
			end

			local chaptersList = AsList(chapters)
			Reverse(chaptersList)
			info:setChapters(chaptersList)
		end

		return info
	end,

	getPassage = function(chapterURL)
		local htmlElement = GETDocument(expandURL(chapterURL))
		local title = htmlElement:selectFirst("header h1"):text()
		htmlElement = htmlElement:selectFirst("main div.prose.max-w-none")
		-- Chapter title inserted before chapter text
		htmlElement:child(0):before("<h1>" .. title .. "</h1>");

		return pageOfElem(htmlElement, true)
	end
}
