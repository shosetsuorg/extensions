-- {"id":93082,"ver":"2.0.0","libVer":"1.0.0","author":"Doomsdayrs"}
local baseURL = "https://www.nanomashin.online"

local function text(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-nanomashin%.online/?", "")
end

local function expandURL(url)
	return baseURL .. url
end

return {
	id = 93082,
	name = "NM Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NMTranslations.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,
	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Projects", false, function()
			local doc = GETDocument(baseURL)

			return map(doc:select("div.p-4 a"), function(v)
				return Novel {
					title = v:selectFirst("h2"):text(),
					link = v:attr("href"),
					imageURL = expandURL("/_next/image?url=%2Fstatic%2Fimages%2F" .. v:attr("href") .. "-cover.png&w=384&q=75"),
				}
			end)
		end)
	},

	parseNovel = function(url, loadChapters)
		local document = GETDocument(baseURL .. url)

		local info = NovelInfo {
			title = document:selectFirst("h1.text-3xl"):text(),
			imageURL = expandURL(document:selectFirst("img.object-contain"):attr("src")),
			description = document:selectFirst("div.pt-6.pb-8"):selectFirst("div.pt-6.pb-8"):text(),
		}

		if loadChapters then
			--- @param chaptersDocument Document
			local function parseChapters(chaptersDocument)
				return map(chaptersDocument:select("article.space-y-2"), function(article)
					local titleElement = article:selectFirst("a")
					return NovelChapter {
						title = titleElement:text(),
						link = titleElement:attr("href"),
						release = article:selectFirst("time"):text()
					}
				end)
			end

			local chapters = { parseChapters(document) }

			-- There can be more chapters in other pages
			local navBox = document:selectFirst("nav.flex")
			if navBox then
				local maxPage = tonumber(navBox:selectFirst("span"):text():match("of (%d+)"))

				for page = 2, maxPage do
					local chaptersDocument = GETDocument(expandURL(url .. "/page/" .. page))
					chapters[page] = parseChapters(chaptersDocument)
				end
			end

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
		local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst("article")
		local title = htmlElement:selectFirst("header.pt-6 h1")
		htmlElement:selectFirst("div.pt-10")
		-- Chapter title inserted before chapter text
		htmlElement:child(0):before(title);

		-- Remove/modify unwanted HTML elements to get a clean webpage.
		--htmlElement:select("br"):remove()

		return pageOfElem(htmlElement, true)
	end
}
