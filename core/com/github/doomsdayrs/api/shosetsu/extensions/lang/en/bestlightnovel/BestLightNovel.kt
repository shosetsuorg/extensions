@file:Suppress("unused")

package com.github.doomsdayrs.api.shosetsu.extensions.lang.en.bestlightnovel

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
import com.github.doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat
import com.github.doomsdayrs.api.shosetsu.services.core.objects.*
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.jsoup.select.Elements

/**
 * shosetsu-extensions
 * 02 / 08 / 2019
 *
 * @author github.com/doomsdayrs
 */
@Deprecated("Lua version")
class BestLightNovel : ScrapeFormat(5) {
    private val baseURL = "https://bestlightnovel.com"

    override val name: String = "BestLightNovel"

    override val imageURL: String = ""

    override fun getLatestURL(page: Int): String {
        var i = page
        if (i <= 0) i = 1
        return "$baseURL/novel_list?type=latest&category=all&state=all&page=$i"
    }

    override fun getNovelPassage(document: Document): String {
        val elements = document.selectFirst("div.vung_doc").select("p")
        val stringBuilder = StringBuilder()
        if (elements.size != 0) {
            for (element in elements)
                stringBuilder.append(element.text()).append("\n")
        } else stringBuilder.append("NOT YET TRANSLATED")
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
     * MAXCHAPTERPAGE: NO
     * NOVELCHAPTERS: YES
     */
    override fun parseNovel(document: Document): NovelPage {
        val novelPage = NovelPage()
        // Image
        run {
            val element = document.selectFirst("div.truyen_info_left")
            novelPage.imageURL = element.selectFirst("img").attr("src")
        }
        // Bulk data
        run {
            val element = document.selectFirst("ul.truyen_info_right")
            val elements = element.select("li")
            var text: String
            var subElement: Element
            var subElements: Elements
            var strings: ArrayList<String>
            for (x in elements.indices) {
                val e = elements[x]
                when (x) {
                    0 -> novelPage.title = e.selectFirst("h1").text()
                    1 -> {
                        subElements = e.select("a")
                        strings = arrayListOf()
                        var y = 0
                        while (y < strings.size) {
                            strings[y] = subElements[y].text()
                            y++
                        }
                        novelPage.authors = strings.toArray(arrayOf(""))
                    }
                    2 -> {
                        subElements = e.select("a")
                        strings = arrayListOf()
                        var y = 0
                        while (y < strings.size) {
                            strings[y] = subElements[y].text()
                            y++
                        }
                        novelPage.genres = strings.toArray(arrayOf(""))
                    }
                    3 -> {
                        subElement = e.selectFirst("a")
                        text = subElement.text()
                        when (text) {
                            "ongoing" -> novelPage.status = NovelStatus.PUBLISHING
                            "completed" -> novelPage.status = NovelStatus.COMPLETED
                            else -> {
                            }
                        }
                    }
                    else -> {
                    }
                }
            }
        }
        // Description
        run {
            val elements = document.selectFirst("div.entry-header").select("div")
            for (div in elements) {
                if (div.id() == "noidungm") {
                    var unformatted = div.text()
                    unformatted = unformatted.replace("<br>".toRegex(), "\n")
                    novelPage.description = unformatted
                }
            }
        }
        // Chapters
        run {
            val e = document.selectFirst("div.chapter-list")
            novelPage.novelChapters = arrayListOf()
            if (e != null) {
                val chapters = e.select("div.row")
                val novelChapters: ArrayList<NovelChapter> = arrayListOf()
                for ((y, row) in chapters.withIndex()) {
                    val novelChapter = NovelChapter()
                    val elements = row.select("span")
                    for (x in elements.indices) {
                        when (x) {
                            0 -> {
                                val titleLink = elements[x].selectFirst("a")
                                novelChapter.title = titleLink.attr("title").replace(novelPage.title,"")
                                novelChapter.link = titleLink.attr("href")
                            }
                            1 -> novelChapter.release = elements[x].text()
                        }
                    }
                    novelChapter.order = y.toDouble()
                    novelChapters.add(novelChapter)
                }
                novelChapters.reverse()
                novelPage.novelChapters = novelChapters
            }
        }
        return novelPage
    }

    override fun novelPageCombiner(url: String, increment: Int): String {
        return ""
    }

    override fun parseLatest(document: Document): List<Novel> {
        val novels: ArrayList<Novel> = arrayListOf()
        val elements = document.select("div.update_item.list_category")
        for (element in elements) {
            val novel = Novel()
            run {
                val e = element.selectFirst("h3.nowrap").selectFirst("a")
                novel.title = e.attr("title")
                novel.link = e.attr("href")
            }
            novel.imageURL = element.selectFirst("img").attr("src")
            novels.add(novel)
        }
        return novels
    }

    override fun parseNovel(document: Document, increment: Int): NovelPage {
        return parseNovel(document)
    }

    override fun getSearchString(query: String): String {
        var s = query
        s = s.replace(" ".toRegex(), "_")
        s = "$baseURL/search_novels/$s"
        return s
    }

    override fun parseSearch(document: Document): List<Novel> {
        val novels: MutableList<Novel> = ArrayList()
        val elements = document.select("div.update_item.list_category")
        for (element in elements) {
            val novel = Novel()
            run {
                val e = element.selectFirst("h3.nowrap").selectFirst("a")
                novel.title = e.attr("title")
                novel.link = e.attr("href")
            }
            novel.imageURL = element.selectFirst("img").attr("src")
            novels.add(novel)
        }
        return novels
    }

    override val genres: Array<NovelGenre> = arrayOf()
}