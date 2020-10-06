-- {"id":3,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "https://yomou.syosetu.com"
local passageURL = "https://ncode.syosetu.com"
local encode = Require("url").encode

---@param url string
local function shrinkURL(url)
	return url:gsub(passageURL, "")
end

---@param url string
local function expandURL(url)
	return passageURL .. url
end

return {
	id = 3,
	name = "Syosetsu",
	baseURL = baseURL,
	imageURL = "https://static.syosetu.com/view/images/common/logo_yomou.png",
	listings = {
		Listing("Latest", true, function(data)
			if data[PAGE] == 0 then
				data[PAGE] = 1
			end
			return map(GETDocument(
					baseURL .. "/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=" .. data[PAGE])
					:select("div.searchkekka_box"), function(v)
				local novel = Novel()
				local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
				novel:setLink(shrinkURL(e:attr("href")))
				novel:setTitle(e:text())
				return novel
			end)
		end)
	},

	-- Default functions that had to be set
	getPassage = function(chapterURL)
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
,
	parseNovel = function(novelURL, loadChapters)
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
				chap:setLink(v:selectFirst("a"):attr("href"))
				chap:setRelease(v:selectFirst("dt.long_update"):text())
				chap:setOrder(i)
				return chap
			end)))
		end
		return novelPage
	end,
	shrinkURL = shrinkURL,
	expandURL = expandURL,
	search = function(data)
		return map(GETDocument(baseURL .. "/search.php?&word=" .. encode(data[0]) .. "&p=" .. data[PAGE])
				:select("div.searchkekka_box"),
				function(v)
					local novel = Novel()
					local e = v:selectFirst("div.novel_h"):selectFirst("a.tl")
					novel:setLink(shrinkURL(e:attr("href")))
					novel:setTitle(e:text())
					return novel
				end)
	end,
}
