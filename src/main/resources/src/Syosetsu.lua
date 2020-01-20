-- {"id":3,"version":"1.1.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.1.0

local luajava = require("luajava")

--local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "https://yomou.syosetu.com"
local passageURL = "https://ncode.syosetu.com"

--- @return boolean
function isIncrementingChapterList()
    return false
end

--- @return boolean
function isIncrementingPassagePage()
    return false
end

--- @return Ordering
function chapterOrder()
    return LuaSupport:getOrdering(0)
end

--- @return Ordering
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
    return false
end

--- @return Array @Array<NovelGenre>
function genres()
    return LuaSupport:getGAL()
end

--- @return number @ID
function getID()
    return 3
end

--- @return string @name of site
function getName()
    return "Syosetu"
end

--- @return string @image url of site
function getImageURL()
    return "https://static.syosetu.com/view/images/common/logo_yomou.png"
end

--- @param page number @value
--- @return string @url of said latest page
function getLatestURL(page)
    if page == 0 then page = 1 end
    return baseURL .. "/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=" .. page
end

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    local elements = document:select("div")
    local elem
    for i=0, elements:size()-1 do
        if elements:get(i):id() == "novel_contents" then
            elem = elements:get(i):select("p")
            break
        end
    end
    if not elem then
        return "INVALID PARSING, CONTACT DEVELOPERS"
    end

    local t = {}
    for i=1, elem:size(), 1 do
        t[i] = elem:get(i-1):text()
    end
    return table.concat(t, "\n"):gsub("<br>", "\n\n")
end

--- @param document Document @Jsoup document of the novel information page
--- @return NovelPage @java object
function parseNovel(document)
    local novelPage = LuaSupport:getNovelPage()

    do
        local authors = LuaSupport:getStringArray()
        authors:setSize(1)
        authors:setPosition(0, document:selectFirst("div.novel_writername"):text():gsub("作者：", ""))
        novelPage:setAuthors(authors:getStrings())
        novelPage:setTitle(document:selectFirst("p.novel_title"):text())
    end

    -- Description
    do
        local elements = document:select("div")
        local elem
        for i=0, elements:size()-1 do
            if elements:get(i):id() == "novel_color" then
                elem = elements:get(i)
                break
            end
        end

        if elem then
            novelPage:setDescription(elem:text():gsub("<br>\n<br>", "\n"):gsub("<br>", "\n"))
        end
    end

    -- Chapters
    do
        local novelChapters = LuaSupport:getCAL()
        local elements = document:select("dl.novel_sublist2")
        for i = 0, elements:size() - 1, 1 do
            local element = elements:get(i)
            local novelChapter = LuaSupport:getNovelChapter()
            novelChapter:setTitle(element:selectFirst("a"):text())
            novelChapter:setLink(passageURL .. element:selectFirst("a"):attr("href"))
            novelChapter:setRelease(element:selectFirst("dt.long_update"):text())
            novelChapter:setOrder(i+1)
            novelChapters:add(novelChapter)
        end
        novelPage:setNovelChapters(novelChapters)
    end

    return novelPage
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelPage @java object
function parseNovelI(document, increment)
    return parseNovel(document)
end


--- @param url string       url of novel page
--- @param increment number which page
function novelPageCombiner(url, increment)
    return url
end

--- @param document Document @Jsoup document of latest listing
--- @return Array @Novel array list
function parseLatest(document)
    local novels = LuaSupport:getNAL()
    local elements = document:select("div.searchkekka_box")
    for i = 0, elements:size() - 1, 1 do
        local novel = LuaSupport:getNovel()
        local e = elements:get(i):selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        novels:add(novel)
    end
    return novels
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
function parseSearch(document)
    local novels = LuaSupport:getNAL()
    local elements = document:select("div.searchkekka_box")
    for i = 0, elements:size() - 1, 1 do
        local novel = LuaSupport:getNovel()
        local e = elements:get(i):selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        novels:add(novel)
    end
    return novels
end

--- @param query string @query to use
--- @return string @url
function getSearchString(query)
    return baseURL .. "/search.php?&word=" .. query:gsub("%+", "%2"):gsub(" ", "\\+")
end

