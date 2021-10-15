-- {"id":28505740,"ver":"1.0.56","libVer":"1.0.0","author":"Khonkhortisan","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://novelasligeras.net" --WordPress site, plugins: WooCommerce, Yoast SEO, js_composer, user_verificat_front, avatar-privacy

local ORDER_BY_FILTER_EXT = {"Ordenar por los últimos", "Orden alfabético", "Relevancia", "Ordenar por popularidad", "Ordenar por calificación media", "Ordenar por precio: bajo a alto", "Orden aleatorio", "Ordenar por id", "Ordenar por slug", "Ordenar por include"}
local ORDER_BY_FILTER_INT = {
	[0]="date"      , --Ordenar por los últimos
	[1]="title"     , --Orden alfabético/Orden por defecto (Listing is title, webview search is title-DESC, selecting Orden por defecto is menu_order)
	[2]="relevance" , --Relevancia (webview search is title-DESC when it should be relevance)
	[3]="popularity", --Ordenar por popularidad
	[4]="rating"    , --Ordenar por calificación media
	[5]="price"     , --Ordenar por precio: bajo a alto
	[6]="rand"      , --single-seed random order
	[7]="id"        , --id/slug/include are supported by WooCommerce, but not currently shown in the extension
	[8]="slug"      , --id is different from slug
	[9]="include"   , --is what? https://woocommerce.github.io/woocommerce-rest-api-docs/#list-all-products
	--only some of these can be descending
}
local ORDER_BY_FILTER_KEY = 789
local ORDER_FILTER_KEY = 1010

--can this be multi-select? https://stackoverflow.com/a/27898435 https://developer.wordpress.org/reference/classes/wp_query/
--https://novelasligeras.net/index.php/lista-de-novela-ligera-novela-web/?ixwpst[product_cat][0]=52&ixwpst[product_cat][1]=49&ixwpst[product_cat][2]=-45
--currently in OR mode, not AND https://wordpress.org/support/topic/multiple-categories-per-filter-results/ https://prnt.sc/tl9zt9 https://prnt.sc/t9wsoy
local CATEGORIAS_FILTER_INT = {
	[0] =""  , --Cualquier Categoría
	[1] ="40", --Acción
	[2] ="53", --Adulto
	[3] ="52", --Artes Marciales
	[4] ="41", --Aventura
	[5] ="59", --Ciencia Ficción
	[6] ="43", --Comedia
	[7] ="68", --Deportes
	[8] ="44", --Drama
	[9] ="45", --Ecchi
	[10]="46", --Fantasía
	[11]="47", --Gender Bender
	[12]="48", --Harem
	[13]="49", --Histórico
	[14]="50", --Horror
	[15]="54", --Mechas (Robots Gigantes)
	[16]="55", --Misterio
	[17]="56", --Psicológico
	[18]="66", --Recuentos de la Vida
	[19]="57", --Romance
	[20]="60", --Seinen
	[21]="62", --Shojo
	[22]="63", --Shojo Ai
	[23]="64", --Shonen
	[24]="69", --Sobrenatural
	[25]="70", --Tragedia
	[26]="58", --Vida Escolar
	[27]="73", --Xuanhuan
}
local CATEGORIAS_FILTER_KEY = 4242

local ESTADO_FILTER_INT = {
	[0]=""   , --Cualquiera --NovelStatus.UNKNOWN
	[1]="16" , --En Proceso --NovelStatus.PUBLISHING
	[2]="17" , --Pausado    --            On Hold/haitus
	[3]="407", --Completado --NovelStatus.COMPLETED
}
local ESTADO_FILTER_KEY = 407

local TIPO_FILTER_INT = {
	[0]=""  , --Cualquier
	[1]="23", --Novela Ligera
	[2]="24", --Novela Web
}
local TIPO_FILTER_KEY = 2324

local PAIS_FILTER_INT = {
	[0] =""    , --Cualquiera
	[1] ="1865", --Argentina
	[2] ="1749", --Chile
	[3] ="20"  , --China
	[4] ="4184", --Colombia
	[5] ="22"  , --Corea
	[6] ="1792", --Ecuador
	[7] ="21"  , --Japón
	[8] ="1704", --México
	[9] ="1657", --Nicaragua
	[10]="4341", --Perú
	[11]="2524", --Venezuela
}
local PAIS_FILTER_KEY = 2121
local TAG_FILTER_KEY = 2222

local ADBLOCK_SETTING_KEY = 0
local SUBSCRIBEBLOCK_SETTING_KEY = 1
local settings = {}

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
	--  (data[CATEGORIAS_FILTER_KEY]~=0 and "&ixwpst[product_cat][]="..encode(CATEGORIAS_FILTER_INT[data[CATEGORIAS_FILTER_KEY]]) or "")..
	--ixwpst[product_cat] is fine being a sparse array, so no need to count up from 0
	return "orderby=" .. encode(ORDER_BY_FILTER_INT[data[ORDER_BY_FILTER_KEY]]) .. (data[ORDER_FILTER_KEY] and "-desc" or "") ..
		(data[40] and "&ixwpst[product_cat][40]=40" or "").. --Acción
		(data[53] and "&ixwpst[product_cat][53]=53" or "").. --Adulto
		(data[52] and "&ixwpst[product_cat][52]=52" or "").. --Artes Marciales
		(data[41] and "&ixwpst[product_cat][41]=41" or "").. --Aventura
		(data[59] and "&ixwpst[product_cat][59]=59" or "").. --Ciencia Ficción
		(data[43] and "&ixwpst[product_cat][43]=43" or "").. --Comedia
		(data[68] and "&ixwpst[product_cat][68]=68" or "").. --Deportes
		(data[44] and "&ixwpst[product_cat][44]=44" or "").. --Drama
		(data[45] and "&ixwpst[product_cat][45]=45" or "").. --Ecchi
		(data[46] and "&ixwpst[product_cat][46]=46" or "").. --Fantasía
		(data[47] and "&ixwpst[product_cat][47]=47" or "").. --Gender Bender
		(data[48] and "&ixwpst[product_cat][48]=48" or "").. --Harem
		(data[49] and "&ixwpst[product_cat][49]=49" or "").. --Histórico
		(data[50] and "&ixwpst[product_cat][50]=50" or "").. --Horror
		(data[54] and "&ixwpst[product_cat][54]=54" or "").. --Mechas (Robots Gigantes)
		(data[55] and "&ixwpst[product_cat][55]=55" or "").. --Misterio
		(data[56] and "&ixwpst[product_cat][56]=56" or "").. --Psicológico
		(data[66] and "&ixwpst[product_cat][66]=66" or "").. --Recuentos de la Vida
		(data[57] and "&ixwpst[product_cat][57]=57" or "").. --Romance
		(data[60] and "&ixwpst[product_cat][60]=60" or "").. --Seinen
		(data[62] and "&ixwpst[product_cat][62]=62" or "").. --Shojo
		(data[63] and "&ixwpst[product_cat][63]=63" or "").. --Shojo Ai
		(data[64] and "&ixwpst[product_cat][64]=64" or "").. --Shonen
		(data[69] and "&ixwpst[product_cat][69]=69" or "").. --Sobrenatural
		(data[70] and "&ixwpst[product_cat][70]=70" or "").. --Tragedia
		(data[58] and "&ixwpst[product_cat][58]=58" or "").. --Vida Escolar
		(data[73] and "&ixwpst[product_cat][73]=73" or "").. --Xuanhuan
		(data[ESTADO_FILTER_KEY]~=0 and "&ixwpst[pa_estado][]="..encode(ESTADO_FILTER_INT[data[ESTADO_FILTER_KEY]]) or "")..
		(data[TIPO_FILTER_KEY]~=0   and "&ixwpst[pa_tipo][]="  ..encode(TIPO_FILTER_INT[data[TIPO_FILTER_KEY]])     or "")..
		(data[PAIS_FILTER_KEY]~=0   and "&ixwpst[pa_pais][]="  ..encode(PAIS_FILTER_INT[data[PAIS_FILTER_KEY]])     or "")..
		(data[TAG_FILTER_KEY]~=""   and "&product_tag[0]="     ..encode(data[TAG_FILTER_KEY])                       or "")
		--https://novelasligeras.net/?product_tag[0]=guerras&product_tag[1]=Asesinatos
		--other than orderby, filters in url must not be empty
		--Logic is (cat1 OR cat2) AND (tag1 OR tag2)
end
local function createSearchString(data)
	return expandURL("?s="..encode(data[QUERY]).."&post_type=product&"..createFilterString(data))
end

local function parseListing(doc)
	local results = doc:selectFirst(".dt-css-grid")

	return map(results:children(), function(v)
		local a = v:selectFirst(".entry-title a")
		return Novel {
			title = a:text(),
			link = a:attr("href"):match("(index.php/producto/[^/]+)/.-"),
			imageURL = img_src(v:selectFirst("img")),
		}
	end)
end

local function listing(name, inc, url)
	url = expandURL(url)
	return Listing(name, inc, function(data)
		return parseListing(GETDocument(inc and (url .. "/page/" .. data[PAGE]+1 .. "/?" .. createFilterString(data)) or url))
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
		--RadioGroupFilter(CATEGORIAS_FILTER_KEY, "Categorías", {"Cualquier Categoría","Acción","Adulto","Artes Marciales","Aventura","Ciencia Ficción","Comedia","Deportes","Drama","Ecchi","Fantasía","Gender Bender","Harem","Histórico","Horror","Mechas (Robots Gigantes)","Misterio","Psicológico","Recuentos de la Vida","Romance","Seinen","Shojo","Shojo Ai","Shonen","Sobrenatural","Tragedia","Vida Escolar","Xuanhuan"}),
		SwitchFilter(40, "Acción"),
		SwitchFilter(53, "Adulto"),
		SwitchFilter(52, "Artes Marciales"),
		SwitchFilter(41, "Aventura"),
		SwitchFilter(59, "Ciencia Ficción"),
		SwitchFilter(43, "Comedia"),
		SwitchFilter(68, "Deportes"),
		SwitchFilter(44, "Drama"),
		SwitchFilter(45, "Ecchi"),
		SwitchFilter(46, "Fantasía"),
		SwitchFilter(47, "Gender Bender"),
		SwitchFilter(48, "Harem"),
		SwitchFilter(49, "Histórico"),
		SwitchFilter(50, "Horror"),
		SwitchFilter(54, "Mechas (Robots Gigantes)"),
		SwitchFilter(55, "Misterio"),
		SwitchFilter(56, "Psicológico"),
		SwitchFilter(66, "Recuentos de la Vida"),
		SwitchFilter(57, "Romance"),
		SwitchFilter(60, "Seinen"),
		SwitchFilter(62, "Shojo"),
		SwitchFilter(63, "Shojo Ai"),
		SwitchFilter(64, "Shonen"),
		SwitchFilter(69, "Sobrenatural"),
		SwitchFilter(70, "Tragedia"),
		SwitchFilter(58, "Vida Escolar"),
		SwitchFilter(73, "Xuanhuan"),
		DropdownFilter(ESTADO_FILTER_KEY, "Estado", {"⏯️ Cualquiera","▶️ En Proceso","⏸️ Pausado","⏹️ Completado"}),
		DropdownFilter(TIPO_FILTER_KEY, "Tipo", {"Cualquiera","Novela Ligera","Novela Web"}),
		DropdownFilter(PAIS_FILTER_KEY, "País", {"🌐 Cualquiera","🇦🇷 Argentina","🇨🇱 Chile","🇨🇳 China","🇨🇴 Colombia","🇰🇷 Corea","🇪🇨 Ecuador","🇯🇵 Japón","🇲🇽 México","🇳🇮 Nicaragua","🇵🇪 Perú","🇻🇪 Venezuela"}),
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
