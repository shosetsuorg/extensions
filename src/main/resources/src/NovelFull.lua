-- {"id":1,"version":"1.2.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.2.0

local baseURL = "http://novelfull.com"
---@param o Elements
---@param f fun(v:Element):any
---@return table|Array
local function map(o, f)
    local t = {}
    for i = 1, o:size() do
        t[i] = f(o:get(i - 1))
    end
    return t
end

---@param o1 Elements
---@param f1 fun(element:Element):Elements|Array|table
---@param f2 fun(v:Element):table|Array
local function map2flat(o1, f1, f2)
    local t = {}
    local i = 1
    for j = 1, o1:size() do
        local o2 = f1(o1:get(j - 1))
        if o2 then
            for k = 1, o2:size() do
                t[i] = f2(o2:get(k - 1))
                i = i + 1
            end
        end
    end
    return t
end

---@param elements Elements
---@param novel Novel
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
    return Ordering(0)
end

--- @return Ordering
function latestOrder()
    return Ordering(0)
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

--- @return Array|table @Array<NovelGenre>
function genres()
    return {}
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
    return table.concat(map(document:select("div.chapter-c"):select("p"), function(v)
        return v:text()
    end), "\n")
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
    local novelPage = NovelPage()
    novelPage:setImageURL(baseURL .. document:selectFirst("div.book"):selectFirst("img"):attr("src"))

    -- max page
    local lastPageURL = document:selectFirst("ul.pagination.pagination-sm"):selectFirst("li.last"):select("a"):attr("href")
    novelPage:setMaxChapterPage(lastPageURL ~= ""
            and tonumber(lastPageURL:match("%?page=(%d+)&per%-page="))
            or increment)

    -- title, description
    local titleDesc = document:selectFirst("div.col-xs-12.col-sm-8.col-md-8.desc")
    novelPage:setTitle(titleDesc:selectFirst("h3"):text())
    novelPage:setDescription(table.concat(map(titleDesc:selectFirst("div.desc-text"):select("p"), function(v)
        v:text()
    end), "\n"))

    -- set information
    local elements = document:selectFirst("div.info"):select("div.info"):select("div")
    novelPage:setAuthors(map(elements:get(1):select("a"), function(v)
        return v:text()
    end))
    novelPage:setGenres(map(elements:get(2):select("a"), function(v)
        return v:text()
    end))
    novelPage:setStatus(NovelStatus(
            elements:get(4):select("a"):text() == "Completed" and 1 or 0
    ))

    -- formats chapters
    local a = (increment - 1) * 50
    local chapters = AsList(map2flat(document:select("ul.list-chapter"),
            function(v)
                return v:select("li")
            end, function(v)
                local chap = NovelChapter()
                local data = v:selectFirst("a")
                local link = data:attr("href")
                if link then
                    chap:setLink(baseURL .. link)
                end
                chap:setTitle(data:attr("title"))
                chap:setOrder(a)
                a = a - 1
                return chap
            end))

    novelPage:setNovelChapters(chapters)

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
    return AsList(map2flat(document:select("div.container"), function(v)
        if v:id() == "list-page" then
            return v:select("div.row")
        end
    end, function(v)
        return stripListing(v:select("div"), Novel())
    end))
end

--- @param document Document @Jsoup document of search results
--- @return Array @Novel array list
function parseSearch(document)
    return AsList(map2flat(document:select("div.container"), function(v)
        if v:id() == "list-page" then
            return v:select("div.row")
        end
    end, function(v)
        return stripListing(v:select("div"), Novel())
    end))
end

--- @param query string @query to use
--- @return string @url
function getSearchString(query)
    return baseURL .. "/search?keyword=" .. query:gsub(" ", "%20")
end