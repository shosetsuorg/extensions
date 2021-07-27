-- {"id":3301,"ver":"1.0.0","libVer":"1.0.0","author":"Ali Mohamed"}
local baseURL = "https://kolnovel.com"

return {
    id = 3301,
    name = "Kolnovel - ملوك الروايات",
    baseURL = baseURL,
    imageURL = "https://kolnovel.com/wp-content/uploads/2021/01/PicsArt_10-21-02.01.20.png",
    hasSearch = true,
    listings = {
        Listing("Novel List", true, function(data)
            local d = GETDocument(baseURL .. "/series/?page=" .. data[PAGE])

            return map(d:select("#content > div > div.postbody > div > div.mrgn > div.listupd > article"), function(v)

                return Novel {
                    title = v:selectFirst(" div > a > div.tt > span.ntitle"):text(),
                    imageURL = v:selectFirst("div > a > div.limit > img"):attr("src"),
                    link = v:selectFirst(" div > a"):attr("href")
                }
            end)
        end),
        Listing("Latest", true, function(data)
            local d = GETDocument(baseURL .. "/page/" .. data[PAGE] .. "/")

            return map(d:select("#content  div  div.postbody  div  div.latesthome~div.listupd  div.excstf  div.utao  div.uta"), function(v)
                return Novel {
                    title = v:select(" div.luf  a  h3"):text(),
                    imageURL = v:select("div.imgu  a  img"):attr("src"),
                    link = v:select(" div.luf  a.series"):attr("href")
                }
            end)
        end)
    },
    parseNovel = function(novelURL)
        local document = GETDocument(novelURL):selectFirst("#content > div > div.postbody article")
        local novelInfo = NovelInfo()
        novelInfo:setTitle(document:select("div.bixbox.animefull > div.bigcontent > div.infox > h1"):text())
        novelInfo:setImageURL(document:select("div.bixbox.animefull > div.bigcover > div > img"):attr("src"))
        novelInfo:setDescription(table.concat(map(document:select("div.bixbox.synp > div.entry-content p"), function(v)
            return v:text()
        end), "\n"))

        local sta = document:selectFirst("div.bixbox.animefull > div.bigcontent > div.infox > div > div.info-content > div.spe > span:nth-child(1)"):text()
        -- local t = string.sub(sta,8,sta:size)
        local t = sta:gsub("الحالة: ", "")
        -- local t = sta
        novelInfo:setStatus(NovelStatus(t == "Completed" and 1 or t == "Hiatus" and 2 or t == "Ongoing" and 0 or 3))

        novelInfo:setAuthors(map(document:select(
            "div.bixbox.animefull > div.bigcontent > div.infox > div > div.info-content > div.spe > span:nth-child(3)  a"),
            function(v)
                return v:text()
            end))

        novelInfo:setGenres(map(document:select(
            "div.bixbox.animefull > div.bigcontent > div.infox > div > div.info-content > div.genxed a"), function(v)
            return v:text()
        end))

        local listOfChapters = document:select("div.bixbox.bxcl.epcheck  div  ul  a")

        local count = listOfChapters:size()

        local chapterList = AsList(map(listOfChapters, function(v)
            local c = NovelChapter()
            c:setLink(v:attr("href"))
            c:setTitle(v:select("div.epl-title"):text())
            c:setOrder(count)
            count = count - 1
            return c
        end))
        Reverse(chapterList)
        novelInfo:setChapters(chapterList)

        return novelInfo

    end,
    getPassage = function(chapterURL)
        local d = GETDocument(chapterURL)
        return table.concat(map(d:select("article div.bixbox.episodedl > div  div.epcontent.entry-content  p"),function(v)
                return v:text()
            end), "\n")
    end,
    search = function(data)
        local d = GETDocument(baseURL .. "/page/" .. data[PAGE] .. "/?s=" .. data[QUERY])
        return map(d:select("#content > div > div.postbody > div > div.listupd > article"), function(v)
            return Novel {
                title = v:selectFirst(" div > a > div.tt > span.ntitle"):text(),
                imageURL = v:selectFirst("div > a > div.limit > img"):attr("src"),
                link = v:selectFirst(" div > a"):attr("href")
            }
        end)
    end,

    shrinkURL = function(url)
        return url:gsub(baseURL, "")
    end,

    expandURL = function(url)
        return baseURL .. url
    end

}
