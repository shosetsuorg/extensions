-- {"id":762,"ver":"2.1.0","libVer":"1.0.0","author":"Doomsdayrs","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://lightnovelbastion.com", {
	id = 762,
	name = "Light Novel Bastion",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/LightNovelBastion.png",

	-- defaults values
	latestNovelSel = "div.col-6.col-md-3",
	novelListingURLPath = "novels",
	chaptersScriptLoaded = false,

	genres = {}
})
