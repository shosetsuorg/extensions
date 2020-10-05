-- {"id":2443,"version":"1.0.0","author":"Doomsdayrs","repo":"","dep":["foo","bar"]}

local baseURL = "https://saikaiscan.com.br"
local settings = {}

local FILTER_TIPO_KEY = 91
local TIPO_V = { [0] = "novels",[1] = "manhuas",[2] = "curiosities" }

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	local lines = GETDocument(chapterURL):selectFirst("div.full-text"):select("p")
	local passage = "\n"
	map(lines,function (e)
		passage = passage .. e:text() .. "\n"
	end)
	return passage
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
	local novelInfo = NovelInfo()
	local document = GETDocument(novelURL)
	local infos = document:select("div.info")

	novelInfo:setTitle(document:selectFirst("h2"):text())
	novelInfo:setImageURL(document:selectFirst("div.cover"):select("img"):attr("data-src"))
	novelInfo:setAlternativeTitles({ infos:get(0):text() })
	novelInfo:setGenres({ infos:get(1):text() })
	novelInfo:setAuthors({ infos:get(2):text() })
	local st = infos:get(3):text()
	if st == "Em Tradução" then
		novelInfo:setStatus(NovelStatus(0))
	else
		novelInfo:setStatus(NovelStatus(3))
	end

	local description = ""
	map(document:select("div.summary-text"):select("span"), function(e)
		description = description .. e:text() .. "\n"
	end)
	novelInfo:setDescription(description)

	local chaptersDocs = document:selectFirst("div.project-chapters"):select("div.chapters")

	local chapterCount = 0
	---@type ArrayList
	local chapters = map2flat(chaptersDocs, function(e)
		return e:select("a")
	end, function(e)
		local chapter = NovelChapter()
		chapter:setTitle(e:text())
		chapter:setLink(e:attr("href"))
		chapter:setOrder(chapterCount)
		chapterCount = chapterCount + 1
		return chapter
	end)
	novelInfo:setChapters(chapters)
	return novelInfo
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @param reporter fun(v : string | any)
--- @return Novel[]
local function search(filters, reporter)
	return {}
end

return {
	id = 2443,
	name = "Saikai Scan",
	baseURL = baseURL,

	-- Optional values to change
	imageURL = baseURL .. "/media/cache/16/89/1689ed75fe55808825d33185a28788ed.png",
	hasSearch = true,

	-- Must have at least one value
	listings = {
		Listing("Últimas atualizações", false, function(data)
			local doc = GETDocument(baseURL)
			local type = data[FILTER_TIPO_KEY]
			local itemList = doc:selectFirst("ul." .. TIPO_V[type])
			---@type Elements
			local items
			if type == 0 then
				items = itemList:select("li.novel-item")
			elseif type == 1 then
				items = itemList:select("li.manhua-item")
			else
				items = itemList:select("li")
			end
			return map(items, function(e)
				local novel = Novel()
				novel:setTitle(e:selectFirst("h3"):text())
				novel:setImageURL(baseURL .. e:selectFirst("div.image"):attr("data-src"))
				novel:setLink(e:selectFirst("a"):attr("href"))
				return novel
			end)
		end)
	},

	-- Optional if usable
	searchFilters = {
		DropdownFilter(FILTER_TIPO_KEY, "Tipo", { "Novels","Comics","Curiosidades" })
	},

	shrinkURL = function(url) end,

	expandURL = function(url)
		return baseURL .. url
	end,

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
}
