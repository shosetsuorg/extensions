-- {"id":1376,"ver":"2.0.0","libVer":"1.0.0","dep":["Utilities>=1.0.0"],"author":"AriaMoradi"}

local baseURL = "https://www.wuxia.blog"
-- An hash containing the already displayed links to avoid the same novel appearing on multiple pages.
local _linksHash = {}

local removeDuplicateNovels = Require("Utilities").removeDuplicateNovels
local convertHTMLToText = Require("Utilities").convertHTMLToText

local function shrinkURL(url)
	return url:gsub(".-wuxia%.blog", "")
end

local function expandURL(url)
	return baseURL .. url
end

local text = function(v) return v:text() end

return {
	id = 1376,
	name = "wuxia.blog",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/WuxiaDotBlog.png",
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Latest Updated", true, function(data)
			-- Annoying fix to avoid the page 0 being loaded, which is broken.
			local pageOffset = 0
			if data[PAGE] == 0 then
				pageOffset = 1
			end
			
			if data[PAGE] == 1 or data[PAGE] + pageOffset == 1 then
				_linksHash = {}
			end
			
			local document = GETDocument(expandURL( "/?page=" .. data[PAGE]+ pageOffset)):select(".media")
			local novels = map(document, function(it)
				return Novel {
					title = it:selectFirst(".media-heading"):text(),
					link = it:selectFirst(".media-body a"):attr("href"),
					imageURL = expandURL("/" .. it:selectFirst("img"):attr("src")),
				}
			end)

			novels, _linksHash = removeDuplicateNovels(novels, _linksHash)
			return novels
		end),
		Listing("Novel list", false, function(data)
			return map(GETDocument(expandURL("/listNovels"))
					:select("table tbody tr td:nth-child(2) a"), function(it)
				return Novel {
					link = it:attr("href"),
					title = it:text()
				}
			end)
		end)
	},

	parseNovel = function(novelURL, loadChapters)
		local document = GETDocument(expandURL(novelURL))
		local panel = document:selectFirst("div.panel.panel-default")
		local panelBody = panel:selectFirst("div.panel-body .row")
		local information = panelBody:selectFirst(".row")

		-- Removal of elements needs to be its own step.
		local description = panelBody:selectFirst('[itemprop="description"]')
		description:select("h4"):remove()

		local novel = NovelInfo {
			title = panel:selectFirst("h4.panel-title"):text(),
			setAlternativeTitles = map(information:select(".coll:nth-child(1) a"), text),
			imageURL = panelBody:selectFirst(".imageCover img"):attr("src"),
			description = convertHTMLToText(description, false, true),
			genres = map(information:select(".label"), text),
			tags = map(document:select(".panel .panel .label"), text),
			authors = map(information:select(".row > div:nth-child(2) > a"), text)
		}

		if loadChapters then
			local first100 = map(document:select("table tbody tr"), function(it, i)
				local chap = NovelChapter()
				chap:setTitle(it:selectFirst("a"):text())
				chap:setLink(shrinkURL(it:selectFirst("a"):attr("href")))
				chap:setRelease(it:selectFirst("td:nth-child(2)"):text())
				return chap
			end)

			-- might run into 404 if 100< chapters on the site
			pcall(function ()
				local moreEl = document:selectFirst("#more")
				local nid = moreEl:attr("data-nid")
				local document2 = GETDocument(expandURL('/temphtml/_tempChapterList_all_' .. tostring(nid) .. '.html'))
				local rest = map(document2:select("a"), function(it, i)
					return NovelChapter {
						title = it:text(),
						link = shrinkURL(it:attr("href")),
						release = it:nextSibling():text()
					}
				end)
				for _,value in pairs(rest) do
					first100[#first100+1] = value
				end
			end)
			local chapters = AsList(first100)
			Reverse(chapters)

			novel:setChapters(chapters)
		end
		return novel
	end,

	getPassage = function(chapterURL)
		local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst(".panel-body.article")

		-- Remove/modify unwanted HTML elements to get a clean webpage.
		htmlElement:select("div"):remove()
		htmlElement:select("button"):remove()

		return pageOfElem(htmlElement, true)
	end,

	isSearchIncrementing = false,
	search = function(data)
		local result = {}

		-- fails if query returns nothing
		pcall(function ()
			local rows = GETDocument(expandURL("/?search=" .. string.gsub(data[QUERY]," ","+"))):select("tr")
			for i=1, rows:size()-1 do -- ignore the first
				local row = rows:get(i)
				local novel = Novel()
				novel:setImageURL(row:selectFirst("td:nth-child(2) img"):attr("src"))
				novel:setTitle(row:selectFirst("td:nth-child(3) a"):text())
				novel:setLink(shrinkURL(row:selectFirst("td:nth-child(3) a"):attr("href")))

				result[#result+1] = novel
			end
		end)
		return result
	end,
}
