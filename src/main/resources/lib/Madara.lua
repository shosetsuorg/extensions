-- {"version":"1.2.0","author":"TechnoJo4","dep":["url"]}

local encode=Require("url").encode

local text=function(v)
	return v:text()
end

local genres_map={}
local settings={}

--- Default values for a madara script
local defaults={
	latestNovelSel="div.col-12.col-md-6",
	searchNovelSel="div.c-tabs-item__content",
	novelListingURLPath="novel",
	novelPageTitleSel="h3",
	shrinkURLNovel="novel",
	hasCloudFlare=false,
	hasSearch=true
}

local ORDER_BY_FILTER_KEY=1
local ORDER_BY_FILTER_EXT={ "Relevance","Latest","A-Z","Rating","Trending","Most Views","New" }

local AUTHOR_FILTER_KEY=2
local ARTIST_FILTER_KEY=3
local RELEASE_FILTER_KEY=4
local STATUS_FILTER_KEY_COMPLETED=5
local STATUS_FILTER_KEY_ONGOING=6
local STATUS_FILTER_KEY_CANCELED=7
local STATUS_FILTER_KEY_ON_HOLD=8

function defaults:encode(string)
	return encode(string)
end

---@param page int @increment
function defaults:latest(data,page)
	return self.parse(GETDocument(self.baseURL .. "/" .. self.novelListingURLPath .. "/page/" .. page .. "/?m_orderby=latest"))
end

--- @param table table
------@return string
function defaults:createSearchString(table)
	local query=table[QUERY]
	local orderBy=table[ORDER_BY_FILTER_KEY]
	local author=table[AUTHOR_FILTER_KEY]
	local artist=table[ARTIST_FILTER_KEY]
	local release=table[RELEASE_FILTER_KEY]

	local url=self.baseURL .. "/?s=" .. encode(query) .. "&post_type=wp-manga" ..
			"&author=" .. encode(author) ..
			"&artist=" .. encode(artist) ..
			"&release=" .. encode(release)

	if orderBy ~= nil then
		url=url .. "&m_orderby=" .. ({
			[0]="relevance",
			[1]="latest",
			[2]="alphabet",
			[3]="rating",
			[4]="trending",
			[5]="views",
			[6]="new-manga"
		})[orderBy]
	end
	if table[STATUS_FILTER_KEY_COMPLETED] then
		url=url .. "&status[]=end"
	end
	if table[STATUS_FILTER_KEY_ONGOING] then
		url=url .. "&status[]=on-going"
	end
	if table[STATUS_FILTER_KEY_CANCELED] then
		url=url .. "&status[]=canceled"
	end
	if table[STATUS_FILTER_KEY_ON_HOLD] then
		url=url .. "&status[]=on-hold"
	end
	for key,value in pairs(genres_map) do
		if table[key] then
			url=url .. "&genre[]=" .. value
		end
	end
	url=self.appendToSearchURL(url,table)
	return url
end

---@param string string
---@param table table
---@return string
function defaults:appendToSearchURL(string,table)
	return string
end

---@param table table
---@return table
function defaults:appendToSearchFilters(table)
	return table
end

function defaults:search(data)
	local url=self.createSearchString(data)
	return self.parse(GETDocument(url),true)
end

---@param url string
---@return string
function defaults:getPassage(url)
	return table.concat(map(GETDocument(url):select("div.text-left p"),text),"\n")
end

---@param url string
---@param loadChapters boolean
---@return NovelInfo
function defaults:parseNovel(url,loadChapters)
	local doc=GETDocument(url)
	local info=NovelInfo()
	info:setImageURL(doc:selectFirst("div.summary_image"):selectFirst("img.img-responsive"):attr("src"))
	info:setTitle(doc:selectFirst(self.novelPageTitleSel):text())
	info:setDescription(doc:selectFirst("p"):text())

	-- Info
	local elements=doc:selectFirst("div.post-content"):select("div.post-content_item")

	-- authors
	info:setAuthors(map(elements:get(3):select("a"),text))
	-- artists
	info:setArtists(map(elements:get(4):select("a"),text))
	-- genres
	info:setGenres(map(elements:get(5):select("a"),text))

	-- sorry for this extremely long line
	info:setStatus(NovelStatus((
			doc:selectFirst("div.post-status"):select("div.post-content_item"):get(1)
			   :select("div.summary-content"):text() == "OnGoing") and 0 or 1))

	-- Chapters
	if loadChapters then
		local e=doc:select("li.wp-manga-chapter")
		local a=e:size()
		local l=AsList(map(e,function(v)
			local c=NovelChapter()
			c:setLink(self.shrinkURL(v:selectFirst("a"):attr("href")))
			c:setTitle(v:selectFirst("a"):text())

			local i=v:selectFirst("i")
			c:setRelease(i and i:text() or v:selectFirst("img[alt]"):attr("alt"))
			c:setOrder(a)
			a=a - 1
			return c
		end))
		Reverse(l)
		info:setChapters(l)
	end

	return info
end

---@param doc Document
---@param search boolean
function defaults:parse(doc,search)
	return map(doc:select(search and self.searchNovelSel or self.latestNovelSel),function(v)
		local novel=Novel()
		local data=v:selectFirst("a")
		novel:setLink(self.shrinkURL(data:attr("href")))
		local tit=data:attr("title")
		if tit == "" then
			tit=data:text()
		end
		novel:setTitle(tit)
		local e=data:selectFirst("img")
		if e then
			novel:setImageURL(e:attr("src"))
		end
		return novel
	end)
end

function defaults:expandURL(url)
	return self.baseURL .. "/" .. self.shrinkURLNovel .. "/" .. url
end

function defaults:shrinkURL(url)
	return url:gsub(self.baseURL .. "/" .. self.shrinkURLNovel .. "/","")
end

return function(baseURL,_self)
	_self=setmetatable(_self or {},{ __index=function(_,k)
		local d=defaults[k]
		return (type(d) == "function" and wrap(_self,d) or d)
	end })
	local keyID=100;
	local filters={
		DropdownFilter(ORDER_BY_FILTER_KEY,"Order by",ORDER_BY_FILTER_EXT),
		TextFilter(AUTHOR_FILTER_KEY,"Author"),
		TextFilter(ARTIST_FILTER_KEY,"Artist"),
		TextFilter(RELEASE_FILTER_KEY,"Year of Release"),
		FilterGroup("Status",{
			CheckboxFilter(STATUS_FILTER_KEY_COMPLETED,"Completed"),
			CheckboxFilter(STATUS_FILTER_KEY_ONGOING,"Ongoing"),
			CheckboxFilter(STATUS_FILTER_KEY_CANCELED,"Canceled"),
			CheckboxFilter(STATUS_FILTER_KEY_ON_HOLD,"On Hold")
		}),
		FilterGroup("Genres",map(_self.genres,function(v,_)
			genres_map[keyID]=v:getName():lower():match("(%a+)")
			keyID=keyID + 1
			return CheckboxFilter(keyID,v)
		end)) -- 6
	}
	filters=_self.appendToSearchFilters(filters)
	_self["searchFilters"]=filters
	_self["baseURL"]=baseURL
	_self["listings"]={
		Listing("default",true,_self.latest)
	}
	_self["updateSetting"]=function(id,value)
		settings[id]=value
	end
	return _self
end
