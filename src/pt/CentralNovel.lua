-- {"id":227675,"ver":"1.0.0","libVer":"1.0.0","author":"Claudemirovsky",deps=["url>=1.0.0"]}

-- ============================= CONSTANTS ==============================
local id = 227675 -- from a good doujinshi
local baseURL = "https://centralnovel.com"
local name = "Central Novel"

local qs = Require("url").querystring

local FILTER_TYPES_KEYS = {
  "Light Novel",
  "Novel Chinesa",
  "Novel Coreana",
  "Novel Japonesa",
  "Novel Ocidental",
  "Webnovel"
}
local FILTER_TYPES_VALUES = {
  "light-novel",
  "novel-chinesa",
  "novel-coreana",
  "novel-japonesa",
  "novel-ocidental",
  "webnovel"
}
local FILTER_TYPES_ID = 100

local FILTER_GENRES_KEYS = {
  "Ação",
  "Adulto",
  "Adventure",
  "Artes Marciais",
  "Aventura",
  "Comédia",
  "Comedy",
  "Cotidiano",
  "Cultivo",
  "Drama",
  "Ecchi",
  "Escolar",
  "Esportes",
  "Fantasia",
  "Ficção Científica",
  "Harém",
  "Isekai",
  "Magia",
  "Mecha",
  "Medieval",
  "Mistério",
  "Mitologia",
  "Monstros",
  "Pet",
  "Protagonista Feminina",
  "Protagonista Maligno",
  "Psicológico",
  "Reencarnação",
  "Romance",
  "Seinen",
  "Shounen",
  "Sistema",
  "Sistema de Jogo",
  "Slice of Life",
  "Sobrenatural",
  "Supernatural",
  "Tragédia",
  "Vida Escolar",
  "VRMMO",
  "Xianxia",
  "Xuanhuan"
}
local FILTER_GENRES_VALUES = {
  "acao",
  "adulto",
  "adventure",
  "artes-marciais",
  "aventura",
  "comedia",
  "comedy",
  "cotidiano",
  "cultivo",
  "drama",
  "ecchi",
  "escolar",
  "esportes",
  "fantasia",
  "ficcao-cientifica",
  "harem",
  "isekai",
  "magia",
  "mecha",
  "medieval",
  "misterio",
  "mitologia",
  "monstros",
  "pet",
  "protagonista-feminina",
  "protagonista-maligno",
  "psicologico",
  "reencarnacao",
  "romance",
  "seinen",
  "shounen",
  "sistema",
  "sistema-de-jogo",
  "slice-of-life",
  "sobrenatural",
  "supernatural",
  "tragedia",
  "vida-escolar",
  "vrmmo",
  "xianxia",
  "xuanhuan"
}
local FILTER_GENRES_ID = 200

local FILTER_STATUS_ID = 300
local FILTER_STATUS_KEYS = { "Todos", "Em andamento", "Hiato", "Completo" }
local FILTER_STATUS_VALUES = { [0] = "", "em andamento", "hiato", "completo" }

local FILTER_ORDERBY_ID = 400
local FILTER_ORDERBY_KEYS = {
  "Padrão",
  "A-Z",
  "Z-A",
  "Últ. Att",
  "Últ. Add",
  "Populares"
}
local FILTER_ORDERBY_VALUES = {
  [0] = "",
  "title",
  "titlereverse",
  "update",
  "latest",
  "popular"
}

-- ============================== PASSAGE ===============================
local function shrinkURL(url)
  return url:gsub("^.-centralnovel%.com", "")
end

local function expandURL(path)
  return baseURL .. path
end

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
  local document = GETDocument(expandURL(chapterURL))
  local title = document:selectFirst("div.epheader > div.cat-series"):text()
  local text = document:selectFirst("div.epcontent")
  -- Add chapter title
  text:child(0):before("<h1>" .. title .. "</h1>")
  return pageOfElem(text, true)
end

-- =========================== NOVEL DETAILS ============================
---@param document Document
---@return NovelStatus
local function getStatus(document)
  local status = document:selectFirst("div.spe > span:contains(Status:)"):ownText()
  local status_table = {
    ["Em andamento"] = 0,
    ["Completo"] = 1,
    ["Hiato"] = 2
  }
  return NovelStatus(status_table[status] or 3)
end

---@param document Document
---@return NovelChapter[]
local function getChapterList(document)
  local chapters = document:select("div.eplister li > a")
  local count = chapters:size()
  local chapterList = AsList(map(chapters, function(el)
    local num = el:selectFirst("div.epl-num"):text()
    local chapter = NovelChapter {
      title = num .. " " .. el:selectFirst("div.epl-title"):text(),
      link = shrinkURL(el:attr("href")),
      order = count
    }
    count = count - 1
    return chapter
  end))
  Reverse(chapterList)
  return chapterList
end

---@param novelURL string
---@return NovelInfo
local function parseNovel(novelURL)
  local document = GETDocument(expandURL(novelURL))
  local img = document:selectFirst("div.thumb > img")
  local info = document:selectFirst("div.ninfo > div.info-content")
  local nvinfo = NovelInfo {
    title = img:attr("title"),
    imageURL = img:attr("src"),
    description = document:selectFirst("div.entry-content"):text(),
    status = NovelStatus(getStatus(info)),
    chapters = getChapterList(document),
    genres = map(info:select("div.genxed > a"), function(v) return v:text() end)
  }
  return nvinfo
end

-- ============================== FILTERS ===============================
---@param items table
---@param id int
---@return table
local function checkboxList(items, id)
  local result = {}
  for num, key in ipairs(items) do
    table.insert(result, CheckboxFilter(num + id, key))
  end
  return result
end

---@param filters table
---@param order string
---@return string
local function createFilterUrl(filters, order)
  local query = { ["page"] = filters[PAGE] }
  local genres = {}
  local types = {}
  if filters[QUERY] then
    query["s"] = filters[QUERY]
  end
  if order ~= "" then
    query["order"] = order
  end
  for key, value in pairs(filters) do
    if key > 0 and value ~= 0 and value then
      if key == FILTER_ORDERBY_ID then
        query["order"] = FILTER_ORDERBY_VALUES[value]
      elseif key == FILTER_STATUS_ID then
        query["status"] = FILTER_STATUS_VALUES[value]
      elseif key > FILTER_GENRES_ID then
        local index = key - FILTER_GENRES_ID
        table.insert(genres, FILTER_GENRES_VALUES[index])
      elseif key > FILTER_TYPES_ID then
        local index = key - FILTER_TYPES_ID
        table.insert(types, FILTER_TYPES_VALUES[index])
      end
    end
  end
  if #genres > 0 then
    query["genre[]"] = genres
  end
  if #types > 0 then
    query["type[]"] = types
  end
  return qs(query, expandURL("/series/"))
end

-- ============================== LISTING ===============================
---@param element Document
---@return Novel
local function parseNovelFromElement(element)
  local imgElement = element:selectFirst("img")
  return Novel {
    title = imgElement:attr("title"),
    imageURL = imgElement:attr("src"):gsub("e=%d+,%d+", "e=370,500"),
    link = shrinkURL(element:attr("href"))
  }
end

---@param url string
---@return Novel[]
local function parseList(url)
  local document = GETDocument(url)
  return map(document:select("div.listupd a.tip"), parseNovelFromElement)
end

---@param listname string
---@param path string
---@return Listing
local function listing(listname, path)
  return Listing(listname, true, function(data)
    local newUrl = createFilterUrl(data, path)
    return parseList(newUrl)
  end)
end

return {
  id = id,
  name = name,
  baseURL = baseURL,
  imageURL = expandURL("/wp-content/uploads/2021/06/CENTRAL-NOVEL-LOGO-DARK-.png"),
  listings = {
    listing("Populares", "popular"),
    listing("Recentes", "update")
  },
  hasSearch = true,
  isSearchIncrementing = true,
  search = function(data)
    return parseList(createFilterUrl(data, ""))
  end,
  searchFilters = {
    DropdownFilter(FILTER_ORDERBY_ID, "Ordenar por", FILTER_ORDERBY_KEYS),
    DropdownFilter(FILTER_STATUS_ID, "Status", FILTER_STATUS_KEYS),
    FilterGroup("Tipo", checkboxList(FILTER_TYPES_KEYS, FILTER_TYPES_ID)),
    FilterGroup("Gêneros", checkboxList(FILTER_GENRES_KEYS, FILTER_GENRES_ID))
  },
  getPassage = getPassage,
  chapterType = ChapterType.HTML,
  parseNovel = parseNovel,
  expandURL = expandURL,
  shrinkURL = shrinkURL
}
