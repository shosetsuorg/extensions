-- {"version":"1.0.1","author":"TechnoJo4","dep":["dkjson"]}

return function(id, name, base, contentSel, image)
    local settings

    local infos = {}
    local novels = {}
    local api = base.."/api"
    local POST = Require("dkjson").POST
    local data

    local function getNovels()
        if not data or not data.result then data = POST(api.."/novels/search", {count=1000}) end
        if not data.result then return end

        infos = {}
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
        id = id,
        name = name,
        baseURL = base,
        imageURL = image,
        listings = {
            Listing("All Novels", false, function()
                getNovels();
                return novels
            end)
        },
        getPassage = function(url)
            return table.concat(map(GETDocument(base..url):selectFirst(contentSel):children(),
                    function(v)
                        return v:is(".chapter-nav") and "" or v:text()
                    end), "\n")
        end,
        parseNovel = function(slug, loadChapters)
            getNovels()
            local info =  infos[slug]
            if loadChapters then
                local i = 1
                info:setChapters(AsList(map2flat(GETDocument(base.."/novel/"..slug):select("#accordion .panel"),
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
        search = function(s)
            getNovels()
            local q = s[0]:lower()
            return filter(AsList(novels), function(v)
                local i = v:getTitle():lower():find(q)
                return i ~= nil
            end)
        end,
        setSettings = function(s) settings = s end,
        updateSetting = function() end
    }
end
