-- {"id":70,"ver":"1.0.0","libVer":"1.0.0","author":"Rider21"}

local baseURL = "https://tl.rulate.ru"

local ORDER_BY_FILTER = 3
local AGE_BY_FILTER = 4
local TYPE_BY_FILTER = 5
local ATMOSPHERE_BY_FILTER = 6
local OTHER_BY_FILTER = 9
local ORDER_BY_TERMS = {
	"ready", --Готовые на 100%
	"gen", --Доступные для скачивания
	"tr", --Доступные для перевода
	"wealth", --Завершённые проекты
	"discount", --Распродажа
	"ongoings", --Только онгоинги
	"remove_machinelate", --Убрать машинный
	"fandoms_ex_all" --без фэндомов
}

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function getSearch(data)
	local url = baseURL .. "/search?"

	if data[0] then --search
		url = url .. "t=" .. data[0] .. "&"
	end

	url = url .. "cat=2&sort=" .. data[ORDER_BY_FILTER]

	for k, v in pairs(data) do
		if v then
			if (k > 9 and k < 18) then
				url = url .. "&" .. ORDER_BY_TERMS[k - 9] .. "=1"
			elseif (k > 20 and k < 100) then
				url = url .. "&genres[]=" .. k - 20
			elseif (k > 100) then
				url = url .. "&tags[]=" .. k - 100
			end
		end
	end

	url = url .. "&adult=" .. data[AGE_BY_FILTER] ..
		"&type=" .. data[TYPE_BY_FILTER] ..
		"&atmosphere=" .. data[ATMOSPHERE_BY_FILTER] ..
		"&Book_page=" .. data[PAGE]

	local d = GETDocument(url)
	return map(d:select(".search-results li"), function(v)
		return Novel {
			title = v:select("p > a"):text(),
			link = v:select("p > a"):attr("href"),
			imageURL = baseURL .. v:select("img"):attr("src")
		}
	end)
end

local function getPassage(chapterURL)
	local doc = RequestDocument(GET(expandURL(chapterURL),
		HeadersBuilder()
		:add("Cookie", "mature=c3a2ed4b199a1a15f5a5483504c7a75a7030dc4bi%3A1%3B")
		:build())
	)
	local chap = doc:selectFirst(".content-text")
	chap:child(0):before("<h1>" .. doc:select(".chapter_select > select > option[selected]"):text() .. "</h1>");

	map(chap:select("img"), function(v)
		if string.sub(v:attr("src"), 0, 1) == "/" then
			v:attr("src", baseURL .. v:attr("src"))
		elseif string.sub(v:attr("data-src"), 0, 1) == "/" then
			v:attr("src", baseURL .. v:attr("data-src"))
		elseif string.match(v:attr("data-src"), "[a-z]*://[^ >,;]*") then
			v:attr("src", v:attr("data-src"))
		end
	end)
	return pageOfElem(chap)
end

local function parseNovel(novelURL, loadChapters)
	local d = RequestDocument(GET(expandURL(novelURL),
		HeadersBuilder()
		:add("Cookie", "mature=c3a2ed4b199a1a15f5a5483504c7a75a7030dc4bi%3A1%3B")
		:build())
	)

	local novel = NovelInfo {
		title = d:select(".span8 > h1"):text(),
		imageURL = baseURL .. d:select(".slick > div > img"):attr("src"),
		description = d:select("#Info > div:nth-child(3)"):text(),
	}

	map(d:select(".span5 > p"), function(v)
		local str = v:select("strong"):text()
		if str == "Автор:" then
			novel:setAuthors({ v:select("em > a"):text():gsub("Автор: ", "") })
		elseif str == "Выпуск:" then
			local status = v:select("em"):text()
			novel:setStatus(NovelStatus(
					status == "завершён" and 1 or
					status == "продолжается" and 0 or 3
				)
			)
		elseif str == "Жанры:" then
			novel:setGenres(map(v:select("em > a"), function(genres) return genres:text() end))
		elseif str == "Тэги:" then
			novel:setTags(map(v:select("em > a"), function(tags) return tags:text() end))
		end
	end)

	if loadChapters then
		local order = -1
		local chapterList = mapNotNil(d:select("tr.chapter_row"), function(v)
			local releaseDate = v:select("td > span"):attr("title")
			order = order + 1
			if v:select('td > span[class="disabled"]'):size() > 0 or releaseDate == "" then
				return nil
			end
			return NovelChapter {
				title = v:selectFirst("td > a"):text(),
				link = v:selectFirst("td > a"):attr("href"),
				release = releaseDate,
				order = order
			}
		end)
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

return {
	id = 70,
	name = "Rulate",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Rulate.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Novel List", true, function(data)
			return getSearch(data)
		end)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,

	hasSearch = true,
	isSearchIncrementing = true,
	search = getSearch,
	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", {
			"По степени готовности", --ID: 0
			"По названию на языке оригинала", --ID: 1
			"По названию на языке перевода", --ID: 2
			"По дате создания", --ID: 3
			"По дате последней активности", --ID: 4
			"По просмотрам", --ID: 5
			"По рейтингу", --ID: 6
			"По кол-ву переведённых глав", --ID: 7
			"По кол-ву лайков", --ID: 8
			"Случайно", --ID: 9
			"По кол-ву страниц", --ID: 10
			"По кол-ву бесплатных глав", --ID: 11
			"По кол-ву рецензий", --ID: 12
			"По кол-ву в закладках", --ID: 13
			"По кол-ву в избранном", --ID: 14
		}),
		FilterGroup("Жанры", { --offset: 20
			CheckboxFilter(21, "Арт"), --ID: 1
			CheckboxFilter(22, "Боевик"), --ID: 2
			CheckboxFilter(23, "Боевые искусства"), --ID: 3
			CheckboxFilter(24, "Вампиры"), --ID: 4
			CheckboxFilter(25, "Гарем"), --ID: 5
			CheckboxFilter(26, "Гендерная интрига"), --ID: 6
			CheckboxFilter(27, "Героическое фэнтези"), --ID: 7
			CheckboxFilter(28, "Детектив"), --ID: 8
			CheckboxFilter(29, "Дзёсэй"), --ID: 9
			CheckboxFilter(30, "Додзинси"), --ID: 10
			CheckboxFilter(31, "Драма"), --ID: 11
			CheckboxFilter(32, "Игра"), --ID: 12
			CheckboxFilter(33, "История"), --ID: 13
			CheckboxFilter(66, "Киберпанк"), --ID: 46
			CheckboxFilter(34, "Кодомо"), --ID: 14
			CheckboxFilter(35, "Комедия"), --ID: 15
			CheckboxFilter(68, "Литрпг"), --ID: 48
			CheckboxFilter(36, "Махо-сёдзё"), --ID: 16
			CheckboxFilter(69, "Мелодрама"), --ID: 49
			CheckboxFilter(37, "Меха"), --ID: 17
			CheckboxFilter(38, "Мистика"), --ID: 18
			CheckboxFilter(39, "Научная фантастика"), --ID: 19
			CheckboxFilter(40, "Повседневность"), --ID: 20
			CheckboxFilter(41, "Постапокалиптика"), --ID: 21
			CheckboxFilter(42, "Приключения"), --ID: 22
			CheckboxFilter(43, "Психология"), --ID: 23
			CheckboxFilter(44, "Романтика"), --ID: 24
			CheckboxFilter(47, "Сёдзё"), --ID: 27
			CheckboxFilter(48, "Сёдзё-ай"), --ID: 28
			CheckboxFilter(49, "Сёнэн"), --ID: 29
			CheckboxFilter(50, "Сёнэн-ай"), --ID: 30
			CheckboxFilter(45, "Самурайский боевик"), --ID: 25
			CheckboxFilter(46, "Сверхъестественное"), --ID: 26
			CheckboxFilter(65, "Смат"), --ID: 45
			CheckboxFilter(51, "Спорт"), --ID: 31
			CheckboxFilter(52, "Сэйнэн"), --ID: 32
			CheckboxFilter(64, "Сюаньхуа"), --ID: 44
			CheckboxFilter(67, "Сюаньхуань"), --ID: 47
			CheckboxFilter(62, "Сянься (XianXia)"), --ID: 42
			CheckboxFilter(53, "Трагедия"), --ID: 33
			CheckboxFilter(54, "Триллер"), --ID: 34
			CheckboxFilter(55, "Ужасы"), --ID: 35
			CheckboxFilter(61, "Уся (wuxia)"), --ID: 41
			CheckboxFilter(56, "Фантастика"), --ID: 36
			CheckboxFilter(70, "Фанфик"), --ID: 50
			CheckboxFilter(57, "Фэнтези"), --ID: 37
			CheckboxFilter(58, "Школа"), --ID: 38
			CheckboxFilter(59, "Этти"), --ID: 39
			CheckboxFilter(60, "Юри"), --ID: 40
			CheckboxFilter(63, "Яой"), --ID: 43
		}),
		FilterGroup("Теги", { --offset: 100
			CheckboxFilter(8073, "Абсурд"), --ID: 7973
			CheckboxFilter(322, "Авантюристы"), --ID: 222
			CheckboxFilter(5372, "Автомат"), --ID: 5272
			CheckboxFilter(1162, "Авторский мир"), --ID: 1062
			CheckboxFilter(3349, "Агрессивные персонажи"), --ID: 3249
			CheckboxFilter(2723, "Ад"), --ID: 2623
			CheckboxFilter(917, "Ад и рай"), --ID: 817
			CheckboxFilter(1749, "Адам дженсен"), --ID: 1649
			CheckboxFilter(292, "Адаптация произведения"), --ID: 192
			CheckboxFilter(6440, "Адвокат"), --ID: 6340
			CheckboxFilter(2053, "Адекватные главные герои"), --ID: 1953
			CheckboxFilter(5401, "Азартные игры"), --ID: 5301
			CheckboxFilter(3594, "Азгард"), --ID: 3494
			CheckboxFilter(5650, "Азула"), --ID: 5550
			CheckboxFilter(7741, "Аид"), --ID: 7641
			CheckboxFilter(4181, "Айдолы"), --ID: 4081
			CheckboxFilter(416, "Академия"), --ID: 316
			CheckboxFilter(5159, "Акамэ"), --ID: 5059
			CheckboxFilter(6052, "Аквакинез"), --ID: 5952
			CheckboxFilter(2739, "Акира"), --ID: 2639
			CheckboxFilter(4734, "Акнология"), --ID: 4634
			CheckboxFilter(4898, "Актерское мастерство"), --ID: 4798
			CheckboxFilter(7606, "Актёры"), --ID: 7506
			CheckboxFilter(6476, "Активные герои"), --ID: 6376
			CheckboxFilter(4213, "Акутагава рюноске"), --ID: 4113
			CheckboxFilter(6589, "Аладдин"), --ID: 6489
			CheckboxFilter(4867, "Алая ведьма"), --ID: 4767
			CheckboxFilter(4861, "Алиса"), --ID: 4761
			CheckboxFilter(5608, "Алкоголь"), --ID: 5508
			CheckboxFilter(371, "Аллегория"), --ID: 271
			CheckboxFilter(5014, "Алукард"), --ID: 4914
			CheckboxFilter(1264, "Алхимики"), --ID: 1164
			CheckboxFilter(1573, "Алхимия"), --ID: 1473
			CheckboxFilter(6997, "Алчность"), --ID: 6897
			CheckboxFilter(5884, "Альбус дамблдор"), --ID: 5784
			CheckboxFilter(5430, "Альтернативное развитие событий"), --ID: 5330
			CheckboxFilter(428, "Альянсы"), --ID: 328
			CheckboxFilter(3851, "Амбициозный главный герой"), --ID: 3751
			CheckboxFilter(4182, "Америка"), --ID: 4082
			CheckboxFilter(2307, "Амнезия"), --ID: 2207
			CheckboxFilter(118, "Аморальный герой"), --ID: 18
			CheckboxFilter(2042, "Анальный секс"), --ID: 1942
			CheckboxFilter(8229, "Анбу"), --ID: 8129
			CheckboxFilter(957, "Ангелы"), --ID: 857
			CheckboxFilter(1427, "Ангелы и демоны"), --ID: 1327
			CheckboxFilter(4738, "Ангст"), --ID: 4638
			CheckboxFilter(2435, "Андрогинные персонажи"), --ID: 2335
			CheckboxFilter(2093, "Андроиды"), --ID: 1993
			CheckboxFilter(5349, "Анимализм"), --ID: 5249
			CheckboxFilter(1394, "Аниме"), --ID: 1294
			CheckboxFilter(5868, "Анко митараши"), --ID: 5768
			CheckboxFilter(2244, "Антагонист"), --ID: 2144
			CheckboxFilter(7825, "Антигерой"), --ID: 7725
			CheckboxFilter(3652, "Антиквариат"), --ID: 3552
			CheckboxFilter(1448, "Антимаг"), --ID: 1348
			CheckboxFilter(762, "Антиутопия"), --ID: 662
			CheckboxFilter(1598, "Апокалипсис"), --ID: 1498
			CheckboxFilter(471, "Аристократия"), --ID: 371
			CheckboxFilter(7438, "Аристократы"), --ID: 7338
			CheckboxFilter(1823, "Армия"), --ID: 1723
			CheckboxFilter(6800, "Артас"), --ID: 6700
			CheckboxFilter(2396, "Артефакты"), --ID: 2296
			CheckboxFilter(6623, "Археология"), --ID: 6523
			CheckboxFilter(3735, "Асгард"), --ID: 3635
			CheckboxFilter(1515, "Ассасин"), --ID: 1415
			CheckboxFilter(5144, "Асуна"), --ID: 5044
			CheckboxFilter(7851, "Аугментации"), --ID: 7751
			CheckboxFilter(4209, "Ацуши накаджима"), --ID: 4109
			CheckboxFilter(6962, "Аянокоджи киетака"), --ID: 6862
			CheckboxFilter(2288, "Бандиты"), --ID: 2188
			CheckboxFilter(6947, "Басейн"), --ID: 6847
			CheckboxFilter(8033, "Баскетбол"), --ID: 7933
			CheckboxFilter(176, "Бастарды"), --ID: 76
			CheckboxFilter(544, "Бдсм"), --ID: 444
			CheckboxFilter(1307, "Бедность"), --ID: 1207
			CheckboxFilter(768, "Без культивации"), --ID: 668
			CheckboxFilter(2325, "Без любовной линий"), --ID: 2225
			CheckboxFilter(362, "Без перерождений"), --ID: 262
			CheckboxFilter(8165, "Без попаданца"), --ID: 8065
			CheckboxFilter(847, "Без системы"), --ID: 747
			CheckboxFilter(7625, "Без цензуры"), --ID: 7525
			CheckboxFilter(863, "Без юмора"), --ID: 763
			CheckboxFilter(1126, "Бездна"), --ID: 1026
			CheckboxFilter(1345, "Безжалостное домашнее животное"), --ID: 1245
			CheckboxFilter(3086, "Безжалостные персонажи"), --ID: 2986
			CheckboxFilter(3223, "Беззаботные персонажи "), --ID: 3123
			CheckboxFilter(7915, "Безответная любовь"), --ID: 7815
			CheckboxFilter(2302, "Безработный"), --ID: 2202
			CheckboxFilter(137, "Безумие"), --ID: 37
			CheckboxFilter(2149, "Безумные персонажи"), --ID: 2049
			CheckboxFilter(7723, "Бейсбол"), --ID: 7623
			CheckboxFilter(2222, "Беременность"), --ID: 2122
			CheckboxFilter(7656, "Бесконечный поток"), --ID: 7556
			CheckboxFilter(842, "Беспечные персонажи"), --ID: 742
			CheckboxFilter(666, "Бессмертные персонажи"), --ID: 566
			CheckboxFilter(7021, "Бесстрашные персонажи"), --ID: 6921
			CheckboxFilter(1357, "Бесстыдные персонажи"), --ID: 1257
			CheckboxFilter(8290, "Бесстыдный главный герой"), --ID: 8190
			CheckboxFilter(4310, "Библиотека"), --ID: 4210
			CheckboxFilter(588, "Библия"), --ID: 488
			CheckboxFilter(804, "Бизнес"), --ID: 704
			CheckboxFilter(2320, "Биология"), --ID: 2220
			CheckboxFilter(2068, "Биомехи"), --ID: 1968
			CheckboxFilter(877, "Биседзе"), --ID: 777
			CheckboxFilter(5214, "Бисексуалы"), --ID: 5114
			CheckboxFilter(821, "Битва за веру"), --ID: 721
			CheckboxFilter(7311, "Битва за трон"), --ID: 7211
			CheckboxFilter(1251, "Битва королевств"), --ID: 1151
			CheckboxFilter(7089, "Битва рас"), --ID: 6989
			CheckboxFilter(1840, "Битвы"), --ID: 1740
			CheckboxFilter(2301, "Благородные персонажи"), --ID: 2201
			CheckboxFilter(3031, "Близнецы"), --ID: 2931
			CheckboxFilter(6622, "Богатство"), --ID: 6522
			CheckboxFilter(620, "Богатые персонажи"), --ID: 520
			CheckboxFilter(273, "Боги"), --ID: 173
			CheckboxFilter(130, "Богини"), --ID: 30
			CheckboxFilter(1353, "Богоубийца"), --ID: 1253
			CheckboxFilter(195, "Богохульство"), --ID: 95
			CheckboxFilter(2208, "Боевая академия"), --ID: 2108
			CheckboxFilter(629, "Боевик"), --ID: 529
			CheckboxFilter(2190, "Боевые искусства"), --ID: 2090
			CheckboxFilter(4817, "Большая грудь"), --ID: 4717
			CheckboxFilter(5399, "Большой член"), --ID: 5299
			CheckboxFilter(6633, "Борос"), --ID: 6533
			CheckboxFilter(2025, "Борьба"), --ID: 1925
			CheckboxFilter(8172, "Борьба за власть"), --ID: 8072
			CheckboxFilter(7257, "Босс и подчиненный"), --ID: 7157
			CheckboxFilter(2407, "Бояръ"), --ID: 2307
			CheckboxFilter(1658, "Брак"), --ID: 1558
			CheckboxFilter(1489, "Брак по расчету"), --ID: 1389
			CheckboxFilter(715, "Брат и сестра"), --ID: 615
			CheckboxFilter(2421, "Братский комплекс"), --ID: 2321
			CheckboxFilter(1203, "Броманс"), --ID: 1103
			CheckboxFilter(2946, "Брошенные дети"), --ID: 2846
			CheckboxFilter(1971, "Буддизм"), --ID: 1871
			CheckboxFilter(1920, "Будущее"), --ID: 1820
			CheckboxFilter(8180, "Бывший муж"), --ID: 8080
			CheckboxFilter(1543, "Быстрое развитие"), --ID: 1443
			CheckboxFilter(2684, "Бэтгерл"), --ID: 2584
			CheckboxFilter(4768, "Бэтмен"), --ID: 4668
			CheckboxFilter(6312, "В первый раз"), --ID: 6212
			CheckboxFilter(149, "В этот же мир"), --ID: 49
			CheckboxFilter(4842, "Вагинальный секс"), --ID: 4742
			CheckboxFilter(4147, "Валькирии"), --ID: 4047
			CheckboxFilter(2306, "Вампиры"), --ID: 2206
			CheckboxFilter(5764, "Веб камера"), --ID: 5664
			CheckboxFilter(2449, "Веб новелла"), --ID: 2349
			CheckboxFilter(943, "Ведьмак"), --ID: 843
			CheckboxFilter(743, "Ведьмы"), --ID: 643
			CheckboxFilter(1979, "Везучие персонажи"), --ID: 1879
			CheckboxFilter(4094, "Веном"), --ID: 3994
			CheckboxFilter(2231, "Вестерн"), --ID: 2131
			CheckboxFilter(8271, "Вестерос"), --ID: 8171
			CheckboxFilter(724, "Взросление"), --ID: 624
			CheckboxFilter(2516, "Взрослый главный герой"), --ID: 2416
			CheckboxFilter(2730, "Видео игры"), --ID: 2630
			CheckboxFilter(367, "Викинги"), --ID: 267
			CheckboxFilter(7072, "Вино"), --ID: 6972
			CheckboxFilter(6313, "Вирт"), --ID: 6213
			CheckboxFilter(425, "Виртуальная реальность"), --ID: 325
			CheckboxFilter(3427, "Вирусы"), --ID: 3327
			CheckboxFilter(655, "Владыка демонов"), --ID: 555
			CheckboxFilter(856, "Власть"), --ID: 756
			CheckboxFilter(6232, "Влюбленность"), --ID: 6132
			CheckboxFilter(2038, "Внешний вид отличается от личности"), --ID: 1938
			CheckboxFilter(1196, "Военные"), --ID: 1096
			CheckboxFilter(1260, "Возрождение"), --ID: 1160
			CheckboxFilter(387, "Воины"), --ID: 287
			CheckboxFilter(543, "Война"), --ID: 443
			CheckboxFilter(2531, "Войны"), --ID: 2431
			CheckboxFilter(4378, "Воландеморт"), --ID: 4278
			CheckboxFilter(6515, "Волейбол"), --ID: 6415
			CheckboxFilter(1266, "Волки"), --ID: 1166
			CheckboxFilter(222, "Волшебники"), --ID: 122
			CheckboxFilter(1789, "Волшебные существа"), --ID: 1689
			CheckboxFilter(819, "Волшебство"), --ID: 719
			CheckboxFilter(1499, "Вор"), --ID: 1399
			CheckboxFilter(7048, "Воровка"), --ID: 6948
			CheckboxFilter(948, "Ворон"), --ID: 848
			CheckboxFilter(7015, "Воскрешение"), --ID: 6915
			CheckboxFilter(1466, "Воспоминания из другого мира"), --ID: 1366
			CheckboxFilter(1472, "Воспоминания из прошлого"), --ID: 1372
			CheckboxFilter(8230, "Воссоединие семьи"), --ID: 8130
			CheckboxFilter(480, "Восхождение"), --ID: 380
			CheckboxFilter(1078, "Враги становятся любовниками"), --ID: 978
			CheckboxFilter(140, "Врата"), --ID: 40
			CheckboxFilter(2057, "Врата в другой мир"), --ID: 1957
			CheckboxFilter(1343, "Врач"), --ID: 1243
			CheckboxFilter(2952, "Временная петля"), --ID: 2852
			CheckboxFilter(2143, "Врмморпг"), --ID: 2043
			CheckboxFilter(196, "Все дозволено"), --ID: 96
			CheckboxFilter(1514, "Всемогущий главный герой"), --ID: 1414
			CheckboxFilter(2472, "Второй шанс"), --ID: 2372
			CheckboxFilter(2598, "Вуайеризм"), --ID: 2498
			CheckboxFilter(601, "Выживание"), --ID: 501
			CheckboxFilter(3566, "Вымышленные существа"), --ID: 3466
			CheckboxFilter(7805, "Вынужденный брак"), --ID: 7705
			CheckboxFilter(753, "Высокие технологии"), --ID: 653
			CheckboxFilter(3350, "Высокомерные персонажи"), --ID: 3250
			CheckboxFilter(5299, "Галустян"), --ID: 5199
			CheckboxFilter(7804, "Гангстеры"), --ID: 7704
			CheckboxFilter(540, "Гарем"), --ID: 440
			CheckboxFilter(326, "Гарри поттер"), --ID: 226
			CheckboxFilter(2230, "Геймеры"), --ID: 2130
			CheckboxFilter(873, "Гендерная интрига"), --ID: 773
			CheckboxFilter(1850, "Генетические модификации"), --ID: 1750
			CheckboxFilter(1600, "Гениальный главный герой"), --ID: 1500
			CheckboxFilter(1750, "Гений"), --ID: 1650
			CheckboxFilter(4380, "Гермиона грейнджер"), --ID: 4280
			CheckboxFilter(285, "Герои"), --ID: 185
			CheckboxFilter(1248, "Героическое фэнтези"), --ID: 1148
			CheckboxFilter(6131, "Гильгамеш"), --ID: 6031
			CheckboxFilter(1000, "Гильдии"), --ID: 900
			CheckboxFilter(1958, "Гильдия авантюристов"), --ID: 1858
			CheckboxFilter(4644, "Гинтама"), --ID: 4544
			CheckboxFilter(458, "Гипноз"), --ID: 358
			CheckboxFilter(1073, "Главная героиня влюбляется первой"), --ID: 973
			CheckboxFilter(264, "Главный герой бог"), --ID: 164
			CheckboxFilter(3729, "Главный герой влюбляется первым"), --ID: 3629
			CheckboxFilter(220, "Главный герой выживальщик"), --ID: 120
			CheckboxFilter(7977, "Главный герой гонг"), --ID: 7877
			CheckboxFilter(357, "Главный герой девушка"), --ID: 257
			CheckboxFilter(236, "Главный герой демон"), --ID: 136
			CheckboxFilter(7429, "Главный герой женщина"), --ID: 7329
			CheckboxFilter(1653, "Главный герой жестокий"), --ID: 1553
			CheckboxFilter(194, "Главный герой извращенец"), --ID: 94
			CheckboxFilter(2521, "Главный герой имба"), --ID: 2421
			CheckboxFilter(7880, "Главный герой киборг"), --ID: 7780
			CheckboxFilter(969, "Главный герой монстр"), --ID: 869
			CheckboxFilter(2097, "Главный герой мужчина"), --ID: 1997
			CheckboxFilter(1614, "Главный герой на стороне сил зла"), --ID: 1514
			CheckboxFilter(105, "Главный герой не адекватный"), --ID: 5
			CheckboxFilter(7904, "Главный герой не психопат"), --ID: 7804
			CheckboxFilter(2272, "Главный герой не человек"), --ID: 2172
			CheckboxFilter(1250, "Главный герой не эмоционален"), --ID: 1150
			CheckboxFilter(2315, "Главный герой подросток"), --ID: 2215
			CheckboxFilter(7887, "Главный герой позитивный"), --ID: 7787
			CheckboxFilter(7903, "Главный герой психопат"), --ID: 7803
			CheckboxFilter(2447, "Главный герой ребенок"), --ID: 2347
			CheckboxFilter(2517, "Главный герой русский"), --ID: 2417
			CheckboxFilter(188, "Главный герой сильный с самого начала"), --ID: 88
			CheckboxFilter(1159, "Главный герой скрывает свою силу"), --ID: 1059
			CheckboxFilter(4591, "Глотание спермы"), --ID: 4491
			CheckboxFilter(1970, "Гномы"), --ID: 1870
			CheckboxFilter(2129, "Гоблины"), --ID: 2029
			CheckboxFilter(7090, "Годзилла"), --ID: 6990
			CheckboxFilter(1790, "Големы"), --ID: 1690
			CheckboxFilter(7854, "Голливуд"), --ID: 7754
			CheckboxFilter(1797, "Головоломка"), --ID: 1697
			CheckboxFilter(8191, "Горничные"), --ID: 8091
			CheckboxFilter(488, "Гробница"), --ID: 388
			CheckboxFilter(1414, "Групповой секс"), --ID: 1314
			CheckboxFilter(1610, "Гуро"), --ID: 1510
			CheckboxFilter(4212, "Дазай осаму"), --ID: 4112
			CheckboxFilter(3511, "Даньмэй"), --ID: 3411
			CheckboxFilter(358, "Даосизм"), --ID: 258
			CheckboxFilter(6157, "Дарк соулс"), --ID: 6057
			CheckboxFilter(6926, "Дарт вейдер"), --ID: 6826
			CheckboxFilter(5292, "Дафна гринграсс"), --ID: 5192
			CheckboxFilter(7304, "Дворяне"), --ID: 7204
			CheckboxFilter(7768, "Девушки"), --ID: 7668
			CheckboxFilter(2331, "Девушки монстры"), --ID: 2231
			CheckboxFilter(8161, "Дейви джонс"), --ID: 8061
			CheckboxFilter(1525, "Действие"), --ID: 1425
			CheckboxFilter(253, "Демон лорд"), --ID: 153
			CheckboxFilter(2124, "Демонология"), --ID: 2024
			CheckboxFilter(1506, "Демоны"), --ID: 1406
			CheckboxFilter(1365, "Детектив"), --ID: 1265
			CheckboxFilter(680, "Дети"), --ID: 580
			CheckboxFilter(1033, "Джарвис"), --ID: 933
			CheckboxFilter(4542, "Джедай"), --ID: 4442
			CheckboxFilter(4124, "Джин"), --ID: 4024
			CheckboxFilter(3451, "Джокер"), --ID: 3351
			CheckboxFilter(7512, "Джон сноу"), --ID: 7412
			CheckboxFilter(4036, "Джоффри баратеон"), --ID: 3936
			CheckboxFilter(778, "Дзесэй"), --ID: 678
			CheckboxFilter(7053, "Дин винчестер"), --ID: 6953
			CheckboxFilter(3082, "Династии"), --ID: 2982
			CheckboxFilter(3766, "Динозавры"), --ID: 3666
			CheckboxFilter(1517, "Директор"), --ID: 1417
			CheckboxFilter(1541, "Для девушек"), --ID: 1441
			CheckboxFilter(398, "Дневник"), --ID: 298
			CheckboxFilter(6862, "Добби"), --ID: 6762
			CheckboxFilter(1785, "Добрый мир"), --ID: 1685
			CheckboxFilter(2252, "Договоры с богами"), --ID: 2152
			CheckboxFilter(2022, "Договоры с демонами"), --ID: 1922
			CheckboxFilter(2091, "Доктор"), --ID: 1991
			CheckboxFilter(7734, "Доктор стрэндж"), --ID: 7634
			CheckboxFilter(2154, "Доминирование"), --ID: 2054
			CheckboxFilter(7065, "Дота"), --ID: 6965
			CheckboxFilter(7233, "Доудзюцу"), --ID: 7133
			CheckboxFilter(3391, "Дочь"), --ID: 3291
			CheckboxFilter(146, "Драко малфой"), --ID: 46
			CheckboxFilter(382, "Драконы"), --ID: 282
			CheckboxFilter(8182, "Драконы оборотни"), --ID: 8082
			CheckboxFilter(711, "Драма"), --ID: 611
			CheckboxFilter(7881, "Древние времена"), --ID: 7781
			CheckboxFilter(7714, "Древний египет"), --ID: 7614
			CheckboxFilter(573, "Древний китай"), --ID: 473
			CheckboxFilter(104, "Древний мир"), --ID: 4
			CheckboxFilter(4665, "Дрочка"), --ID: 4565
			CheckboxFilter(139, "Другая вселенная"), --ID: 39
			CheckboxFilter(2471, "Другие планеты"), --ID: 2371
			CheckboxFilter(2348, "Другой мир"), --ID: 2248
			CheckboxFilter(2003, "Дружба"), --ID: 1903
			CheckboxFilter(1253, "Друзья детства"), --ID: 1153
			CheckboxFilter(214, "Духи"), --ID: 114
			CheckboxFilter(2055, "Духовные силы"), --ID: 1955
			CheckboxFilter(1312, "Души"), --ID: 1212
			CheckboxFilter(1194, "Дьявол"), --ID: 1094
			CheckboxFilter(1664, "Дьявольские фрукты"), --ID: 1564
			CheckboxFilter(4499, "Дэдпул"), --ID: 4399
			CheckboxFilter(6393, "Евнух"), --ID: 6293
			CheckboxFilter(5937, "Европейская атмосфера"), --ID: 5837
			CheckboxFilter(628, "Египет"), --ID: 528
			CheckboxFilter(2156, "Еда"), --ID: 2056
			CheckboxFilter(537, "Единороги"), --ID: 437
			CheckboxFilter(755, "Екаи"), --ID: 655
			CheckboxFilter(197, "Жалкий главный герой"), --ID: 97
			CheckboxFilter(5829, "Жена"), --ID: 5729
			CheckboxFilter(4722, "Женское доминирование"), --ID: 4622
			CheckboxFilter(2848, "Женщина в теле мужчины"), --ID: 2748
			CheckboxFilter(7613, "Женщина кошка"), --ID: 7513
			CheckboxFilter(2338, "Жесткий секс"), --ID: 2238
			CheckboxFilter(3253, "Жестокие персонажи "), --ID: 3153
			CheckboxFilter(1632, "Жестокий мир"), --ID: 1532
			CheckboxFilter(184, "Жестокое обращение с детьми"), --ID: 84
			CheckboxFilter(7980, "Жестокость"), --ID: 7880
			CheckboxFilter(7588, "Животные"), --ID: 7488
			CheckboxFilter(2161, "Животные компаньоны"), --ID: 2061
			CheckboxFilter(2114, "Жизнь и смерть"), --ID: 2014
			CheckboxFilter(6388, "Жнец"), --ID: 6288
			CheckboxFilter(4026, "Жойен рид"), --ID: 3926
			CheckboxFilter(438, "Заботливый главный герой"), --ID: 338
			CheckboxFilter(248, "Закалка тела"), --ID: 148
			CheckboxFilter(658, "Заклинания"), --ID: 558
			CheckboxFilter(3152, "Заключенные"), --ID: 3052
			CheckboxFilter(1202, "Занпакто"), --ID: 1102
			CheckboxFilter(8133, "Запретная любовь"), --ID: 8033
			CheckboxFilter(1141, "Запутанный сюжет"), --ID: 1041
			CheckboxFilter(415, "Захват мира"), --ID: 315
			CheckboxFilter(4269, "Зачарованные"), --ID: 4169
			CheckboxFilter(1738, "Звери"), --ID: 1638
			CheckboxFilter(2106, "Зверодевочки"), --ID: 2006
			CheckboxFilter(1118, "Зверолюди"), --ID: 1018
			CheckboxFilter(182, "Земля"), --ID: 82
			CheckboxFilter(7868, "Злая организация"), --ID: 7768
			CheckboxFilter(1612, "Зло"), --ID: 1512
			CheckboxFilter(1160, "Злодей"), --ID: 1060
			CheckboxFilter(2476, "Злодейка"), --ID: 2376
			CheckboxFilter(716, "Злой главный герой"), --ID: 616
			CheckboxFilter(7209, "Злые боги"), --ID: 7109
			CheckboxFilter(3343, "Злые персонажи"), --ID: 3243
			CheckboxFilter(5821, "Змей"), --ID: 5721
			CheckboxFilter(1441, "Знаменитости"), --ID: 1341
			CheckboxFilter(1511, "Знание медицины"), --ID: 1411
			CheckboxFilter(1928, "Золотой дождь"), --ID: 1828
			CheckboxFilter(3080, "Золушка"), --ID: 2980
			CheckboxFilter(1843, "Зомби"), --ID: 1743
			CheckboxFilter(1012, "Зомби апокалипсис"), --ID: 912
			CheckboxFilter(3151, "Зона 51"), --ID: 3051
			CheckboxFilter(475, "Зооморфы"), --ID: 375
			CheckboxFilter(1265, "Зоофилия"), --ID: 1165
			CheckboxFilter(6836, "Зорро"), --ID: 6736
			CheckboxFilter(1558, "Зрелые женщины"), --ID: 1458
			CheckboxFilter(763, "Игра"), --ID: 663
			CheckboxFilter(2282, "Игра на выживание"), --ID: 2182
			CheckboxFilter(484, "Игровая система"), --ID: 384
			CheckboxFilter(820, "Игровые элементы"), --ID: 720
			CheckboxFilter(751, "Извращения"), --ID: 651
			CheckboxFilter(1974, "Измена"), --ID: 1874
			CheckboxFilter(1213, "Изменение характера"), --ID: 1113
			CheckboxFilter(359, "Изменения внешности"), --ID: 259
			CheckboxFilter(1180, "Изменения личности"), --ID: 1080
			CheckboxFilter(1383, "Изнасилование"), --ID: 1283
			CheckboxFilter(226, "Изобретения"), --ID: 126
			CheckboxFilter(7067, "Изуку мидория"), --ID: 6967
			CheckboxFilter(967, "Император"), --ID: 867
			CheckboxFilter(812, "Империи"), --ID: 712
			CheckboxFilter(1816, "Империя"), --ID: 1716
			CheckboxFilter(2173, "Инвалидность"), --ID: 2073
			CheckboxFilter(243, "Инквизитор"), --ID: 143
			CheckboxFilter(3364, "Инкуб"), --ID: 3264
			CheckboxFilter(309, "Инопланетное вторжение"), --ID: 209
			CheckboxFilter(966, "Инопланетяне"), --ID: 866
			CheckboxFilter(572, "Интерактив с читателями"), --ID: 472
			CheckboxFilter(7474, "Интересный сюжет"), --ID: 7374
			CheckboxFilter(839, "Интернет"), --ID: 739
			CheckboxFilter(3550, "Интимные сцены"), --ID: 3450
			CheckboxFilter(417, "Интрига"), --ID: 317
			CheckboxFilter(1109, "Интриги и заговоры"), --ID: 1009
			CheckboxFilter(2034, "Инцест"), --ID: 1934
			CheckboxFilter(135, "Иные миры"), --ID: 35
			CheckboxFilter(3079, "Исекай"), --ID: 2979
			CheckboxFilter(2000, "Искусственный интеллект"), --ID: 1900
			CheckboxFilter(1726, "Исследование"), --ID: 1626
			CheckboxFilter(673, "Исторический роман"), --ID: 573
			CheckboxFilter(4656, "Итачи учиха"), --ID: 4556
			CheckboxFilter(7354, "Ичиго"), --ID: 7254
			CheckboxFilter(6929, "Йода"), --ID: 6829
			CheckboxFilter(6855, "Йоруичи"), --ID: 6755
			CheckboxFilter(8162, "Калипсо"), --ID: 8062
			CheckboxFilter(2349, "Каннибализм"), --ID: 2249
			CheckboxFilter(6401, "Капитан америка"), --ID: 6301
			CheckboxFilter(7573, "Каракура"), --ID: 7473
			CheckboxFilter(1657, "Карточная игра"), --ID: 1557
			CheckboxFilter(7054, "Кастиэль"), --ID: 6954
			CheckboxFilter(4034, "Кафе"), --ID: 3934
			CheckboxFilter(7796, "Кацуки бакуго"), --ID: 7696
			CheckboxFilter(1807, "Квесты"), --ID: 1707
			CheckboxFilter(1714, "Киберпанк"), --ID: 1614
			CheckboxFilter(2084, "Киберспорт"), --ID: 1984
			CheckboxFilter(7226, "Кино"), --ID: 7126
			CheckboxFilter(3862, "Китай"), --ID: 3762
			CheckboxFilter(341, "Кицунэ"), --ID: 241
			CheckboxFilter(934, "Кланы"), --ID: 834
			CheckboxFilter(1724, "Клоны"), --ID: 1624
			CheckboxFilter(1168, "Книги"), --ID: 1068
			CheckboxFilter(621, "Книжный червь"), --ID: 521
			CheckboxFilter(2781, "Колдовство"), --ID: 2681
			CheckboxFilter(5158, "Колледж"), --ID: 5058
			CheckboxFilter(2688, "Коллекционер"), --ID: 2588
			CheckboxFilter(1728, "Кольцо"), --ID: 1628
			CheckboxFilter(1530, "Комедия"), --ID: 1430
			CheckboxFilter(1142, "Коммунисты"), --ID: 1042
			CheckboxFilter(2927, "Коноха"), --ID: 2827
			CheckboxFilter(4404, "Контракт"), --ID: 4304
			CheckboxFilter(585, "Контроль разума"), --ID: 485
			CheckboxFilter(441, "Конфеты"), --ID: 341
			CheckboxFilter(4689, "Кончил внутрь"), --ID: 4589
			CheckboxFilter(2668, "Копрофилия"), --ID: 2568
			CheckboxFilter(6635, "Корейцы"), --ID: 6535
			CheckboxFilter(2543, "Корея"), --ID: 2443
			CheckboxFilter(155, "Королевская власть"), --ID: 55
			CheckboxFilter(376, "Королевская семья"), --ID: 276
			CheckboxFilter(1795, "Королевство"), --ID: 1695
			CheckboxFilter(339, "Короткий рассказ"), --ID: 239
			CheckboxFilter(931, "Коррупция"), --ID: 831
			CheckboxFilter(2345, "Космическая опера"), --ID: 2245
			CheckboxFilter(5960, "Космические рейнджеры"), --ID: 5860
			CheckboxFilter(429, "Космос"), --ID: 329
			CheckboxFilter(5271, "Кот"), --ID: 5171
			CheckboxFilter(1259, "Кража навыков"), --ID: 1159
			CheckboxFilter(286, "Красивая главная героиня"), --ID: 186
			CheckboxFilter(166, "Красивые женщины"), --ID: 66
			CheckboxFilter(5887, "Красивые персонажи "), --ID: 5787
			CheckboxFilter(995, "Красивый главный герой"), --ID: 895
			CheckboxFilter(1699, "Крафт"), --ID: 1599
			CheckboxFilter(7852, "Кровь и расчлененка"), --ID: 7752
			CheckboxFilter(175, "Кроссовер"), --ID: 75
			CheckboxFilter(2365, "Ксенофилия"), --ID: 2265
			CheckboxFilter(1020, "Ктулху"), --ID: 920
			CheckboxFilter(953, "Кузнец"), --ID: 853
			CheckboxFilter(3185, "Кукла"), --ID: 3085
			CheckboxFilter(2330, "Кулинария"), --ID: 2230
			CheckboxFilter(2001, "Культивация"), --ID: 1901
			CheckboxFilter(1960, "Культивирование"), --ID: 1860
			CheckboxFilter(4751, "Кунилингус"), --ID: 4651
			CheckboxFilter(5809, "Курама"), --ID: 5709
			CheckboxFilter(6234, "Курилин"), --ID: 6134
			CheckboxFilter(5322, "Кушина узумаки"), --ID: 5222
			CheckboxFilter(6163, "Лавкрафт"), --ID: 6063
			CheckboxFilter(6535, "Лара крофт"), --ID: 6435
			CheckboxFilter(3236, "Лгбт"), --ID: 3136
			CheckboxFilter(5807, "Легенда о зельде"), --ID: 5707
			CheckboxFilter(1616, "Ленивый главный герой"), --ID: 1516
			CheckboxFilter(7569, "Леон золдик"), --ID: 7469
			CheckboxFilter(6745, "Лес"), --ID: 6645
			CheckboxFilter(662, "Лечебная магия"), --ID: 562
			CheckboxFilter(605, "Литрпг"), --ID: 505
			CheckboxFilter(1825, "Локи"), --ID: 1725
			CheckboxFilter(1676, "Лоли"), --ID: 1576
			CheckboxFilter(5089, "Лопата"), --ID: 4989
			CheckboxFilter(7497, "Лориен"), --ID: 7397
			CheckboxFilter(6210, "Лошади"), --ID: 6110
			CheckboxFilter(3620, "Лунатизм"), --ID: 3520
			CheckboxFilter(374, "Луффи"), --ID: 274
			CheckboxFilter(1138, "Лучник"), --ID: 1038
			CheckboxFilter(7853, "Любовный интерес влюбляется первым"), --ID: 7753
			CheckboxFilter(2209, "Любовный треугольник"), --ID: 2109
			CheckboxFilter(2397, "Любовь"), --ID: 2297
			CheckboxFilter(7848, "Любовь с первого взгляда"), --ID: 7748
			CheckboxFilter(2799, "Любящие родители"), --ID: 2699
			CheckboxFilter(3672, "Люди"), --ID: 3572
			CheckboxFilter(5983, "Люцифер"), --ID: 5883
			CheckboxFilter(880, "Маг"), --ID: 780
			CheckboxFilter(4862, "Магазин"), --ID: 4762
			CheckboxFilter(158, "Маги"), --ID: 58
			CheckboxFilter(6888, "Магическая академия"), --ID: 6788
			CheckboxFilter(784, "Магические звери"), --ID: 684
			CheckboxFilter(1748, "Магические предметы"), --ID: 1648
			CheckboxFilter(678, "Магический мир"), --ID: 578
			CheckboxFilter(250, "Магия"), --ID: 150
			CheckboxFilter(6550, "Магия воды"), --ID: 6450
			CheckboxFilter(7727, "Магия воздуха"), --ID: 7627
			CheckboxFilter(7726, "Магия земли"), --ID: 7626
			CheckboxFilter(207, "Магия и технология"), --ID: 107
			CheckboxFilter(8076, "Магия крови"), --ID: 7976
			CheckboxFilter(1479, "Магия льда"), --ID: 1379
			CheckboxFilter(7725, "Магия огня"), --ID: 7625
			CheckboxFilter(985, "Магия призыва"), --ID: 885
			CheckboxFilter(6326, "Магия природы"), --ID: 6226
			CheckboxFilter(7773, "Магия стихий"), --ID: 7673
			CheckboxFilter(3696, "Магия тьмы"), --ID: 3596
			CheckboxFilter(3029, "Мадара"), --ID: 2929
			CheckboxFilter(2061, "Мазохизм"), --ID: 1961
			CheckboxFilter(112, "Мама"), --ID: 12
			CheckboxFilter(7994, "Мама и дочь"), --ID: 7894
			CheckboxFilter(7995, "Мама и сын"), --ID: 7895
			CheckboxFilter(2564, "Манга"), --ID: 2464
			CheckboxFilter(1032, "Манипуляция временем"), --ID: 932
			CheckboxFilter(2126, "Маньяк"), --ID: 2026
			CheckboxFilter(4035, "Маргери тирелл"), --ID: 3935
			CheckboxFilter(3275, "Марионетки"), --ID: 3175
			CheckboxFilter(4113, "Марс"), --ID: 4013
			CheckboxFilter(694, "Марти стью"), --ID: 594
			CheckboxFilter(3289, "Мастер на все руки"), --ID: 3189
			CheckboxFilter(3178, "Мастурбация"), --ID: 3078
			CheckboxFilter(7297, "Матриархат"), --ID: 7197
			CheckboxFilter(8046, "Мать и сестры"), --ID: 7946
			CheckboxFilter(453, "Мафия"), --ID: 353
			CheckboxFilter(4764, "Мачеха"), --ID: 4664
			CheckboxFilter(3422, "Мегаполис"), --ID: 3322
			CheckboxFilter(541, "Медицина"), --ID: 441
			CheckboxFilter(7562, "Медленное развитие истории"), --ID: 7462
			CheckboxFilter(3589, "Межрасовый секс"), --ID: 3489
			CheckboxFilter(7324, "Мелиодас"), --ID: 7224
			CheckboxFilter(1607, "Мелодрама"), --ID: 1507
			CheckboxFilter(468, "Менеджмент"), --ID: 368
			CheckboxFilter(4077, "Мерлин"), --ID: 3977
			CheckboxFilter(1318, "Месть"), --ID: 1218
			CheckboxFilter(2403, "Меха"), --ID: 2303
			CheckboxFilter(148, "Меч"), --ID: 48
			CheckboxFilter(1069, "Мечники"), --ID: 969
			CheckboxFilter(627, "Мечта"), --ID: 527
			CheckboxFilter(4369, "Мизуки"), --ID: 4269
			CheckboxFilter(3962, "Микото"), --ID: 3862
			CheckboxFilter(234, "Милая главная героиня"), --ID: 134
			CheckboxFilter(2087, "Милф"), --ID: 1987
			CheckboxFilter(2778, "Милый главный герой"), --ID: 2678
			CheckboxFilter(5806, "Мимик"), --ID: 5706
			CheckboxFilter(7795, "Мина ашидо"), --ID: 7695
			CheckboxFilter(5323, "Минато намикадзе"), --ID: 5223
			CheckboxFilter(3389, "Минет"), --ID: 3289
			CheckboxFilter(1870, "Мир будущего"), --ID: 1770
			CheckboxFilter(1371, "Мир меча и магии"), --ID: 1271
			CheckboxFilter(665, "Мистер пропер"), --ID: 565
			CheckboxFilter(610, "Мистика"), --ID: 510
			CheckboxFilter(1978, "Мифические существа"), --ID: 1878
			CheckboxFilter(4563, "Мифы и легенды"), --ID: 4463
			CheckboxFilter(1623, "Младшая сестра"), --ID: 1523
			CheckboxFilter(720, "Мморпг"), --ID: 620
			CheckboxFilter(1291, "Много главных героев"), --ID: 1191
			CheckboxFilter(5418, "Много крови"), --ID: 5318
			CheckboxFilter(1639, "Много персонажей"), --ID: 1539
			CheckboxFilter(132, "Множество королевств"), --ID: 32
			CheckboxFilter(5557, "Модерн"), --ID: 5457
			CheckboxFilter(4538, "Мокутон"), --ID: 4438
			CheckboxFilter(5569, "Молоко"), --ID: 5469
			CheckboxFilter(3690, "Монархия"), --ID: 3590
			CheckboxFilter(407, "Монстры"), --ID: 307
			CheckboxFilter(1022, "Море"), --ID: 922
			CheckboxFilter(1242, "Моритика ринносукэ"), --ID: 1142
			CheckboxFilter(5961, "Мортал комбат"), --ID: 5861
			CheckboxFilter(1059, "Мошенник"), --ID: 959
			CheckboxFilter(101, "Мрачный мир"), --ID: 1
			CheckboxFilter(1143, "Мужская беременность"), --ID: 1043
			CheckboxFilter(131, "Мужчина протагонист"), --ID: 31
			CheckboxFilter(1283, "Музыка"), --ID: 1183
			CheckboxFilter(7510, "Мультивселенная"), --ID: 7410
			CheckboxFilter(7442, "Мурим"), --ID: 7342
			CheckboxFilter(2492, "Мутанты"), --ID: 2392
			CheckboxFilter(129, "Мутация"), --ID: 29
			CheckboxFilter(1603, "Мясо"), --ID: 1503
			CheckboxFilter(126, "На реальных событиях"), --ID: 26
			CheckboxFilter(515, "Навыки"), --ID: 415
			CheckboxFilter(5321, "Нагато узумаки"), --ID: 5221
			CheckboxFilter(1768, "Наемники"), --ID: 1668
			CheckboxFilter(5469, "Назарик"), --ID: 5369
			CheckboxFilter(259, "Наивный главный герой"), --ID: 159
			CheckboxFilter(4967, "Наложница"), --ID: 4867
			CheckboxFilter(2432, "Наноботы"), --ID: 2332
			CheckboxFilter(1536, "Наркотики"), --ID: 1436
			CheckboxFilter(7277, "Наруто"), --ID: 7177
			CheckboxFilter(5866, "Наруто и хината"), --ID: 5766
			CheckboxFilter(1540, "Насилие и жестокость"), --ID: 1440
			CheckboxFilter(2250, "Наука"), --ID: 2150
			CheckboxFilter(2344, "Научная фантастика"), --ID: 2244
			CheckboxFilter(5656, "Национализм"), --ID: 5556
			CheckboxFilter(5926, "Нацу"), --ID: 5826
			CheckboxFilter(6756, "Нацуки субару"), --ID: 6656
			CheckboxFilter(4020, "Начальная школа"), --ID: 3920
			CheckboxFilter(1914, "Наши дни"), --ID: 1814
			CheckboxFilter(142, "Не всесильный главный герой"), --ID: 42
			CheckboxFilter(1711, "Не по канону"), --ID: 1611
			CheckboxFilter(5835, "Неверность"), --ID: 5735
			CheckboxFilter(6111, "Невеста"), --ID: 6011
			CheckboxFilter(3199, "Неджи хьюга"), --ID: 3099
			CheckboxFilter(143, "Недооценённый главный герой"), --ID: 43
			CheckboxFilter(2049, "Нежить"), --ID: 1949
			CheckboxFilter(7541, "Некромаг"), --ID: 7441
			CheckboxFilter(2014, "Некромант"), --ID: 1914
			CheckboxFilter(854, "Некромантия"), --ID: 754
			CheckboxFilter(1385, "Некрофилия"), --ID: 1285
			CheckboxFilter(260, "Ненормативная лексика"), --ID: 160
			CheckboxFilter(167, "Необычные герои"), --ID: 67
			CheckboxFilter(7586, "Нет людей"), --ID: 7486
			CheckboxFilter(503, "Нетораре"), --ID: 403
			CheckboxFilter(5493, "Нетори"), --ID: 5393
			CheckboxFilter(7864, "Нефилимы"), --ID: 7764
			CheckboxFilter(5012, "Нецензурная лексика"), --ID: 4912
			CheckboxFilter(4659, "Нечисть"), --ID: 4559
			CheckboxFilter(6404, "Ник фьюри"), --ID: 6304
			CheckboxFilter(2454, "Ниндзюцу"), --ID: 2354
			CheckboxFilter(1430, "Ниндзя"), --ID: 1330
			CheckboxFilter(2205, "Новелла"), --ID: 2105
			CheckboxFilter(2333, "Нудизм"), --ID: 2233
			CheckboxFilter(247, "Нэко"), --ID: 147
			CheckboxFilter(6930, "Оби ван кеноби"), --ID: 6830
			CheckboxFilter(2914, "Обито учиха"), --ID: 2814
			CheckboxFilter(153, "Оборотни"), --ID: 53
			CheckboxFilter(3403, "Обратный гарем"), --ID: 3303
			CheckboxFilter(6198, "Овощ"), --ID: 6098
			CheckboxFilter(3255, "Огнестрельное оружие"), --ID: 3155
			CheckboxFilter(808, "Одержимость"), --ID: 708
			CheckboxFilter(6598, "Один в поле воин"), --ID: 6498
			CheckboxFilter(305, "Омегаверс"), --ID: 205
			CheckboxFilter(1665, "Онлайн игра"), --ID: 1565
			CheckboxFilter(949, "Ооками теппей"), --ID: 849
			CheckboxFilter(705, "Оральный секс"), --ID: 605
			CheckboxFilter(1074, "Оргия"), --ID: 974
			CheckboxFilter(7841, "Оригинальные персонажи"), --ID: 7741
			CheckboxFilter(1697, "Орки"), --ID: 1597
			CheckboxFilter(225, "Оружие"), --ID: 125
			CheckboxFilter(702, "Основано на видео игре"), --ID: 602
			CheckboxFilter(3004, "Особые способности"), --ID: 2904
			CheckboxFilter(1001, "От бедности к богатству"), --ID: 901
			CheckboxFilter(218, "От слабого до сильного"), --ID: 118
			CheckboxFilter(2979, "Отель"), --ID: 2879
			CheckboxFilter(3390, "Отец"), --ID: 3290
			CheckboxFilter(498, "Отношения"), --ID: 398
			CheckboxFilter(7506, "Отношения человек/нечеловек"), --ID: 7406
			CheckboxFilter(3560, "Офис"), --ID: 3460
			CheckboxFilter(2363, "Охотники"), --ID: 2263
			CheckboxFilter(5201, "Оцуцуки"), --ID: 5101
			CheckboxFilter(2462, "Ошейник"), --ID: 2362
			CheckboxFilter(8148, "Ояш"), --ID: 8048
			CheckboxFilter(7123, "Падчерица"), --ID: 7023
			CheckboxFilter(284, "Падший ангел"), --ID: 184
			CheckboxFilter(3660, "Пайзури"), --ID: 3560
			CheckboxFilter(952, "Палач"), --ID: 852
			CheckboxFilter(2782, "Палочка"), --ID: 2682
			CheckboxFilter(4460, "Пандорум"), --ID: 4360
			CheckboxFilter(4406, "Пансексуалы"), --ID: 4306
			CheckboxFilter(7747, "Папа и дочь"), --ID: 7647
			CheckboxFilter(1313, "Паразит"), --ID: 1213
			CheckboxFilter(2192, "Параллельный мир"), --ID: 2092
			CheckboxFilter(719, "Парень"), --ID: 619
			CheckboxFilter(3491, "Паркур"), --ID: 3391
			CheckboxFilter(998, "Пародия"), --ID: 898
			CheckboxFilter(555, "Пасхалки"), --ID: 455
			CheckboxFilter(2309, "Паук"), --ID: 2209
			CheckboxFilter(7152, "Педофилия"), --ID: 7052
			CheckboxFilter(5173, "Пекарь"), --ID: 5073
			CheckboxFilter(369, "Первая книга"), --ID: 269
			CheckboxFilter(740, "Первая любовь"), --ID: 640
			CheckboxFilter(1565, "Первый раз"), --ID: 1465
			CheckboxFilter(124, "Переводы"), --ID: 24
			CheckboxFilter(1696, "Перевоплощение"), --ID: 1596
			CheckboxFilter(192, "Перевоплощение в игровом мире"), --ID: 92
			CheckboxFilter(1388, "Перемещение в другой мир"), --ID: 1288
			CheckboxFilter(246, "Перемещение во времени"), --ID: 146
			CheckboxFilter(994, "Перерождение"), --ID: 894
			CheckboxFilter(1211, "Перерождение в демона"), --ID: 1111
			CheckboxFilter(6967, "Перерождение в дракона"), --ID: 6867
			CheckboxFilter(5719, "Перерождение в злодейку"), --ID: 5619
			CheckboxFilter(849, "Перерождение в злодея"), --ID: 749
			CheckboxFilter(209, "Перерождение в ином мире"), --ID: 109
			CheckboxFilter(1017, "Перерождение в монстра"), --ID: 917
			CheckboxFilter(435, "Перерождений"), --ID: 335
			CheckboxFilter(913, "Переселение"), --ID: 813
			CheckboxFilter(1964, "Переселение души"), --ID: 1864
			CheckboxFilter(6429, "Перси джексон"), --ID: 6329
			CheckboxFilter(5621, "Пилот"), --ID: 5521
			CheckboxFilter(1631, "Пилюли"), --ID: 1531
			CheckboxFilter(1679, "Пират"), --ID: 1579
			CheckboxFilter(180, "Пирог"), --ID: 80
			CheckboxFilter(834, "Писатель"), --ID: 734
			CheckboxFilter(5016, "Пистолеты"), --ID: 4916
			CheckboxFilter(940, "Письмо"), --ID: 840
			CheckboxFilter(3222, "Питомцы"), --ID: 3122
			CheckboxFilter(162, "Планомерное развитие событий"), --ID: 62
			CheckboxFilter(4997, "Пленница"), --ID: 4897
			CheckboxFilter(4939, "Плети"), --ID: 4839
			CheckboxFilter(4343, "Пляж"), --ID: 4243
			CheckboxFilter(758, "Повар"), --ID: 658
			CheckboxFilter(1154, "Повествование от первого лица"), --ID: 1054
			CheckboxFilter(700, "Повествование от разных лиц"), --ID: 600
			CheckboxFilter(2216, "Повествование от третьего лица"), --ID: 2116
			CheckboxFilter(902, "Повседневность"), --ID: 802
			CheckboxFilter(597, "Подавитель"), --ID: 497
			CheckboxFilter(898, "Подземелье"), --ID: 798
			CheckboxFilter(736, "Подростки"), --ID: 636
			CheckboxFilter(5904, "Подруга"), --ID: 5804
			CheckboxFilter(4600, "Подчинение и унижение"), --ID: 4500
			CheckboxFilter(2940, "Покемоны"), --ID: 2840
			CheckboxFilter(1400, "Полиамория"), --ID: 1300
			CheckboxFilter(1436, "Полигамия"), --ID: 1336
			CheckboxFilter(1413, "Политика"), --ID: 1313
			CheckboxFilter(2007, "Полицейский"), --ID: 1907
			CheckboxFilter(7270, "Полубог"), --ID: 7170
			CheckboxFilter(1099, "Полукровка"), --ID: 999
			CheckboxFilter(2373, "Полулюди"), --ID: 2273
			CheckboxFilter(1304, "Поношенные трусики"), --ID: 1204
			CheckboxFilter(2496, "Попаданец"), --ID: 2396
			CheckboxFilter(785, "Попаданец в другой мир"), --ID: 685
			CheckboxFilter(6566, "Попаданец в игру"), --ID: 6466
			CheckboxFilter(7057, "Попадание в книгу"), --ID: 6957
			CheckboxFilter(4123, "Порно"), --ID: 4023
			CheckboxFilter(1179, "Постапокалипсис"), --ID: 1079
			CheckboxFilter(5979, "Потеря девственности"), --ID: 5879
			CheckboxFilter(7552, "Похищение"), --ID: 7452
			CheckboxFilter(1220, "Поэзия"), --ID: 1120
			CheckboxFilter(2361, "Правитель"), --ID: 2261
			CheckboxFilter(3510, "Превращения в животных"), --ID: 3410
			CheckboxFilter(2155, "Преданный любовный интерес"), --ID: 2055
			CheckboxFilter(170, "Предательство"), --ID: 70
			CheckboxFilter(4434, "Президент"), --ID: 4334
			CheckboxFilter(4149, "Преступник"), --ID: 4049
			CheckboxFilter(1065, "Преступный мир"), --ID: 965
			CheckboxFilter(611, "Призрак"), --ID: 511
			CheckboxFilter(432, "Призыв"), --ID: 332
			CheckboxFilter(881, "Призыв в другой мир"), --ID: 781
			CheckboxFilter(512, "Призыв существ"), --ID: 412
			CheckboxFilter(1064, "Приключения"), --ID: 964
			CheckboxFilter(5445, "Приложение на телефоне"), --ID: 5345
			CheckboxFilter(3054, "Принудительный брак"), --ID: 2954
			CheckboxFilter(1542, "Принуждение"), --ID: 1442
			CheckboxFilter(462, "Принц"), --ID: 362
			CheckboxFilter(2503, "Принцесса"), --ID: 2403
			CheckboxFilter(2438, "Приручение мостров"), --ID: 2338
			CheckboxFilter(5285, "Прислуга"), --ID: 5185
			CheckboxFilter(373, "Пришельцы"), --ID: 273
			CheckboxFilter(2112, "Проза"), --ID: 2012
			CheckboxFilter(1170, "Прокачка"), --ID: 1070
			CheckboxFilter(1447, "Проклятия"), --ID: 1347
			CheckboxFilter(1811, "Проработанный мир"), --ID: 1711
			CheckboxFilter(7862, "Пророчество"), --ID: 7762
			CheckboxFilter(3759, "Псайкеры"), --ID: 3659
			CheckboxFilter(5316, "Псионика"), --ID: 5216
			CheckboxFilter(7069, "Психбольница"), --ID: 6969
			CheckboxFilter(2545, "Психические расстройства"), --ID: 2445
			CheckboxFilter(3518, "Психологические травмы"), --ID: 3418
			CheckboxFilter(117, "Психология"), --ID: 17
			CheckboxFilter(7960, "Публичный дом"), --ID: 7860
			CheckboxFilter(6747, "Публичный секс"), --ID: 6647
			CheckboxFilter(110, "Путешествие в другой мир"), --ID: 10
			CheckboxFilter(4386, "Пух"), --ID: 4286
			CheckboxFilter(7334, "Пушечное мясо"), --ID: 7234
			CheckboxFilter(1856, "Пытки"), --ID: 1756
			CheckboxFilter(1755, "Пьяный мастер"), --ID: 1655
			CheckboxFilter(7511, "Пэнси паркинсон"), --ID: 7411
			CheckboxFilter(1077, "Раб"), --ID: 977
			CheckboxFilter(1340, "Рабы"), --ID: 1240
			CheckboxFilter(4090, "Разведение животных"), --ID: 3990
			CheckboxFilter(308, "Развитие"), --ID: 208
			CheckboxFilter(1880, "Развитие персонажа"), --ID: 1780
			CheckboxFilter(7303, "Развитие поселения"), --ID: 7203
			CheckboxFilter(1975, "Развитие технологий"), --ID: 1875
			CheckboxFilter(2024, "Разврат"), --ID: 1924
			CheckboxFilter(2162, "Раздвоение личности"), --ID: 2062
			CheckboxFilter(1288, "Разные расы"), --ID: 1188
			CheckboxFilter(2157, "Разорванная помолвка"), --ID: 2057
			CheckboxFilter(2433, "Разработчик"), --ID: 2333
			CheckboxFilter(1668, "Ранги"), --ID: 1568
			CheckboxFilter(1864, "Ранобэ"), --ID: 1764
			CheckboxFilter(3654, "Расизм"), --ID: 3554
			CheckboxFilter(507, "Растение"), --ID: 407
			CheckboxFilter(7225, "Расчленение"), --ID: 7125
			CheckboxFilter(1280, "Реализм"), --ID: 1180
			CheckboxFilter(306, "Реанкарнация"), --ID: 206
			CheckboxFilter(2981, "Ребенок"), --ID: 2881
			CheckboxFilter(393, "Ревность"), --ID: 293
			CheckboxFilter(4096, "Революция"), --ID: 3996
			CheckboxFilter(1402, "Реинкарнация"), --ID: 1302
			CheckboxFilter(2280, "Реинкарнация в другом мире"), --ID: 2180
			CheckboxFilter(404, "Реинкарнация в игровой мир"), --ID: 304
			CheckboxFilter(5247, "Рейджер"), --ID: 5147
			CheckboxFilter(2284, "Религия"), --ID: 2184
			CheckboxFilter(6755, "Рем"), --ID: 6655
			CheckboxFilter(1583, "Ремесленник"), --ID: 1483
			CheckboxFilter(5803, "Ремонт"), --ID: 5703
			CheckboxFilter(3595, "Репликаторы"), --ID: 3495
			CheckboxFilter(7619, "Ресторан"), --ID: 7519
			CheckboxFilter(7050, "Риас гремори"), --ID: 6950
			CheckboxFilter(712, "Рим"), --ID: 612
			CheckboxFilter(4330, "Риннеган"), --ID: 4230
			CheckboxFilter(1333, "Ритуал"), --ID: 1233
			CheckboxFilter(4111, "Робот"), --ID: 4011
			CheckboxFilter(567, "Роботы"), --ID: 467
			CheckboxFilter(7102, "Рок ли"), --ID: 7002
			CheckboxFilter(7480, "Рокси"), --ID: 7380
			CheckboxFilter(1125, "Романтика"), --ID: 1025
			CheckboxFilter(4379, "Рон уизли"), --ID: 4279
			CheckboxFilter(1690, "Ророноа зоро"), --ID: 1590
			CheckboxFilter(1135, "Росомаха"), --ID: 1035
			CheckboxFilter(2246, "Российская империя"), --ID: 2146
			CheckboxFilter(4346, "Россия"), --ID: 4246
			CheckboxFilter(7479, "Рудеус"), --ID: 7379
			CheckboxFilter(2493, "Руны"), --ID: 2393
			CheckboxFilter(3227, "Русалки"), --ID: 3127
			CheckboxFilter(2116, "Русь"), --ID: 2016
			CheckboxFilter(2002, "Рыцари"), --ID: 1902
			CheckboxFilter(2923, "Рэо хатаке"), --ID: 2823
			CheckboxFilter(6236, "Сабли"), --ID: 6136
			CheckboxFilter(6902, "Сайян"), --ID: 6802
			CheckboxFilter(2615, "Сакура"), --ID: 2515
			CheckboxFilter(1692, "Самец"), --ID: 1592
			CheckboxFilter(4412, "Самоубийство"), --ID: 4312
			CheckboxFilter(676, "Самураи"), --ID: 576
			CheckboxFilter(4025, "Санса старк"), --ID: 3925
			CheckboxFilter(4758, "Сарказм"), --ID: 4658
			CheckboxFilter(7337, "Саске"), --ID: 7237
			CheckboxFilter(315, "Сатира"), --ID: 215
			CheckboxFilter(7467, "Сборник"), --ID: 7367
			CheckboxFilter(1624, "Свадьба"), --ID: 1524
			CheckboxFilter(1155, "Сверхсила"), --ID: 1055
			CheckboxFilter(1174, "Сверхъестественное"), --ID: 1074
			CheckboxFilter(614, "Свингеры"), --ID: 514
			CheckboxFilter(5422, "Свинцовые книги"), --ID: 5322
			CheckboxFilter(4606, "Связывание"), --ID: 4506
			CheckboxFilter(161, "Священик"), --ID: 61
			CheckboxFilter(5883, "Северус снейп"), --ID: 5783
			CheckboxFilter(2319, "Сёдзе"), --ID: 2219
			CheckboxFilter(2572, "Секс"), --ID: 2472
			CheckboxFilter(251, "Секс без проникновения"), --ID: 151
			CheckboxFilter(1224, "Секс игрушки"), --ID: 1124
			CheckboxFilter(7407, "Секс по согласию"), --ID: 7307
			CheckboxFilter(7274, "Секс рабыня"), --ID: 7174
			CheckboxFilter(7557, "Секс с близнецами"), --ID: 7457
			CheckboxFilter(6173, "Секс с монстрами"), --ID: 6073
			CheckboxFilter(2670, "Секс с учителем"), --ID: 2570
			CheckboxFilter(7365, "Секса будет много"), --ID: 7265
			CheckboxFilter(988, "Сексуальные и психологические отклонения"), --ID: 888
			CheckboxFilter(1334, "Секты"), --ID: 1234
			CheckboxFilter(7598, "Селфцест"), --ID: 7498
			CheckboxFilter(887, "Сельское хозяйство"), --ID: 787
			CheckboxFilter(1035, "Семейный конфликт"), --ID: 935
			CheckboxFilter(828, "Семья"), --ID: 728
			CheckboxFilter(6169, "Сенджу"), --ID: 6069
			CheckboxFilter(2158, "Сёнэн"), --ID: 2058
			CheckboxFilter(7743, "Сёнэн-ай"), --ID: 7643
			CheckboxFilter(361, "Серийный убийца"), --ID: 261
			CheckboxFilter(2442, "Сестра"), --ID: 2342
			CheckboxFilter(1119, "Сила глаза"), --ID: 1019
			CheckboxFilter(7392, "Сильная героиня"), --ID: 7292
			CheckboxFilter(2094, "Сильная главная героиня"), --ID: 1994
			CheckboxFilter(670, "Сильный главный герой"), --ID: 570
			CheckboxFilter(7481, "Сильфиетта"), --ID: 7381
			CheckboxFilter(2748, "Симбиот"), --ID: 2648
			CheckboxFilter(7755, "Сириус блэк"), --ID: 7655
			CheckboxFilter(397, "Сирота"), --ID: 297
			CheckboxFilter(351, "Система"), --ID: 251
			CheckboxFilter(2274, "Система уровней"), --ID: 2174
			CheckboxFilter(116, "Сиськи"), --ID: 16
			CheckboxFilter(1718, "Ситх"), --ID: 1618
			CheckboxFilter(3670, "Сказка"), --ID: 3570
			CheckboxFilter(4132, "Скайрим"), --ID: 4032
			CheckboxFilter(6928, "Скайуокер"), --ID: 6828
			CheckboxFilter(4201, "Сквиб"), --ID: 4101
			CheckboxFilter(4626, "Сквирт"), --ID: 4526
			CheckboxFilter(1415, "Скелет"), --ID: 1315
			CheckboxFilter(3517, "Скрытые способности"), --ID: 3417
			CheckboxFilter(1278, "Скульптор"), --ID: 1178
			CheckboxFilter(5905, "Слабая главная героиня"), --ID: 5805
			CheckboxFilter(831, "Слабый главный герой"), --ID: 731
			CheckboxFilter(2268, "Славяне"), --ID: 2168
			CheckboxFilter(7079, "Слизерин"), --ID: 6979
			CheckboxFilter(1195, "Слизь"), --ID: 1095
			CheckboxFilter(3586, "Служанка"), --ID: 3486
			CheckboxFilter(4517, "Слэш"), --ID: 4417
			CheckboxFilter(557, "Смартфон"), --ID: 457
			CheckboxFilter(2242, "Смена пола"), --ID: 2142
			CheckboxFilter(1879, "Смерть"), --ID: 1779
			CheckboxFilter(1630, "Смерть основного персонажа"), --ID: 1530
			CheckboxFilter(6209, "Собаки"), --ID: 6109
			CheckboxFilter(8094, "Соблазн"), --ID: 7994
			CheckboxFilter(2390, "Соблазнение"), --ID: 2290
			CheckboxFilter(668, "Современность"), --ID: 568
			CheckboxFilter(1088, "Современные знания"), --ID: 988
			CheckboxFilter(3126, "Сожительство"), --ID: 3026
			CheckboxFilter(2092, "Создание армии"), --ID: 1992
			CheckboxFilter(1597, "Создание королевства"), --ID: 1497
			CheckboxFilter(916, "Создание пилюль"), --ID: 816
			CheckboxFilter(1145, "Создатель"), --ID: 1045
			CheckboxFilter(6621, "Сокровища"), --ID: 6521
			CheckboxFilter(2994, "Сокрытие истинной личности"), --ID: 2894
			CheckboxFilter(5837, "Сома и эрина"), --ID: 5737
			CheckboxFilter(7799, "Соперничество"), --ID: 7699
			CheckboxFilter(4175, "Соседи"), --ID: 4075
			CheckboxFilter(6439, "Сотрудник"), --ID: 6339
			CheckboxFilter(7718, "Социология"), --ID: 7618
			CheckboxFilter(336, "Спокойная главная героиня"), --ID: 236
			CheckboxFilter(1756, "Спокойный главный герой"), --ID: 1656
			CheckboxFilter(3584, "Спор"), --ID: 3484
			CheckboxFilter(1487, "Спорт"), --ID: 1387
			CheckboxFilter(7884, "Способность кражи"), --ID: 7784
			CheckboxFilter(123, "Сражения"), --ID: 23
			CheckboxFilter(1122, "Средневековье"), --ID: 1022
			CheckboxFilter(2032, "Сталкер"), --ID: 1932
			CheckboxFilter(211, "Становление государства"), --ID: 111
			CheckboxFilter(1758, "Старшая школа"), --ID: 1658
			CheckboxFilter(554, "Стёб"), --ID: 454
			CheckboxFilter(7553, "Стекло"), --ID: 7453
			CheckboxFilter(252, "Стеснительный персонаж"), --ID: 152
			CheckboxFilter(1994, "Стимпанк"), --ID: 1894
			CheckboxFilter(1409, "Стихи"), --ID: 1309
			CheckboxFilter(669, "Стратегия"), --ID: 569
			CheckboxFilter(7014, "Стриптиз"), --ID: 6914
			CheckboxFilter(1021, "Строительство"), --ID: 921
			CheckboxFilter(1564, "Студент"), --ID: 1464
			CheckboxFilter(7618, "Студентка"), --ID: 7518
			CheckboxFilter(2762, "Суккубы"), --ID: 2662
			CheckboxFilter(6674, "Супер зрение"), --ID: 6574
			CheckboxFilter(589, "Супер удача"), --ID: 489
			CheckboxFilter(1581, "Супергерои"), --ID: 1481
			CheckboxFilter(2225, "Суперзлодеи"), --ID: 2125
			CheckboxFilter(7097, "Супермен"), --ID: 6997
			CheckboxFilter(2376, "Суперсилы"), --ID: 2276
			CheckboxFilter(6133, "Существа"), --ID: 6033
			CheckboxFilter(1177, "Сферы"), --ID: 1077
			CheckboxFilter(7216, "Схемы и заговоры"), --ID: 7116
			CheckboxFilter(7589, "Сценарий"), --ID: 7489
			CheckboxFilter(3393, "Счастливый конец"), --ID: 3293
			CheckboxFilter(3397, "Сын"), --ID: 3297
			CheckboxFilter(445, "Сэйнэн"), --ID: 345
			CheckboxFilter(7561, "Сэм винчестер"), --ID: 7461
			CheckboxFilter(2660, "Сюаньхуа"), --ID: 2560
			CheckboxFilter(7302, "Сюжетные повороты"), --ID: 7202
			CheckboxFilter(1226, "Сянься"), --ID: 1126
			CheckboxFilter(689, "Таблетки для развития"), --ID: 589
			CheckboxFilter(869, "Таинственное прошлое"), --ID: 769
			CheckboxFilter(8196, "Тайная личность"), --ID: 8096
			CheckboxFilter(213, "Тайная любовь"), --ID: 113
			CheckboxFilter(7581, "Тайны"), --ID: 7481
			CheckboxFilter(7550, "Тайные отношения"), --ID: 7450
			CheckboxFilter(6513, "Тайцы"), --ID: 6413
			CheckboxFilter(1887, "Танки"), --ID: 1787
			CheckboxFilter(2550, "Твинцест"), --ID: 2450
			CheckboxFilter(120, "Творчество"), --ID: 20
			CheckboxFilter(3626, "Тейлор эберт"), --ID: 3526
			CheckboxFilter(2303, "Телекинез"), --ID: 2203
			CheckboxFilter(1014, "Телепортация"), --ID: 914
			CheckboxFilter(823, "Телохранитель"), --ID: 723
			CheckboxFilter(4910, "Темари"), --ID: 4810
			CheckboxFilter(4888, "Темная магия"), --ID: 4788
			CheckboxFilter(1775, "Темное фэнтези"), --ID: 1675
			CheckboxFilter(7298, "Темные эльфы"), --ID: 7198
			CheckboxFilter(4467, "Тенсейган"), --ID: 4367
			CheckboxFilter(3336, "Тентакли"), --ID: 3236
			CheckboxFilter(4294, "Тетя"), --ID: 4194
			CheckboxFilter(608, "Техномагия"), --ID: 508
			CheckboxFilter(1274, "Тиран"), --ID: 1174
			CheckboxFilter(3408, "Титаны"), --ID: 3308
			CheckboxFilter(5205, "Тодороки шото"), --ID: 5105
			CheckboxFilter(5891, "Токио"), --ID: 5791
			CheckboxFilter(6752, "Том реддл"), --ID: 6652
			CheckboxFilter(1438, "Тони старк"), --ID: 1338
			CheckboxFilter(1900, "Тор"), --ID: 1800
			CheckboxFilter(2745, "Тор и локи"), --ID: 2645
			CheckboxFilter(1737, "Торговля"), --ID: 1637
			CheckboxFilter(321, "Травничество"), --ID: 221
			CheckboxFilter(570, "Трагедия"), --ID: 470
			CheckboxFilter(744, "Трагическое прошлое"), --ID: 644
			CheckboxFilter(2018, "Трактир"), --ID: 1918
			CheckboxFilter(1171, "Трансмиграция"), --ID: 1071
			CheckboxFilter(256, "Трансформация"), --ID: 156
			CheckboxFilter(4716, "Трансформеры"), --ID: 4616
			CheckboxFilter(6417, "Трап"), --ID: 6317
			CheckboxFilter(5527, "Тревор филипс"), --ID: 5427
			CheckboxFilter(1776, "Триллер"), --ID: 1676
			CheckboxFilter(7269, "Тройняшки"), --ID: 7169
			CheckboxFilter(4350, "Троли"), --ID: 4250
			CheckboxFilter(348, "Трудолюбивый главный герой"), --ID: 248
			CheckboxFilter(3810, "Тупой главный герой"), --ID: 3710
			CheckboxFilter(2019, "Тьма"), --ID: 1919
			CheckboxFilter(5697, "Тюрьма"), --ID: 5597
			CheckboxFilter(2353, "Тяжёлое детство"), --ID: 2253
			CheckboxFilter(478, "Убийства"), --ID: 378
			CheckboxFilter(1866, "Убийцы"), --ID: 1766
			CheckboxFilter(1584, "Убийцы драконов"), --ID: 1484
			CheckboxFilter(3366, "Увечья"), --ID: 3266
			CheckboxFilter(6675, "Удача"), --ID: 6575
			CheckboxFilter(1847, "Ужасы"), --ID: 1747
			CheckboxFilter(7679, "Узумаки"), --ID: 7579
			CheckboxFilter(467, "Укротитель"), --ID: 367
			CheckboxFilter(631, "Умения"), --ID: 531
			CheckboxFilter(1481, "Умная главная героиня"), --ID: 1381
			CheckboxFilter(2856, "Умные персонажи"), --ID: 2756
			CheckboxFilter(2193, "Умный главный герой"), --ID: 2093
			CheckboxFilter(2202, "Университет"), --ID: 2102
			CheckboxFilter(181, "Уничтожение мира"), --ID: 81
			CheckboxFilter(5748, "Управление временем"), --ID: 5648
			CheckboxFilter(108, "Уровни"), --ID: 8
			CheckboxFilter(3649, "Усиление"), --ID: 3549
			CheckboxFilter(6837, "Усопп"), --ID: 6737
			CheckboxFilter(2323, "Устроенный брак"), --ID: 2223
			CheckboxFilter(495, "Усыновление"), --ID: 395
			CheckboxFilter(1272, "Уся"), --ID: 1172
			CheckboxFilter(4777, "Утопия"), --ID: 4677
			CheckboxFilter(7709, "Уход за детьми"), --ID: 7609
			CheckboxFilter(2897, "Учеба в университете"), --ID: 2797
			CheckboxFilter(1917, "Учебное заведение"), --ID: 1817
			CheckboxFilter(1943, "Ученые"), --ID: 1843
			CheckboxFilter(945, "Учитель"), --ID: 845
			CheckboxFilter(5448, "Учиха"), --ID: 5348
			CheckboxFilter(1571, "Фамильяры"), --ID: 1471
			CheckboxFilter(6821, "Фанатичная любовь"), --ID: 6721
			CheckboxFilter(7839, "Фанаты"), --ID: 7739
			CheckboxFilter(386, "Фантастика"), --ID: 286
			CheckboxFilter(2514, "Фантастический мир"), --ID: 2414
			CheckboxFilter(867, "Фанфик"), --ID: 767
			CheckboxFilter(1806, "Фармацевт"), --ID: 1706
			CheckboxFilter(3218, "Фашисты"), --ID: 3118
			CheckboxFilter(7285, "Феи"), --ID: 7185
			CheckboxFilter(5980, "Фелляция"), --ID: 5880
			CheckboxFilter(6627, "Феминизм"), --ID: 6527
			CheckboxFilter(2513, "Феникс"), --ID: 2413
			CheckboxFilter(2840, "Фенрир"), --ID: 2740
			CheckboxFilter(380, "Феодализм"), --ID: 280
			CheckboxFilter(385, "Ферма"), --ID: 285
			CheckboxFilter(2498, "Фетиш"), --ID: 2398
			CheckboxFilter(4785, "Фехтовальщик"), --ID: 4685
			CheckboxFilter(228, "Филиппины"), --ID: 128
			CheckboxFilter(1959, "Философия"), --ID: 1859
			CheckboxFilter(4306, "Фистинг"), --ID: 4206
			CheckboxFilter(5148, "Флафф"), --ID: 5048
			CheckboxFilter(5291, "Флер делакур"), --ID: 5191
			CheckboxFilter(4767, "Флэш"), --ID: 4667
			CheckboxFilter(7702, "Фокусник"), --ID: 7602
			CheckboxFilter(4186, "Фольклор"), --ID: 4086
			CheckboxFilter(6261, "Фугаку"), --ID: 6161
			CheckboxFilter(6731, "Фурри"), --ID: 6631
			CheckboxFilter(2096, "Футанари"), --ID: 1996
			CheckboxFilter(1221, "Футбол"), --ID: 1121
			CheckboxFilter(274, "Фэнтези"), --ID: 174
			CheckboxFilter(1656, "Фэнтезийный мир"), --ID: 1556
			CheckboxFilter(575, "Хакер"), --ID: 475
			CheckboxFilter(1296, "Халк"), --ID: 1196
			CheckboxFilter(4917, "Хан нуньен синг"), --ID: 4817
			CheckboxFilter(4469, "Ханма юджиро"), --ID: 4369
			CheckboxFilter(3217, "Хаос"), --ID: 3117
			CheckboxFilter(2450, "Харизматичный главный герой"), --ID: 2350
			CheckboxFilter(2920, "Хатаке какаши"), --ID: 2820
			CheckboxFilter(1782, "Хентай"), --ID: 1682
			CheckboxFilter(6003, "Хиддлстон"), --ID: 5903
			CheckboxFilter(2683, "Химавари"), --ID: 2583
			CheckboxFilter(2613, "Хината"), --ID: 2513
			CheckboxFilter(2136, "Хитрый главный герой"), --ID: 2036
			CheckboxFilter(6798, "Хоббит"), --ID: 6698
			CheckboxFilter(6054, "Хогвартс"), --ID: 5954
			CheckboxFilter(6607, "Холодная главная героиня"), --ID: 6507
			CheckboxFilter(4989, "Холодное оружие"), --ID: 4889
			CheckboxFilter(2786, "Холодный главный герой"), --ID: 2686
			CheckboxFilter(2235, "Храм"), --ID: 2135
			CheckboxFilter(977, "Христианство"), --ID: 877
			CheckboxFilter(2480, "Художественная литература"), --ID: 2380
			CheckboxFilter(618, "Художница"), --ID: 518
			CheckboxFilter(954, "Хулиганы"), --ID: 854
			CheckboxFilter(1002, "Цветок"), --ID: 902
			CheckboxFilter(1805, "Цезарь"), --ID: 1705
			CheckboxFilter(4623, "Целители"), --ID: 4523
			CheckboxFilter(2080, "Церковь"), --ID: 1980
			CheckboxFilter(1178, "Цундере"), --ID: 1078
			CheckboxFilter(1493, "Чакра"), --ID: 1393
			CheckboxFilter(2968, "Черный юмор"), --ID: 2868
			CheckboxFilter(5955, "Честная главная героиня"), --ID: 5855
			CheckboxFilter(229, "Честный главный герой"), --ID: 129
			CheckboxFilter(551, "Читы"), --ID: 451
			CheckboxFilter(7275, "Шантаж"), --ID: 7175
			CheckboxFilter(5265, "Шаринган"), --ID: 5165
			CheckboxFilter(4761, "Шинигами"), --ID: 4661
			CheckboxFilter(1327, "Шиноби"), --ID: 1227
			CheckboxFilter(384, "Школьная жизнь"), --ID: 284
			CheckboxFilter(318, "Школьники"), --ID: 218
			CheckboxFilter(6046, "Школьницы"), --ID: 5946
			CheckboxFilter(5922, "Шлюха"), --ID: 5822
			CheckboxFilter(7219, "Шоу-бизнес"), --ID: 7119
			CheckboxFilter(4362, "Шпионы"), --ID: 4262
			CheckboxFilter(2140, "Эволюция"), --ID: 2040
			CheckboxFilter(776, "Экзорцизм"), --ID: 676
			CheckboxFilter(221, "Экономика"), --ID: 121
			CheckboxFilter(1743, "Эксгибиционизм"), --ID: 1643
			CheckboxFilter(210, "Экспансия"), --ID: 110
			CheckboxFilter(7508, "Эксперименты над людьми"), --ID: 7408
			CheckboxFilter(2959, "Экшен"), --ID: 2859
			CheckboxFilter(1364, "Элементальная магия"), --ID: 1264
			CheckboxFilter(1423, "Элементы бдсм"), --ID: 1323
			CheckboxFilter(1462, "Эльфы"), --ID: 1362
			CheckboxFilter(2153, "Эротика"), --ID: 2053
			CheckboxFilter(1417, "Этти"), --ID: 1317
			CheckboxFilter(7460, "Юмор"), --ID: 7360
			CheckboxFilter(1899, "Юри"), --ID: 1799
			CheckboxFilter(301, "Яды"), --ID: 201
			CheckboxFilter(4699, "Якудза"), --ID: 4599
			CheckboxFilter(7211, "Яндере"), --ID: 7111
			CheckboxFilter(1324, "Яой"), --ID: 1224
			CheckboxFilter(190, "Rpg"), --ID: 90
			CheckboxFilter(2085, "Star wars"), --ID: 1985
			CheckboxFilter(924, "Time skip"), --ID: 824
			CheckboxFilter(5389, "Warrior of light"), --ID: 5289
			CheckboxFilter(3416, "12+"), --ID: 3316
			CheckboxFilter(183, "16+"), --ID: 83
			CheckboxFilter(1849, "18+"), --ID: 1749
			CheckboxFilter(3291, "21+"), --ID: 3191
		}),
		DropdownFilter(ATMOSPHERE_BY_FILTER, "Атмосфера", {
			"Неважно", --ID: 0
			"Позитивная", --ID: 1
			"Темная", --ID: 2
		}),
		DropdownFilter(TYPE_BY_FILTER, "Тип", {
			"Неважно", --ID: 0
			"Только переводы", --ID: 1
			"Только авторские", --ID: 2
		}),
		FilterGroup("Другое", {
			CheckboxFilter(10, "Готовые на 100%"), --ID: ready
			CheckboxFilter(11, "Доступные для скачивания"), --ID: gen
			CheckboxFilter(12, "Доступные для перевода"), --ID: tr
			CheckboxFilter(13, "Завершённые проекты"), --ID: wealth
			CheckboxFilter(14, "Распродажа"), --ID: discount
			CheckboxFilter(15, "Только онгоинги"), --ID: ongoings
			CheckboxFilter(16, "Убрать машинный"), --ID: remove_machinelate
			CheckboxFilter(17, "без фэндомов"), --ID: fandoms_ex_all
		}),
		DropdownFilter(AGE_BY_FILTER, "Возрастные ограничения", {
			"Все", --ID: 0
			"Убрать 18+", --ID: 1
			"Только 18+", --ID: 2
		}),
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
