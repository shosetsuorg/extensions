-- {"id":420,"ver":"1.0.0","libVer":"1.0.0","author":"Dunbock","dep":["url>=1.0.0"]}

local baseURL = "https://octopii.co"

local encode = Require("url").encode
 
local function shrinkURL(url)
	return url:gsub(".-octopii%.co", "")
end

local function expandURL(url)
	return baseURL .. url
end

local text = function(v) return v:text() end

local function parseTop(doc)
	return map(doc:selectFirst("main#primary"):select("div.col-12.col-md-6"), function(v)
		local e = v:selectFirst("h3.novel-name a")
		return Novel {
			title = text(e),
			link = shrinkURL(e:attr("href")),
			imageURL = v:selectFirst("img"):attr("src")
		}
	end)
end

return {
	id = 420,
	name = "Octopii",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Octopii.png",
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Top Novels", true, function(data)
			return parseTop(GETDocument(expandURL("/novel-list/page/" .. data[PAGE] .. "/?m_orderby=latest")))
		end)
	},

	getPassage = function(chapterURL)
		local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst("header.entry-header")

		-- Remove/modify unwanted HTML elements to get a clean webpage.
		htmlElement:select("div.on-top-nav"):remove() -- top navigation
		htmlElement:select("div.chapter-list-wrapper"):remove() -- bottom navigation

		return pageOfElem(htmlElement, true)
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(expandURL(novelURL))

		local main = doc:selectFirst("main#primary")
		local info_wrapper = main:selectFirst("div.info-wrapper")
		local details = info_wrapper:selectFirst("div#top-info")

		local info = NovelInfo {
			title = details:selectFirst("h1"):text(),
			imageURL = info_wrapper:selectFirst("img"):attr("src"),
			description = info_wrapper:selectFirst("div#description p"):text(),
			status = ({
				Ongoing = NovelStatus.PUBLISHING,
				Completed = NovelStatus.COMPLETED,
			})[details:selectFirst("div.novel-status"):text()],
			genres = map(details:select("div.genre-title"), text),
		}
		local selector = details:selectFirst("div.author-wrapper")
		if selector ~= nil then
			info:setAuthors(map(selector:select("a"), text))
		end
		selector = details:selectFirst("div.alternative-name")
		if selector ~= nil then
			info:setAlternativeTitles(map(selector:select("h2"), text))
		end

		if loadChapters then
			local chapter_list = main:selectFirst("div#chapter-list")
			local curOrder = 0
			info:setChapters(
				AsList(
					map(chapter_list:select("h3.chapter-title a"), function(v)
						curOrder = curOrder + 1
						return NovelChapter {
							order = curOrder,
							title = v:text(),
							link = shrinkURL(v:attr("href")),
						}
					end)
				)
			)
		end

		return info
	end,

	hasSearch = true,
	isSearchIncrementing = true,
	search = function(data)
		return parseTop(GETDocument(expandURL("/page/" .. data[PAGE] .. "/?s=" .. encode(data[QUERY]))))
	end,
}
