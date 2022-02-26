-- {"id":420,"ver":"1.1.0","libVer":"1.0.0","author":"Dunbock","dep":["dkjson>=1.0.1"]}

local baseURL = "https://octopii.co"

local json = Require("dkjson")

local MTYPE = MediaType("application/json")
 
local function shrinkURL(url)
	return url:gsub(".-octopii%.co", "")
end

local function expandURL(url)
	return baseURL .. url
end

local text = function(v) return v:text() end

local function parseTop(doc)
	return map(doc:selectFirst("main div.row.mt-4"):select("div.col-12.col-sm-6"), function(v)
		local e = v:selectFirst("div.novel-info > a")
		return Novel {
			title = e:selectFirst("h4"):text(),
			link = shrinkURL(e:attr("href")),
			imageURL = v:selectFirst("img"):attr("src")
		}
	end)
end

return {
	id = 420,
	name = "Octopii",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Octopii.png",
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Top Novels", true, function(data)
			return parseTop(GETDocument(expandURL("/latest-release?page=" .. data[PAGE])))
		end)
	},

	getPassage = function(chapterURL)
		local htmlElement = GETDocument(expandURL(chapterURL)):selectFirst("div.content")

        -- Change header from h5 to something bigger.
        htmlElement:traverse(NodeVisitor(function(v)
            if v:tagName() == "h5" then
                v:tagName("h1")
            end
        end, nil, true))

		-- Remove/modify unwanted HTML elements to get a clean webpage.
		--htmlElement:select("div.example"):remove()

		return pageOfElem(htmlElement, true)
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(expandURL(novelURL))

		local main = doc:selectFirst("main > div > div")
		local info_wrapper = main:selectFirst("div.col-12.col-lg-9 > div")
		local details = info_wrapper:selectFirst("div.col-12.col-sm-9")

		local info = NovelInfo {
			title = details:selectFirst("h3"):text(),
			imageURL = expandURL(info_wrapper:selectFirst("img"):attr("src")),
			description = info_wrapper:selectFirst("div#novel-desc"):attr("data-desc"),
			genres = map(details:selectFirst("div.genre-container"):select("div.genre-el > a"), text),
			authors = map(details:selectFirst("div.author-container"):select("div.author-el > a"), text),
		}

		if loadChapters then
			local chapter_list = main:selectFirst("div#chapter-list-content")
			local curOrder = 0

			info:setChapters(
				AsList(
					map(chapter_list:select("div > div > a"), function(v)
						curOrder = curOrder + 1
						return NovelChapter {
							order = curOrder,
							title = v:text(),
							link = shrinkURL(v:attr("href")),
						}
					end)
				)
			)
		end

		return info
	end,

	hasSearch = true,
	isSearchIncrementing = false,
	search = function(data)
        -- Create JSON body for POST request.
		local requestJson = json.encode({
			clicked = false,
			limit = "200", -- increased limit to limit to a single request
			page = 0, -- therefore, only request first page
			pageCount = 1,
			value = data[QUERY],
			sort = 4,
			selected = {
				genre = {},
				status = {},
				sort = {},
				author = {}
			},
			results = {},
			label = "searching ....",
		})

        local body = RequestBody(requestJson, MTYPE)
        local post = RequestDocument(POST("https://octopii.co/api/advance-search", nil, body)):toString()

        -- Cut HTML body from the actual JSON answer and decode it.
        post = post:sub(33, -18)
        local decodedJson = json.decode(post)

        -- Get novels from the JSON.
        local novels = {}
        for _, n in ipairs(decodedJson.results) do
            novels[#novels + 1] = Novel {
                title = n.novel_name,
                link = "/novel/" .. n.novel_slug,
                imageURL = expandURL(n.image)
            }
        end

		return novels
	end,
}
