-- {"id":74485,"ver":"1.1.1","libVer":"1.0.0","author":"TechnoJo4"}

local baseURL = "https://kobatochan.com"

local function shrinkURL(url)
	return url:gsub("^.-kobatochan%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function page(url, r)
	local doc = GETDocument(r and url or baseURL..url)
	local content = doc:selectFirst("#content article")
	local p = content:selectFirst(".entry-content")

	local page_block = content:selectFirst(".pgntn-page-pagination-block")
	if page_block then
		local p2 = page_block:children()
		local last = p2:get(p2:size()-1)
		if last:hasClass("post-page-numbers") then
			page(last:attr("href"), p)
		end
		page_block:remove()
	end
	local page_link = content:selectFirst("div.page-link")
	if page_link then page_link:remove() end

	-- remove previous/next chapter links
	map(p:select("h3"), function(v)
		if v:selectFirst("a") then
			v:remove()
		end
	end)

	if r then
		p:appendTo(r):unwrap()
	end
	return r or p
end

return {
	id = 74485,
	name = "KobatoChanDaiSuki",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/KobatoChan.png",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("nav#access ul"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Novels", 0, true) or text == "Original Works") and
						map(v:selectFirst("ul.sub-menu"):select("> li > a"), function(v) return v end)
			end)), function(v)
				return Novel {
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return pageOfElem(page(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local content = doc:selectFirst("#content article")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title a"):text(),
			imageURL = content:selectFirst("img"):attr("src")
		}

		if loadChapters then
			info:setChapters(AsList(map(content:selectFirst(".entry-content"):select("a"), function(v, i)
				return NovelChapter {
					order = i,
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
