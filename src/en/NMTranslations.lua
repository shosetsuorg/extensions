-- {"id":93082,"ver":"1.0.0","libVer":"1.0.0","author":"Doomsdayrs","dep":[]}
local baseURL = "https://www.nanomashin.online"

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
	local novelInfo = NovelInfo()
	local document = GETDocument(novelURL)
	novelInfo:setTitle(document:selectFirst("h1.text-2xl"):text())
	novelInfo:setImageURL(baseURL .. document:selectFirst("img.object-contain"):attr("src"))
	novelInfo:setDescription(document:selectFirst("div.pt-6.pb-8"):selectFirst("div.pt-6.pb-8"):text())

	local navBox = document:selectFirst("nav.flex")

	if navBox ~= nil then

	end

end

return {
	id = 93082,
	name = "NM Translations",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NMTranslations.png",
	hasSearch = false,
	listings = {
		Listing("Projects", false, function()
			local d = GETDocument(baseURL .. "/projects")

			return map(d:select("div.p-4"), function(v)
				local lis = Novel()
				local title = v:selectFirst("h2.mb-3")

				lis:setTitle(title:text())
				lis:setLink(baseURL .. title:selectFirst("href"))

				local imageURL = v:selectFirst("img.object-cover")
				lis:setImageURL(baseURL .. imageURL:attr("src"))
				return lis
			end)
		end)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	--settings = {
	--  DropdownFilter(1, "Language", { "English", "Chinese" })
	--},
	--updateSetting = function(id, value)
	--	settings[id] = value
	--end
}