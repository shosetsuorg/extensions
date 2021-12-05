-- {"id":-1,"ver":"1.0.0","libVer":"1.0.0","author":"","repo":"","dep":["foo","bar"]}

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

	-- Optional values to change
	imageURL = "",
	hasCloudFlare = false,
	hasSearch = true,


	-- Must have at least one value
	listings = {
		Listing("Something", false, function(data)
			return {}
		end),
		Listing("Something (with pages!)", true, function(data, index)
			return {}
		end),
		Listing("Something without anything", false, function()
			return {}
		end)
	},

	-- Optional if usable
	searchFilters = {
		TextFilter(1, "RANDOM STRING INPUT"),
		SwitchFilter(2, "RANDOM SWITCH INPUT"),
		CheckboxFilter(3, "RANDOM CHECKBOX INPUT"),
		TriStateFilter(4, "RANDOM TRISTATE CHECKBOX INPUT"),
		RadioGroupFilter(5, "RANDOM RGROUP INPUT", { "A","B","C" }),
		DropdownFilter(6, "RANDOM DDOWN INPUT", { "A","B","C" })
	},
	settings = {
		TextFilter(1, "RANDOM STRING INPUT"),
		SwitchFilter(2, "RANDOM SWITCH INPUT"),
		CheckboxFilter(3, "RANDOM CHECKBOX INPUT"),
		TriStateFilter(4, "RANDOM TRISTATE CHECKBOX INPUT"),
		RadioGroupFilter(5, "RANDOM RGROUP INPUT", { "A","B","C" }),
		DropdownFilter(6, "RANDOM DDOWN INPUT", { "A","B","C" })
	},

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	updateSetting = function(id, value)
		settings[id] = value
	end
}
