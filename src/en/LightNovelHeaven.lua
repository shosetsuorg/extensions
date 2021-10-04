-- {"id":2925,"ver":"2.1.0","libVer":"1.0.0","author":"Doomsdayrs","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://lightnovelheaven.com", {
	id = 2925,
	name = "Light Novel Heaven",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/LightNovelHeaven.png",

	-- defaults values
	novelListingURLPath = "novel-list",
	shrinkURLNovel = "series",

	genres = {}
})
