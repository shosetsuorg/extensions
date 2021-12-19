-- {"ver":"1.2.1","author":"TechnoJo4","dep":["dkjson","CommonCSS"]}

local css = Require("CommonCSS").table

return function(id, name, base, contentSel, image)
	local settings

	local infos = {}
	local novels = {}
	local api = base .. "/api"
	local POST = Require("dkjson").POST
	local data

	local function getNovels()
		if not data or not data.result or (not data.items) then
			data = POST(api .. "/novels/search", { count = 1000 })
		end
		if not data.result then return end

		infos = {}
		novels = {}
		for _, v in pairs(data.items) do
			novels[#novels + 1] = {
				link = v.slug,
				title = v.name,
				imageURL = v.coverUrl
			}

			-- TODO: Clean description html
			infos[v.slug] = {
				title = v.name,
				imageURL = v.coverUrl,
				description = ("Description:\n%s\n\nSynopsis:\n%s\n"):format(v.description or "None", v.synopsis or "None"),
				authors = { v.authorName },
				tags = v.tags,
				genres = v.genres,
				language = v.language,
				status = v.status == 1 and NovelStatus.PUBLISHING
						or v.status == 2 and NovelStatus.COMPLETED
						or NovelStatus.UNKNOWN
			}
		end
	end

	return {
		id = id,
		name = name,
		baseURL = base,
		imageURL = image,
		chapterType = ChapterType.HTML,

		listings = {
			Listing("All Novels", false, function()
				getNovels()
				return map(novels, Novel)
			end)
		},

		getPassage = function(url)
			local content = GETDocument(base .. url):selectFirst(contentSel)
			map(content:select(".chapter-nav"), function(v)
				v:remove()
			end)
			map(content:select("[border]"), function(elem)
				elem:removeAttr("border")
			end)
			return pageOfElem(content, true, css)
		end,

		parseNovel = function(slug, loadChapters)
			getNovels()
			local info = infos[slug]
			if loadChapters then
				local i = 1
				info.chapters = AsList(map2flat(
						GETDocument(base .. "/novel/" .. slug):select("#accordion .panel"),
						function(v)
							return v:select("li.chapter-item a")
						end, function(v)
							local c = NovelChapter()
							c:setLink(v:attr("href"))
							c:setTitle(v:text())
							c:setOrder(i)
							i = i + 1
							return c
						end))
			end
			return NovelInfo(info)
		end,

		search = function(s)
			getNovels()
			local q = s[QUERY]:lower()
			return map(filter(novels, function(v)
				return v.title:lower():find(q, 1, true) ~= nil
			end), Novel)
		end,

		setSettings = function(s) settings = s end,
		updateSetting = function() end,
		expandURL = function(url, type)
			return type == KEY_NOVEL_URL and base.."/novel/"..url or base..url
		end
	}
end
