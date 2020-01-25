-- {"id":-1,"version":"9.9.9","author":"","repo":""}
---@author Doomsdayrs
---@version 1.0.0

local baseURL = "TODO"

---@param elements Elements
---@param f fun(v:Element):any
---@return table|Array
local function map(elements, f)
    local t = {}
    for i = 1, elements:size() do
        t[i] = f(elements:get(i - 1))
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
    -- TODO Complete
    return false
end

---@return boolean
function isIncrementingPassagePage()
    -- TODO Complete
    return false
end

---@return Ordering
function chapterOrder()
    -- TODO Complete
    return Ordering(0)
end

---@return Ordering
function latestOrder()
    -- TODO Complete
    return Ordering(0)
end

---@return boolean
function hasCloudFlare()
    -- TODO Complete
    return false
end

---@return boolean
function hasSearch()
    -- TODO Complete
    return true
end

---@return boolean
function hasGenres()
    -- TODO Complete
    return true
end

---@return Array @Array<Genre>
function genres()
    -- TODO Complete
    return {}
end

---@return number @ID
function getID()
    -- TODO If the site doesn't provide their own IDs, then use random number generator. between 10 and 10000, Make sure the number hasn't already been used
    return -1
end

---@return string @name of site
function getName()
    -- TODO Complete
    return ""
end

---@return string @image url of site
function getImageURL()
    -- TODO Complete
    return ""
end

---@param page number @value
---@return string @url of said latest page
function getLatestURL(page)
    -- TODO Complete
    return ""
end

---@param document Document @Jsoup document of the page with chapter text on it
---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
function getNovelPassage(document)
    -- TODO Complete
    return ""
end

---@param document Document @Jsoup document of the novel information page
---@return NovelPage
function parseNovel(document)
    local novelPage = NovelPage()
    -- TODO Complete
    return novelPage
end

---@param document Document @Jsoup document of the novel information page
---@param increment number @Page #
---@return NovelPage
function parseNovelI(document, increment)
    local novelPage = NovelPage()
    -- TODO Complete
    return novelPage
end

---@param url string @url of novel page
---@param increment number @which page
function novelPageCombiner(url, increment)
    -- TODO Complete
    return ""
end

---@param document Document @Jsoup document of latest listing
---@return Array @Novel array list
function parseLatest(document)
    -- TODO Complete
    return {}
end

---@param document Document @Jsoup document of search results
---@return Array @Novel array list
function parseSearch(document)
    -- TODO Complete
    return {}
end

---@param query string @query to use
---@return string @url
function getSearchString(query)
    -- TODO Complete
    return ""
end

