-- {"id":12483,"ver":"1.0.0","libVer":"1.0.0","author":"Doomsdayrs","dep":[]}

local baseURL = "https://kolnovel.com"

local function shrinkURL(url)
	return url:gsub("^.-kolnovel%.com/?", "")
end

local function expandURL(url)
	return baseURL .. url
end

return {
	id = 12483,
	name = "KOL Novel",
	baseURL = baseURL,
	imageURL = "https://kolnovel.com/wp-content/uploads/2021/01/%D8%A7%D9%84%D9%84%D9%88%D8%AC%D9%88-%D8%A7%D9%84%D8%AC%D8%AF%D9%8A%D8%AF-3.png",
	hasSearch = false,
	listings = {
		Listing("Series", false, function()
			return {}
		end),
		Listing("Bookmarked", false, function()

			return {}
		end),
		Listing("A-Z", true, function(data)
			local page = data[PAGE]
			local section = "/az-list"
			local urlPath = "/?show="
			local show = ""
			if page == 0 then
				show = "."
			elseif page == 1 then
				show = "0-9"
			elseif page >= 2 then
				show = string.char(65 + (page - 2))
			end
			local document = GETDocument(baseURL .. section .. urlPath .. show)

			return map(document:select("article.bs"), function(article)
				return Novel {
					title = article:selectFirst("span.ntitle"):text(),
					link = shrinkURL(article:selectFirst("a.tip"):attr("href")),
					imageURL = article:selectFirst("img"):attr("src")
				}
			end)
		end)
	},

	parseNovel = function(url, loadChapters)
		return NovelInfo()
	end,

	getPassage = function(url)
		return ""
	end,
	shrinkURL = shrinkURL,
	expandURL = expandURL
}