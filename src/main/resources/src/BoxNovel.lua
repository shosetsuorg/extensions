-- {"id":2,"version":"1.1.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.1.0

local luajava = require("luajava")

--local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "https://boxnovel.com"

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
    return 2
end

--- @return string @name of site
function getName()
    return "BoxNovel"
end

--- @return string @image url of site
function getImageURL()
    return "https://boxnovel.com/wp-content/uploads/2018/04/BoxNovel-1.png"
end

--- @param page number @value
--- @return string @url of said latest page
function getLatestURL(page)
    return baseURL .. "/novel/page/" .. page .. "/?m_orderby=latest"
end

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    local paragraphs = document:select("div.text-left"):select("p")
    local t = {}
    for i=1, paragraphs:size(), 1 do
        t[i] = paragraphs:get(i-1):text()
    end
    return table.concat(t, "\n"):gsub("</?p>", "")
end

--- @param document Document @Jsoup document of the novel information page
--- @return NovelPage @java object
function parseNovel(document)
    local novelPage = LuaSupport:getNovelPage()
    novelPage:setImageURL(document:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"))
    novelPage:setTitle(document:selectFirst("h3"):text())
    novelPage:setDescription(document:selectFirst("p"):text())

    -- Info
    do
        local elements = document:selectFirst("div.post-content"):select("div.post-content_item")

        -- authors
        do
            local authorE = elements:get(3):select("a")
            local authors = LuaSupport:getStringArray()
            authors:setSize(authorE:size())
            for y = 0, authorE:size() - 1, 1 do
                authors:setPosition(y, authorE:get(y):text())
            end
            novelPage:setAuthors(authors:getStrings())
        end
        -- artists
        do
            local artistE = elements:get(4):select("a")
            local artists = LuaSupport:getStringArray()
            artists:setSize(artistE:size())
            for y = 0, artistE:size() - 1, 1 do
                artists:setPosition(y, artistE:get(y):text())
            end
            novelPage:setArtists(artists:getStrings())
        end
        -- genres
        do
            local genreE = elements:get(5):select("a")
            local genres = LuaSupport:getStringArray()
            genres:setSize(genreE:size())
            for y = 0, genreE:size() - 1, 1 do
                genres:setPosition(y, genreE:get(y):text())
            end
            novelPage:setArtists(genres:getStrings())
        end

        -- sorry for this extremely long line
        novelPage:setStatus(LuaSupport:getStatus((
            document:selectFirst("div.post-status"):select("div.post-content_item"):get(1)
                :select("div.summary-content"):text() == "OnGoing") and 0 or 1))
    end

    -- Chapters
    do
        local novelChapters = LuaSupport:getCAL()
        local elements = document:select("li.wp-manga-chapter")
        local a = elements:size()
        for i=0, a-1 do
            local element = elements:get(i)
            local novelChapter = LuaSupport:getNovelChapter()
            novelChapter:setLink(element:selectFirst("a"):attr("href"))
            novelChapter:setTitle(element:selectFirst("a"):text())
            novelChapter:setRelease(element:selectFirst("i"):text())
            novelChapter:setOrder(a - i)
            novelChapters:add(novelChapter)
        end
        novelChapters = LuaSupport:reverseAL(novelChapters)
        novelPage:setNovelChapters(novelChapters)
    end

    return novelPage
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelPage @java object
function parseNovelI(document, increment)
    print("Lua: Passing novel")
    return parseNovel(document)
end

--- @param url string @url of novel page
--- @param increment number @which page
function novelPageCombiner(url, increment)
    return url
end

local function parseNovelList(doc, sel)
    local novels = LuaSupport:getNAL()
    local novelsHTML = doc:select(sel)
    for i = 0, novelsHTML:size() - 1, 1 do
        local novel = LuaSupport:getNovel()
        local data = novelsHTML:get(i):selectFirst("a")
        novel:setTitle(data:attr("title"))
        novel:setLink(data:attr("href"))
        novel:setImageURL(data:selectFirst("img"):attr("src"))
        novels:add(novel)
    end
    return novels
end

--- @param document Document @Jsoup document of latest listing
--- @return Array @Novel array list
function parseLatest(document)
    return parseNovelList(document, "div.col-xs-12.col-md-6")
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
function parseSearch(document)
    return parseNovelList(document, "div.c-tabs-item__content")
end

--- @param query string @query to use
--- @return string @url
function getSearchString(query)
    return baseURL .. "/?s=" .. query:gsub("%+", "%2"):gsub(" ", "+") .. "&post_type=wp-manga"
end

