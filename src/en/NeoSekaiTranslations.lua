-- {"id":8323,"ver":"2.1.0","libVer":"1.0.0","author":"Doomsdayrs","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://www.neosekaitranslations.com", {
	id = 8323,
	name = "NeoSekai Translations",
	imageURL = "https://www.neosekaitranslations.com/wp-content/uploads/2021/04/NeoSekaiLogoSpelled_correctly1.png",

	-- defaults values
	latestNovelSel = "div.col-12.col-md-4.badge-pos-1",
	novelListingURLPath = "novels",
	ajaxUsesFormData = true,

	genres = {
		"Action",
		"Adventure",
		"Comedy",
		"Drama",
		"Fantasy",
		"Harem",
		"Horror",
		"Mature",
		"Mecha",
		"Mystery",
		"Psychological",
		"Romance",
		"School Life",
		"Sci-fi",
		"Slice of Life"
	}
})
