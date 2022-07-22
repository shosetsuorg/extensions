-- {"id":4304,"ver":"1.0.0","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://readhive.org"

local json = Require("dkjson")

local text = function(v)
	return v:text()
end


local function shrinkURL(url)
	return url:gsub("^.-readhive%.org", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function clearNewLines(v)
	-- Remove addtional empty paragraphs if they exist
	local toRemove = {}
	v:traverse(NodeVisitor(function(v)
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
	return v
end

local function getLatestListing(data)
	local page = data[PAGE]
	local url = "/page/" ..page.. "/?"
	local doc = GETDocument(expandURL(url))
	local data = doc:selectFirst(".mb-16.space-y-16"):selectFirst(".flex.flex-wrap")
	return map(data:select(".flex.flex-col.w-full.px-2"), function(v)
		local a = v:selectFirst("a")
		if a ~= nil then
			return Novel {
				title = a:selectFirst("img"):attr("alt"):gsub(" Thumbnail*$", ""),
				link = shrinkURL(a:attr("href")),
				imageURL = expandURL(a:selectFirst("img"):attr("src"))
			}
		end
	end)
end

local function parseNovel(novelURL, loadChapters)
	local doc = GETDocument(expandURL(novelURL))
	local content = doc:selectFirst("main")
	local description = content:selectFirst(".grid-in-desc")
	description = clearNewLines(description)

	local info = NovelInfo {
		title = content:selectFirst("h1"):text(),
		imageURL = expandURL(content:selectFirst(".grid-in-art"):selectFirst("img"):attr("src")),
		description = table.concat(map(description:select("p"), text), '\n'),
		genres = map(content:selectFirst(".grid-in-info"):child(1):select("a"), text),
		tags = map(content:selectFirst(".grid-in-info"):child(3):select("a"), text)
	}
	
	if loadChapters then
		local chapterList = content:selectFirst(".grid-in-content"):select("a")
		local chapters = (mapNotNil(chapterList, function(v, i)
			-- This is to ignore the premium chapter, those have a lock icon in their anchor.
			local PremChapter = v:selectFirst("svg")
			if PremChapter ~= nil then return nil end
			return NovelChapter {
				order = i,
				title = v:selectFirst("p"):text(),
				link = shrinkURL(v:attr("href")),
				release = v:selectFirst("span.text-xs"):text()
			}
		end))
		info:setChapters(AsList(chapters))
	end
	return info
end

local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))
	local title = doc:selectFirst("h1"):text()
	local chap = doc:selectFirst(".justify-center.flex-grow.mx-auto.prose")
	chap = clearNewLines(chap)
	chap:child(0):before("<h1>" .. title .. "</h1>")
	return pageOfElem(chap, true)
end

local function dump(o)
	if type(o) == 'table' then
		 local s = '{ '
		 for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. dump(v) .. ','
		 end
		 return s .. '} '
	else
		 return tostring(o)
	end
end

local function getSearch(data)
	local query = data[QUERY]
	local m = MediaType("multipart/form-data; boundary=----aWhhdGVrb3RsaW4K")
	local body = RequestBody("------aWhhdGVrb3RsaW4K\r\nContent-Disposition: form-data; name=\"query\"\r\n\r\n" 
		.. query.. 
		"\r\n------aWhhdGVrb3RsaW4K--\r\n"
		.. "------aWhhdGVrb3RsaW4K\r\nContent-Disposition: form-data; name=\"action\"\r\n\r\n"
		.. "search" .. 
		"\r\n------aWhhdGVrb3RsaW4K--\r\n", m)

	local response = RequestDocument(POST(expandURL("/ajax"), nil, body))
	response = json.decode(response:selectFirst('body'):text())
	return map(response["data"], function(v)
		return Novel {
			title = v.title,
			link = shrinkURL(v.url),
			imageURL = expandURL(v.thumb)
		}
	end)
end

local function getListing(data)
	return getSearch(data)
end

return {
	id = 4304,
	name = "Readhive",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/TravisTranslations.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Latest", true, getLatestListing)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	
	hasSearch = true,
	isSearchIncrementing = false,
	search = getSearch,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
