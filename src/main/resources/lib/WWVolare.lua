-- {"ver":"1.2.0","author":"TechnoJo4","dep":["dkjson"]}

-- good table style for USAW
-- PR a good style if any other elements are used for layout in any other novels
local css = [[
table {
    background: #004b7a;
    margin: 10px auto;
    width: 90%;
    border: none;
    box-shadow: 1px 1px 1px rgba(0, 0, 0, .75);
    border-collapse: separate;
    border-spacing: 2px;
}]]

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
				status = v.status == 1 and NovelStatus.PUBLISHING or NovelStatus.UNKNOWN
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
