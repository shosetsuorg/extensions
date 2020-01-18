-- {"id":3}
--- @author Doomsdayrs
--- @version 1.0.0

luajava = require("luajava")

local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
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
    return false
end

--- @return Array of genres
function genres()
    return LuaSupport:getGAL()
end

--- @return number ID
function getID()
    return 3
end

--- @return string name of site
function getName()
    return "Syosetu"
end

--- @return string image url of site
function getImageURL()
    return "https://static.syosetu.com/view/images/common/logo_yomou.png"
end

--- @param page number value
--- @return string url of said latest page
function getLatestURL(page)
    if page == 0 then
        page = 1
    end
    return baseURL .. "/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=" .. page
end

--- @param document : Jsoup document of the page with chapter text on it
--- @return string passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    elements = document:select("div")
    found = false
    x = 0
    while (x < elements:size() and not found) do
        if elements:get(x):id() == "novel_contents" then
            found = true
            elements = elements:get(x):select("p")
        end
        x = x + 1
    end
    if found then
        passage = ""
        for i = 0, elements:size() - 1, 1 do
            passage = passage .. elements:get(i):text() .. "\n"
        end
        return string.gsub(passage, "<br>", "\n\n")
    end
    return "INVALID PARSING, CONTACT DEVELOPERS"
end

--- @param document : Jsoup document of the novel information page
--- @return NovelPage : java object
function parseNovel(document)
    novelPage = LuaSupport:getNovelPage()

    authors = LuaSupport:getStringArray()
    authors:setSize(1)
    authors:setPosition(0, string.gsub(document:selectFirst("div.novel_writername"):text(), "作者：", ""))
    novelPage:setAuthors(authors:getStrings())

    novelPage:setTitle(document:selectFirst("p.novel_title"):text())

    -- Description
    element = nil
    found = false
    elements = document:select("div")
    x = 0
    while (x < elements:size() and not found) do
        if elements:get(x):id() == "novel_color" then
            element = elements:get(x)
            found = true
        end
        x = x + 1
    end

    if found then
        desc = element:text()
        desc = string.gsub(string.gsub(desc, "<br>\n<br>", "\n"), "<br>", "\n")
        novelPage:setDescription(desc)
    end

    -- Chapters
    novelChapters = LuaSupport:getCAL()
    elements = document:select("dl.novel_sublist2")
    for i = 0, elements:size() - 1, 1 do
        element = elements:get(i)
        novelChapter = LuaSupport:getNovelChapter()
        novelChapter:setTitle(element:selectFirst("a"):text())
        novelChapter:setLink(passageURL .. element:selectFirst("a"):attr("href"))
        novelChapter:setRelease(element:selectFirst("dt.long_update"):text())
        novelChapter:setOrder(x)
        novelChapters:add(novelChapter)
    end
    novelPage:setNovelChapters(novelChapters)

    return novelPage
end

--- @param document : Jsoup document of the novel information page
--- @param increment number : Page #
--- @return NovelPage : java object
function parseNovelI(document, increment)
    return parseNovel(document)
end

--- @param url string       url of novel page
--- @param increment number which page
function novelPageCombiner(url, increment)
    return url
end

--- @param document : Jsoup document of latest listing
--- @return Array : Novel array list
function parseLatest(document)
    novels = LuaSupport:getNAL()
    elements = document:select("div.searchkekka_box")
    for i = 0, elements:size() - 1, 1 do
        element = elements:get(i)
        novel = LuaSupport:getNovel()
        e = element:selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        novels:add(novel)
    end
    return novels
end

--- @param document : Jsoup document of search results
--- @return Array : Novel array list
function parseSearch(document)
    novels = LuaSupport:getNAL()
    elements = document:select("div.searchkekka_box")
    for i = 0, elements:size() - 1, 1 do
        element = elements:get(i)
        novel = LuaSupport:getNovel()
        e = element:selectFirst("div.novel_h"):selectFirst("a.tl")
        novel:setLink(e:attr("href"))
        novel:setTitle(e:text())
        novels:add(novel)
    end
    return novels
end

--- @param query string query to use
--- @return string url
function getSearchString(query)
    query = string.gsub(string.gsub(query, "\+", "%2"), " ", "\\+")
    query = baseURL .. "/search.php?&word=" .. query
    return query
end

