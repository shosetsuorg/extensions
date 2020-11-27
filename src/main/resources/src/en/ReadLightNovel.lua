-- {"id":6118,"ver":"1.0.0","libVer":"1.0.0","author":"TechnoJo4"}

local baseURL = "https://www.readlightnovel.org"
local qs = Require("url").querystring
 
local function shrinkURL(url)
	return url:gsub(".-readlightnovel%.org", "")
end

local function expandURL(url)
	return baseURL .. url
end

local text = function(v) return v:text() end

local function parseTop(doc)
	return map(doc:select("div.top-novel-block"), function(v)
		local e = v:selectFirst("a")
		return Novel {
			link = shrinkURL(e:attr("href")),
			title = e:text(),
			imageURL = v:selectFirst("img"):attr("src")
		}
	end)
end

return {
	id = 6118,
	name = "ReadLightNovel",
	baseURL = baseURL,
	imageURL = "https://readlightnovel.org/favicon.ico",

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Top Novels", true, function(data)
			return parseTop(GETDocument(baseURL .. "/top-novel/" .. data[PAGE]))
		end)
	},

	getPassage = function(chapterURL)
		local e = GETDocument(expandURL(chapterURL)):selectFirst(".container--content .row .desc")
		return table.concat(map(e:select("p"), text), "\n")
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(expandURL(novelURL))

		local info = NovelInfo {
			title = doc:selectFirst(".block-title h1"):text(),
			description = table.concat(map(doc:selectFirst(".novel-detail-body"):select("p"), text), "\n")
		}

		if loadChapters then
			local i = 0
			info:setChapters(AsList(map2flat(
				doc:selectFirst(".tab-content"):select(".tab-pane"),
				function(v) return v:select("li a") end,
				function(v)
					i = i + 1
					return NovelChapter {
						order = i,
						title = v:text(),
						link = shrinkURL(v:attr("href")),
					}
				end)))
		end

		return info
	end,

	search = function(data)
		return parseTop(RequestDocument(
			POST(baseURL .. "/detailed-search", nil,
				RequestBody(qs({ keyword=data[QUERY], search=1 }), MediaType("application/x-www-form-urlencoded")))
			))
	end,
}
