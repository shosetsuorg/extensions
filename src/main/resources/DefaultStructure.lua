-- {"id":-1,"version":"1.0.0","author":"","repo":""}

local baseURL = "TODO"
local settings = {}

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL) return "" end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL) return NovelInfo() end

--- @param data table @Table of search values (according to filters). Contains a "query" string if searching.
--- @return Novel[]
local function search(data) return {} end

return {
    id = -1,
    name = "DEFAULT",
    imageURL = "",
    hasCloudFlare = false,
    hasSearch = true,
    listings = {
        Listing("Something", false, function() return {} end),
        Listing("Something (with pages!)", true, function(idx) return {} end)
    },

    filters = {},
    settings = {},

    -- Default functions that have to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    setSettings = function(setting) settings = setting end
}
