-- {"id":1,"version":"1.0.0","author":"TechnoJo4","repo":""}

return Require("NovelFull")("http://novelfull.com", {
    id = 1,
    name = "NovelFull",
    imageURL = "",
    genres = {},

    meta_offset = 0,
    ajax_hot = "/ajax-search?type=hot",
    ajax_latest = "/ajax-search?type=latest",
    ajax_chapters = "/ajax-chapter-option",
})
