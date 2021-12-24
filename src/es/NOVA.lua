-- {"id":28505740,"ver":"1.1.0","libVer":"1.0.0","author":"Khonkhortisan","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://novelasligeras.net" --WordPress site, plugins: WooCommerce, Yoast SEO, js_composer, user_verificat_front, avatar-privacy

local ORDER_BY_FILTER_EXT = {"Ordenar por los últimos", "Orden alfabético", "Relevancia", "Ordenar por popularidad", "Ordenar por calificación media", "Ordenar por precio: bajo a alto", "Orden aleatorio", "Ordenar por id", "Ordenar por slug", "Ordenar por include"} 	--translate to identificación/babosa/incluír?
local ORDER_BY_FILTER_INT = {
	[0] = "date", --Ordenar por los últimos
	"title"     , --Orden alfabético/Orden por defecto (Listing is title, webview search is title-DESC, selecting Orden por defecto is menu_order)
	"relevance" , --Relevancia (webview search is title-DESC when it should be relevance)
	"popularity", --Ordenar por popularidad
	"rating"    , --Ordenar por calificación media
	"price"     , --Ordenar por precio: bajo a alto
	"rand"      , --single-seed random order
	"id"        , --id/slug/include are supported by WooCommerce, but not currently shown in the extension
	"slug"      , --id is different from slug
	"include"   , --is what? https://woocommerce.github.io/woocommerce-rest-api-docs/#list-all-products
	--only some of these can be descending
}
local ORDER_BY_FILTER_KEY = 789
local ORDER_FILTER_KEY = 1010

--can this be multi-select? https://stackoverflow.com/a/27898435 https://developer.wordpress.org/reference/classes/wp_query/
--https://novelasligeras.net/index.php/lista-de-novela-ligera-novela-web/?ixwpst[product_cat][0]=52&ixwpst[product_cat][1]=49&ixwpst[product_cat][2]=-45
--currently in OR mode, not AND https://wordpress.org/support/topic/multiple-categories-per-filter-results/ https://prnt.sc/tl9zt9 https://prnt.sc/t9wsoy
local CATEGORIAS_FILTER_INT = {
	[0] = "", --Cualquier Categoría
	40, --Acción
	53, --Adulto
	52, --Artes Marciales
	41, --Aventura
	59, --Ciencia Ficción
	43, --Comedia
	68, --Deportes
	44, --Drama
	45, --Ecchi
	46, --Fantasía
	47, --Gender Bender
	48, --Harem
	49, --Histórico
	50, --Horror
	54, --Mechas (Robots Gigantes)
	55, --Misterio
	56, --Psicológico
	66, --Recuentos de la Vida
	57, --Romance
	60, --Seinen
	62, --Shojo
	63, --Shojo Ai
	64, --Shonen
	69, --Sobrenatural
	70, --Tragedia
	58, --Vida Escolar
	73, --Xuanhuan
}
local CATEGORIAS_FILTER_KEY = 4242

local ESTADO_FILTER_INT = {
	[0] = "", --Cualquiera --NovelStatus.UNKNOWN
	 16,     --En Proceso --NovelStatus.PUBLISHING
	 17,     --Pausado    --            On Hold/haitus
	407,    --Completado --NovelStatus.COMPLETED
}
local ESTADO_FILTER_KEY = 407

local TIPO_FILTER_INT = {
	[0] = "", --Cualquier
	23, --Novela Ligera
	24, --Novela Web
}
local TIPO_FILTER_KEY = 2324

local PAIS_FILTER_INT = {
	[0] = "", --Cualquiera
	1865, --Argentina
	1749, --Chile
	  20, --China
	4184, --Colombia
	  22, --Corea
	1792, --Ecuador
	  21, --Japón
	1704, --México
	1657, --Nicaragua
	4341, --Perú
	2524, --Venezuela
}
local PAIS_FILTER_KEY = 2121
local TAG_FILTER_KEY = 2222
local searchHasOperId = 2323

local ADBLOCK_SETTING_KEY = 0
local SUBSCRIBEBLOCK_SETTING_KEY = 1
local settings = {
--	[ADBLOCK_SETTING_KEY] = false,
--	[SUBSCRIBEBLOCK_SETTING_KEY] = false,
}

local qs = Require("url").querystring

local css = Require("CommonCSS").table

local encode = Require("url").encode
local text = function(v)
	return v:text()
end
--This function was copied directly from lib/Madara.lua
---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
local function img_src(image_element)
	-- Different extensions have the image(s) saved in different attributes. Not even uniformly for one extension.
	-- Partially this comes down to script loading the pictures. Therefore, scour for a picture in the default HTML page.

	-- Check data-srcset:
	local srcset = image_element:attr("data-srcset")
	if srcset ~= "" then
		-- Get the largest image.
		local max_size, max_url = 0, ""
		for url, size in srcset:gmatch("(http.-) (%d+)w") do
			if tonumber(size) > max_size then
				max_size = tonumber(size)
				max_url = url
			end
		end
		return max_url
	end

	-- Check data-src:
	srcset = image_element:attr("data-src")
	if srcset ~= "" then
		return srcset
	end

	-- Default to src (the most likely place to be loaded via script):
	return image_element:attr("src")
end

local function shrinkURL(url)
	return url:gsub("^.-novelasligeras%.net/?", "")
end
local function expandURL(url)
	return baseURL .. (url:sub(1, 1) == "/" and "" or "/") .. url
end

local function createFilterString(data)
	--ixwpst[product_cat] is fine being a sparse array, so no need to count up from 0
	
	local orderby = ORDER_BY_FILTER_INT[data[ORDER_BY_FILTER_KEY]]
	if data[ORDER_FILTER_KEY] then
		orderby =orderby.. "-desc"
	end
	
	local function MultiQuery(strings, start, len)
		local arr = {}
		for i=start+1,start+len do
			if data[i] then
				arr[#arr+1] = strings[i]
			end
		end
		return arr
	end
	
	return qs({
		orderby = orderby,
		ixwpst = {
			product_cat = MultiQuery(CATEGORIAS_FILTER_INT, CATEGORIAS_FILTER_KEY, #CATEGORIAS_FILTER_INT),
			pa_estado = MultiQuery(ESTADO_FILTER_INT, ESTADO_FILTER_KEY, #ESTADO_FILTER_INT),
			pa_tipo = TIPO_FILTER_INT[data[TIPO_FILTER_KEY]],
			pa_pais = MultiQuery(PAIS_FILTER_INT, PAIS_FILTER_KEY, #PAIS_FILTER_INT),
			op = data[searchHasOperId],
		},
		product_tag = product_tag,
	})
	--https://novelasligeras.net/?product_tag[0]=guerras&product_tag[1]=Asesinatos
	--other than orderby, filters in url must not be empty
	--Logic is (cat1 OR cat2) AND (tag1 OR tag2)
end
local function createSearchString(data)
	return expandURL("?s="..encode(data[QUERY]).."&post_type=product&"..createFilterString(data))
end

local function parseListing(doc)
	local results = doc:selectFirst(".dt-css-grid")

	if results then
		return map(results:children(), function(v)
			local a = v:selectFirst(".entry-title a")
			return Novel {
				title = a:text(),
				link = a:attr("href"):match("(index.php/producto/[^/]+)/.-"),
				imageURL = img_src(v:selectFirst("img")),
			}
		end)
	end
	return {}
end

local function listing(name, inc, url)
	url = expandURL(url)
	return Listing(name, inc, function(data)
		return parseListing(GETDocument(inc and (url .. "/page/" .. data[PAGE] .. "/?" .. createFilterString(data)) or url))
	end)
end

return {
	id = 28505740,
	name = "NOVA",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NOVA.png",
	imageURL = "https://github.com/khonkhortisan/extensions/raw/novelasligeras.net/icons/NOVA.png", --TODO
	hasSearch = true,
	chapterType = ChapterType.HTML,
	startIndex = 1,

	listings = {
		listing("Lista de Novelas", true, "index.php/lista-de-novela-ligera-novela-web"),
		listing("Novelas Exclusivas", false, "index.php/etiqueta-novela/novela-exclusiva"),
		listing("Novelas Completados", false, "index.php/filtro/estado/completado"),
		listing("Autores Hispanos", false, "index.php/etiqueta-novela/autor-hispano"),
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(expandURL(url))

		local page = doc:selectFirst(".content")
		local header = page:selectFirst(".entry-summary")
		local title = header:selectFirst(".entry-title")
		local info = page:selectFirst(".woocommerce-product-details__short-description")
		local genres = header:selectFirst(".posted_in")
		local tags = header:selectFirst(".tagged_as")
		
		local text = function(v) return v:text() end
		local status  =   page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_estado     td p a") and page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_estado     td p a"):text() or ""
		status = NovelStatus(status == "Completado" and 1 or status == "Pausado" and 2 or status == "En Proceso" and 0 or 3)
		local novel = NovelInfo {
			imageURL = page:selectFirst(".wp-post-image"):attr("src") or page:selectFirst(".wp-post-image"):attr("srcset"):match("^([^\s]+)"),
			title = title:text(),
			authors = map(page:select(".woocommerce-product-attributes-item--attribute_pa_escritor td p a"), text),
			artists = map(page:select(".woocommerce-product-attributes-item--attribute_pa_ilustrador td p a"), text),
			status = status,
			genres = map(genres:select("a"), text), --clicking a genre should filter the library or extension
			tags = map(tags:select("a"), text), --if visible, clicking a tag should filter the library or extension
			description = page:selectFirst(".woocommerce-product-details__short-description"):text(),--.."<br>Etiquetas: "..tostring(tags)
		}
		-- '.wpb_wrapper' has left column whole chapters '.wpb_tabs_nav a' and right column chapter parts '.post-content a'
		if loadChapters then
			local i = 0
			--STRUCTURE OF CHAPTERS PAGE:
			--  R sidebar|:nth-child(2)                          List of chapters|individual chapters                                             |title without time
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper                                                                p a	- 86 prologue chapter
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper div.wf-cell.wf-1 article.post-format-standard div.post-content p a	- 86 other chapters
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper div.wf-cell.wf-1 article.post-format-standard div.post-content   a	- A Monster Who Levels Up prologue chapter
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper div.wf-cell.wf-1 article.post-format-standard div.post-content p a	- A Monster Who Levels Up other chapters
			--div.wpb_tab section.items-grid.wf-container                         div.wf-cell.wf-1 article.post-format-standard div.post-content   a	- Abyss (NH), 10 nen
			
			--div.wpb_tab.ui-tabs-panel.wpb_ui-tabs-hide.vc_clearfix.ui-corner-bottom.ui-widget-content --right sidebar of single volume/section of chapters, including label
			--div.dt-fancy-separator.h3-size.style-thick.accent-title-color.accent-border-color         --                                                              label
			--section.items-grid.wf-container                                                           --                               section of chapters
			--div.wpb_text_column.wpb_content_element div.wpb_wrapper                                   --                               section of chapters
			novel:setChapters(AsList(map(doc:select(".wpb_tab a"), function(v) --each volume has multiple tabs, each tab has one or more a, each a is a chapter title/link/before time
				local a = v
				local a_time = a:lastElementSibling() --it's possible this isn't the <time> element
				i = i + 1
				return NovelChapter {
					order = i,
					title = a and a:text() or nil,
					link = (a and a:attr("href")) or nil,
					--release = (v:selectFirst("time") and (v:selectFirst("time"):attr("datetime") or v:selectFirst("time"):text())) or nil
					release = (a_time and (a_time:attr("datetime") or a_time:text())) or nil
				}
			end)))
		end

		return novel
	end,

	getPassage = function(url)
		local doc = GETDocument(url)
		--leave any other possible <center> tags alone
		if not settings[ADBLOCK_SETTING_KEY] then --block Publicidad Y-AR, Publicidad M-M4, etc.
			doc:select(".wpb_text_column .wpb_wrapper div center:matchesOwn(^Publicidad [A-Z0-9]-[A-Z0-9][A-Z0-9])"):remove()
		end
		if not settings[SUBSCRIBEBLOCK_SETTING_KEY] then --hide "¡Ayudanos! A traducir novelas del japones ¡Suscribete! A NOVA" (86)
			doc:select(".wpb_text_column .wpb_wrapper div center a[href*=index.php/nuestras-suscripciones/]"):remove()
		end
		--emoji svg is too big without css from head https://novelasligeras.net/index.php/2018/05/15/a-monster-who-levels-up-capitulo-2-novela-ligera/
		return pageOfElem(doc:selectFirst(".wpb_text_column .wpb_wrapper"), true, "img.wp-smiley,img.emoji{height: 1em !important;}"..css)
	end,

	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER_KEY, "Pedido de la tienda", ORDER_BY_FILTER_EXT),
		SwitchFilter(ORDER_FILTER_KEY, "Ascendiendo / Descendiendo"),
		FilterGroup("Géneros", {
			CheckboxFilter(CATEGORIAS_FILTER_INT[01], "Acción"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[02], "Adulto"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[03], "Artes Marciales"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[04], "Aventura"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[05], "Ciencia Ficción"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[06], "Comedia"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[07], "Deportes"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[08], "Drama"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[09], "Ecchi"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[10], "Fantasía"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[11], "Gender Bender"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[12], "Harem"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[13], "Histórico"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[14], "Horror"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[15], "Mechas (Robots Gigantes)"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[16], "Misterio"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[17], "Psicológico"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[18], "Recuentos de la Vida"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[19], "Romance"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[20], "Seinen"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[21], "Shojo"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[22], "Shojo Ai"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[23], "Shonen"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[24], "Sobrenatural"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[25], "Tragedia"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[26], "Vida Escolar"),
			CheckboxFilter(CATEGORIAS_FILTER_INT[27], "Xuanhuan"),
		}),
		DropdownFilter(searchHasOperId, "Condición de géneros", {"O (cualquiera de los seleccionados)", "Y (todos los seleccionados)"}),
		FilterGroup("Estado", {
			CheckboxFilter(ESTADO_FILTER_INT[1], "▶️ En Proceso"),
			CheckboxFilter(ESTADO_FILTER_INT[2], "⏸️ Pausado"),
			CheckboxFilter(ESTADO_FILTER_INT[3], "⏹️ Completado"),
		}),
		DropdownFilter(TIPO_FILTER_KEY, "Tipo", {"Cualquiera","Novela Ligera","Novela Web"}),
		FilterGroup("País", {
			CheckboxFilter(PAIS_FILTER_INT[01], "🇦🇷 Argentina"),
			CheckboxFilter(PAIS_FILTER_INT[02], "🇨🇱 Chile"),
			CheckboxFilter(PAIS_FILTER_INT[03], "🇨🇳 China"),
			CheckboxFilter(PAIS_FILTER_INT[04], "🇨🇴 Colombia"),
			CheckboxFilter(PAIS_FILTER_INT[05], "🇰🇷 Corea"),
			CheckboxFilter(PAIS_FILTER_INT[06], "🇪🇨 Ecuador"),
			CheckboxFilter(PAIS_FILTER_INT[07], "🇯🇵 Japón"),
			CheckboxFilter(PAIS_FILTER_INT[08], "🇲🇽 México"),
			CheckboxFilter(PAIS_FILTER_INT[09], "🇳🇮 Nicaragua"),
			CheckboxFilter(PAIS_FILTER_INT[10], "🇵🇪 Perú"),
			CheckboxFilter(PAIS_FILTER_INT[11], "🇻🇪 Venezuela"),
		}),
		TextFilter(TAG_FILTER_KEY, "Etiqueta"),
	},

	isSearchIncrementing = false,
	search = function(data)
		return parseListing(GETDocument(createSearchString(data)))
	end,
	
	settings = {
		SwitchFilter(ADBLOCK_SETTING_KEY, "Mostrar publicidades"),
		SwitchFilter(SUBSCRIBEBLOCK_SETTING_KEY, "Mostrar imagen de suscripción"),
	},
	setSettings = function(s) 
		settings = s 
	end,
	updateSetting = function(id, value)
		settings[id] = value
	end,
}
--})
