-- {"id":-1,"version":"1.0.0","author":"","repo":""}

local baseURL = "TODO"
local settings = {}

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	return ""
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
	return NovelInfo()
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @param reporter fun(v : string | any)
--- @return Novel[]
local function search(filters, reporter)
	return {}
end

return {
	id = -1,
	name = "DEFAULT",
	baseURL = baseURL,
	imageURL = "",
	hasCloudFlare = false,
	hasSearch = true,
	updateSetting = function(id, value)
		settings[id] = value
	end,

	-- Must have at least one value
	listings = {
		Listing("Something", false, function()
			return {}
		end),
		Listing("Something (with pages!)", true, function(idx)
			return {}
		end)
	},

	-- Optional if usable
	filters = {
		TextFilter(1, "RANDOM STRING INPUT"),
		SwitchFilter(2, "RANDOM SWITCH INPUT"),
		RadioGroupFilter(3, "RANDOM RGROUP INPUT", { "A", "B", "C" }),
		DropdownFilter(4, "RANDOM DDOWN INPUT", { "A", "B", "C" })
	},
	settings = {
		TextFilter(1, "RANDOM STRING INPUT"),
		SwitchFilter(2, "RANDOM SWITCH INPUT"),
		RadioGroupFilter(3, "RANDOM RGROUP INPUT", { "A", "B", "C" }),
		DropdownFilter(4, "RANDOM DDOWN INPUT", { "A", "B", "C" })
	},

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
}
