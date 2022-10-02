-- {"id":72,"ver":"1.0.0","libVer":"1.0.0","author":"Rider21","dep":["dkjson>=1.0.1"]}

local baseURL = "https://ranobehub.org"

local json = Require("dkjson")

local ORDER_BY_FILTER = 3
local ORDER_BY_TERMS = { "computed_rating", "last_chapter_at", "created_at", "name_rus", "views", "count_chapters", "count_of_symbols" }
local COUNTRY_BY_FILTER = 4
local STATUS_BY_FILTER = 5

local function shrinkURL(url)
	return url:gsub(baseURL .. "/", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))
	local chap = doc:selectFirst("div.text:nth-child(1)")
	chap:select(".ads-desktop"):remove()
	chap:select("div.or:nth-child(1)"):remove()
	chap:select(".title-wrapper"):remove()
	chap:child(0):before("<h1>" .. doc:selectFirst("head > title"):text() .. "</h1>");

	map(chap:select("img"), function(v)
		v:attr("src", baseURL .. "/api/media/" .. v:attr("data-media-id"))
	end)

	return pageOfElem(chap, true)
end

local function parseNovel(novelURL, loadChapters)
	local response = json.GET(baseURL .. "/api/" .. novelURL)

	local novel = NovelInfo {
		title = response.data.names.rus or response.data.names.eng,
		genres = map(response.data.tags.genres, function(v) return v.names.rus or v.names.eng end),
		tags = map(response.data.tags.events, function(v) return v.names.rus or v.names.eng end),
		imageURL = response.data.posters.medium,
		description = Document(response.data.description):text(),
		authors = { response.data.authors[1].name_eng },
		status = NovelStatus(
			response.data.status.title == "Завершено" and 1 or
			response.data.status.title == "Заморожено" and 2 or
			response.data.status.title == "В процессе" and 0 or 3
		)
	}

	if loadChapters then
		local chapterJson = json.GET(baseURL .. "/api/" .. novelURL .. "/contents")
		local chapterList = {}
		local chapterOrder = 0
		for k1, volumes in pairs(chapterJson.volumes) do
			for k2, v2 in pairs(volumes.chapters) do
				table.insert(chapterList, NovelChapter {
					title = "Том " .. volumes.num .. ": " .. v2.name,
					link = shrinkURL(v2.url),
					release = os.date("%Y-%m-%d %H:%M:%S", v2.changed_at),
					order = chapterOrder
				});
				chapterOrder = chapterOrder + 1
			end
		end
		novel:setChapters(AsList(chapterList))
	end
	return novel
end

local function search(data)
	local response = json.GET(expandURL("api/fulltext/global?query=" .. data[QUERY]))
	local novels = {}

	for k, v in pairs(response) do
		if v.meta.key == "ranobe" then
			novels = map(v.data, function(v2)
				return Novel {
					title = v2.names.rus or v2.names.eng,
					link = "ranobe/" .. v2.id,
					imageURL = v2.image:gsub("/small", "/medium")
				}
			end)
		end
	end

	return novels
end

return {
	id = 72,
	name = "Ranobehub",
	baseURL = baseURL,

	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Ranobehub.png",
	chapterType = ChapterType.HTML,
	hasSearch = true,

	listings = {
		Listing("Novel List", true, function(data)
			local url = baseURL .. "/api/search?take=50&page=" .. data[PAGE]
			local orderBy = data[ORDER_BY_FILTER]
			local tags = {}

			for k, v in pairs(data) do
				if v then
					if (k > 1999 and k < 2050) then
						table.insert(tags, k - 1000)
					elseif (k > 2050 and k < 3100) then
						table.insert(tags, k - 2100)
					end
				end
			end

			if orderBy ~= nil then
				url = url .. "&sort=" .. ORDER_BY_TERMS[orderBy + 1]
			else
				url = url .. "&sort=computed_rating"
			end
			if data[COUNTRY_BY_FILTER] then
				url = url .. "&country=" .. (countryBy + 1)
			end
			if data[STATUS_BY_FILTER] then
				url = url .. "&status=" .. data[STATUS_BY_FILTER]
			end
			if #tags > 0 then
				url = url .. "&tags:positive=" .. table.concat(tags, ",")
			end

			local d = json.GET(url)
			return map(d.resource, function(v)
				return Novel {
					title = v.names.rus or v.names.eng,
					link = "ranobe/" .. v.id,
					imageURL = v.poster.medium
				}
			end)
		end)
	},

	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER, "Сортировка", { "Рейтинг", "Дате обновления", "Дате добавления", "Название", "Просмотры", "Количеству глав", "объем перевода" }),
		DropdownFilter(COUNTRY_BY_FILTER, "Страна", { "Япония", "Китай", "Корея", "США" }),
		DropdownFilter(STATUS_BY_FILTER, "Статус перевода", { "Любой", "В процессе", "Завершено", "Заморожено", "Неизвестно" }),
		FilterGroup("Тэги", { --offset: 1000
			CheckboxFilter(1353, "Авантюристы"), --ID: 353
			CheckboxFilter(1538, "Автоматоны"), --ID: 538
			CheckboxFilter(1434, "Агрессивные персонажи"), --ID: 434
			CheckboxFilter(1509, "Ад"), --ID: 509
			CheckboxFilter(1522, "Адаптация в радиопостановку"), --ID: 522
			CheckboxFilter(1025, "Академия"), --ID: 25
			CheckboxFilter(1578, "Актеры озвучки"), --ID: 578
			CheckboxFilter(1132, "Активный главный герой"), --ID: 132
			CheckboxFilter(1116, "Алхимия"), --ID: 116
			CheckboxFilter(1028, "Альтернативный мир"), --ID: 28
			CheckboxFilter(1247, "Амнезия/Потеря памяти"), --ID: 247
			CheckboxFilter(1657, "Анабиоз"), --ID: 657
			CheckboxFilter(1218, "Ангелы"), --ID: 218
			CheckboxFilter(1217, "Андрогинные персонажи"), --ID: 217
			CheckboxFilter(1082, "Андроиды"), --ID: 82
			CheckboxFilter(1471, "Анти-магия"), --ID: 471
			CheckboxFilter(1346, "Антигерой"), --ID: 346
			CheckboxFilter(1572, "Антикварный магазин"), --ID: 572
			CheckboxFilter(1562, "Антисоциальный главный герой"), --ID: 562
			CheckboxFilter(1663, "Антиутопия"), --ID: 663
			CheckboxFilter(1029, "Апатичный протагонист"), --ID: 29
			CheckboxFilter(1314, "Апокалипсис"), --ID: 314
			CheckboxFilter(1285, "Аранжированный брак"), --ID: 285
			CheckboxFilter(1598, "Армия"), --ID: 598
			CheckboxFilter(1117, "Артефакты"), --ID: 117
			CheckboxFilter(1460, "Артисты"), --ID: 460
			CheckboxFilter(1581, "Банды"), --ID: 581
			CheckboxFilter(1676, "БДСМ"), --ID: 676
			CheckboxFilter(1309, "Бедный главный герой"), --ID: 309
			CheckboxFilter(1144, "Безжалостный главный герой"), --ID: 144
			CheckboxFilter(1355, "Беззаботный главный герой"), --ID: 355
			CheckboxFilter(1650, "Безусловная любовь"), --ID: 650
			CheckboxFilter(1131, "Беременность"), --ID: 131
			CheckboxFilter(1222, "Бесполый главный герой"), --ID: 222
			CheckboxFilter(1275, "Бессмертные"), --ID: 275
			CheckboxFilter(1619, "Бесстрашный протагонист"), --ID: 619
			CheckboxFilter(1256, "Бесстыдный главный герой"), --ID: 256
			CheckboxFilter(1699, "Бесчестный главный герой"), --ID: 699
			CheckboxFilter(1342, "Библиотека"), --ID: 342
			CheckboxFilter(1813, "Бизнесмен "), --ID: 813
			CheckboxFilter(1120, "Биочип"), --ID: 120
			CheckboxFilter(1822, "Бисексуальный главный герой"), --ID: 822
			CheckboxFilter(1148, "Близнецы"), --ID: 148
			CheckboxFilter(1211, "Боги"), --ID: 211
			CheckboxFilter(1356, "Богини"), --ID: 356
			CheckboxFilter(1369, "Боевая академия"), --ID: 369
			CheckboxFilter(1347, "Боевые духи"), --ID: 347
			CheckboxFilter(1422, "Боевые соревнования"), --ID: 422
			CheckboxFilter(1336, "Божественная защита"), --ID: 336
			CheckboxFilter(1224, "Божественные силы"), --ID: 224
			CheckboxFilter(1348, "Большая разница в возрасте между героем и его любовным интересом"), --ID: 348
			CheckboxFilter(1544, "Борьба за власть"), --ID: 544
			CheckboxFilter(1363, "Брак"), --ID: 363
			CheckboxFilter(1065, "Брак по расчету"), --ID: 65
			CheckboxFilter(1031, "Братский комплекс"), --ID: 31
			CheckboxFilter(1413, "Братство"), --ID: 413
			CheckboxFilter(1518, "Братья и сестры"), --ID: 518
			CheckboxFilter(1742, "Буддизм"), --ID: 742
			CheckboxFilter(1273, "Быстрая культивация"), --ID: 273
			CheckboxFilter(1221, "Быстрообучаемый"), --ID: 221
			CheckboxFilter(1667, "Валькирии"), --ID: 667
			CheckboxFilter(1266, "Вампиры"), --ID: 266
			CheckboxFilter(1679, "Ваншот"), --ID: 679
			CheckboxFilter(1169, "Ведьмы"), --ID: 169
			CheckboxFilter(1289, "Вежливый главный герой"), --ID: 289
			CheckboxFilter(1225, "Верные подчиненные"), --ID: 225
			CheckboxFilter(1183, "Взрослый главный герой"), --ID: 183
			CheckboxFilter(1636, "Видит то, чего не видят другие"), --ID: 636
			CheckboxFilter(1313, "Виртуальная реальность"), --ID: 313
			CheckboxFilter(1653, "Владелец магазина"), --ID: 653
			CheckboxFilter(1376, "Внезапная сила"), --ID: 376
			CheckboxFilter(1802, "Внезапное богатство"), --ID: 802
			CheckboxFilter(1334, "Внешний вид отличается от фактического возраста"), --ID: 334
			CheckboxFilter(1740, "Военные Летописи"), --ID: 740
			CheckboxFilter(1673, "Возвращение из другого мира"), --ID: 673
			CheckboxFilter(1058, "Войны"), --ID: 58
			CheckboxFilter(1678, "Вокалоид"), --ID: 678
			CheckboxFilter(1477, "Волшебники/Волшебницы"), --ID: 477
			CheckboxFilter(1201, "Волшебные звери"), --ID: 201
			CheckboxFilter(1614, "Воображаемый друг"), --ID: 614
			CheckboxFilter(1326, "Воры"), --ID: 326
			CheckboxFilter(1078, "Воскрешение"), --ID: 78
			CheckboxFilter(1428, "Враги становятся возлюбленными"), --ID: 428
			CheckboxFilter(1502, "Враги становятся союзниками"), --ID: 502
			CheckboxFilter(1558, "Врата в другой мир"), --ID: 558
			CheckboxFilter(1286, "Врачи"), --ID: 286
			CheckboxFilter(1163, "Временной парадокс"), --ID: 163
			CheckboxFilter(1042, "Всемогущий главный герой"), --ID: 42
			CheckboxFilter(1077, "Вторжение на землю"), --ID: 77
			CheckboxFilter(1112, "Второй шанс"), --ID: 112
			CheckboxFilter(1851, "Вуайеризм"), --ID: 851
			CheckboxFilter(1290, "Выживание"), --ID: 290
			CheckboxFilter(1268, "Высокомерные персонажи"), --ID: 268
			CheckboxFilter(1540, "Гадание"), --ID: 540
			CheckboxFilter(1828, "Гарем рабов"), --ID: 828
			CheckboxFilter(1302, "Геймеры"), --ID: 302
			CheckboxFilter(1223, "Генералы"), --ID: 223
			CheckboxFilter(1620, "Генетические модификации"), --ID: 620
			CheckboxFilter(1566, "Гениальный главный герой"), --ID: 566
			CheckboxFilter(1173, "Герои"), --ID: 173
			CheckboxFilter(1525, "Героиня — сорванец"), --ID: 525
			CheckboxFilter(1064, "Герой влюбляется первым"), --ID: 64
			CheckboxFilter(1510, "Гетерохромия"), --ID: 510
			CheckboxFilter(1323, "Гильдии"), --ID: 323
			CheckboxFilter(1768, "Гипнотизм"), --ID: 768
			CheckboxFilter(1655, "Главный герой влюбляется первым"), --ID: 655
			CheckboxFilter(1396, "Главный герой играет роль"), --ID: 396
			CheckboxFilter(1637, "Главный герой носит очки"), --ID: 637
			CheckboxFilter(1675, "Главный герой пацифист"), --ID: 675
			CheckboxFilter(1628, "Главный герой с несколькими телами"), --ID: 628
			CheckboxFilter(1045, "Главный герой силен с самого начала"), --ID: 45
			CheckboxFilter(1486, "Главный герой — бог"), --ID: 486
			CheckboxFilter(1595, "Главный герой — гуманоид"), --ID: 595
			CheckboxFilter(1063, "Главный герой — женщина"), --ID: 63
			CheckboxFilter(1039, "Главный герой — мужчина"), --ID: 39
			CheckboxFilter(1362, "Главный герой — наполовину человек"), --ID: 362
			CheckboxFilter(1859, "Главный герой — отец"), --ID: 859
			CheckboxFilter(1832, "Главный герой — раб"), --ID: 832
			CheckboxFilter(1415, "Главный герой — ребенок"), --ID: 415
			CheckboxFilter(1400, "Главный герой — рубака"), --ID: 400
			CheckboxFilter(1439, "Главный герой — собиратель гарема"), --ID: 439
			CheckboxFilter(1549, "Гладиаторы"), --ID: 549
			CheckboxFilter(1295, "Глуповатый главный герой"), --ID: 295
			CheckboxFilter(1529, "Гоблины"), --ID: 529
			CheckboxFilter(1569, "Големы"), --ID: 569
			CheckboxFilter(1850, "Гомункул"), --ID: 850
			CheckboxFilter(1380, "Горничные"), --ID: 380
			CheckboxFilter(2043, "Госпиталь"), --ID: 1043
			CheckboxFilter(1193, "Готовка"), --ID: 193
			CheckboxFilter(1303, "Гриндинг"), --ID: 303
			CheckboxFilter(1384, "Дао Компаньон"), --ID: 384
			CheckboxFilter(1792, "Даосизм"), --ID: 792
			CheckboxFilter(1151, "Дарк"), --ID: 151
			CheckboxFilter(1220, "Дварфы"), --ID: 220
			CheckboxFilter(1601, "Двойная личность"), --ID: 601
			CheckboxFilter(1547, "Двойник"), --ID: 547
			CheckboxFilter(1623, "Дворецкий"), --ID: 623
			CheckboxFilter(1041, "Дворяне"), --ID: 41
			CheckboxFilter(1354, "Дворянство/Аристократия"), --ID: 354
			CheckboxFilter(1634, "Девушки-монстры"), --ID: 634
			CheckboxFilter(1706, "Демоническая техника культивации"), --ID: 706
			CheckboxFilter(1006, "Демоны"), --ID: 6
			CheckboxFilter(1841, "Денежный долг"), --ID: 841
			CheckboxFilter(1494, "Депрессия"), --ID: 494
			CheckboxFilter(1561, "Детективы"), --ID: 561
			CheckboxFilter(1034, "Дискриминация"), --ID: 34
			CheckboxFilter(1307, "Добыча денег одно из основных стремлений главного героя"), --ID: 307
			CheckboxFilter(1200, "Долгая разлука"), --ID: 200
			CheckboxFilter(1178, "Домашние дела"), --ID: 178
			CheckboxFilter(1394, "Домогательство"), --ID: 394
			CheckboxFilter(1195, "Драконы"), --ID: 195
			CheckboxFilter(1555, "Драконьи всадники"), --ID: 555
			CheckboxFilter(1102, "Древние времена"), --ID: 102
			CheckboxFilter(1284, "Древний Китай"), --ID: 284
			CheckboxFilter(1097, "Дружба"), --ID: 97
			CheckboxFilter(1170, "Друзья детства"), --ID: 170
			CheckboxFilter(1507, "Друзья становятся врагами"), --ID: 507
			CheckboxFilter(1427, "Друиды"), --ID: 427
			CheckboxFilter(1842, "Дух лисы"), --ID: 842
			CheckboxFilter(1046, "Духи/Призраки"), --ID: 46
			CheckboxFilter(1351, "Духовный советник"), --ID: 351
			CheckboxFilter(1587, "Душевность"), --ID: 587
			CheckboxFilter(1136, "Души"), --ID: 136
			CheckboxFilter(1457, "Европейская атмосфера"), --ID: 457
			CheckboxFilter(1026, "Есть аниме-адаптация"), --ID: 26
			CheckboxFilter(1491, "Есть видеоигра по мотивам"), --ID: 491
			CheckboxFilter(1027, "Есть манга-адаптация"), --ID: 27
			CheckboxFilter(1453, "Есть манхва-адаптация"), --ID: 453
			CheckboxFilter(1298, "Есть маньхуа-адаптация"), --ID: 298
			CheckboxFilter(1421, "Есть сериал-адаптация"), --ID: 421
			CheckboxFilter(1047, "Есть фильм по мотивам"), --ID: 47
			CheckboxFilter(1438, "Женища-наставник"), --ID: 438
			CheckboxFilter(1414, "Жертва изнасилования влюбляется в насильника"), --ID: 414
			CheckboxFilter(1249, "Жесткая, двуличная личность"), --ID: 249
			CheckboxFilter(1436, "Жестокие персонажи"), --ID: 436
			CheckboxFilter(1617, "Жестокое обращение с ребенком"), --ID: 617
			CheckboxFilter(1127, "Жестокость"), --ID: 127
			CheckboxFilter(1765, "Животноводство"), --ID: 765
			CheckboxFilter(1466, "Животные черты"), --ID: 466
			CheckboxFilter(1554, "Жизнь в квартире"), --ID: 554
			CheckboxFilter(1564, "Жрицы"), --ID: 564
			CheckboxFilter(1176, "Заботливый главный герой"), --ID: 176
			CheckboxFilter(1579, "Забывчивый главный герой"), --ID: 579
			CheckboxFilter(1177, "Заговоры"), --ID: 177
			CheckboxFilter(1269, "Закалка тела"), --ID: 269
			CheckboxFilter(1769, "Законники"), --ID: 769
			CheckboxFilter(1533, "Замкнутый главный герой"), --ID: 533
			CheckboxFilter(1344, "Запечатанная сила"), --ID: 344
			CheckboxFilter(1443, "Застенчивые персонажи"), --ID: 443
			CheckboxFilter(1119, "Звери"), --ID: 119
			CheckboxFilter(1192, "Звери-компаньоны"), --ID: 192
			CheckboxFilter(1125, "Злой протагонист"), --ID: 125
			CheckboxFilter(1437, "Злые боги"), --ID: 437
			CheckboxFilter(1503, "Злые организации"), --ID: 503
			CheckboxFilter(1725, "Злые религии"), --ID: 725
			CheckboxFilter(1397, "Знаменитости"), --ID: 397
			CheckboxFilter(1469, "Знаменитый главный герой"), --ID: 469
			CheckboxFilter(1185, "Знания современного мира"), --ID: 185
			CheckboxFilter(1321, "Зомби"), --ID: 321
			CheckboxFilter(1162, "Игра на выживание"), --ID: 162
			CheckboxFilter(1700, "Игривый протагонист"), --ID: 700
			CheckboxFilter(1301, "Игровая система рейтинга"), --ID: 301
			CheckboxFilter(1152, "Игровые элементы"), --ID: 152
			CheckboxFilter(1644, "Игрушки (18+)"), --ID: 644
			CheckboxFilter(1330, "Из грязи в князи"), --ID: 330
			CheckboxFilter(1688, "Из женщины в мужчину "), --ID: 688
			CheckboxFilter(1698, "Из мужчины в женщину"), --ID: 698
			CheckboxFilter(1809, "Из полного в худого"), --ID: 809
			CheckboxFilter(1081, "Из слабого в сильного"), --ID: 81
			CheckboxFilter(1810, "Из страшно(го/й) в красиво(го/ю)"), --ID: 810
			CheckboxFilter(1349, "Извращенный главный герой"), --ID: 349
			CheckboxFilter(1472, "Изгои"), --ID: 472
			CheckboxFilter(1627, "Изменение расы"), --ID: 627
			CheckboxFilter(1191, "Изменения внешнего вида"), --ID: 191
			CheckboxFilter(1099, "Изменения личности"), --ID: 99
			CheckboxFilter(1110, "Изнасилование"), --ID: 110
			CheckboxFilter(1260, "Изображения жестокости"), --ID: 260
			CheckboxFilter(1749, "Империи"), --ID: 749
			CheckboxFilter(1656, "Инвалидность"), --ID: 656
			CheckboxFilter(1180, "Индустриализация"), --ID: 180
			CheckboxFilter(1035, "Инженер"), --ID: 35
			CheckboxFilter(1463, "Инцест"), --ID: 463
			CheckboxFilter(1118, "Искусственный интеллект"), --ID: 118
			CheckboxFilter(1635, "Исследования"), --ID: 635
			CheckboxFilter(1377, "Каннибализм"), --ID: 377
			CheckboxFilter(1654, "Карточные игры"), --ID: 654
			CheckboxFilter(1658, "Киберспорт"), --ID: 658
			CheckboxFilter(1950, "Кланы"), --ID: 950
			CheckboxFilter(1727, "Класс безработного [Игровой класс в игре]"), --ID: 727
			CheckboxFilter(1365, "Клоны"), --ID: 365
			CheckboxFilter(1096, "Клубы"), --ID: 96
			CheckboxFilter(1341, "Книги"), --ID: 341
			CheckboxFilter(1312, "Книги навыков"), --ID: 312
			CheckboxFilter(1455, "Книжный червь"), --ID: 455
			CheckboxFilter(1111, "Коварство"), --ID: 111
			CheckboxFilter(1683, "Коллеги"), --ID: 683
			CheckboxFilter(1712, "Колледж/Университет"), --ID: 712
			CheckboxFilter(1826, "Кома"), --ID: 826
			CheckboxFilter(1426, "Командная работа"), --ID: 426
			CheckboxFilter(1523, "Комедийный оттенок"), --ID: 523
			CheckboxFilter(1489, "Комплекс неполноценности"), --ID: 489
			CheckboxFilter(1104, "Комплекс семейных отношений"), --ID: 104
			CheckboxFilter(1746, "Конкуренция"), --ID: 746
			CheckboxFilter(1483, "Контракты"), --ID: 483
			CheckboxFilter(1262, "Контроль разума/сознания"), --ID: 262
			CheckboxFilter(1339, "Копейщик"), --ID: 339
			CheckboxFilter(2025, "Королевская битва"), --ID: 1025
			CheckboxFilter(1053, "Королевская власть"), --ID: 53
			CheckboxFilter(1141, "Королевства"), --ID: 141
			CheckboxFilter(1378, "Коррупция"), --ID: 378
			CheckboxFilter(1674, "Космические войны"), --ID: 674
			CheckboxFilter(1107, "Красивый герой"), --ID: 107
			CheckboxFilter(1287, "Крафт"), --ID: 287
			CheckboxFilter(1599, "Кризис личности"), --ID: 599
			CheckboxFilter(1257, "Кругосветное путешествие"), --ID: 257
			CheckboxFilter(1440, "Кудере"), --ID: 440
			CheckboxFilter(1701, "Кузены"), --ID: 701
			CheckboxFilter(1454, "Кузнец"), --ID: 454
			CheckboxFilter(1431, "Кукловоды"), --ID: 431
			CheckboxFilter(1573, "Куклы/марионетки"), --ID: 573
			CheckboxFilter(1123, "Культивация"), --ID: 123
			CheckboxFilter(1632, "Куннилингус"), --ID: 632
			CheckboxFilter(1430, "Легенды"), --ID: 430
			CheckboxFilter(1604, "Легкая жизнь"), --ID: 604
			CheckboxFilter(1570, "Ленивый главный герой"), --ID: 570
			CheckboxFilter(1424, "Лидерство"), --ID: 424
			CheckboxFilter(1092, "Лоли"), --ID: 92
			CheckboxFilter(1401, "Лотерея"), --ID: 401
			CheckboxFilter(1647, "Любовный интерес влюбляется первым"), --ID: 647
			CheckboxFilter(1576, "Любовный интерес главного героя носит очки"), --ID: 576
			CheckboxFilter(1098, "Любовный треугольник"), --ID: 98
			CheckboxFilter(1500, "Любовь детства"), --ID: 500
			CheckboxFilter(1730, "Любовь с первого взгляда"), --ID: 730
			CheckboxFilter(1373, "Магические надписи"), --ID: 373
			CheckboxFilter(1277, "Магические печати"), --ID: 277
			CheckboxFilter(1357, "Магические технологии"), --ID: 357
			CheckboxFilter(1244, "Магическое пространство/измерение, доступное не всем персонажам"), --ID: 244
			CheckboxFilter(1038, "Магия"), --ID: 38
			CheckboxFilter(1333, "Магия призыва"), --ID: 333
			CheckboxFilter(1660, "Мазохистские персонажи"), --ID: 660
			CheckboxFilter(1130, "Манипулятивные персонажи"), --ID: 130
			CheckboxFilter(1091, "Мания"), --ID: 91
			CheckboxFilter(1390, "Мастер на все руки"), --ID: 390
			CheckboxFilter(1846, "Мастурбация"), --ID: 846
			CheckboxFilter(1496, "Махо-сёдзё"), --ID: 496
			CheckboxFilter(1441, "Медицинские знания"), --ID: 441
			CheckboxFilter(1113, "Медленная романтическая линия"), --ID: 113
			CheckboxFilter(1670, "Медленное развитие на старте "), --ID: 670
			CheckboxFilter(1316, "Межпространственные путешествия"), --ID: 316
			CheckboxFilter(1182, "Менеджмент"), --ID: 182
			CheckboxFilter(1794, "Мертвый главный герой"), --ID: 794
			CheckboxFilter(1088, "Месть"), --ID: 88
			CheckboxFilter(1234, "Метаморфы"), --ID: 234
			CheckboxFilter(1055, "Меч и магия"), --ID: 55
			CheckboxFilter(1607, "Мечник"), --ID: 607
			CheckboxFilter(1733, "Мечты"), --ID: 733
			CheckboxFilter(1709, "Милая история"), --ID: 709
			CheckboxFilter(1596, "Милое дитя"), --ID: 596
			CheckboxFilter(1697, "Милый главный герой"), --ID: 697
			CheckboxFilter(1385, "Мировое дерево"), --ID: 385
			CheckboxFilter(1409, "Мистический ореол вокруг семьи"), --ID: 409
			CheckboxFilter(1418, "Мифические звери"), --ID: 418
			CheckboxFilter(1468, "Мифология"), --ID: 468
			CheckboxFilter(1843, "Младшие братья"), --ID: 843
			CheckboxFilter(1465, "Младшие сестры"), --ID: 465
			CheckboxFilter(1306, "ММОРПГ (ЛитРПГ)"), --ID: 306
			CheckboxFilter(1488, "Множество перемещенных людей"), --ID: 488
			CheckboxFilter(1278, "Множество реальностей"), --ID: 278
			CheckboxFilter(1227, "Множество реинкарнированных людей"), --ID: 227
			CheckboxFilter(1649, "Модели"), --ID: 649
			CheckboxFilter(1705, "Молчаливый персонаж"), --ID: 705
			CheckboxFilter(1069, "Монстры"), --ID: 69
			CheckboxFilter(1685, "Мужская гей-пара"), --ID: 685
			CheckboxFilter(1155, "Мужчина-яндере"), --ID: 155
			CheckboxFilter(1589, "Музыка"), --ID: 589
			CheckboxFilter(1588, "Музыкальные группы"), --ID: 588
			CheckboxFilter(1668, "Мутации"), --ID: 668
			CheckboxFilter(1317, "Мутированные существа"), --ID: 317
			CheckboxFilter(1626, "Навык кражи"), --ID: 626
			CheckboxFilter(1085, "Навязчивая любовь"), --ID: 85
			CheckboxFilter(1324, "Наемники"), --ID: 324
			CheckboxFilter(1501, "Назойливый возлюбленный"), --ID: 501
			CheckboxFilter(1066, "Наивный главный герой"), --ID: 66
			CheckboxFilter(1661, "Наркотики"), --ID: 661
			CheckboxFilter(1470, "Нарциссический главный герой"), --ID: 470
			CheckboxFilter(1824, "Насилие сексуального характера"), --ID: 824
			CheckboxFilter(1372, "Наследование"), --ID: 372
			CheckboxFilter(1318, "Национализм"), --ID: 318
			CheckboxFilter(1328, "Не блещущий внешне главный герой"), --ID: 328
			CheckboxFilter(1464, "Не родные братья и сестры"), --ID: 464
			CheckboxFilter(1508, "Небеса"), --ID: 508
			CheckboxFilter(1274, "Небесное испытание"), --ID: 274
			CheckboxFilter(1622, "Негуманоидный главный герой"), --ID: 622
			CheckboxFilter(1485, "Недоверчивый главный герой"), --ID: 485
			CheckboxFilter(1140, "Недооцененный главный герой"), --ID: 140
			CheckboxFilter(1202, "Недоразумения"), --ID: 202
			CheckboxFilter(1075, "Неизлечимая болезнь"), --ID: 75
			CheckboxFilter(1308, "Некромант"), --ID: 308
			CheckboxFilter(1157, "Нелинейная история"), --ID: 157
			CheckboxFilter(1487, "Ненавистный главный герой"), --ID: 487
			CheckboxFilter(1165, "Ненадежный рассказчик"), --ID: 165
			CheckboxFilter(1821, "Нерезиденты"), --ID: 821
			CheckboxFilter(1741, "Нерешительный главный герой"), --ID: 741
			CheckboxFilter(1294, "Несерьезный главный герой"), --ID: 294
			CheckboxFilter(1517, "Несколько временных линий"), --ID: 517
			CheckboxFilter(1475, "Несколько главных героев"), --ID: 475
			CheckboxFilter(1615, "Несколько идентичностей"), --ID: 615
			CheckboxFilter(1474, "Несколько личностей"), --ID: 474
			CheckboxFilter(1721, "Нетораре"), --ID: 721
			CheckboxFilter(1450, "Нетори"), --ID: 450
			CheckboxFilter(1567, "Неудачливый главный герой"), --ID: 567
			CheckboxFilter(1358, "Ниндзя"), --ID: 358
			CheckboxFilter(1738, "Обещание из детства"), --ID: 738
			CheckboxFilter(1411, "Обманщик"), --ID: 411
			CheckboxFilter(1094, "Обмен телами"), --ID: 94
			CheckboxFilter(1417, "Обнаженка"), --ID: 417
			CheckboxFilter(1718, "Обольщение"), --ID: 718
			CheckboxFilter(1624, "Оборотни"), --ID: 624
			CheckboxFilter(1255, "Обратный гарем"), --ID: 255
			CheckboxFilter(1226, "Общество монстров"), --ID: 226
			CheckboxFilter(1548, "Обязательство"), --ID: 548
			CheckboxFilter(1179, "Огнестрельное оружие"), --ID: 179
			CheckboxFilter(1073, "Ограниченная продолжительность жизни"), --ID: 73
			CheckboxFilter(1447, "Одержимость"), --ID: 447
			CheckboxFilter(1304, "Одинокий главный герой"), --ID: 304
			CheckboxFilter(1199, "Одиночество"), --ID: 199
			CheckboxFilter(1207, "Одиночное проживание"), --ID: 207
			CheckboxFilter(1773, "Околосмертные переживания"), --ID: 773
			CheckboxFilter(1542, "Оммёдзи"), --ID: 542
			CheckboxFilter(1237, "Омоложение"), --ID: 237
			CheckboxFilter(1478, "Организованная преступность"), --ID: 478
			CheckboxFilter(1825, "Оргия"), --ID: 825
			CheckboxFilter(1228, "Орки"), --ID: 228
			CheckboxFilter(1235, "Освоение навыков"), --ID: 235
			CheckboxFilter(1553, "Основано на аниме"), --ID: 553
			CheckboxFilter(1704, "Основано на видео игре"), --ID: 704
			CheckboxFilter(1861, "Основано на визуальной новелле "), --ID: 861
			CheckboxFilter(1677, "Основано на песне"), --ID: 677
			CheckboxFilter(1552, "Основано на фильме"), --ID: 552
			CheckboxFilter(1122, "Осторожный главный герой"), --ID: 122
			CheckboxFilter(1512, "Отаку"), --ID: 512
			CheckboxFilter(1150, "Открытый космос"), --ID: 150
			CheckboxFilter(1713, "Отношения в сети"), --ID: 713
			CheckboxFilter(1603, "Отношения между богом и человеком"), --ID: 603
			CheckboxFilter(1205, "Отношения между людьми и нелюдьми"), --ID: 205
			CheckboxFilter(1852, "Отношения на расстоянии"), --ID: 852
			CheckboxFilter(1590, "Отношения начальник-подчиненный"), --ID: 590
			CheckboxFilter(1513, "Отношения Сенпай-Коухай"), --ID: 513
			CheckboxFilter(1451, "Отношения ученика и учителя"), --ID: 451
			CheckboxFilter(1343, "Отношения учитель-ученик"), --ID: 343
			CheckboxFilter(1206, "Отношения хозяин-слуга"), --ID: 206
			CheckboxFilter(1723, "Отомэ игра"), --ID: 723
			CheckboxFilter(1605, "Отсутствие здравого смысла"), --ID: 605
			CheckboxFilter(1575, "Отсутствие родителей"), --ID: 575
			CheckboxFilter(1686, "Офисный роман"), --ID: 686
			CheckboxFilter(1681, "Официанты"), --ID: 681
			CheckboxFilter(1288, "Охотники"), --ID: 288
			CheckboxFilter(1659, "Очаровательный главный герой"), --ID: 659
			CheckboxFilter(1618, "Падшее дворянство"), --ID: 618
			CheckboxFilter(1505, "Падшие ангелы"), --ID: 505
			CheckboxFilter(1630, "Пайзури"), --ID: 630
			CheckboxFilter(1535, "Паразиты"), --ID: 535
			CheckboxFilter(1086, "Параллельные миры"), --ID: 86
			CheckboxFilter(1586, "Парк развлечений"), --ID: 586
			CheckboxFilter(1319, "Пародия"), --ID: 319
			CheckboxFilter(1734, "Певцы/Певицы"), --ID: 734
			CheckboxFilter(1716, "Первая любовь"), --ID: 716
			CheckboxFilter(1560, "Первоисточник новеллы — манга"), --ID: 560
			CheckboxFilter(1845, "Первый раз"), --ID: 845
			CheckboxFilter(1732, "Перемещение в другой мир, имея при себе современные достижения"), --ID: 732
			CheckboxFilter(1532, "Перемещение в игровой мир"), --ID: 532
			CheckboxFilter(1754, "Перемещение в иной мир"), --ID: 754
			CheckboxFilter(1755, "Перерождение в ином мире"), --ID: 755
			CheckboxFilter(1139, "Переселение души/Трансмиграция"), --ID: 139
			CheckboxFilter(1631, "Персонаж использует щит"), --ID: 631
			CheckboxFilter(1079, "Петля времени"), --ID: 79
			CheckboxFilter(1817, "Пираты"), --ID: 817
			CheckboxFilter(1408, "Писатели"), --ID: 408
			CheckboxFilter(1253, "Питомцы"), --ID: 253
			CheckboxFilter(1291, "Племенное общество"), --ID: 291
			CheckboxFilter(1171, "Повелитель демонов"), --ID: 171
			CheckboxFilter(1156, "Повествование от нескольких лиц/Несколько точек зрения"), --ID: 156
			CheckboxFilter(1219, "Подземелья"), --ID: 219
			CheckboxFilter(1166, "Пожелания"), --ID: 166
			CheckboxFilter(1360, "Познание Дао"), --ID: 360
			CheckboxFilter(1534, "Покинутое дитя"), --ID: 534
			CheckboxFilter(1296, "Полигамия"), --ID: 296
			CheckboxFilter(1043, "Политика"), --ID: 43
			CheckboxFilter(1801, "Полиция"), --ID: 801
			CheckboxFilter(1335, "Полулюди"), --ID: 335
			CheckboxFilter(1432, "Пользователь уникального оружия"), --ID: 432
			CheckboxFilter(1241, "Популярный любовный интерес"), --ID: 241
			CheckboxFilter(1060, "Постапокалиптика"), --ID: 60
			CheckboxFilter(1751, "Потерянные цивилизации"), --ID: 751
			CheckboxFilter(1707, "Похищения людей"), --ID: 707
			CheckboxFilter(1404, "Поэзия"), --ID: 404
			CheckboxFilter(1694, "Правонарушители"), --ID: 694
			CheckboxFilter(1536, "Прагматичный главный герой"), --ID: 536
			CheckboxFilter(1106, "Преданный любовный интерес"), --ID: 106
			CheckboxFilter(1103, "Предательство"), --ID: 103
			CheckboxFilter(1052, "Предвидение"), --ID: 52
			CheckboxFilter(1030, "Прекрасная героиня"), --ID: 30
			CheckboxFilter(1728, "Преступники"), --ID: 728
			CheckboxFilter(1083, "Преступность"), --ID: 83
			CheckboxFilter(1147, "Призванный герой"), --ID: 147
			CheckboxFilter(1051, "Призраки"), --ID: 51
			CheckboxFilter(1602, "Принуждение к отношениям"), --ID: 602
			CheckboxFilter(1933, "Принцессы"), --ID: 933
			CheckboxFilter(1600, "Притворная пара"), --ID: 600
			CheckboxFilter(1297, "Причудливые персонажи"), --ID: 297
			CheckboxFilter(1076, "Пришельцы/Инопланетяне"), --ID: 76
			CheckboxFilter(1666, "Программист"), --ID: 666
			CheckboxFilter(1048, "Проклятия"), --ID: 48
			CheckboxFilter(1519, "Промывание мозгов"), --ID: 519
			CheckboxFilter(1138, "Пропуск времени"), --ID: 138
			CheckboxFilter(1429, "Пророчества"), --ID: 429
			CheckboxFilter(1844, "Проститутки"), --ID: 844
			CheckboxFilter(1375, "Пространственное манипулирование"), --ID: 375
			CheckboxFilter(1215, "Прошлое играет большую роль"), --ID: 215
			CheckboxFilter(1737, "Прыжки между мирами"), --ID: 737
			CheckboxFilter(1265, "Психические силы"), --ID: 265
			CheckboxFilter(1158, "Психопаты"), --ID: 158
			CheckboxFilter(1080, "Путешествие во времени"), --ID: 80
			CheckboxFilter(1168, "Пытка"), --ID: 168
			CheckboxFilter(1829, "Рабы"), --ID: 829
			CheckboxFilter(1771, "Развод"), --ID: 771
			CheckboxFilter(1174, "Разумные предметы"), --ID: 174
			CheckboxFilter(1320, "Расизм"), --ID: 320
			CheckboxFilter(1061, "Рассказ"), --ID: 61
			CheckboxFilter(1243, "Расторжения помолвки"), --ID: 243
			CheckboxFilter(1209, "Расы зооморфов"), --ID: 209
			CheckboxFilter(1717, "Ревность"), --ID: 717
			CheckboxFilter(1684, "Редакторы"), --ID: 684
			CheckboxFilter(1281, "Реинкарнация"), --ID: 281
			CheckboxFilter(1204, "Реинкарнация в монстра"), --ID: 204
			CheckboxFilter(1692, "Реинкарнация в объект"), --ID: 692
			CheckboxFilter(1565, "Религии"), --ID: 565
			CheckboxFilter(1837, "Репортеры"), --ID: 837
			CheckboxFilter(1652, "Ресторан"), --ID: 652
			CheckboxFilter(1124, "Решительный главный герой"), --ID: 124
			CheckboxFilter(1800, "Робкий главный герой"), --ID: 800
			CheckboxFilter(1687, "Родитель одиночка"), --ID: 687
			CheckboxFilter(1531, "Родительский комплекс"), --ID: 531
			CheckboxFilter(1121, "Родословная"), --ID: 121
			CheckboxFilter(1159, "Романтический подсюжет "), --ID: 159
			CheckboxFilter(1095, "Рост персонажа"), --ID: 95
			CheckboxFilter(1142, "Рыцари"), --ID: 142
			CheckboxFilter(1664, "Сёнэн-ай подсюжет "), --ID: 664
			CheckboxFilter(1642, "Садистские персонажи"), --ID: 642
			CheckboxFilter(1748, "Самоотверженный главный герой"), --ID: 748
			CheckboxFilter(1616, "Самоубийства"), --ID: 616
			CheckboxFilter(1646, "Самурай"), --ID: 646
			CheckboxFilter(1456, "Сборник коротких историй"), --ID: 456
			CheckboxFilter(1473, "Связанные сюжетные линии"), --ID: 473
			CheckboxFilter(1761, "Святые"), --ID: 761
			CheckboxFilter(1325, "Священники"), --ID: 325
			CheckboxFilter(1799, "Сдержанный главный герой"), --ID: 799
			CheckboxFilter(1331, "Секретные организации"), --ID: 331
			CheckboxFilter(1577, "Секреты"), --ID: 577
			CheckboxFilter(1830, "Секс рабы"), --ID: 830
			CheckboxFilter(1770, "Семейный конфликт"), --ID: 770
			CheckboxFilter(1233, "Семь добродетелей"), --ID: 233
			CheckboxFilter(1134, "Семь смертных грехов"), --ID: 134
			CheckboxFilter(1251, "Семья"), --ID: 251
			CheckboxFilter(1497, "Серийные убийцы"), --ID: 497
			CheckboxFilter(1498, "Сестринский комплекс"), --ID: 498
			CheckboxFilter(1282, "Сила духа"), --ID: 282
			CheckboxFilter(1520, "Сила, требующая платы за пользование"), --ID: 520
			CheckboxFilter(1109, "Сильная пара"), --ID: 109
			CheckboxFilter(1359, "Сильный в сильнейшего"), --ID: 359
			CheckboxFilter(1161, "Сильный любовный интерес"), --ID: 161
			CheckboxFilter(1090, "Синдром восьмиклассника"), --ID: 90
			CheckboxFilter(1214, "Сироты"), --ID: 214
			CheckboxFilter(1198, "Система уровней"), --ID: 198
			CheckboxFilter(1476, "Системный администратор"), --ID: 476
			CheckboxFilter(1371, "Скрытие истинной личности"), --ID: 371
			CheckboxFilter(1252, "Скрытие истинных способностей"), --ID: 252
			CheckboxFilter(1133, "Скрытный главный герой"), --ID: 133
			CheckboxFilter(1128, "Скрытые способности"), --ID: 128
			CheckboxFilter(1366, "Скульпторы"), --ID: 366
			CheckboxFilter(1213, "Слабо выраженная романтическая линия"), --ID: 213
			CheckboxFilter(1188, "Слабый главный герой"), --ID: 188
			CheckboxFilter(1864, "Слепой главный герой"), --ID: 864
			CheckboxFilter(1232, "Слуги"), --ID: 232
			CheckboxFilter(1049, "Смерть"), --ID: 49
			CheckboxFilter(1361, "Смерть близких"), --ID: 361
			CheckboxFilter(1108, "Собственнические персонажи"), --ID: 108
			CheckboxFilter(1040, "Современность"), --ID: 40
			CheckboxFilter(1482, "Сожительство"), --ID: 482
			CheckboxFilter(1175, "Создание армии"), --ID: 175
			CheckboxFilter(1292, "Создание артефактов"), --ID: 292
			CheckboxFilter(1448, "Создание клана"), --ID: 448
			CheckboxFilter(1181, "Создание королевства"), --ID: 181
			CheckboxFilter(1236, "Создание навыков"), --ID: 236
			CheckboxFilter(1393, "Создание секты"), --ID: 393
			CheckboxFilter(1071, "Солдаты/Военные"), --ID: 71
			CheckboxFilter(1571, "Сон"), --ID: 571
			CheckboxFilter(1067, "Состоятельные персонажи"), --ID: 67
			CheckboxFilter(1137, "Социальная иерархия на основе силы"), --ID: 137
			CheckboxFilter(1480, "Социальные изгои"), --ID: 480
			CheckboxFilter(1597, "Спасение мира"), --ID: 597
			CheckboxFilter(1054, "Специальные способности"), --ID: 54
			CheckboxFilter(1032, "Спокойный главный герой"), --ID: 32
			CheckboxFilter(1702, "Справедливый главный герой"), --ID: 702
			CheckboxFilter(1184, "Средневековье"), --ID: 184
			CheckboxFilter(1293, "Ссорящаяся пара"), --ID: 293
			CheckboxFilter(1689, "Сталкеры"), --ID: 689
			CheckboxFilter(1190, "Старение"), --ID: 190
			CheckboxFilter(1444, "Стоические персонажи"), --ID: 444
			CheckboxFilter(1643, "Стокгольмский синдром"), --ID: 643
			CheckboxFilter(1425, "Стратег"), --ID: 425
			CheckboxFilter(1160, "Стратегические битвы"), --ID: 160
			CheckboxFilter(2038, "Стратегия"), --ID: 1038
			CheckboxFilter(1458, "Стрелки"), --ID: 458
			CheckboxFilter(1383, "Стрельба из лука"), --ID: 383
			CheckboxFilter(1490, "Студенческий совет"), --ID: 490
			CheckboxFilter(1271, "Судьба"), --ID: 271
			CheckboxFilter(1484, "Суккубы"), --ID: 484
			CheckboxFilter(2039, "Супер герои"), --ID: 1039
			CheckboxFilter(1261, "Суровая подготовка"), --ID: 261
			CheckboxFilter(1074, "Таинственная болезнь"), --ID: 74
			CheckboxFilter(1263, "Таинственное прошлое"), --ID: 263
			CheckboxFilter(1310, "Тайная личность"), --ID: 310
			CheckboxFilter(1812, "Тайные отношения"), --ID: 812
			CheckboxFilter(1840, "Танцоры"), --ID: 840
			CheckboxFilter(1452, "Телохранители"), --ID: 452
			CheckboxFilter(1693, "Тентакли"), --ID: 693
			CheckboxFilter(1515, "Террористы"), --ID: 515
			CheckboxFilter(1621, "Технологический разрыв"), --ID: 621
			CheckboxFilter(1546, "Тихие персонажи"), --ID: 546
			CheckboxFilter(1299, "Толстый главный герой"), --ID: 299
			CheckboxFilter(1416, "Торговцы"), --ID: 416
			CheckboxFilter(1089, "Травля/Буллинг"), --ID: 89
			CheckboxFilter(1708, "Травник"), --ID: 708
			CheckboxFilter(1164, "Трагическое прошлое"), --ID: 164
			CheckboxFilter(1367, "Трансплантация воспоминаний"), --ID: 367
			CheckboxFilter(1582, "Трап (Путаница с гендером персонажа)"), --ID: 582
			CheckboxFilter(1037, "Трудолюбивый главный герой"), --ID: 37
			CheckboxFilter(1479, "Тюрьма"), --ID: 479
			CheckboxFilter(1084, "Убийства"), --ID: 84
			CheckboxFilter(1248, "Убийцы"), --ID: 248
			CheckboxFilter(1606, "Убийцы драконов"), --ID: 606
			CheckboxFilter(1270, "Уверенный главный герой"), --ID: 270
			CheckboxFilter(1402, "Удачливый главный герой"), --ID: 402
			CheckboxFilter(1337, "Укротитель монстров"), --ID: 337
			CheckboxFilter(1280, "Умения из прошлой жизни"), --ID: 280
			CheckboxFilter(1493, "Умная пара"), --ID: 493
			CheckboxFilter(1033, "Умный главный герой"), --ID: 33
			CheckboxFilter(1254, "Уникальная техника Культивации"), --ID: 254
			CheckboxFilter(1340, "Уникальное оружие"), --ID: 340
			CheckboxFilter(1315, "Управление бизнесом"), --ID: 315
			CheckboxFilter(1167, "Управление временем"), --ID: 167
			CheckboxFilter(1764, "Управление кровью"), --ID: 764
			CheckboxFilter(1672, "Упрямый главный герой"), --ID: 672
			CheckboxFilter(1803, "Уродливый главный герой"), --ID: 803
			CheckboxFilter(1300, "Ускоренный рост"), --ID: 300
			CheckboxFilter(1481, "Усыновленные дети"), --ID: 481
			CheckboxFilter(1412, "Усыновленный главный герой"), --ID: 412
			CheckboxFilter(1398, "Уход за детьми"), --ID: 398
			CheckboxFilter(1345, "Учителя"), --ID: 345
			CheckboxFilter(1541, "Фамильяры"), --ID: 541
			CheckboxFilter(1613, "Фанатизм"), --ID: 613
			CheckboxFilter(1322, "Фантастические существа"), --ID: 322
			CheckboxFilter(1388, "Фанфикшн"), --ID: 388
			CheckboxFilter(1715, "Фармацевт"), --ID: 715
			CheckboxFilter(1379, "Фарминг"), --ID: 379
			CheckboxFilter(1210, "Феи"), --ID: 210
			CheckboxFilter(1584, "Фелляция"), --ID: 584
			CheckboxFilter(1374, "Фениксы"), --ID: 374
			CheckboxFilter(1499, "Фетиш груди"), --ID: 499
			CheckboxFilter(1087, "Философия"), --ID: 87
			CheckboxFilter(1403, "Фильмы"), --ID: 403
			CheckboxFilter(1528, "Флэшбэки"), --ID: 528
			CheckboxFilter(1100, "Фобии"), --ID: 100
			CheckboxFilter(1467, "Фольклор"), --ID: 467
			CheckboxFilter(1568, "Футанари"), --ID: 568
			CheckboxFilter(1382, "Футуристический сеттинг"), --ID: 382
			CheckboxFilter(1126, "Фэнтези мир"), --ID: 126
			CheckboxFilter(1399, "Хакеры"), --ID: 399
			CheckboxFilter(1391, "Харизматический герой"), --ID: 391
			CheckboxFilter(1462, "Хикикомори/Затворники"), --ID: 462
			CheckboxFilter(1105, "Хитроумный главный герой"), --ID: 105
			CheckboxFilter(1557, "Хозяин подземелий"), --ID: 557
			CheckboxFilter(1259, "Холодный главный герой"), --ID: 259
			CheckboxFilter(1506, "Хорошие отношения с семьей"), --ID: 506
			CheckboxFilter(1068, "Хранители могил"), --ID: 68
			CheckboxFilter(1389, "Целители"), --ID: 389
			CheckboxFilter(1735, "Цзянши"), --ID: 735
			CheckboxFilter(1445, "Цундэрэ"), --ID: 445
			CheckboxFilter(1580, "Чаты"), --ID: 580
			CheckboxFilter(1521, "Человеческое оружие"), --ID: 521
			CheckboxFilter(1240, "Честный главный герой"), --ID: 240
			CheckboxFilter(1238, "Читы"), --ID: 238
			CheckboxFilter(1526, "Шантаж"), --ID: 526
			CheckboxFilter(1239, "Шеф-повар"), --ID: 239
			CheckboxFilter(1543, "Шикигами"), --ID: 543
			CheckboxFilter(1633, "Школа только для девочек"), --ID: 633
			CheckboxFilter(1514, "Шота"), --ID: 514
			CheckboxFilter(1407, "Шоу-бизнес"), --ID: 407
			CheckboxFilter(1563, "Шпионы"), --ID: 563
			CheckboxFilter(1196, "Эволюция"), --ID: 196
			CheckboxFilter(1539, "Эгоистичный главный герой"), --ID: 539
			CheckboxFilter(1392, "Эйдетическая память"), --ID: 392
			CheckboxFilter(1504, "Экзорсизм"), --ID: 504
			CheckboxFilter(1492, "Экономика"), --ID: 492
			CheckboxFilter(1639, "Эксгибиционизм"), --ID: 639
			CheckboxFilter(1129, "Эксперименты с людьми"), --ID: 129
			CheckboxFilter(1395, "Элементальная магия"), --ID: 395
			CheckboxFilter(1172, "Эльфы"), --ID: 172
			CheckboxFilter(1816, "Эмоционально слабый главный герой"), --ID: 816
			CheckboxFilter(1612, "Эпизодический"), --ID: 612
			CheckboxFilter(1446, "Юный любовный интерес"), --ID: 446
			CheckboxFilter(1410, "Яды"), --ID: 410
			CheckboxFilter(1406, "Языкастые персонажи"), --ID: 406
			CheckboxFilter(1059, "Языковой барьер"), --ID: 59
			CheckboxFilter(1208, "Яндере"), --ID: 208
			CheckboxFilter(1559, "Японские силы самообороны"), --ID: 559
			CheckboxFilter(1272, "Ярко выраженная романтическая линия"), --ID: 272
			CheckboxFilter(1611, "[Награжденная работа]"), --ID: 611
			CheckboxFilter(1516, "Ёкаи"), --ID: 516
			CheckboxFilter(1625, "Abusive Characters"), --ID: 625
			CheckboxFilter(2046, "Adapted to Visual Novel"), --ID: 1046
			CheckboxFilter(1886, "Adopted-lead"), --ID: 886
			CheckboxFilter(1866, "Adultery"), --ID: 866
			CheckboxFilter(1645, "Affair"), --ID: 645
			CheckboxFilter(1923, "Age-gap"), --ID: 923
			CheckboxFilter(1975, "Almost-human-lead"), --ID: 975
			CheckboxFilter(1780, "An*l"), --ID: 780
			CheckboxFilter(2002, "Androgynous-male-lead"), --ID: 1002
			CheckboxFilter(1976, "Anti-hero-lead"), --ID: 976
			CheckboxFilter(1967, "Apathetic-lead"), --ID: 967
			CheckboxFilter(1839, "Arms Dealers"), --ID: 839
			CheckboxFilter(2003, "Army-commander"), --ID: 1003
			CheckboxFilter(1924, "Artifact-refining"), --ID: 924
			CheckboxFilter(1855, "Autism"), --ID: 855
			CheckboxFilter(1669, "Awkward Protagonist"), --ID: 669
			CheckboxFilter(1892, "Awkward-lead"), --ID: 892
			CheckboxFilter(1796, "Bestiality"), --ID: 796
			CheckboxFilter(1908, "Big-breasts"), --ID: 908
			CheckboxFilter(2004, "Birth-of-a-nation"), --ID: 1004
			CheckboxFilter(2027, "Bisexual-lead"), --ID: 1027
			CheckboxFilter(1947, "Body-refining"), --ID: 947
			CheckboxFilter(2036, "Body-swap/s"), --ID: 1036
			CheckboxFilter(1876, "Boss-subordinate-relationship"), --ID: 876
			CheckboxFilter(1948, "Bride-kidnapping"), --ID: 948
			CheckboxFilter(1879, "Caring-lead"), --ID: 879
			CheckboxFilter(2032, "Cautious-lead"), --ID: 1032
			CheckboxFilter(1925, "Changed-man"), --ID: 925
			CheckboxFilter(2005, "Charismatic-lead"), --ID: 1005
			CheckboxFilter(1936, "Child-lead"), --ID: 936
			CheckboxFilter(1880, "Clever-lead"), --ID: 880
			CheckboxFilter(1815, "Clumsy Love Interests"), --ID: 815
			CheckboxFilter(1651, "Cold Love Interests"), --ID: 651
			CheckboxFilter(1860, "Coming of Age"), --ID: 860
			CheckboxFilter(1894, "Confident-lead"), --ID: 894
			CheckboxFilter(1951, "Confident-male-lead"), --ID: 951
			CheckboxFilter(1767, "Confinement"), --ID: 767
			CheckboxFilter(1793, "Conflicting Loyalties"), --ID: 793
			CheckboxFilter(1690, "Couple Growth"), --ID: 690
			CheckboxFilter(1863, "Court Official"), --ID: 863
			CheckboxFilter(1703, "Cowardly Protagonist"), --ID: 703
			CheckboxFilter(2000, "Cowardly-lead"), --ID: 1000
			CheckboxFilter(1250, "Cross-dressing"), --ID: 250
			CheckboxFilter(1867, "Cunnilingus"), --ID: 867
			CheckboxFilter(1952, "Cunning-lead"), --ID: 952
			CheckboxFilter(1953, "Cunning-male-lead"), --ID: 953
			CheckboxFilter(1849, "Curious Protagonist"), --ID: 849
			CheckboxFilter(1887, "Cute-lead"), --ID: 887
			CheckboxFilter(1868, "Dense-lead"), --ID: 868
			CheckboxFilter(1972, "Determined-lead"), --ID: 972
			CheckboxFilter(2006, "Developing-technology"), --ID: 1006
			CheckboxFilter(2007, "Devil/s"), --ID: 1007
			CheckboxFilter(1758, "Different Social Status"), --ID: 758
			CheckboxFilter(1838, "Disfigurement"), --ID: 838
			CheckboxFilter(1665, "Doting Love Interests"), --ID: 665
			CheckboxFilter(1609, "Doting Older Siblings"), --ID: 609
			CheckboxFilter(1530, "Doting Parents"), --ID: 530
			CheckboxFilter(1990, "Dungeon/s-exploring"), --ID: 990
			CheckboxFilter(1774, "Elderly Protagonist"), --ID: 774
			CheckboxFilter(1729, "Enlightenment"), --ID: 729
			CheckboxFilter(2047, "Eunuch"), --ID: 1047
			CheckboxFilter(1386, "Eye Powers"), --ID: 386
			CheckboxFilter(1785, "Family Business"), --ID: 785
			CheckboxFilter(1790, "Famous Parents"), --ID: 790
			CheckboxFilter(1897, "Famous-lead"), --ID: 897
			CheckboxFilter(1942, "Fanfic"), --ID: 942
			CheckboxFilter(1797, "Fated Lovers"), --ID: 797
			CheckboxFilter(1870, "Fellatio"), --ID: 870
			CheckboxFilter(1888, "Female-lead"), --ID: 888
			CheckboxFilter(1871, "First-time-intercourse"), --ID: 871
			CheckboxFilter(1836, "Fleet Battles"), --ID: 836
			CheckboxFilter(1808, "Forced Living Arrangements"), --ID: 808
			CheckboxFilter(1835, "Forced Marriage"), --ID: 835
			CheckboxFilter(1752, "Former Hero"), --ID: 752
			CheckboxFilter(2045, "Fujoshi"), --ID: 1045
			CheckboxFilter(1848, "Galge"), --ID: 848
			CheckboxFilter(2031, "Gambling"), --ID: 1031
			CheckboxFilter(1994, "Gamelit"), --ID: 994
			CheckboxFilter(2008, "Genderless-lead"), --ID: 1008
			CheckboxFilter(1995, "Glasses-wearing-lead"), --ID: 995
			CheckboxFilter(1197, "Guardian Relationship"), --ID: 197
			CheckboxFilter(1629, "H*ndjob"), --ID: 629
			CheckboxFilter(1956, "Half-human-lead"), --ID: 956
			CheckboxFilter(1957, "Hard-working-lead"), --ID: 957
			CheckboxFilter(1958, "Hard-working-male-lead"), --ID: 958
			CheckboxFilter(2030, "Hard-working-protagonist/s"), --ID: 1030
			CheckboxFilter(1929, "Harem-seeking-lead"), --ID: 929
			CheckboxFilter(1909, "Harem-subtext"), --ID: 909
			CheckboxFilter(1760, "Helpful Protagonist"), --ID: 760
			CheckboxFilter(1882, "Helpful-lead"), --ID: 882
			CheckboxFilter(1998, "Hidden-gem"), --ID: 998
			CheckboxFilter(1991, "High-fantasy"), --ID: 991
			CheckboxFilter(2009, "Human-becomes-demon/monster"), --ID: 1009
			CheckboxFilter(1914, "Human-nonhuman-relationship"), --ID: 914
			CheckboxFilter(1915, "Humanoid-lead"), --ID: 915
			CheckboxFilter(1805, "Imperial Harem"), --ID: 805
			CheckboxFilter(1831, "Insects"), --ID: 831
			CheckboxFilter(1959, "Interspatial-storage"), --ID: 959
			CheckboxFilter(1757, "Kind Love Interests"), --ID: 757
			CheckboxFilter(2010, "Large-number-of-skills"), --ID: 1010
			CheckboxFilter(2011, "Legendary-hero"), --ID: 1011
			CheckboxFilter(1977, "Litrpg"), --ID: 977
			CheckboxFilter(1788, "Love Rivals"), --ID: 788
			CheckboxFilter(1853, "Lovers Reunited"), --ID: 853
			CheckboxFilter(2037, "Low-fantasy"), --ID: 1037
			CheckboxFilter(1899, "Master-disciple-relationship"), --ID: 899
			CheckboxFilter(1807, "Matriarchy"), --ID: 807
			CheckboxFilter(1900, "Mature-lead"), --ID: 900
			CheckboxFilter(1862, "Mind Break"), --ID: 862
			CheckboxFilter(1695, "Mismatched Couple"), --ID: 695
			CheckboxFilter(1648, "Mob Protagonist"), --ID: 648
			CheckboxFilter(1902, "Mob-lead"), --ID: 902
			CheckboxFilter(1988, "Modern"), --ID: 988
			CheckboxFilter(2012, "Monster-pov"), --ID: 1012
			CheckboxFilter(1856, "Mpreg"), --ID: 856
			CheckboxFilter(2013, "Multiple-povs"), --ID: 1013
			CheckboxFilter(1710, "Mystery Solving"), --ID: 710
			CheckboxFilter(2014, "Naive-lead"), --ID: 1014
			CheckboxFilter(1996, "Near-death-experience"), --ID: 996
			CheckboxFilter(1495, "Neet"), --ID: 495
			CheckboxFilter(1833, "Nightmares"), --ID: 833
			CheckboxFilter(2015, "Nobility"), --ID: 1015
			CheckboxFilter(1978, "Non-human-lead"), --ID: 978
			CheckboxFilter(2016, "Non-humanoid-lead"), --ID: 1016
			CheckboxFilter(1979, "Not-so-secret-identity"), --ID: 979
			CheckboxFilter(1857, "Omegaverse"), --ID: 857
			CheckboxFilter(1910, "Online-game"), --ID: 910
			CheckboxFilter(1911, "Online-gaming"), --ID: 911
			CheckboxFilter(1847, "Outdoor Interc**rse"), --ID: 847
			CheckboxFilter(1903, "Outdoor-intercourse"), --ID: 903
			CheckboxFilter(1610, "Overprotective Siblings"), --ID: 610
			CheckboxFilter(1865, "Part-Time Job"), --ID: 865
			CheckboxFilter(1726, "Past Trauma"), --ID: 726
			CheckboxFilter(2017, "Past-memories"), --ID: 1017
			CheckboxFilter(1714, "Persistent Love Interests"), --ID: 714
			CheckboxFilter(1932, "Perverted-lead"), --ID: 932
			CheckboxFilter(1798, "Photography"), --ID: 798
			CheckboxFilter(1279, "Pill Based Cultivation"), --ID: 279
			CheckboxFilter(1245, "Pill Concocting"), --ID: 245
			CheckboxFilter(1820, "Pilots"), --ID: 820
			CheckboxFilter(1795, "Playboys"), --ID: 795
			CheckboxFilter(1989, "Playful-lead"), --ID: 989
			CheckboxFilter(1811, "Polyandry"), --ID: 811
			CheckboxFilter(1992, "Portal-fantasy-/-isekai"), --ID: 992
			CheckboxFilter(1884, "Pragmatic-lead"), --ID: 884
			CheckboxFilter(1980, "Profanity"), --ID: 980
			CheckboxFilter(1905, "Protagonist-loyal-to-love-interest"), --ID: 905
			CheckboxFilter(1230, "R-15 (Японское возрастное ограничение)"), --ID: 230
			CheckboxFilter(1834, "Rebellion"), --ID: 834
			CheckboxFilter(1804, "Reincarnated in a Game World"), --ID: 804
			CheckboxFilter(1696, "Reluctant Protagonist"), --ID: 696
			CheckboxFilter(1776, "Reverse R*pe"), --ID: 776
			CheckboxFilter(1854, "Reversible Couple"), --ID: 854
			CheckboxFilter(1943, "Ruling-class"), --ID: 943
			CheckboxFilter(1750, "S*x Friends"), --ID: 750
			CheckboxFilter(1823, "S*xual Cultivation Technique"), --ID: 823
			CheckboxFilter(2035, "Salaryman"), --ID: 1035
			CheckboxFilter(1981, "Satire"), --ID: 981
			CheckboxFilter(1745, "Schemes And Conspiracies"), --ID: 745
			CheckboxFilter(1997, "Scientist/s"), --ID: 997
			CheckboxFilter(2029, "Scientists"), --ID: 1029
			CheckboxFilter(1827, "Secret Crush"), --ID: 827
			CheckboxFilter(2034, "Seme Protagonist"), --ID: 1034
			CheckboxFilter(2028, "Seme-lead"), --ID: 1028
			CheckboxFilter(2048, "Sentimental Protagonist"), --ID: 1048
			CheckboxFilter(2018, "Seven-heavenly-virtues"), --ID: 1018
			CheckboxFilter(1350, "Sexual Cultivation Technique"), --ID: 350
			CheckboxFilter(1982, "Sexual-content"), --ID: 982
			CheckboxFilter(1983, "Sexuality"), --ID: 983
			CheckboxFilter(1814, "Sharing A Body"), --ID: 814
			CheckboxFilter(1858, "Shotacon"), --ID: 858
			CheckboxFilter(1777, "Shoujo-Ai Subplot"), --ID: 777
			CheckboxFilter(1766, "Sibling Rivalry"), --ID: 766
			CheckboxFilter(2042, "Sibling's Care"), --ID: 1042
			CheckboxFilter(1787, "Sickly Characters"), --ID: 787
			CheckboxFilter(2019, "Skills"), --ID: 1019
			CheckboxFilter(2001, "Slave-harem"), --ID: 1001
			CheckboxFilter(2020, "Slime"), --ID: 1020
			CheckboxFilter(1963, "Smart-male-lead"), --ID: 963
			CheckboxFilter(1739, "Spirit Users"), --ID: 739
			CheckboxFilter(1819, "Straight Seme"), --ID: 819
			CheckboxFilter(1818, "Straight Uke"), --ID: 818
			CheckboxFilter(1974, "Strength-based-social-hierarchy"), --ID: 974
			CheckboxFilter(1944, "Strong-lead"), --ID: 944
			CheckboxFilter(1964, "Strong-male-lead"), --ID: 964
			CheckboxFilter(2026, "Student-teacher-relationship"), --ID: 1026
			CheckboxFilter(1987, "Suspense"), --ID: 987
			CheckboxFilter(1875, "Sword-and-sorcery"), --ID: 875
			CheckboxFilter(1574, "Threesome"), --ID: 574
			CheckboxFilter(1736, "Transformation Ability"), --ID: 736
			CheckboxFilter(2040, "Traumatising-content"), --ID: 1040
			CheckboxFilter(1919, "Underestimated-lead"), --ID: 919
			CheckboxFilter(1966, "Underestimated-male-lead"), --ID: 966
			CheckboxFilter(2021, "Unique-abilities"), --ID: 1021
			CheckboxFilter(2022, "Unique-skill"), --ID: 1022
			CheckboxFilter(2023, "Unique-skills"), --ID: 1023
			CheckboxFilter(2044, "Unlimited Flow"), --ID: 1044
			CheckboxFilter(1806, "Unrequited Love"), --ID: 806
			CheckboxFilter(2041, "Urban-fantasy"), --ID: 1041
			CheckboxFilter(1719, "Villainess Noble Girls"), --ID: 719
			CheckboxFilter(1885, "Weak-lead"), --ID: 885
			CheckboxFilter(2024, "Web-novel"), --ID: 1024
			CheckboxFilter(1338, "18+"), --ID: 338
		}),
		FilterGroup("Жанры", { --offset: 2100
			CheckboxFilter(2122, "Боевые искусства"), --ID: 22
			CheckboxFilter(2214, "Гарем"), --ID: 114
			CheckboxFilter(2346, "Гендер бендер"), --ID: 246
			CheckboxFilter(2316, "Дзёсэй"), --ID: 216
			CheckboxFilter(2215, "Для взрослых"), --ID: 115
			CheckboxFilter(2358, "Для взрослых"), --ID: 258
			CheckboxFilter(2107, "Драма"), --ID: 7
			CheckboxFilter(2201, "Исторический"), --ID: 101
			CheckboxFilter(2117, "Комедия"), --ID: 17
			CheckboxFilter(2738, "Лоликон"), --ID: 638
			CheckboxFilter(3022, "Магический реализм"), --ID: 922
			CheckboxFilter(2124, "Меха"), --ID: 24
			CheckboxFilter(2112, "Милитари"), --ID: 12
			CheckboxFilter(2102, "Мистика"), --ID: 2
			CheckboxFilter(2113, "Научная фантастика"), --ID: 13
			CheckboxFilter(2847, "Непристойность"), --ID: 747
			CheckboxFilter(2193, "Повседневность"), --ID: 93
			CheckboxFilter(2111, "Приключение"), --ID: 11
			CheckboxFilter(2118, "Психология"), --ID: 18
			CheckboxFilter(2109, "Романтика"), --ID: 9
			CheckboxFilter(2115, "Сёдзё"), --ID: 15
			CheckboxFilter(2123, "Сёдзё-ай"), --ID: 23
			CheckboxFilter(2289, "Сёнэн"), --ID: 189
			CheckboxFilter(2780, "Сёнэн-ай"), --ID: 680
			CheckboxFilter(2120, "Сверхъестественное"), --ID: 20
			CheckboxFilter(2520, "Спорт"), --ID: 420
			CheckboxFilter(2105, "Сэйнэн"), --ID: 5
			CheckboxFilter(2342, "Сюаньхуа"), --ID: 242
			CheckboxFilter(2464, "Сянься"), --ID: 364
			CheckboxFilter(2119, "Трагедия"), --ID: 19
			CheckboxFilter(2103, "Триллер"), --ID: 3
			CheckboxFilter(2101, "Ужасы"), --ID: 1
			CheckboxFilter(2820, "Уся"), --ID: 720
			CheckboxFilter(2108, "Фэнтези"), --ID: 8
			CheckboxFilter(2121, "Школьная жизнь"), --ID: 21
			CheckboxFilter(2114, "Экшн"), --ID: 14
			CheckboxFilter(2427, "Эччи"), --ID: 327
			CheckboxFilter(2791, "Юри"), --ID: 691
			CheckboxFilter(2782, "Яой"), --ID: 682
			CheckboxFilter(3007, "Eastern fantasy"), --ID: 907
			CheckboxFilter(3099, "Isekai"), --ID: 999
			CheckboxFilter(3093, "Video games"), --ID: 993
		})
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	shrinkURL = shrinkURL,
	expandURL = expandURL,
}
