-- {"id":93082,"ver":"1.0.2","libVer":"1.0.0","author":"Doomsdayrs","dep":[]}
local baseURL = "https://www.nanomashin.online"

local function text(v)
	return v:text()
end

return {
	id = 93082,
	name = "NM Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NMTranslations.png",
	hasSearch = false,
	listings = {
		Listing("Projects", false, function()
			local doc = GETDocument(baseURL)

			return map(doc:select("div.p-4"), function(v)
				local title = v:selectFirst("h2.mb-3"):selectFirst("a")
				return Novel {
					title = title:text(),
					link = title:attr("href"),
					imageURL = baseURL .. v:selectFirst("img.object-cover"):attr("src"),
				}
			end)
		end)
	},

	parseNovel = function(url, loadChapters)
		local document = GETDocument(baseURL .. url)

		local info = NovelInfo {
			title = document:selectFirst("h1.text-3xl"):text(),
			imageURL = baseURL .. document:selectFirst("img.object-contain"):attr("src"),
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
					local chaptersDocument = GETDocument(baseURL .. url .. "/page/" .. page)
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

	getPassage = function(url)
		local doc = GETDocument(baseURL .. "/" .. url)
		return table.concat(map(doc:selectFirst("div.pt-10"):select("p"), text), "\n")
	end
}
