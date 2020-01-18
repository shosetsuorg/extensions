-- {"id":2}
--- @author Doomsdayrs
--- @version 1.0.0

luajava = require("luajava")

local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "https://boxnovel.com"

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
    return 2
end

--- @return string name of site
function getName()
    return "BoxNovel"
end

--- @return string image url of site
function getImageURL()
    return "https://boxnovel.com/wp-content/uploads/2018/04/BoxNovel-1.png"
end

--- @param page number value
--- @return string url of said latest page
function getLatestURL(page)
    return baseURL .. "/novel/page/" .. page .. "/?m_orderby=latest"
end

--- @param document : Jsoup document of the page with chapter text on it
--- @return string passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    paragraphs = document:select("div.text-left"):select("p")
    passage = ""
    for i = 0, paragraphs:size() - 1, 1 do
        passage = passage .. paragraphs:get(i):toString() .. "\n"
    end
    return string.gsub(string.gsub(passage, "</p>", ""), "<p>", "")
end

--- @param document : Jsoup document of the novel information page
--- @return NovelPage : java object
function parseNovel(document)
    novelPage = LuaSupport:getNovelPage()
    novelPage:setImageURL(document:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"))
    novelPage:setTitle(document:selectFirst("h3"):text())
    novelPage:setDescription(document:selectFirst("p"):text())

    -- Info
    elements = document:selectFirst("div.post-content"):select("div.post-content_item")
    for i = 1, elements:size() - 1, 1 do
        subElements = nil
        if i == 0 or i == 1 or i == 2 or i == 6 then
        elseif i == 3 then
            subElements = elements:get(i):select("a")
            authors = LuaSupport:getStringArray()
            authors:setSize(subElements:size())
            for y = 0, subElements:size() - 1, 1 do
                authors:setPosition(y, subElements:get(y):text())
            end
            novelPage:setAuthors(authors:getStrings())
        elseif i == 4 then
            subElements = elements:get(i):select("a")
            artists = LuaSupport:getStringArray()
            artists:setSize(subElements:size())
            for y = 0, subElements:size() - 1, 1 do
                artists:setPosition(y, subElements:get(y):text())
            end
            novelPage:setArtists(artists:getStrings())
        elseif i == 5 then
            subElements = elements:get(i):select("a")
            genres = LuaSupport:getStringArray()
            genres:setSize(subElements:size())
            for y = 0, subElements:size() - 1, 1 do
                genres:setPosition(y, subElements:get(y):text())
            end
            novelPage:setArtists(genres:getStrings())
        end
    end

    elements = document:selectFirst("div.post-status"):select("div.post-content_item")
    for i = 0, elements:size() - 1, 1 do
        if i == 0 or i == 2 then
        elseif i == 1 then
            status = elements:get(i):select("div.summary-content"):text()
            if status == "OnGoing" then
                novelPage:setStatus(LuaSupport:getStatus(0))
            elseif status == "Completed" then
                novelPage:setStatus(LuaSupport:getStatus(1))
            end
        end
    end

    -- Chapters
    novelChapters = LuaSupport:getCAL()
    elements = document:select("li.wp-manga-chapter")
    a = elements:size()
    for i = 0, elements:size() - 1, 1 do
        element = elements:get(i)
        novelChapter = LuaSupport:getNovelChapter()
        novelChapter:setLink(element:selectFirst("a"):attr("href"))
        novelChapter:setTitle(element:selectFirst("a"):text())
        novelChapter:setRelease(element:selectFirst("i"):text())
        novelChapter:setOrder(a)
        a = a - 1
        novelChapters:add(novelChapter)
    end
    novelChapters = LuaSupport:reverseAL(novelChapters)
    novelPage:setNovelChapters(novelChapters)

    return novelPage
end

--- @param document : Jsoup document of the novel information page
--- @param increment number : Page #
--- @return NovelPage : java object
function parseNovelI(document, increment)
    print("LUA: Passing novel")
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
    novelsHTML = document:select("div.col-xs-12.col-md-6")
    for i = 0, novelsHTML:size() - 1, 1 do
        novel = LuaSupport:getNovel()
        data = novelsHTML:get(i):selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        novel:setImageURL(data:selectFirst("img"):attr("src"))
        novels:add(novel)
    end
    return novels
end

--- @param document : Jsoup document of search results
--- @return Array : Novel array list
function parseSearch(document)
    novels = LuaSupport:getNAL()
    novelsHTML = document:select("div.c-tabs-item__content")
    for i = 0, novelsHTML:size() - 1, 1 do
        novel = LuaSupport:getNovel()
        data = novelsHTML:get(i):selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        novel:setImageURL(data:selectFirst("img"):attr("src"))
        novels:add(novel)
    end
    return novels
end

--- @param query string query to use
--- @return string url
function getSearchString(query)
    query = string.gsub(query, "\+", "%2")
    query = string.gsub(query, " ", "+")
    return baseURL .. "/?s=" .. query .. "&post_type=wp-manga"
end

