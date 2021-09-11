-- {"id":3746,"ver":"1.0.0","libVer":"1.0.0","author":"Doomsdayrs","dep":[]}

local baseURL = "https://a-t.nu/"

local function shrinkURL(url)
	return url:gsub(baseURL, "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getPassage(url)
	local doc = GETDocument(url)
	return table.concat(map(doc:selectFirst("div.text-left"):select("p"), function(p)
		p:text()
	end), "\n")
end

local function parseNovel(url)
	local doc = GETDocument(url)
	local novel = NovelInfo()
	local novelID = doc:selectFirst("div.button-wrapper > a.wp-manga-action-button"):attr("data-post")

	novel:setTitle(doc:selectFirst("h1.madara-title"):text())
	novel:setImageURL(doc:selectFirst("img.img-responsive"):attr("src"))
	novel:setDescription(
			table.concat(map(doc:selectFirst("div.summary__content"):select("strong"), function(strong)
				strong:text()
			end), "\n"))
	novel:setAuthors({ novelID })

	local chapterDoc = RequestDocument(
			POST(baseURL .. "wp-admin/admin-ajax.php",
					HeadersBuilder()
							:add("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
							:build(),
					FormBodyBuilder()
							:add("action", "manga_get_chapters")
							:add("manga", novelID)
							:build())
	)

	local htmlChapters = chapterDoc:select("li.wp-manga-chapter.free-chap > a")
	local size = htmlChapters:size() - 1

	novel:setChapters(AsList(map(htmlChapters, function(chapterA)
		local chapter = NovelChapter()
		chapter:setTitle(chapterA:text())
		chapter:setLink(shrinkURL(chapterA:attr("href")))
		chapter:setOrder(size)
		size = size - 1
		return chapter
	end)))

	return novel
end

return {
	id = 3746,
	name = "Very Active Fan Translations",
	baseURL = baseURL,
	hasSearch = false,
	imageURL = "https://a-t.nu/wp-content/uploads/2021/06/cropped-AT-LOGO-192x192.png",
	listings = {
		Listing("Novels", false, function()
			return map(GETDocument(baseURL):select("div.post"), function(post)
				local novel = Novel()
				novel:setTitle(post:selectFirst("h1"):attr("title"))
				novel:setImageURL(post:selectFirst("img"):attr("src"))
				novel:setLink(shrinkURL(post:selectFirst("a"):attr("href")))
				return novel
			end)
		end)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	shrinkURL = shrinkURL,
	expandURL = expandURL
}