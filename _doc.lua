-- {"id":-999,"version":"0.0.0","author":"TechnoJo4","repo":""}
---@author TechnoJo4

-- ! ! ! ! !  DO NOT RUN AS AN EXTENSION  ! ! ! ! !
-- ! THIS FILE CONTAINS EmmyLua CLASS DEFINITIONS !
-- ! ! ! ! !  DO NOT RUN AS AN EXTENSION  ! ! ! ! !

-- Please, do NOT auto-format this file.

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
    local Document = {}

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

    ---@return Elements
    function Element:children() return end

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
    local Node = {}

    ---@param attributeKey string
    ---@return string
    function Node:attr(attributeKey) return end
end

-- okhttp
do
    -- You shouldn't use methods of these classes manually in extension code unless you know what you're doing anyways,
    -- So I didn't bother making documentation for them. Refer to the existing kotlin okhttp documentation.

    ---@class Request
    local Request = {}
    ---@class Headers
    local Headers = {}
    ---@class RequestBody
    local RequestBody = {}
    ---@class CacheControl
    local CacheControl = {}
    ---@class MediaType
    local MediaType = {}

    do
        ---@class RequestBuilder
        local RequestBuilder = {}
        ---@return Request
        function RequestBuilder:build() return end

        ---@param url string
        ---@return RequestBuilder
        function RequestBuilder:url(url) return end

        ---@param name string
        ---@param value string
        ---@return RequestBuilder
        function RequestBuilder:addHeader(name, value) return end

        ---@param body string
        ---@return RequestBuilder
        function RequestBuilder:post(body) return end

        ---@param headers Headers
        ---@return RequestBuilder
        function RequestBuilder:headers(headers) return end

        ---@param cacheControl CacheControl
        ---@return RequestBuilder
        function RequestBuilder:cacheControl(cacheControl) return end

        ---@return RequestBuilder
        function RequestBuilder:get() return end
    end

    do
        ---@class HeadersBuilder
        local HeadersBuilder = {}
        ---@return Headers
        function HeadersBuilder:build() return end

        ---@param name string
        ---@return string
        function HeadersBuilder:get(name) return end

        ---@param name string
        ---@param value string
        ---@return HeadersBuilder
        function HeadersBuilder:add(name, value) return end

        ---@param name string
        ---@param value string
        ---@return HeadersBuilder
        function HeadersBuilder:set(name, value) return end
    end

    do
        ---@class FormBodyBuilder
        local FormBodyBuilder = {}
        ---@return RequestBody
        function FormBodyBuilder:build() return end

        ---@param name string
        ---@param value string
        ---@return FormBodyBuilder
        function FormBodyBuilder:add(name, value) return end
    end

    do
        ---@class Response
        local Response = {}
        ---@return ResponseBody
        function Response:getBody() return end

        ---@class ResponseBody
        local ResponseBody = {}
        ---@return string
        function ResponseBody:string() return end
    end
end

-- dkjson
do
    ---@class dkjson
    local dkjson = {}

    ---@return string
    ---@param tbl table
    function dkjson.encode(tbl) return end

    ---@return table
    ---@param str string @JSON string
    function dkjson.decode(str) return end

    ---@param url string
    ---@return string | table @Response
    function dkjson.GET(url, ...) return end

    ---@param url string
    ---@param body string | table
    ---@return string | table @Response
    function dkjson.POST(url, body, ...) return end
end

-- Filter things
do
    ---@class Filter
    local Filter = {}

    ---@class TextFilter
    local TextFilter = {}

    ---@class SwitchFilter
    local SwitchFilter = {}

    ---@class RadioGroupFilter
    local RadioGroupFilter = {}

    ---@class DropdownFilter
    local DropdownFilter = {}

    ---@class FilterGroup
    local FilterGroup = {}

    ---@class
    local GenreGroup = {}

    ---@class
    local GenreCheckBoxFilter = {}

end

-- Formatter things
do
    ---@class Listing
    local Listing = {}
end

-- Novel Stuff
do
    ---@class NovelStatus
    local NovelStatus = {}

    ---@class Novel @Novel.Listing
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

    ---@class NovelInfo
    local NovelInfo = {}

    ---@param title string
    ---@return void
    function NovelInfo:setTitle(title) return end

    ---@param titles Array | table
    ---@return void
    function NovelInfo:setAlternativeTitles(titles) return end

    ---@param imageURL string|any
    ---@return void
    function NovelInfo:setImageURL(imageURL) return end

    ---@param description string
    ---@return void
    function NovelInfo:setDescription(description) return end

    ---@param genres Array | table
    ---@return void
    function NovelInfo:setGenres(genres) return end

    ---@param authors Array | table
    ---@return void
    function NovelInfo:setAuthors(authors) return end

    ---@param status "NovelStatus(3)" | NovelStatus
    ---@return void
    function NovelInfo:setStatus(status) return end

    ---@param tags Array | table
    ---@return void
    function NovelInfo:setTags(tags) return end

    ---@param artists Array | table
    ---@return void
    function NovelInfo:setArtists(artists) return end

    ---@param language string
    ---@return void
    function NovelInfo:setLanguage(language) return end

    ---@param chapters ArrayList
    ---@return void
    function NovelInfo:setChapters(chapters) return end
end

-- ShosetsuLib
do
    -- OTHER
    ---@param name string
    ---@return any
    function Require(name) return end

    ---@type int @Index of search query in search data
    _G.QUERY = 0

    ---@type int @Index of search page in search data
    _G.PAGE = 1

    ---@type int @Used in shrinkURL and expandURL
    _G.KEY_NOVEL_URL = 1

    ---@type int @Used in shrinkURL and expandURL
    _G.KEY_CHAPTER_URL = 2

    -- EXTENSION METHODS
    do
        --- Map and Filter combined.
        ---@see ArrayList
        ---@param o ArrayList | Elements @Target
        ---@param f fun(v: any|Element): any
        ---@return table
        function mapNotNil(o, f) return end

        --- Filters an array.
        ---@see ArrayList
        ---@param o ArrayList | Elements @Target
        ---@param f fun(v: any|Element): any
        ---@return table
        function filter(o, f) return end

        --- Maps values of an ArrayList or Elements to a table
        ---@see ArrayList
        ---@param o ArrayList | Elements @Target
        ---@param f fun(v: any|Element): any
        ---@return table
        function map(o, f) return end

        --- Maps values of an ArrayList or Elements to another ArrayList or Elements, and then to a table (using two functions).
        --- Effectively flattens an array, which gives the function its name.
        ---@see ArrayList
        ---@see Elements
        ---@param o ArrayList | Elements @Target
        ---@param f1 fun(v: any): void | nil | ArrayList | Elements
        ---@param f2 fun(v: any): any
        ---@return table
        function map2flat(o, f1, f2) return end

        --- Returns the first element of the ArrayList or Elements whose output from the function is true.
        ---@see ArrayList
        ---@param o ArrayList | Elements
        ---@param f fun(v: any): boolean
        ---@return any
        function first(o, f) return end

        --- Wraps a function by creating a new one that prepends a specified argument then calls the underlying function.
        --- A wrapper function W(...), for a given underlying function F and object O, is equivalent to F(O, ...).
        ---@param o any @Prepended argument
        ---@param f function @Function to wrap
        ---@return function @Wrapper
        function wrap(o, f) return end
    end

    -- ArrayList
    do
        ---@return ArrayList
        function List() return end

        ---@param arr Array | table
        ---@return ArrayList
        function AsList(arr) return end

        ---@param arr ArrayList
        ---@return void
        function Reverse(arr) return end
    end

    -- OKHTTP3
    do
        ---@param url string
        ---@param headers Headers
        ---@param cacheControl CacheControl
        ---@return Request
        function GET(url, headers, cacheControl) return end

        ---@param url string
        ---@param headers Headers
        ---@param body RequestBody
        ---@param cacheControl CacheControl
        ---@return Request
        function POST(url, headers, body, cacheControl) return end

        ---@return RequestBuilder
        function RequestBuilder() return end
        ---@return HeadersBuilder
        function HeadersBuilder() return end
        ---@return FormBodyBuilder
        function FormBodyBuilder() return end
        ---@return CacheControl
        function DefaultCacheControl() return end

        ---@return CacheControl
        function DEFAULT_CACHE_CONTROL() return end
        ---@return Headers
        function DEFAULT_HEADERS() return end
        ---@return RequestBody
        function DEFAULT_BODY() return end

        --- Executes a request.
        ---@param req Request
        ---@return Response
        function Request(req) return end

        --- Obtains a document from an HTML string.
        ---@param str string
        ---@return Document
        function Document(str) return end

        --- Obtains a document from a Request.
        ---@param req Request
        ---@return Document
        function RequestDocument(req) return end

        --- Obtains a document from a url, using a GET request.
        ---@param url string
        ---@return Document
        function GETDocument(url) return end

        ---@param str string
        ---@return MediaType
        function MediaType(str) return end

        ---@param data string
        ---@param type MediaType
        ---@return RequestBody
        function RequestBody(data, type) return end
    end

    -- CONSTRUCTORS
    do
        ---@param name string
        ---@param increments boolean
        ---@param func fun(): Novel[] | fun(data: table, inc: int): Novel[]
        ---@return Listing
        function Listing(name, increments, func) return end

        ---@return Novel
        function Novel() return end

        ---@return NovelInfo
        function NovelInfo() return end

        ---@return NovelChapter
        function NovelChapter() return end

        ---@param type int
        ---@return NovelStatus
        function NovelStatus(type) return end

        -- FILTERS

        ---@param name string
        ---return TextFilter
        function TextFilter(id, name) return end

        ---@param name string
        ---return SwitchFilter
        function SwitchFilter(id, name) return end

        ---@param name string
        ---return CheckBoxFilter
        function CheckboxFilter(id, name) return end

        ---@param name string
        ---return TriStateFilter
        function TriStateFilter(id, name) return end

        ---@param name string
        ---@param choices string[] | Array | table
        ---return RadioGroupFilter
        function RadioGroupFilter(id, name, choices) return end

        ---@param name string
        ---@param choices string[] | Array | table
        ---return DropdownFilter
        function DropdownFilter(id, name, choices) return end

        ---@param name string
        ---@param choices Filter[] | Array
        ---return FilterGroup
        function FilterGroup(name, choices) return end

        ---@param name string
        ---@param filters Filter[] | Array
        function FilterList(name, filters) return end
    end
end
