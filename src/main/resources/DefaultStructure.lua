--- @author Doomsdayrs
--- @version 1.0.0

luajava = require("luajava")

local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "TODO"

--- @return boolean
function isIncrementingChapterList()
    -- TODO Complete
    return false
end

--- @return boolean
function isIncrementingPassagePage()
    -- TODO Complete
    return false
end

--- @return Ordering java object
function chapterOrder()
    -- TODO Complete
    return LuaSupport:getOrdering(0)
end

--- @return Ordering java object
function latestOrder()
    -- TODO Complete
    return LuaSupport:getOrdering(0)
end

--- @return boolean
function hasCloudFlare()
    -- TODO Complete
    return false
end

--- @return boolean
function hasSearch()
    -- TODO Complete
    return true
end

--- @return boolean
function hasGenres()
    -- TODO Complete
    return true
end

--- @return Array of genres
function genres()
    -- TODO Complete
    return LuaSupport:getGAL()
end

--- @return number ID
function getID()
    -- TODO Use random number generator. between 10 and 10000, Make sure the number hasn't already been used
    return -1
end

--- @return string name of site
function getName()
    -- TODO Complete
    return ""
end

--- @return string image url of site
function getImageURL()
    -- TODO Complete
    return ""
end

--- @param page number value
--- @return string url of said latest page
function getLatestURL(page)
    -- TODO Complete
    return ""
end

--- @param document : Jsoup document of the page with chapter text on it
--- @return string passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    -- TODO Complete
    return ""
end

--- @param document : Jsoup document of the novel information page
--- @return NovelPage : java object
function parseNovel(document)
    novelPage = LuaSupport:getNovelPage()
    -- TODO Complete
    return novelPage
end

--- @param document : Jsoup document of the novel information page
--- @param increment number : Page #
--- @return NovelPage : java object
function parseNovelI(document, increment)
    novelPage = LuaSupport:getNovelPage()
    -- TODO Complete
    return novelPage
end

--- @param url string       url of novel page
--- @param increment number which page
function novelPageCombiner(url, increment)
    -- TODO Complete
    return ""
end

--- @param document : Jsoup document of latest listing
--- @return Array : Novel array list
function parseLatest(document)
    novels = LuaSupport:getNAL()
    -- TODO Complete
    return novels
end

--- @param document : Jsoup document of search results
--- @return Array : Novel array list
function parseSearch(document)
    novels = LuaSupport:getNAL()
    -- TODO Complete
    return novels
end

--- @param query string query to use
--- @return string url
function getSearchString(query)
    -- TODO Complete
    return ""
end

