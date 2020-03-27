-- {"id":394,"version":"1.0.0","author":"TechnoJo4","repo":""}

return Require("Madara")("https://readnovelforlife.com", {
	id = 394,
	name = "ReadNovelForLife",
	imageURL = "https://readnovelforlife.com/wp-content/uploads/2019/12/Logo-1-e1570608260730.png",
	genres = {},
	appendToSearchFilters = function()
		return {}
	end,
	appendToSearchURL = function(url,data)
		return self.___baseURL .. "/?s=".. self.parseString(data[QUERY])
	end,
})
