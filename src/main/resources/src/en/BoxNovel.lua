-- {"id":2,"ver":"2.0.1","libVer":"1.0.0","author":"Doomsdayrs","dep":["Madara>=1.1.0"]}

return Require("Madara")("https://boxnovel.com", {
	id = 2,
	name = "BoxNovel",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/src/main/resources/icons/BoxNovel.png",
	genres = {
		"Action",
		"Adventure",
		"Comedy",
		"Drama",
		"Ecchi",
		"Fantasy",
		"Gender Bender",
		"Harem",
		"Historical",
		"Horror",
		"Josei",
		"Martial Arts",
		"Mature",
		"Mecha",
		"Mystery",
		"Psychological",
		"Romance",
		"School Life",
		"Sci-fi",
		"Seinen",
		"Shoujo",
		"Shounen",
		"Slice of Life",
		"Smut",
		"Sports",
		"Supernatural",
		"Tragedy",
		"Wuxia",
		"Xianxia",
		"Xuanhuan",
		"Yaoi"
	},
	latestNovelSel = "div.col-12.col-md-6",
	novelPageTitleSel = "h1",
	chapterLoader = ---@param document Document
	---@param novelInfo NovelInfo
	function(self, document, novelInfo)
		local button = document:selectFirst("a.wp-manga-action-button")
		local id = button:attr("data-post")

		local chapterDocument = RequestDocument(
				POST("https://boxnovel.com/wp-admin/admin-ajax.php", nil,
						FormBodyBuilder()
								:add("action", "manga_get_chapters")
								:add("manga", id):build())
		)

		local e = chapterDocument:select("li.wp-manga-chapter")
		local a = e:size()

		local l = AsList(map(e, function(v)
			local c = NovelChapter()
			c:setLink(self.shrinkURL(v:selectFirst("a"):attr("href")))
			c:setTitle(v:selectFirst("a"):text())

			local i = v:selectFirst("i")
			c:setRelease(i and i:text() or v:selectFirst("img[alt]"):attr("alt"))
			c:setOrder(a)
			a = a - 1
			return c
		end))
		Reverse(l)
		novelInfo:setChapters(l)
	end
})
