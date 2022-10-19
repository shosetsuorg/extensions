-- {"id":1781,"ver":"1.0.1","libVer":"1.0.0","author":"Xanvial"}
local qs = Require("url").querystring

local defaults = {
	hot = "/list/hot-novel",
	latest = "/list/latest-release-novel",
	completed = "/list/completed-novel",

	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML
}

--- Get string from Element
--- @param v Element
--- @return string
local text = function(v)
	return v:text()
end

--- Concatenate two tables into one
--- @param t1 table
--- @param t2 table
--- @return table
local function tableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end

function defaults:getPassage(url)
	local doc = GETDocument(self.expandURL(url))
	local title = doc:selectFirst("div.chapter-title"):text()
	local htmlElement = doc:selectFirst("div.chapter-content")

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:removeAttr("style") -- Hopefully only temporary as a hotfix
	htmlElement:select("script"):remove()
	htmlElement:select("ins"):remove()
	htmlElement:select("div.ads"):remove()
	htmlElement:select("div[align=\"left\"]:last-child"):remove() -- Report error text

	-- Chapter title inserted before chapter text.
	htmlElement:child(0):before("<h1>" .. title .. "</h1>");

	local toRemove = {}
	htmlElement:traverse(NodeVisitor(function(v)
		-- exclude element with styles (footer messages), TODO: allow to customize this
		if v:hasAttr("style") and v:attr("style"):match("0.8em") then
			toRemove[#toRemove+1] = v
		end
	end, nil, true))
	for _,v in pairs(toRemove) do
		v:remove()
	end

	return pageOfElem(htmlElement)
end

function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.expandURL(url))
	local info = NovelInfo()
	info:setTitle(doc:selectFirst("h1.title"):text())

	local elem = doc:selectFirst(".info"):children()
	local function meta_links(i)
		return map(elem:get(i):select("a"), text)
	end

	info:setAuthors(meta_links(0))
	info:setGenres( meta_links(1) )
	info:setStatus( ({
		Ongoing = NovelStatus.PUBLISHING,
		Completed = NovelStatus.COMPLETED
	})[elem:get(3):selectFirst("span"):text()] )

	info:setImageURL(doc:selectFirst("div.book img"):attr("src"))

	local desc = ""
	local descParent = doc:selectFirst("div.desc-text")
	-- check if element <p> exist
	local descP = descParent:select("p")
	if descP:size() > 0 then
		-- if exist, use it as description
		desc = table.concat(map(descP, text), "\n")
	else
		-- otherwise use the parent text
		desc = descParent:text()
	end
	info:setDescription(desc:gsub("<br>", "\n"))

	if loadChapters then
		local i = 0
		local nextSize = 0
		local curPage = 1
		local chapterTable = {}

		-- loop each chapter list pages
		repeat
			local curDocs = GETDocument(qs({ page = curPage }, self.expandURL(url))):selectFirst("div#list-chapter")
			local pagination = curDocs:select(".pagination")
			if (pagination ~= nil and pagination:size() > 0) then
				local paginationList = pagination:get(0):select("li") --
				nextSize = paginationList:get(paginationList:size()-1):select("a"):size()
				curPage = curPage + 1
			end
			chapterTable = tableConcat(chapterTable, map(
					curDocs:selectFirst(".list-chapter"):select("li a"),
					function(v)
						local chap = NovelChapter()
						chap:setLink(self.shrinkURL(v:attr("href")))
						chap:setTitle(v:text())
						chap:setOrder(i)
						i = i + 1
						return chap
					end))
		until (nextSize == 0)
		info:setChapters(AsList(chapterTable))
	end

	return info
end

---@param url string
function defaults:shrinkURL(url)
	return url:gsub(self.baseURL, "")
end

---@param url string
function defaults:expandURL(url)
	return self.baseURL .. url
end

function defaults:parseList(url)
	return map(GETDocument(url):selectFirst(".list-cat2"):select("div.item"), function(v)
		local novel = Novel()
		local data = v:selectFirst("a")
		novel:setImageURL(data:selectFirst("img"):attr("src"))
		novel:setTitle(data:selectFirst("div.title"):selectFirst("h3"):text())
		novel:setLink(self.shrinkURL(data:attr("href")))
		return novel
	end)
end

--https://novelnb.com/search?q=sample&page=1
--- @return Novel[]
function defaults:search(data)
	return self.parseList(qs({ q = data[QUERY], page = data[PAGE] }, self.baseURL .. "/search"))
end

--https://novelnb.com/list/hot-novel?page=1
--- @return Novel[]
function defaults:hotList(data)
	return self.parseList(self.baseURL .. self.hot .. "?page="  .. data[PAGE])
end

--https://novelnb.com/list/latest-release-novel?page=1
--- @return Novel[]
function defaults:latestList(data)
	return self.parseList(self.baseURL .. self.latest .. "?page="  .. data[PAGE])
end

--https://novelnb.com/list/completed-novel?page=1
--- @return Novel[]
function defaults:completedList(data)
	return self.parseList(self.baseURL .. self.completed .. "?page="  .. data[PAGE])
end

---@param baseURL string
local function novelData(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })
	_self["baseURL"] = baseURL
	if not _self["base"] then
		_self["base"] = baseURL
	end
	_self["listings"] = {
		Listing("Hot", true, _self.hotList),
		Listing("Latest", true, _self.latestList),
		Listing("Completed", true, _self.completedList),
	}
	return _self
end

return novelData("https://novelnb.com", {
	id = 1781,
	name = "Novel Nb",
	imageURL = "https://novelnb.com/assets/css/img/logo.png",
})
