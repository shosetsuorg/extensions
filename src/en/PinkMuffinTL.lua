-- {"id":4301,"ver":"1.0.8","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://pinkmuffinyum.wordpress.com"

local text = function(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-pinkmuffinyum%.wordpress%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getPassage(chapterURL)
	local doc = GETDocument(chapterURL):selectFirst("div.wp-site-blocks")
	local chap = doc:selectFirst(".entry-content.wp-block-post-content")
	local title = doc:selectFirst("h2.wp-block-post-title"):text()
	chap:child(0):before("<h1>" .. title .. "</h1>")
	return pageOfElem(chap, false, css)
end

local function parseNovel(novelURL, loadChapters)
	local doc = GETDocument(novelURL):selectFirst("div.wp-site-blocks")
	local content = doc:selectFirst("main.wp-block-group")

	local info = NovelInfo {
		title = doc:selectFirst("h2.wp-block-post-title"):text(),
		imageURL = content:selectFirst("img"):attr("data-orig-file"),
		description = table.concat(map(doc:selectFirst(".entry-content.wp-block-post-content"):select("p"), text), '\n'),
		artists = {
			"Translator: " .. content:selectFirst(".wp-block-post-author__name"):text(),
		}
	}

	if loadChapters then
		local chapters = (mapNotNil(content:selectFirst(".entry-content.wp-block-post-content"):select("a.wp-block-button__link"), function(v, i)
			return NovelChapter {
				order = i,
				title = v:text(),
				link = shrinkURL(v:attr("href"))
			}
		end))
		info:setChapters(AsList(chapters))
	end
	
	return info
end

local function parseListing(listingURL)
	local doc = GETDocument(listingURL)
	return map(doc:select(".blocks-gallery-item__caption"), function(v)
		local a = v:selectFirst("a")
		if a ~= nil then
			return Novel {
				title = a:text(),
				link = shrinkURL(a:attr("href")),
				imageURL = v:parent():selectFirst("img"):attr("data-orig-file")
			}
		end
	end)
end

local function getListing()
	local docURL = expandURL("/all-projects/")
	return parseListing(docURL)
end

return {
	id = 4301,
	name = "Pink Muffin TL",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/PinkMuffinTL.png",
	chapterType = ChapterType.HTML,
	
	listings = { Listing("All Projects", false, getListing) },
	getPassage = getPassage,
	parseNovel = parseNovel,
	
	hasSearch = false,
	isSearchIncrementing = false,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
