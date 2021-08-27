-- {"id":3302,"ver":"1.0.1","libVer":"1.0.0","author":"Ali Mohamed"}

local baseURL = "https://rewayat.club"
local baseUrlApi = "https://api.rewayat.club"

---@type dkjson
local json = Require("dkjson")
local qs = Require("url").querystring

return {
    id = 3302,
    name = "RewayatClub - نادي الروايات",
    baseURL = baseURL,
    hasSearch = true,
    chapterType = ChapterType.HTML,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/RewayatClub.png",
    listings = {
        Listing("Novel List", true, function(data)
            local d = json.GET(baseURL .. "/api/novels/?page=" .. data[PAGE] + 1)

            return map(d.results, function(v)
                return Novel {
                    link = v.slug,
                    title = v.english,
                    imageURL = baseUrlApi .. "/" .. v.poster_url,
                }
            end)
        end),

        Listing("Latest", true, function(data)
            local d = json.GET(baseURL .. "/api/chapters/weekly/list/?page=" .. data[PAGE] + 1)

            return map(d.results, function(v)
                return Novel {
                    link = v.novel.slug,
                    title = v.novel.english,
                    imageURL = baseUrlApi .. "/" .. v.novel.poster_url,
                }
            end)
        end)
    },

    parseNovel = function(novelURL, loadChapters)
        local d = json.GET(baseURL.."/api/novels/"..novelURL)

        local status = d.get_novel_status

        local novelInfo = NovelInfo {
            title = d.english,
            description = d.english,
            imageURL = baseUrlApi .. d.poster_url,
            genres = map(d.genre, function(v) return v.english end),
            status = NovelStatus(
                    status == "مكتملة" and 1 or
                    status == "متوقفة" and 2 or
                    status == "مستمرة" and 0 or 3)
        }

        if loadChapters then
            local chaptersJson = json.GET(baseURL.."/api/chapters/"..novelURL.."/all")
            novelInfo:setChapters(AsList(map(chaptersJson, function(v)
                return NovelChapter {
                    link = novelURL .. "/" .. v.number,
                    title = v.title,
                    order = v.number
                }
            end)))
        end

        return novelInfo
    end,

    getPassage = function(chapterURL)
        local resJson = json.GET(baseURL.."/api/chapters/"..chapterURL)
        return pageOfElem(Document(table.concat(flatten(resJson.content))))
    end,

    search = function(data)
        local d = json.GET(qs({
            search = data[QUERY],
            page = data[PAGE] + 1
        }, baseURL .. "/api/novels/search/all/"))

        return map(d.results, function(v)
            return Novel {
                title = v.english,
                imageURL = baseUrlApi .. v.poster_url,
                link = v.slug
            }
        end)
    end,

    shrinkURL = function(url)
        return url:gsub("^.-rewayat%.club/?", "")
    end,
    expandURL = function(url)
        return baseURL .. "/novel/" .. url
    end
}
