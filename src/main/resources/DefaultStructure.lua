-- {"id":-1,"version":"9.9.9","author":"","repo":""}

local baseURL = "TODO"
local settings = {}

local function setSettings(setting)
    settings = setting
end

--- @return Novel[]
local function someFunction()
    return {}
end

--- @param inc int @page of said
--- @return Novel[]
local function someFunctionInc(inc)
    return {}
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    -- TODO
    return ""
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    -- TODO
    return NovelInfo()
end

--- @param data table @Table of values. Always has "query"
--- @return Novel[]
local function search(data)
    -- TODO
    return {}
end

return {
    id = -1,
    name = "DEFAULT",
    imageURL = "",
    hasCloudFlare = false,
    hasSearch = true,
    listings = {
        Listing("Of something", false, someFunction),
        Listing("Of something that increments", true, someFunctionInc)
    },

    -- Filters / Settings the app can use
    filters = {
        "We will define someday"
    },
    settings = {
        "Settings that can be implemented / changed"
    },


    -- Default functions that had to be set
    getPassage = getPassage,
    parseNovel = parseNovel,
    search = search,
    setSettings = setSettings
}
