-- {"id":1376,"ver":"1.0.0","libVer":"1.0.0","author":"AriaMoradi"}
--- @author AriaMoradi
--- @version 1.0.0

local baseURL = "https://www.wuxia.blog"

return {
	id = 1376,
	name = "wuxia.blog",
	baseURL = baseURL,
	imageURL = baseURL .. "/android-icon-192x192.png",
	listings = {
		Listing("Latest Updated", true, function(data)
			return map(GETDocument(
					baseURL .. "/?page=" .. data[PAGE])
					:select(".media"), function(it)
				local novel = Novel()
				novel:setLink(it:selectFirst(".media-body a"):attr("href"))
				novel:setTitle(it:selectFirst(".media-heading"):text())
				novel:setImageURL(it:selectFirst("img"):attr("src"))
				return novel
			end)
		end),
		Listing("Novel list", false, function(data)
			return map(GETDocument(
					baseURL .. "/listNovels")
					:select("table tbody tr td:nth-child(2) a"), function(it)
				local novel = Novel()
				novel:setLink(it:attr("href"))
				novel:setTitle(it:text())
				return novel
			end)
		end)
	},

	parseNovel = function(novelURL, loadChapters)
		local novel = NovelInfo()
		local document = GETDocument(baseURL .. novelURL)

		novel:setTitle(document:selectFirst("h4.panel-title"):text())

		novel:setAuthors(
			map(
				document:select(".panel-body .row .row .row > div:nth-child(2) > a"),
				function (it)
					it:text()
				end
			)
		)

		novel:setDescription(
			string.match(
				document:selectFirst('[itemprop="description"]'):text(),
				"Description: (.*)"
		))

		if loadChapters then
			local first100 = map(document:select("table tbody tr"), function(it, i)
				local chap = NovelChapter()
				chap:setTitle(it:selectFirst("a"):text())
				chap:setLink(it:selectFirst("a"):attr("href"))
				chap:setRelease(it:selectFirst("td:nth-child(2)"):text())
				chap:setOrder(i)
				return chap
			end)

			-- might run into 404 if 100< chapters on the site
			pcall(function ()
				local moreEl = document:selectFirst("#more")
				local nid = moreEl:attr("data-nid")
				local document2 = GETDocument(baseURL .. '/temphtml/_tempChapterList_all_' .. tostring(nid) .. '.html')
				local rest = map(document2:select("a"), function(it, i)
					local chap = NovelChapter()
					chap:setTitle(it:text())
					chap:setLink(it:attr("href"))
					chap:setRelease(it:nextSibling():text())
					chap:setOrder(i)
					return chap
				end)
				for key,value in pairs(rest) do
					first100[#first100+1] = value
				end
			end)

			novel:setChapters(AsList(first100))
		end
		return novel
	end,

	getPassage = function(chapterURL)
		local document = GETDocument(chapterURL):select("panel-body.article")

		return table.concat(map(document:select("p"), function(v)
			return v:text()
		end), "\n") :gsub("<br>", "\n\n")
	end,

	search = function(data)
		local result = {}

		-- fails if query retuns nothing
		pcall(function ()
			local rows = GETDocument(baseURL .. "/?search=" .. string.gsub(data[QUERY]," ","+")):select("tr")
			for i=1, rows:size()-1 do -- ignore the first
				local row = rows:get(i)
				local novel = Novel()
				novel:setImageURL(row:selectFirst("td:nth-child(2) img"):attr("src"))
				novel:setTitle(row:selectFirst("td:nth-child(3) a"):text())
				novel:setLink(string.gsub(row:selectFirst("td:nth-child(3) a"):attr("href"),baseURL,""))

				result[#result+1] = novel
			end
		end)
		return result
	end,
	isSearchIncrementing = false,
}
