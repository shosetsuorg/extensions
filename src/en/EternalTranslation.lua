-- {"id":4224,"ver":"1.0.3","libVer":"1.0.0","author":"MechTechnology","dep":["Madara>=2.3.2"]}

return Require("Madara")("https://eternaltranslation.com", {
	id = 4224,
	name = "Eternal Translation",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/EternalTranslation.png",
	chaptersOrderReversed = false,
	chaptersScriptLoaded = true,
	ajaxUsesFormData = true,
	ajaxFormDataSel= "#manga-chapters-holder",
	ajaxFormDataAttr = "data-id",
	novelPageTitleSel = "div.post-title > h1",
	latestNovelSel = ".col-12.col-md-4.badge-pos-2",
	novelListingURLPath = "novel",
	shrinkURLNovel = "novel",
	searchHasOper = false,

	genres = {
		"Action",
		"Comedy",
		"Drama",
		"Fantasy",
		"Historical",
		"Josei",
		"Mystery",
		"Romance",
		"Romance Fantasy",
		"Seinen",
		"Shoujo",
		["slice-of-life"] = "Slice of Life",
		"Supernatural",
		"Tragedy",
		["complete"] = "Completed",
		["on-going"] = "Ongoing",
		"Canceled",
		"On Hold",
	}
})
