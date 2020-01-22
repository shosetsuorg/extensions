-- {"id":258,"version":"0.1.0","author":"Doomsdayrs","repo":""}
---@author Doomsdayrs
---@version 0.1.0

local baseURL = "https://fastnovel.net/"

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

---@param el Elements
---@param f1 fun(element:Element):Elements|Array|table
---@param f2 fun(v:Element):table|Array
local function map2flat(el, f1, f2)
    local t = {}
    local i = 1
    for j = 1, el:size() do
        local o2 = f1(el:get(j - 1))
        if o2 then
            for k = 1, o2:size() do
                t[i] = f2(o2:get(k - 1))
                i = i + 1
            end
        end
    end
    return t
end

---@return boolean
function isIncrementingChapterList()
    return false
end

---@return boolean
function isIncrementingPassagePage()
    return false
end

---@return Ordering
function chapterOrder()
    return Ordering(0)
end

---@return Ordering
function latestOrder()
    return Ordering(1)
end

---@return boolean
function hasCloudFlare()
    return false
end

---@return boolean
function hasSearch()
    return true
end

---@return boolean
function hasGenres()
    return true
end

---@return Array|table @Array<Genre>
function genres()
    return {}
end

---@return number @ID
function getID()
    return 258
end

---@return string @name of site
function getName()
    return "FastNovel"
end

---@return string @image url of site
function getImageURL()
    return "https://fastnovel.net/skin/images/logo.png"
end

---@param page number @value
---@return string @url of said latest page
function getLatestURL(page)
    return "https://fastnovel.net/list/latest.html?page=" .. page
end

---@param document Document @Jsoup document of the page with chapter text on it
---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
function getNovelPassage(document)
    return table.concat(map(document:select("div.box-player"):select("p"), function(v)
        return v:text()
    end), "\n")
end

---@param document Document @Jsoup document of the novel information page
---@return NovelPage
function parseNovel(document)
    local novelPage = NovelPage()

    novelPage:setImageURL(document:selectFirst("div.book-cover"):attr("data-original"))
    novelPage:setTitle(document:selectFirst("h1.name"):text())
    novelPage:setDescription(table.concat(map(document:select("div.film-content"):select("p"), function(v)
        v:text()
    end), "\n"))

    local elements = document:selectFirst("ul.meta-data"):select("li")
    novelPage:setAuthors(map(elements:get(0):select("a"),
            function(v)
                return v:text()
            end))
    novelPage:setGenres(map(elements:get(1):select("a"), function(v)
        return v:text()
    end))

    novelPage:setStatus(NovelStatus(
            elements:get(2):selectFirst("strong"):text():match("Completed") and 1 or 0
    ))

    -- chapters
    local volumeName = ""
    local chapterIndex = 0
    local chapters = AsList(map2flat(document:select("div.list-chapter"),
            function(element)
                volumeName = element:selectFirst("div.title"):selectFirst("a.accordion-toggle"):text()
                return element:select("li")
            end
    , function(element)
                local chapter = NovelChapter()
                local data = element:selectFirst("a.class")
                chapter:setTitle(volumeName .. " " .. data:text())
                chapter:setLink(baseURL .. data:attr("href"))
                chapter:setOrder(chapterIndex)
                chapterIndex = chapterIndex + 1
                return chapter
            end))

    novelPage:setNovelChapters(chapters)
    return novelPage
end

---@param document Document @Jsoup document of the novel information page
---@param _ number @Page #
---@return NovelPage
function parseNovelI(document, _)
    return parseNovel(document)
end

---@param url string @url of novel page
---@param _ number @which page
function novelPageCombiner(url, _)
    return url
end

---@param document Document @Jsoup document of latest listing
---@return Array @Novel array list
function parseLatest(document)
    return AsList(map(document:select("ul.list-film"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setLink(baseURL .. data:attr("href"))
        novel:setTitle(data:attr("title"))
        novel:setImageURL(data:selectFirst("div.img"):attr("data-original"))
        return novel
    end))
end

---@param document Document @Jsoup document of search results
---@return Array @Novel array list
function parseSearch(document)
    return AsList(map(document:select("ul.list-film"), function(v)
        local novel = Novel()
        local data = v:selectFirst("a")
        novel:setLink(baseURL .. data:attr("href"))
        novel:setTitle(data:attr("title"))
        novel:setImageURL(data:selectFirst("div.img"):attr("data-original"))
        return novel
    end))
end

---@param query string @query to use
---@return string @url
function getSearchString(query)
    return baseURL .. "/search/" .. query:gsub(" ", "%20")
end

