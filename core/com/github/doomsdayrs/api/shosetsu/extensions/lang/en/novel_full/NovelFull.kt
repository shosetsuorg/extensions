package com.github.doomsdayrs.api.shosetsu.extensions.lang.en.novel_full


import com.github.doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat
import com.github.doomsdayrs.api.shosetsu.services.core.objects.*
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.jsoup.select.Elements

/*
 * This file is part of shosetsu-extensions.
 * shosetsu-extensions is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * shosetsu-extensions is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with shosetsu-extensions.  If not, see https://www.gnu.org/licenses/.
 * ====================================================================
 */
/**
 * novelreader-extensions
 * 30 / May / 2019
 *
 * @author github.com/doomsdayrs
 */
class NovelFull : ScrapeFormat(1) {
    private val baseURL = "http://novelfull.com"

    override val name: String = "NovelFull"

    override val imageURL = ""

    override var isIncrementingChapterList: Boolean = true

    private fun stripListing(data: Elements, novel: Novel) {
        for (y in data.indices) {
            val coloum = data[y]
            when (y) {
                0 -> {
                    run {
                        val image = coloum.selectFirst("img")
                        if (image != null) novel.imageURL = baseURL + image.attr("src")
                    }
                    run {
                        val header = coloum.selectFirst("h3")
                        if (header != null) {
                            val titleLink = header.selectFirst("a")
                            novel.title = titleLink.attr("title")
                            novel.link = baseURL + titleLink.attr("href")
                        }
                    }
                }
                1 -> {
                    val header = coloum.selectFirst("h3")
                    if (header != null) {
                        val titleLink = header.selectFirst("a")
                        novel.title = titleLink.attr("title")
                        novel.link = baseURL + titleLink.attr("href")
                    }
                }
                else -> {
                }
            }
        }
    }

    override fun getLatestURL(page: Int): String {
        return "$baseURL/latest-release-novel?page=$page"
    }

    override fun getNovelPassage(document: Document): String {
        val paragraphs = document.select("div.chapter-c").select("p")
        val stringBuilder = StringBuilder()
        for (element in paragraphs) stringBuilder.append(element.text()).append("\n")
        return stringBuilder.toString()
    }

    /**
     * TITLE:YES
     * IMAGEURL: YES
     * DESCRIPTION: YES
     * GENRES: YES
     * AUTHORS: YES
     * STATUS: YES
     * TAGS: NO
     * ARTISTS: NO
     * LANGUAGE: NO
     * MAXCHAPTERPAGE: YES
     * NOVELCHAPTERS: YES
     */
    override fun parseNovel(document: Document): NovelPage {
        return this.parseNovel(document, 1)
    }

    override fun parseNovel(document: Document, increment: Int): NovelPage {
        val novelPage = NovelPage()
        //Sets image
        novelPage.imageURL = baseURL + document.selectFirst("div.book").selectFirst("img").attr("src")
        // Gets max page
        run {
            var lastPageURL = document.selectFirst("ul.pagination.pagination-sm").selectFirst("li.last").select("a").attr("href")
            if (lastPageURL.isNotEmpty()) {
                lastPageURL = baseURL + lastPageURL
                lastPageURL = lastPageURL.substring(lastPageURL.indexOf("?page=") + 6, lastPageURL.indexOf("&per-page="))
                novelPage.maxChapterPage = lastPageURL.toInt()
            } else novelPage.maxChapterPage = increment
        }
        // Sets description
        run {
            val titleDescription = document.selectFirst("div.col-xs-12.col-sm-8.col-md-8.desc")
            novelPage.title = titleDescription.selectFirst("h3").text()
            val description = titleDescription.selectFirst("div.desc-text")
            val text = description.select("p")
            val stringBuilder = StringBuilder()
            for (paragraph in text) {
                stringBuilder.append(paragraph.text()).append("\n")
            }
            novelPage.description = stringBuilder.toString()
        }
        // Formats the chapters
        run {
            val novelChapters: ArrayList<NovelChapter> = arrayListOf()
            val lists = document.select("ul.list-chapter")
            var a: Int = if (increment > 1) (increment - 1) * 50 else 0
            for (list in lists) {
                val chapters = list.select("li")
                for (chapter in chapters) {
                    val novelChapter = NovelChapter()
                    val chapterData = chapter.selectFirst("a")
                    val link = chapterData.attr("href")
                    if (link != null) novelChapter.link = baseURL + link
                    novelChapter.title = chapterData.attr("title")
                    if (novelChapter.title.isNotEmpty() && !novelChapter.link.contains("null")) {
                        novelChapter.order = a.toDouble()
                        a++
                        novelChapters.add(novelChapter)
                    }
                }
            }
            novelPage.novelChapters = novelChapters
        }
        // Sets info Author, Genre, Source, Status
        run {
            val elements = document.selectFirst("div.info").select("div.info").select("div")
            for (x in elements.indices) {
                var subelemets: Elements
                when (x) {
                    0 -> {
                    }
                    1 -> {
                        subelemets = elements[x].select("a")
                        val authors: ArrayList<String> = arrayListOf()
                        for (element: Element in subelemets) authors.add(element.text())
                        novelPage.authors = authors.toArray(arrayOf(""))
                    }
                    2 -> {
                        subelemets = elements[x].select("a")
                        val genres: ArrayList<String> = arrayListOf()
                        for (element: Element in subelemets) genres.add(element.text())
                        novelPage.genres = genres.toArray(arrayOf(""))
                    }
                    3 -> {
                    }
                    4 -> {
                        when (elements[x].select("a").text()) {
                            "Completed" -> novelPage.status = NovelStatus.COMPLETED
                            "Ongoing" -> novelPage.status = NovelStatus.PUBLISHING
                            else -> {
                            }
                        }
                    }
                }
            }
        }
        return novelPage
    }

    override fun novelPageCombiner(url: String, increment: Int): String {
        var s = url
        //s = verify(baseURL, s)
        if (increment > 1) s = "$s?page=$increment"
        return s
    }

    override fun parseLatest(document: Document): List<Novel> {
        val novels: ArrayList<Novel> = arrayListOf()
        val divMAIN = document.select("div.container")
        for (element in divMAIN) {
            if (element.id() == "list-page") {
                val list = element.selectFirst("div")
                val releases = list.select("div.row")
                //For each novel
                for (release in releases) {
                    val novel = Novel()
                    val data = release.select("div")
                    //For each coloum
                    stripListing(data, novel)
                    novels.add(novel)
                }
            }
        }
        return novels
    }

    override fun getSearchString(query: String): String {
        return baseURL + "/search?keyword=" + query.replace(" ".toRegex(), "%20")
    }

    override fun parseSearch(document: Document): List<Novel> {
        val novels: ArrayList<Novel> = arrayListOf()
        val listP = document.select("div.container")
        for (list in listP) if (list.id() == "list-page") {
            val queries = list.select("div.row")
            for (q in queries) {
                val novel = Novel()
                stripListing(q.select("div"), novel)
                novels.add(novel)
            }
        }
        return novels
    }

    override val genres: Array<NovelGenre>
        get() {
            val url = "$baseURL/genre/"
            return arrayOf(
                    NovelGenre("Shounen", true, url + "Shounen"),
                    NovelGenre("Harem", true, url + "Harem"),
                    NovelGenre("Comedy", true, url + "Comedy"),
                    NovelGenre("Martial Arts", true, url + "Martial Arts"),
                    NovelGenre("School Life", true, url + "School Life"),
                    NovelGenre("Mystery", true, url + "Mystery"),
                    NovelGenre("Shoujo", true, url + "Shoujo"),
                    NovelGenre("Romance", true, url + "Romance"),
                    NovelGenre("Sci-fi", true, url + "Sci-fi"),
                    NovelGenre("Gender Bender", true, url + "Gender Bender"),
                    NovelGenre("Mature", true, url + "Mature"),
                    NovelGenre("Fantasy", true, url + "Fantasy"),
                    NovelGenre("Horror", true, url + "Horror"),
                    NovelGenre("Drama", true, url + "Drama"),
                    NovelGenre("Tragedy", true, url + "Tragedy"),
                    NovelGenre("Supernatural", true, url + "Supernatural"),
                    NovelGenre("Ecchi", true, url + "Ecchi"),
                    NovelGenre("Xuanhuan", true, url + "Xuanhuan"),
                    NovelGenre("Adventure", true, url + "Adventure"),
                    NovelGenre("Action", true, url + "Action"),
                    NovelGenre("Psychological", true, url + "Psychological"),
                    NovelGenre("Xianxia", true, url + "Xianxia"),
                    NovelGenre("Wuxia", true, url + "Wuxia"),
                    NovelGenre("Historical", true, url + "Historical"),
                    NovelGenre("Slice of Life", true, url + "Slice of Life"),
                    NovelGenre("Seinen", true, url + "Seinen"),
                    NovelGenre("Lolicon", true, url + "Lolicon"),
                    NovelGenre("Adult", true, url + "Adult"),
                    NovelGenre("Josei", true, url + "Josei"),
                    NovelGenre("Sports", true, url + "Sports"),
                    NovelGenre("Smut", true, url + "Smut"),
                    NovelGenre("Mecha", true, url + "Mecha"))
        }
}