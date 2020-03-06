-- {"id":1273,"version":"1.0.0","author":"TechnoJo4","repo":""}

local settings

local novels
local infos = {}
local api = "https://www.wuxiaworld.com/api"
local base = "https://www.wuxiaworld.com"
local POST = Require("dkjson").POST

local function getNovels()
    if novels then return end
    local data = POST(api.."/novels/search", {count=1000})
    if not data.result then return end

    novels = {}
    for _, v in pairs(data.items) do
        local novel = Novel()
        novel:setLink(v.slug)
        novel:setTitle(v.name)
        novel:setImageURL(v.coverUrl)
        novels[#novels+1] = novel

        local info = NovelInfo()
        info:setTitle(v.name)
        info:setImageURL(v.coverUrl)
        info:setDescription("Description:\n"..(v.description or "None").."\n\nSynopsis:"..(v.synopsis or "None").."\n") -- TODO: CLEAN HTML
        info:setAuthors({ v.authorName })
        info:setTags(v.tags)
        info:setGenres(v.genres)
        info:setLanguage(v.language)
        info:setStatus(NovelStatus(({0,3})[v.status]))
        infos[v.slug] = info
    end
end

return {
    id = 1273,

    name = "WuxiaWorld",
    baseURL = base,
    imageURL = "https://www.wuxiaworld.com/apple-touch-icon.png",
    hasCloudFlare = false,
    hasSearch = true,
    listings = {
        Listing("All Novels", false, function()
            getNovels(); return novels
        end)
    },

    getPassage = function(url)
        return table.concat(map(GETDocument(base..url):selectFirst("#chapter-content"):children(),
                function(v)
                    return v:is(".chapter-nav") and "" or v:text()
                end), "\n")
    end,
    parseNovel = function(id, loadChapters)
        getNovels()
        local info =  infos[id]
        if loadChapters then
            local i = 1
            info:setChapters(AsList(map2flat(GETDocument(base.."/novel/"..id):select("#accordion .panel"),
                    function(v)
                        return v:select("li.chapter-item a")
                    end, function(v)
                        local c = NovelChapter()
                        c:setLink(v:attr("href"))
                        c:setTitle(v:text())
                        c:setOrder(i)
                        i = i + 1
                        return c
                    end)))
        end
        return info
    end,
    search = function(data)
        getNovels()
        local q = data.query:lower()
        return filter(AsList(novels), function(v)
            local i = v:getTitle():lower():find(q)
            return i ~= nil
        end)
    end,
    setSettings = function(s) settings = s end
}
