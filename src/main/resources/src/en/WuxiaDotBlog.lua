-- {"id":1376,"ver":"1.0.2","libVer":"1.0.0","author":"AriaMoradi"}
--- @author AriaMoradi
--- @version 1.0.2

local baseURL = "https://www.wuxia.blog"
local _links = {}

local function shrinkURL(url)
	return url:gsub(baseURL, "")
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

-- from ReadLightNovel
local function identity(...)
	return ...
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
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/src/main/resources/icons/WuxiaDotBlog.png",
	listings = {
		Listing("Latest Updated", true, function(data)
			return pipeline(GETDocument(baseURL .. "/?page=" .. data[PAGE]):select(".media"))
				(map, function(it)
					local novel = Novel()
					novel:setLink(it:selectFirst(".media-body a"):attr("href"))
					novel:setTitle(it:selectFirst(".media-heading"):text())
					novel:setImageURL(baseURL .. "/" .. it:selectFirst("img"):attr("src"))
					return novel
				end, identity)
				(filter, function (v)
					return not isLinkDuplicate(v:getLink())
				end)()
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
			local first100 = map(document:select("table tbody tr"), function(it, i)
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
				local rest = map(document2:select("a"), function(it, i)
					local chap = NovelChapter()
					chap:setTitle(it:text())
					chap:setLink(it:attr("href"))
					chap:setRelease(it:nextSibling():text())
					return chap
				end)
				for key,value in pairs(rest) do
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
		local document = GETDocument(chapterURL):select(".panel-body.article")

		return pipeline(document:select("p"))
			(map, function(v)
				return v:text()
			end)
			(table.concat, "\n")
			(string.gsub, "\n\n", "\n")
			(string.gsub, "This chapter is updated by Wuxia.Blog\n", "")
			(string.gsub, "Liked it?? Take a second to support Wuxia.Blog on Patreon!", "")()
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
				novel:setLink(shrinkURL(row:selectFirst("td:nth-child(3) a"):attr("href")))

				result[#result+1] = novel
			end
		end)
		return result
	end,
	isSearchIncrementing = false,
}
