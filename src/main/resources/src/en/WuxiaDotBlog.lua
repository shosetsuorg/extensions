-- {"id":1376,"ver":"2.0.1","libVer":"1.0.0","author":"AriaMoradi","dep":["fun>=0.1.3"]}
--- @author AriaMoradi
--- @version 2.0.1

local baseURL = "https://www.wuxia.blog"
local _links = {}

local fun = Require("fun")

local function shrinkURL(url)
	return url:gsub(baseURL, "")
end

local function expandURL(url)
	return baseURL .. url
end

local function isLinkDuplicate(link)
	for key, value in pairs(_links) do
		if value == link then
			return true
		end
	end
	_links[#_links+1] = link
	return false
end

local function pipeline(obj)
    return function(f, ...)
        if not f then
            return obj
        else
            return pipeline(f(obj, ...))
        end
    end
end

return {
	id = 1376,
	name = "wuxia.blog",
	baseURL = baseURL,
	imageURL = baseURL .. "/android-icon-192x192.png",
	expandURL = expandURL,
	listings = {
		Listing("Latest Updated", true, function(data)
			return fun.iter(asTable(GETDocument(baseURL .. "/?page=" .. data[PAGE] + 1):select(".media")))
				:map(function(it)
					local novel = Novel()
					novel:setLink(it:selectFirst(".media-body a"):attr("href"))
					novel:setTitle(it:selectFirst(".media-heading"):text())
					novel:setImageURL(baseURL .. "/" .. it:selectFirst("img"):attr("src"))
					return novel
				end)
				:filter(function (v)
					return not isLinkDuplicate(v:getLink())
				end)
				:totable()
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
		novel:setImageURL(document:selectFirst(".imageCover img"):attr("src"))

		novel:setAuthors(
			map(
				document:select(".panel-body .row .row .row > div:nth-child(2) > a"),
				function (it)
					return it:text()
				end
			)
		)
		novel:setGenres(
			map(
				document:select(".panel-body .row .row .label"),
				function (it)
					return it:text()
				end
			)
		)
		local k = map(
			document:select(".panel-body .row .row .row > div:nth-child(2) > a"),
			function (it)
				return it:text()
			end
		)

		novel:setAlternativeTitles(
			map(
				document:select(".panel-body .row .row .coll:nth-child(1) a"),
				function (it)
					return it:text()
				end
			)
		)
		novel:setTags(
			map(
				document:select(".panel .panel .label"),
				function (it)
					return it:text()
				end
			)
		)

		novel:setDescription(
			string.match(
				document:selectFirst('[itemprop="description"]'):text(),
				"Description: (.*)"
		))

		if loadChapters then
			local first100 = fun.iter(asTable(document:select("table tbody tr")))
				:map(function(it)
					local chap = NovelChapter()
					chap:setTitle(it:selectFirst("a"):text())
					chap:setLink(it:selectFirst("a"):attr("href"))
					chap:setRelease(it:selectFirst("td:nth-child(2)"):text())
					return chap
				end)

			-- might run into 404 if 100< chapters on the site
			pcall(function ()
				local moreEl = document:selectFirst("#more")
				local nid = moreEl:attr("data-nid")
				local document2 = GETDocument(baseURL .. '/temphtml/_tempChapterList_all_' .. tostring(nid) .. '.html')
				local rest = fun.iter(asTable(document2:select("a")))
					:map(function(it)
						local chap = NovelChapter()
						chap:setTitle(it:text())
						chap:setLink(it:attr("href"))
						chap:setRelease(it:nextSibling():text())
						return chap
					end)
				first100 = first100:chain(rest)
			end)
			local chapters = AsList(first100:totable())
			Reverse(chapters)

			novel:setChapters(chapters)
		end
		return novel
	end,

	getPassage = function(chapterURL)
		local document = GETDocument(chapterURL):select(".panel-body.article")

		local pragraphs = fun.iter(asTable(document:select("p")))
			:map(function(v)
				return v:text()
			end)
			:totable()

		return pipeline(pragraphs)
			(table.concat, "\n")
			(string.gsub, "\n\n", "\n")
			(string.gsub, "This chapter is updated by Wuxia.Blog\n", "")
			(string.gsub, "Liked it?? Take a second to support Wuxia.Blog on Patreon!", "")()
		
	end,

	search = function(data)
		local result = {}

		-- fails if query retuns nothing
		pcall(function ()
			fun.iter(asTable(GETDocument(baseURL .. "/?search=" .. string.gsub(data[QUERY]," ","+")):select("tr")))
				:tail()
				:map(function (row)
					local novel = Novel()
					novel:setImageURL(row:selectFirst("td:nth-child(2) img"):attr("src"))
					novel:setTitle(row:selectFirst("td:nth-child(3) a"):text())
					novel:setLink(shrinkURL(row:selectFirst("td:nth-child(3) a"):attr("href")))
					return novel
				end)
				:each(function (it)
					result[#result+1] = it
				end)
		 end)

		return result
	end,
	isSearchIncrementing = false,
}
