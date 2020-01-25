-- {"id":-999,"version":"0.0.0","author":"TechnoJo4","repo":""}
---@author TechnoJo4
-- ! ! ! ! !  DO NOT RUN AS AN EXTENSION  ! ! ! ! !
-- ! THIS FILE CONTAINS EmmyLua CLASS DEFINITIONS !
-- ! ! ! ! !  DO NOT RUN AS AN EXTENSION  ! ! ! ! !

---@alias int number

-- base java/kotlin
do
    ---@class Array
    local Array = {}

    ---@param index int
    ---@return any
    function Array:get(index) return end

    ---@param index int
    ---@param value any
    ---@return
    function Array:set(index, value) return end

    ---@class ArrayList : Array
    local ArrayList = {}

    ---@param value any
    ---@return void
    function ArrayList:add(value) return end

    ---@return void
    function ArrayList:reverse() return end

    ---@return int
    function ArrayList:size() return end
end

-- jsoup
do
    ---@class Document : Element
    local Document

    ---@class Element : Node
    local Element = {}

    ---@class Elements : ArrayList
    local Elements = {}

    ---@param query string
    ---@return Elements
    function Element:select(query) return end

    ---@param query string
    ---@return Element
    function Element:selectFirst(query) return end

    ---@return string
    function Element:text() return end

    ---@return string
    function Element:id() return end

    ---@return number
    function Elements:size() return end

    ---@param index number
    ---@return Element
    function Elements:get(index) return end

    ---@param attributeKey string
    ---@return string
    function Elements:attr(attributeKey) return end

    ---@param query string
    ---@return Elements
    function Elements:select(query) return end

    ---@param query string
    ---@return Elements
    function Elements:selectFirst(query) return end

    ---@return string
    function Elements:text() return end

    ---@class Node
    local Node

    ---@param attributeKey string
    ---@return string
    function Node:attr(attributeKey) return end
end

-- everything else
do
    ---@class NovelStatus
    local NovelStatus
    ---@class Ordering
    local Ordering

    ---@class Novel
    local Novel = {}

    ---@param title string
    ---@return void
    function Novel:setTitle(title) return end

    ---@param link string
    ---@return void
    function Novel:setLink(link) return end

    ---@param imageURL string
    ---@return void
    function Novel:setImageURL(imageURL) return end

    ---@class NovelChapter
    local NovelChapter = {}

    ---@param release string
    ---@return void
    function NovelChapter:setRelease(release) return end

    ---@param title string
    ---@return void
    function NovelChapter:setTitle(title) return end

    ---@param link string
    ---@return void
    function NovelChapter:setLink(link) return end

    ---@param order number
    ---@return void
    function NovelChapter:setOrder(order) return end

    ---@class NovelPage
    local NovelPage = {}

    ---@param title string
    ---@return void
    function NovelPage:setTitle(title) return end

    ---@param imageURL string|any
    ---@return void
    function NovelPage:setImageURL(imageURL) return end

    ---@param description string
    ---@return void
    function NovelPage:setDescription(description) return end

    ---@param genres Array | table
    ---@return void
    function NovelPage:setGenres(genres) return end

    ---@param authors Array | table
    ---@return void
    function NovelPage:setAuthors(authors) return end

    ---@param status "LuaSupport:getStatus(3)" | NovelStatus
    ---@return void
    function NovelPage:setStatus(status) return end

    ---@param tags Array | table
    ---@return void
    function NovelPage:setTags(tags) return end

    ---@param artists Array | table
    ---@return void
    function NovelPage:setArtists(artists) return end

    ---@param language string
    ---@return void
    function NovelPage:setLanguage(language) return end

    ---@param chapters ArrayList
    ---@return void
    function NovelPage:setNovelChapters(chapters) return end
end

-- ShosetsuLib
do
    -- OTHER

    ---@param name string @Name of library to load
    ---@return any
    function Require(name) return end


    -- EXTENSION METHODS

    --- Maps values of an ArrayList or Elements to a table
    ---@see ArrayList
    ---@param o ArrayList | Elements @Target
    ---@param f fun(v: any): any
    ---@return table
    function map(o, f) end

    --- Maps values of an ArrayList or Elements to another ArrayList or Elements, and then to a table (using two functions).
    --- Effectively flattens an array, which gives the function its name.
    ---@see ArrayList
    ---@see Elements
    ---@param o ArrayList | Elements @Target
    ---@param f1 fun(v: any): void | nil | ArrayList | Elements
    ---@param f2 fun(v: any): any
    ---@return table
    function map2flat(o, f1, f2) end

    --- Returns the first element of the ArrayList or Elements whose output from the function is true.
    ---@see ArrayList
    ---@param o ArrayList | Elements
    ---@param f fun(v: any): boolean
    ---@return any
    function first(o, f) end


    -- ArrayList CONSTRUCTORS

    ---@return ArrayList
    function List() return end

    ---@param arr Array | table
    ---@return ArrayList
    function AsList(arr) return end

    ---@param arr ArrayList
    ---@return void
    function Reverse(arr) return end


    -- CONSTRUCTORS

    ---@return Novel
    function Novel() return end

    ---@return NovelPage
    function NovelPage() return end

    ---@return NovelChapter
    function NovelChapter() return end

    ---@param type int
    ---@return NovelStatus
    function NovelStatus(type) return end

    ---@param type int
    ---@return Ordering
    function Ordering(type) return end
end

