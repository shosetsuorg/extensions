-- {"id":75,"ver":"1.0.0","libVer":"1.0.0","author":"Doomsdayrs","dep":["Madara>=2.2.0"]}

return Require("Madara")("https://novelcake.com", {
  id = 75,
  name = "Novelcake",
  imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/BoxNovel.png",

      path = { 
        novels: "series",
        novel: "series", 
        chapter: "series" 
  }
})
