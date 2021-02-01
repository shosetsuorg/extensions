-- {"id":4217,"ver":"1.0.1","libVer":"1.0.0","author":"TechnoJo4","dep":["Madara>=1.2.2"]}

return Require("Madara")("https://woopread.com", {
    id = 4217,
    name = "Woopread",
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/src/main/resources/icons/WoopRead.png",
    searchHasOper = true,
    shrinkURLNovel = "series",
    novelListingURLPath = "novel-list",
    novelPageTitleSel = "h1",
    genres = {
        "Action",
        "Adult",
        "Adventure",
        "Comedy",
        "Dark",
        "Drama",
        "Fantasy",
        "Harem",
        "Historical",
        "Horror",
        "Isekai",
        "Josei",
        "Light Novel",
        "Manhua",
        "Manhwa",
        "Martial Arts",
        "Mature",
        "Mystery",
        "Psychological",
        "Romance",
        "School Life",
        "Seinen",
        "Shoujo",
        "Shounen",
        "Supernatural",
        "Thriller",
        "Tragedy",
        "Virtual Reality",
        "Xuanhuan",
        "Canceled",
        "On Hold",
        ["on-going"] = "Ongoing",
        ["complete"] = "Completed",
        ["slice-of-life"] = "Slice of Life",
    },
})
