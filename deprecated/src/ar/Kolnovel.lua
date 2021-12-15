-- {"id":3301,"ver":"1.0.1","libVer":"1.0.0","author":"Ali Mohamed"}
local baseURL = "https://kolnovel.com"

local function shrinkURL(url)
    return url:gsub(baseURL, "")
end

local function expandURL(url)
    return baseURL .. url
end

return {
    id = 3301,
    name = "Kolnovel - ملوك الروايات",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Kolnovel.png",
    hasSearch = true,
    listings = {
        Listing("Novel List", true, function(data)
            local d = GETDocument(baseURL .. "/series/?page=" .. data[PAGE])

            return map(d:select(" div.listupd  article"), function(v)

                return Novel {
                    title = v:selectFirst("span.ntitle"):text(),
                    imageURL = v:selectFirst("img"):attr("src"),
                    link = shrinkURL(v:selectFirst("a"):attr("href"))
                }
            end)
        end),
        Listing("Latest", true, function(data)
            local d = GETDocument(baseURL .. "/page/" .. data[PAGE] .. "/")

            return map(d:select("div.latesthome~div.listupd div.uta"), function(v)
                return Novel {
                    title = v:select("h3"):text(),
                    imageURL = v:select("img"):attr("src"),
                    link = shrinkURL(v:select("div.luf  a.series"):attr("href"))
                }
            end)
        end)},
    parseNovel = function(novelURL, loadChapters)
        local document = GETDocument(expandURL(novelURL)):selectFirst("article")
        local novelInfo = NovelInfo()
        novelInfo:setTitle(document:select("h1"):text())
        novelInfo:setImageURL(document:select("div.bigcover img"):attr("src"))
        novelInfo:setDescription(table.concat(map(document:select("div.entry-content"), function(v)
            return v:text()
        end), "\n"))

        local sta = document:selectFirst("div.info-content span:nth-child(1)"):text()
        local t = sta:gsub("الحالة: ", "")
        novelInfo:setStatus(NovelStatus(t == "Completed" and 1 or t == "Hiatus" and 2 or t == "Ongoing" and 0 or 3))

        novelInfo:setAuthors(map(document:select("div.info-content span:nth-child(3) a"), function(v)
            return v:text()
        end))

        novelInfo:setGenres(map(document:select("div.genxed a"), function(v)
            return v:text()
        end))

        if loadChapters then
            local listOfChapters = document:select("div.bixbox.bxcl.epcheck  div  ul  a")
            local count = listOfChapters:size()
            local chapterList = AsList(map(listOfChapters, function(v)
                local c = NovelChapter()
                c:setLink(shrinkURL(v:attr("href")))
                c:setTitle(v:select("div.epl-title"):text())
                c:setOrder(count)
                count = count - 1
                return c
            end))
            Reverse(chapterList)
            novelInfo:setChapters(chapterList)
        end
        return novelInfo

    end,
    getPassage = function(chapterURL)
        local d = GETDocument(expandURL(chapterURL))
        return table.concat(map(d:select("article p"), function(v)
            return v:text()
        end), "\n")
    end,
    search = function(data)
        local d = GETDocument(baseURL .. "/page/" .. data[PAGE] .. "/?s=" .. data[QUERY])
        return map(d:select("div.listupd > article"), function(v)
            return Novel {
                title = v:selectFirst(" span.ntitle"):text(),
                imageURL = v:selectFirst("img"):attr("src"),
                link = shrinkURL(v:selectFirst(" a"):attr("href"))
            }
        end)
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL

}
