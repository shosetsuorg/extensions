-- {"id":1,"version":"1.1.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.1.0

local luajava = require("luajava")

--local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "http://novelfull.com"

local function isempty(s)
    return s == '' or not s
end

function stripListing(elements, novel)
    local col = elements:get(0)
    local image = col:selectFirst("img")
    if image then
        novel:setImageURL(baseURL .. image:attr("src"))
    end

    local header = col:selectFirst("h3")
    if header then
        local titleLink = header:selectFirst("a")
        novel:setTitle(titleLink:attr("title"))
        novel:setLink(baseURL .. titleLink:attr("href"))
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
    return true
end

--- @return Array @Array<NovelGenre>
function genres()
    -- TODO Complete
    return LuaSupport:getGAL()
end

--- @return number @ID
function getID()
    return 1
end

--- @return string @name of site
function getName()
    return "NovelFull"
end

--- @return string @image url of site
function getImageURL()
    return ""
end

--- @param page number @value
--- @return string @url of said latest page
function getLatestURL(page)
    print(baseURL, page)
    return baseURL .. "/latest-release-novel?page=" .. page
end

--- @param document Document @Jsoup document of the page with chapter text on it
--- @return string @passage of chapter, If nothing can be parsed, then the text should be describing of why there isn't a chapter
function getNovelPassage(document)
    local paragraphs = document:select("div.chapter-c"):select("p")
    local t = {}
    for i=1, paragraphs:size(), 1 do
        t[i] = paragraphs:get(i-1):text()
    end
    return table.concat(t, "\n")
end

--- @param document Document @Jsoup document of the novel information page
--- @return NovelPage
function parseNovel(document)
    return parseNovelI(document, 1)
end

--- @param document Document @Jsoup document of the novel information page
--- @param increment number @Page #
--- @return NovelPage
function parseNovelI(document, increment)
    local novelPage = LuaSupport:getNovelPage()
    novelPage:setImageURL(baseURL .. document:selectFirst("div.book"):selectFirst("img"):attr("src"))
    
    -- max page
    do
        local lastPageURL = document:selectFirst("ul.pagination.pagination-sm"):selectFirst("li.last"):select("a"):attr("href")
        print("Lua: LastPageURL ", lastPageURL)
        novelPage:setMaxChapterPage(lastPageURL ~= ""
                and tonumber(lastPageURL:match("?page=(.+)&per-page="))
                or increment)
    end

    -- description
    do
        local titleDescription = document:selectFirst("div.col-xs-12.col-sm-8.col-md-8.desc")
        novelPage:setTitle(titleDescription:selectFirst("h3"):text())
        local desc = titleDescription:selectFirst("div.desc-text"):select("p")
        
        local t = {}
        for i=1, desc:size() do
            t[i] = desc:get(i-1):text()
        end
        novelPage:setDescription(table.concat(t, "\n"))
    end

    -- set information
    do
        local elements = document:selectFirst("div.info"):select("div.info"):select("div")
        do
            local authorE = elements:get(1):select("a")
            local authors = LuaSupport:getStringArray()
            authors:setSize(authorE:size())
            for i = 0, authorE:size() - 1, 1 do
                authors:setPosition(i, authorE:get(i):text())
            end
            novelPage:setAuthors(authors:getStrings())
        end
        do
            local genreE = elements:get(2):select("a")
            local genres = LuaSupport:getStringArray()
            genres:setSize(genreE:size())
            for i = 0, genreE:size() - 1, 1 do
                genres:setPosition(i, genreE:get(i):text())
            end
            novelPage:setGenres(genres:getStrings())
        end

        novelPage:setStatus(LuaSupport:getStatus(
            elements:get(4):select("a"):text() == "Completed" and 1 or 0
        ))
    end

    -- formats chapters
    do
        local novelChapters = LuaSupport:getCAL()
        local lists = document:select("ul.list-chapter")
        local a = (increment > 1) and (increment - 1) * 50 or 0

        for i = 0, lists:size() - 1, 1 do
            local chapters = lists:get(i):select("li")
            for y = 0, chapters:size() - 1, 1 do
                local novelChapter = LuaSupport:getNovelChapter()
                local chapterData = chapters:get(y):selectFirst("a")
                local link = chapterData:attr("href")
                if link then
                    novelChapter:setLink(baseURL .. link)
                end
                novelChapter:setTitle(chapterData:attr("title"))
                novelChapter:setOrder(a)
                a = a + 1
                novelChapters:add(novelChapter)
            end
        end
        novelPage:setNovelChapters(novelChapters)
    end

    return novelPage
end

--- @param url string @url of novel page
--- @param increment number @which page
function novelPageCombiner(url, increment)
    return (increment > 1 and (url .. "?page=" .. increment) or url)
end

--- @param document Document @Jsoup document of latest listing
--- @return Array @Novel array list
function parseLatest(document)
    local novels = LuaSupport:getNAL()
    local listP = document:select("div.container")
    for i = 0, listP:size() - 1, 1 do
        local list = listP:get(i)
        if list:id() == "list-page" then
            local queries = list:select("div.row")
            for j = 0, queries:size() - 1, 1 do
                novels:add(stripListing(queries:get(j):select("div"), LuaSupport:getNovel()))
            end
        end
    end
    return novels
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
function parseSearch(document)
    local novels = LuaSupport:getNAL()
    local listP = document:select("div.container")
    for i = 0, listP:size() - 1, 1 do
        local list = listP:get(i)
        if list:id() == "list-page" then
            local queries = list:select("div.row")
            for x = 0, queries:size() - 1, 1 do
                novels:add(stripListing(queries:get(x):select("div"), LuaSupport:getNovel()))
            end
        end
    end
    return novels
end

--- @param query string @query to use
--- @return string @url
function getSearchString(query)
    return baseURL .. "/search?keyword=" .. query:gsub(" ", "%20")
end

