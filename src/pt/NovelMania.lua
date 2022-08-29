-- {"id":250401,"ver":"1.0.0","libVer":"1.0.0","author":"Claudemirovsky","dep":["url>=1.0.0"]}

-- ============================= CONSTANTS ==============================
local id = 250401 -- from a good doujinshi by Ringoya/alp
local baseURL = "https://novelmania.com.br"
local name = "Novel Mania"

local qs = Require("url").querystring

local FILTER_GENRES_ID = 100
local FILTER_GENRES_KEYS = {
  "Todos",
  "Ação",
  "Adulto",
  "Artes Marciais",
  "Aventura",
  "Comédia",
  "Cotidiano",
  "Drama",
  "Ecchi",
  "Erótico",
  "Escolar",
  "Fantasia",
  "Harém",
  "Isekai",
  "Magia",
  "Mecha",
  "Medieval",
  "Militar",
  "Mistério",
  "Mitologia",
  "Psicológico",
  "Realidade Virtual",
  "Romance",
  "Sci-fi",
  "Sistema de Jogo",
  "Sobrenatural",
  "Suspense",
  "Terror",
  "Wuxia",
  "Xianxia",
  "Xuanhuan",
  "Yaoi",
  "Yuri"
}
local FILTER_GENRES_VALUES = {
  [0] = "", -- Todos
  01, -- Ação
  02, -- Adulto
  07, -- Artes Marciais
  03, -- Aventura
  04, -- Comédia
  16, -- Cotidiano
  23, -- Drama
  27, -- Ecchi
  22, -- Erótico
  13, -- Escolar
  05, -- Fantasia
  21, -- Harém
  30, -- Isekai
  26, -- Magia
  08, -- Mecha
  31, -- Medieval
  24, -- Militar
  09, -- Mistério
  10, -- Mitologia
  11, -- Psicológico
  36, -- Realidade Virtual
  12, -- Romance
  14, -- Sci-fi
  15, -- Sistema de Jogo
  17, -- Sobrenatural
  29, -- Suspense
  06, -- Terror
  18, -- Wuxia
  19, -- Xianxia
  20, -- Xuanhuan
  35, -- Yaoi
  37 -- Yuri
}

local FILTER_NATIONALITY_ID = 200
local FILTER_NATIONALITY_ITEMS = {
  "Todas",
  "Americana",
  "Angolana",
  "Brasileira",
  "Chinesa",
  "Coreana",
  "Japonesa"
}

local FILTER_STATUS_ID = 300
local FILTER_STATUS_ITEMS = { "Todos", "Ativo", "Completo", "Pausado", "Parado" }

local FILTER_ORDERBY_ID = 400
local FILTER_ORDERBY_ITEMS = {
  "Qualquer ordem",
  "Ordem alfabética",
  "Nº de Capítulos",
  "Popularidade",
  "Novidades",
}

-- ============================== PASSAGE ===============================
local function shrinkURL(url)
  return url:gsub("^.-novelmania%.com%.br", "")
end

local function expandURL(path)
  return baseURL .. path
end

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
  local document = GETDocument(expandURL(chapterURL))
  local htmlElement = document:selectFirst("div#chapter-content")
  -- remove unwanted elements
  htmlElement:select("h3, div"):remove()
  return pageOfElem(htmlElement, true)
end

-- =========================== NOVEL DETAILS ============================
---@param document Document
---@return NovelStatus
local function getStatus(document)
  local status = document:selectFirst("span.authors:contains(Status:)"):ownText()
  local status_table = {
    ["Ativo"] = 0,
    ["Completo"] = 1,
    ["Pausado"] = 2
  }
  return NovelStatus(status_table[status] or 3)
end

---@param document Document
---@return NovelChapter[]
local function getChapterList(document)
  local chapters = document:select("ol.list-inline a")
  local count = 1
  local chapterList = AsList(map(chapters, function(el)
    local chapter = NovelChapter {
      title = el:selectFirst("strong"):text(),
      link = shrinkURL(el:attr("href")),
      release = el:selectFirst("small"):text(),
      order = count
    }
    count = count + 1
    return chapter
  end))
  return chapterList
end

---@param element Element
---@return string
local function text(element)
  return element:text()
end

---@param novelURL string
---@return NovelInfo
local function parseNovel(novelURL)
  local doc = GETDocument(expandURL(novelURL))
  local info = doc:selectFirst("div.novel-info")
  local nvinfo = NovelInfo {
    title = info:selectFirst("div > h1"):text(),
    imageURL = doc:selectFirst("div.novel-img > img"):attr("src"),
    description = table.concat(map(doc:select("div.text > p"), text), "\n"),
    status = NovelStatus(getStatus(info)),
    authors = { info:selectFirst("span.authors:contains(Autor:)"):ownText() },
    chapters = getChapterList(doc),
    genres = map(doc:select("div.tags a"), text)
  }
  return nvinfo
end

-- ============================== FILTERS ===============================

---@param filters table
---@param order string
---@return string
local function createFilterUrl(filters, order)
  local query = { ["page"] = filters[PAGE] }
  if filters[QUERY] then
    query["titulo"] = filters[QUERY]
  end
  if order ~= "" then
    query["ordem"] = order
  end

  for key, value in pairs(filters) do
    if key > 0 and value > 0 then
      if key == FILTER_GENRES_ID then
        query["categoria"] = FILTER_GENRES_VALUES[value]
      elseif key == FILTER_NATIONALITY_ID then
        query["nacionalidade"] = FILTER_NATIONALITY_ITEMS[value + 1]:lower()
      elseif key == FILTER_STATUS_ID then
        query["status"] = FILTER_STATUS_ITEMS[value + 1]:lower()
      elseif key == FILTER_ORDERBY_ID then
        query["ordem"] = tostring(value - 1)
      end
    end
  end
  return qs(query, expandURL("/novels"))
end

-- ============================== LISTING ===============================
---@param element Document
---@return Novel
local function parseNovelFromElement(element)
  local imgElement = element:selectFirst("img")
  return Novel {
    title = imgElement:attr("alt"):gsub("Capa de ", ""),
    imageURL = imgElement:attr("src"),
    link = shrinkURL(element:attr("href"))
  }
end

---@param url string
---@return Novel[]
local function parseList(url)
  local document = GETDocument(url)
  local selector = "div.top-novels div.col-sm-12 > a:not(.novel)"
  return map(document:select(selector), parseNovelFromElement)
end

---@param listname string
---@param order string
---@return Listing
local function listing(listname, order)
  return Listing(listname, true, function(data)
    return parseList(createFilterUrl(data, order))
  end)
end

return {
  id = id,
  name = name,
  baseURL = baseURL,
  imageURL = expandURL("/assets/logo-blue-ccbd5d317242b0f0479edd2cad954fd235dbdfeb662bb338d987f8f57e3794a2.png"),
  listings = {
    listing("Populares", "2"),
    listing("Recentes", "3")
  },
  hasSearch = true,
  isSearchIncrementing = true,
  search = function(data)
    return parseList(createFilterUrl(data, ""))
  end,
  searchFilters = {
    DropdownFilter(FILTER_GENRES_ID, "Gênero", FILTER_GENRES_KEYS),
    DropdownFilter(FILTER_NATIONALITY_ID, "Nacionalidade", FILTER_NATIONALITY_ITEMS),
    DropdownFilter(FILTER_STATUS_ID, "Status", FILTER_STATUS_ITEMS),
    DropdownFilter(FILTER_ORDERBY_ID, "Ordenar por", FILTER_ORDERBY_ITEMS),
  },
  getPassage = getPassage,
  chapterType = ChapterType.HTML,
  parseNovel = parseNovel,
  expandURL = expandURL,
  shrinkURL = shrinkURL
}
