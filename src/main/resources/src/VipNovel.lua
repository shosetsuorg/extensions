-- {"id":586,"version":"1.0.0","author":"TechnoJo4","repo":""}

return Require("Madara")("https://vipnovel.com", {
    id = 586,
    name = "VipNovel",
    imageURL = "http://vipnovel.com/wp-content/uploads/2017/10/coollogo_com-1630861.png",
    genres = {},

    latestNovelSel = "div.col-12.col-md-6",
    getLatestURL = function(page)
        return "https://vipnovel.com/vipnovel/page/" .. page .. "/?m_orderby=latest"
    end
})
