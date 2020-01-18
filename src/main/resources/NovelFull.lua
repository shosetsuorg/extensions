--- @author Doomsdayrs
--- @version 1.0.0

luajava = require("luajava")

local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "http://novelfull.com"

function stripListing(elements, novel)
    for i = 0, elements:size() - 1, 1 do
        coloum = elements:get(i)
        if i == 0 then
            image = coloum:selectFirst("img")
            if not image == nil then
                novel:setImageURL(baseURL .. image:attr("src"))
            end

            header = coloum:selectFirst("h3")
            if not header == nil then
                titleLink = header:selectFirst("a")
                novel:setTitle(titleLink:attr("title"))
                novel:setLink(baseURL .. titleLink:attr("href"))
            end

        elseif i == 1 then

        end
    end
    return novel
end

--- @return boolean
function isIncrementingChapterList()
    return true
end

--- @return boolean
function isIncrementingPassagePage()
    return false
end

--- @return Ordering java object
function chapterOrder()
    return LuaSupport:getOrdering(0)
end

--- @return Ordering java object
function latestOrder()
    return LuaSupport:getOrdering(0)
end

--- @return boolean
function hasCloudFlare()
    return false
end

--- @return boolean
function hasSearch()
    return true
end

--- @return boolean
function hasGenres()
    return true
end

--- @return Array of genres
function genres()
    -- TODO Complete
    return LuaSupport:getGAL()
end

--- @return number ID
function getID()
    return 1
end

--- @return string name of site
function getName()
    return "NovelFull"
end

--- @return string image url of site
function getImageURL()
    return ""
end

--- @param page number value
--- @return string url of said latest page
function getLatestURL(page)
    return baseURL .. "/latest-release-novel?page=" .. page
end

--- @param document : Jsoup document of the page with chapter text on it
--- @return string passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    paragraphs = document:select("div.chapter-c"):select("p")
    passage = ""
    for i = 0, paragraphs:size() - 1, 1 do
        passage = passage .. paragraphs:get(i):text() .. "\n"
    end
    return passage
end

--- @param document : Jsoup document of the novel information page
--- @return NovelPage : java object
function parseNovel(document)
    return parseNovel(document, 1)
end

--- @param document : Jsoup document of the novel information page
--- @param increment number : Page #
--- @return NovelPage : java object
function parseNovel(document, increment)
    novelPage = LuaSupport:getNovelPage()
    -- TODO Complete
    return novelPage
end

--- @param url string       url of novel page
--- @param increment number which page
function novelPageCombiner(url, increment)
    if increment > 1 then
        url = url .. "?page=" .. increment
    end
    return url
end

--- @param document : Jsoup document of latest listing
--- @return Array : Novel array list
function parseLatest(document)
    novels = LuaSupport:getNAL()
    listP = document:select("div.container")
    for i = 0, listP:size() - 1, 1 do
        list = listP:get(i)
        if list:id() == "list-page" then
            queries = list:select("div.row")
            for x = 0, queries:size(), 1 do
                novel = LuaSupport:getNovel()
                novel = stripListing(queries:get(x):select("div"), novel)
                novels:add(novel)
            end
        end
    end
    return novels
end

--- @param document : Jsoup document of search results
--- @return Array : Novel array list
function parseSearch(document)
    novels = LuaSupport:getNAL()
    listP = document:select("div.container")
    for i = 0, listP:size() - 1, 1 do
        list = listP:get(i)
        if list:id() == "list-page" then
            queries = list:select("div.row")
            for x = 0, queries:size(), 1 do
                novel = LuaSupport:getNovel()
                novel = stripListing(queries:get(x):select("div"), novel)
                novels:add(novel)
            end
        end
    end
    return novels
end

--- @param query string query to use
--- @return string url
function getSearchString(query)
    return baseURL .. "/search?keyword=" .. string.gsub(query, " ", "%20")
end

