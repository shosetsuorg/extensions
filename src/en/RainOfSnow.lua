-- {"id":4300,"ver":"1.0.8","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://rainofsnow.com"

local text = function(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-rainofsnow%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getPassage(chapterURL)
	local chap = GETDocument(chapterURL):selectFirst("div.content")
	-- Removes the title and makes it an H1 for consistant custom CSS.
	local title = chap:selectFirst("h2"):text()
	chap:selectFirst("h2"):remove()
	chap:child(0):before("<h1>" .. title .. "</h1>")
	-- Remove empty <p> tags
	local toRemove = {}
	chap:traverse(NodeVisitor(function(v)
		if v:tagName() == "p" and v:text() == "" then
			toRemove[#toRemove+1] = v
		end
		if v:hasAttr("border") then
			v:removeAttr("border")
		end
	end, nil, true))
	for _,v in pairs(toRemove) do
		v:remove()
	end
	return pageOfElem(chap, false, css)
end

local function parseNovel(novelURL, loadChapters)
	local doc = GETDocument(baseURL .. novelURL)
	local content = doc:selectFirst("div.queen")

	local info = NovelInfo {
		title = content:selectFirst("div.text > h2"):text(),
		imageURL = content:selectFirst("img"):attr("data-src"),
		description = table.concat(map(doc:selectFirst("div#synop"):select("p"), text), '\n'),
		authors = { content:selectFirst("ul.vbtcolor1"):child(1):selectFirst(".vt2"):text() },
		artists = {
			"Translator: " .. content:selectFirst("ul.vbtcolor1"):child(2):selectFirst(".vt2"):text(),
			"Editor: " .. content:selectFirst("ul.vbtcolor1"):child(3):selectFirst(".vt2"):text()
		},
		genres = map(content:selectFirst("ul.vbtcolor1"):child(4):selectFirst(".vt2"):select("a"), text),
		tags = map(content:selectFirst("ul.vbtcolor1"):child(6):selectFirst(".vt2"):select("a"), text)
	}

	if loadChapters then
		local chapters = {}
		chapters[#chapters+1] = (mapNotNil(content:selectFirst("#chapter ul.march1"):select("li"), function(v, i)
			return NovelChapter {
				order = i,
				title = v:selectFirst("a"):text(),
				link = v:selectFirst("a"):attr("href"),
				release = v:selectFirst(".july"):text()
			}
		end))
		local chapterPages = content:selectFirst("a.next.page-numbers")
		-- Gets chapters from other pages if they exists!
		if chapterPages ~= nil then
			-- Removing the next button and looping throught the numbered page links
			content:select("a.next.page-numbers"):remove()
			map(content:select("a.page-numbers"), function(v)
				chapters[#chapters+1] = mapNotNil(GETDocument(v:attr("href")):selectFirst("#chapter ul.march1"):select("li"), function(v, i)
					return NovelChapter {
						order = i,
						title = v:selectFirst("a"):text(),
						link = v:selectFirst("a"):attr("href"),
						release = v:selectFirst(".july"):text()
					}
					end)
			end)
		end
		info:setChapters(AsList(flatten(chapters)))
	end
	
	return info
end

local function parseListing(listingURL)
	local doc = GETDocument(listingURL)
	return map(doc:select("div.minbox"), function(v)
		local a = v:selectFirst("a")
		return Novel {
			title = a:attr("title"),
			link = shrinkURL(a:attr("href")),
			imageURL = v:selectFirst("img"):attr("data-src")
		}
	end)
end

local function getListing(data)
	local docURL = expandURL("/novels/page/" ..data[PAGE])
	return parseListing(docURL)
end

local function getSearch(data)
	local docURL = expandURL("?s=" ..data[QUERY])
	return parseListing(docURL)
end

return {
	id = 4300,
	name = "Rain Of Snow Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/RainOfSnow.png",
	chapterType = ChapterType.HTML,
	
	listings = { Listing("Popular", true, getListing) },
	getPassage = getPassage,
	parseNovel = parseNovel,
	
	hasSearch = true,
	isSearchIncrementing = false,
	search = getSearch,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
