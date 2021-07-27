-- {"id":3302,"ver":"1.0.0","libVer":"1.0.0","author":"Ali Mohamed"}

local baseURL = "https://rewayat.club"
local baseUrlApi = "https://api.rewayat.club"


---@type dkjson
local json = Require("dkjson")

local function flatten(arr)
    local results = {}
    -- define recursive local function for flattening
    local function arrFlatten(arr)
        for i, v in ipairs(arr) do
            if type(v) == "table" then
                arrFlatten(v)
            else
                results[#results+1] = v
            end
        end
    end
    -- call this functions
    arrFlatten(arr)
    return results
end

return {
    id = 3302,
    name = "RewayatClub - نادي الروايات",
    baseURL = baseURL,
    hasSearch = true,
    listings = {
        Listing("Novel List",true,function (data)
			local res = Request(GET(baseURL .. "/api/novels/?page=" .. data[PAGE]+1)):body():string()

            local d = json.decode(res)

            return map(d.results,function(v) 
                    return Novel {
                        title = v.english,
                        imageURL = baseUrlApi .. "/".. v.poster_url,
                        link = baseURL .. "/novel/" .. v.slug
                    }
                end)
            end)
            ,Listing("Latest",true,function (data)
			    local res = Request(GET(baseURL .. "/api/chapters/weekly/list/?page=" .. data[PAGE]+1)):body():string()

                local d = json.decode(res)
    
                return map(d.results ,function (v)
                        return Novel {
                            title = v.novel.english,
                            imageURL = baseUrlApi .. "/" .. v.novel.poster_url,
                            link = baseURL .. "/novel/" .. v.novel.slug
                        }    
                    end)
                end)
    },
    parseNovel = function (novelURL)
        local url1 = novelURL:gsub("/novel/","/api/novels/")
        local res = Request(GET(url1)):body():string()

        local d = json.decode(res)

        
        local novelInfo = NovelInfo()
        novelInfo:setTitle(d.english)
        novelInfo:setImageURL(baseUrlApi .. d.poster_url)
        novelInfo:setDescription(d.english)

        local status = d.get_novel_status
        novelInfo:setStatus(NovelStatus(status == "مكتملة" and 1 or status == "متوقفة" and 2 or status == "مستمرة" and 0 or 3))
        novelInfo:setGenres(map(d.genre,function (v)
            return v.english
        end))

        local url2 = novelURL:gsub("/novel/","/api/chapters/") .. "/all"
		local res2 = Request(GET(url2)):body():string()

        local chaptersJson = json.decode(res2)

        local chapterList = AsList(map(chaptersJson,function (v)
            local c = NovelChapter()
            c:setLink(novelURL.."/" .. v.number)
            c:setTitle(v.title)
            c:setOrder(v.number)
            return c
        end))
        novelInfo:setChapters(chapterList)
        
        return novelInfo
        
    end,
    getPassage = function (chapterURL)
        local url = chapterURL:gsub("/novel/","/api/chapters/")
		local res = Request(GET(url)):body():string()
        local resJson = json.decode(res)

        return table.concat(map(resJson.content,function (v) 
                return table.concat(map(v,function (c) 
                    local temp = c:gsub("<br/>","<b/r/>")
                        return Document(temp):text()
                    end),"\n")
            end),"\n"):gsub("\n\n","\n")
      
    end,
    search = function(data) 
		local res2 = Request(GET(baseURL .. "/api/novels/search/all/?search=" .. data[QUERY] .. "&page=" .. data[PAGE]+1)):body():string()
        local d = json.decode(res2)
        return map(d.results,function (v)
                
            return Novel {
                title =  v.english,
                imageURL = baseUrlApi .. v.poster_url,
                link = baseURL .. "/novel/" .. v.slug
            }
        end)
    end,

}