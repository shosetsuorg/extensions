-- {"id":3,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "https://yomou.syosetu.com"
local passageURL = "https://ncode.syosetu.com"

--- @param document Document
--- @return string
local function getPassage(chapterURL)
	local e = first(GETDocument(chapterURL):select("div"), function(v)
		return v:id() == "novel_contents"
	end)
	if not e then
		return "INVALID PARSING, CONTACT DEVELOPERS"
	end
	return table.concat(map(e:select("p"), function(v)
		return v:text()
	end), "\n") :gsub("<br>", "\n\n")
end

--- @param document Document
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
	local novelPage = NovelInfo()
	local document = GETDocument(novelURL)

	novelPage:setAuthors({ document:selectFirst("div.novel_writername"):text():gsub("作者：", "") })
	novelPage:setTitle(document:selectFirst("p.novel_title"):text())

	-- Description
	local e = first(document:select("div"), function(v)
		return v:id() == "novel_color"
	end)
	if e then
		novelPage:setDescription(e:text():gsub("<br>\n<br>", "\n"):gsub("<br>", "\n"))
	end
	-- Chapters
	if loadChapters then
		novelPage:setChapters(AsList(map(document:select("dl.novel_sublist2"), function(v, i)
			local chap = NovelChapter()
			chap:setTitle(v:selectFirst("a"):text())
			chap:setLink(passageURL .. v:selectFirst("a"):attr("href"))
			chap:setRelease(v:selectFirst("dt.long_update"):text())
			chap:setOrder(i)
			return chap
		end)))
	end
	return novelPage
end

--- @return ArrayList
local function parseLatest(data, page)
	if page == 0 then
		page = 1
	end
	return map(GETDocument(baseURL .. "/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=" .. page):select("div.searchkekka_box"), function(v)
		local novel = Novel()
		local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
		novel:setLink(e:attr("href"))
		novel:setTitle(e:text())
		return novel
	end)
end

--- @param document Document
--- @return ArrayList
local function search(data)
	returnmap(GETDocument(baseURL .. "/search.php?&word=" .. data[QUERY]:gsub("%+", "%2"):gsub(" ", "\\+")):select("div.searchkekka_box"), function(v)
		local novel = Novel()
		local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
		novel:setLink(e:attr("href"))
		novel:setTitle(e:text())
		return novel
	end)
end

return {
	id = 3,
	name = "Syosetsu",
	baseURL = baseURL,
	imageURL = "https://static.syosetu.com/view/images/common/logo_yomou.png",
	listings = {
		Listing("Latest", {},true, parseLatest)
	},

	-- Default functions that had to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	updateSetting = function() end
}
