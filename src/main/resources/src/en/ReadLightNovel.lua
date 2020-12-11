-- {"id":6118,"ver":"1.0.1","libVer":"1.0.0","author":"TechnoJo4"}

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
			title = text(e),
			link = shrinkURL(e:attr("href")),
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

		local novel = doc:selectFirst("div.novel")
		local left = novel:selectFirst(".novel-left")
		local details = novel:selectFirst(".novel-right .novel-details")
		local info = NovelInfo {
			title = doc:selectFirst(".block-title h1"):text(),
			imageURL = left:selectFirst(".novel-cover img"):attr("src"),
			description = table.concat(map(details:selectFirst(".novel-detail-body"):select("p"), text), "\n"),
			alternativeTitles = map(details:selectFirst(".novel-detail-item.color-gray"):select("li a"), text)
		}

		if loadChapters then
			local i = 0
			local dedup = {} -- table for deduplication, dedup[url] will be true if chapter already exists

			info:setChapters(AsList(filter(map2flat(
						doc:selectFirst("#accordion .tab-content"):select(".tab-pane ul"),
						function(v) return v:select("li a") end,
						function(v)
							i = i + 1
							return NovelChapter {
								order = i,
								title = v:text(),
								link = shrinkURL(v:attr("href")),
							}
						end),
					function(chap)
						local duplicate = dedup[chap:getLink()]
						dedup[chap:getLink()] = true
						return not duplicate
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
