@file:Suppress("unused")

package com.github.doomsdayrs.api.shosetsu.extensions.lang.en.syosetu


import com.github.doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat
import com.github.doomsdayrs.api.shosetsu.services.core.objects.*
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import java.util.*

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
 * novelreaderextensions
 * 14 / 07 / 2019
 *
 * @author github.com/doomsdayrs
 */
class Syosetu : ScrapeFormat(3) {
    private val baseURL = "https://yomou.syosetu.com"
    private val passageURL = "https://ncode.syosetu.com"


    override val name: String
        get() = "Syosetu"

    override val genres: Array<NovelGenre>
        get() = TODO("not implemented") //To change initializer of created properties use File | Settings | File Templates.

    override val imageURL: String
        get() = "https://static.syosetu.com/view/images/common/logo_yomou.png"

    override fun getLatestURL(page: Int): String {
        var i = page
        if (i == 0) i = 1
        return "$baseURL/search.php?&search_type=novel&order_former=search&order=new&notnizi=1&p=$i"
    }

    override fun getNovelPassage(document: Document): String {
        var elements = document.select("div")
        var found = false
        var x = 0
        while (x < elements.size && !found) {
            if (elements[x].id() == "novel_contents") {
                found = true
                elements = elements[x].select("p")
            }
            x++
        }
        if (found) {
            val stringBuilder = StringBuilder()
            for (element in elements) {
                stringBuilder.append(element.text()).append("\n")
            }
            return stringBuilder.toString().replace("<br>".toRegex(), "\n\n")
        }
        return "INVALID PARSING, CONTACT DEVELOPERS"
    }

    /**
     * TITLE: YES
     * IMAGEURL: NO
     * DESCRIPTION: YES
     * GENRES: NO
     * AUTHORS: YES
     * STATUS: NO
     * TAGS: NO
     * ARTISTS: NO
     * LANGUAGE: NO
     * MAXCHAPTERPAGE: NO
     * NOVELCHAPTERS: YES
     */
    override fun parseNovel(document: Document): NovelPage {
        val novelPage = NovelPage()
        novelPage.authors = arrayOf(document.selectFirst("div.novel_writername").text().replace("作者：", ""))
        novelPage.title = document.selectFirst("p.novel_title").text()
        // Description
        run {
            var element: Element? = null
            var found = false
            val elements = document.select("div")
            var x = 0
            while (x < elements.size && !found) {
                if (elements[x].id() == "novel_color") {
                    element = elements[x]
                    found = true
                }
                x++
            }
            if (found) {
                var desc = element!!.text()
                desc = desc.replace("<br>\n<br>".toRegex(), "\n")
                desc = desc.replace("<br>".toRegex(), "\n")
                novelPage.description = desc
            }
        }
        //Chapters
        run {
            val novelChapters: MutableList<NovelChapter> = ArrayList()
            val elements = document.select("dl.novel_sublist2")
            for ((x, element) in elements.withIndex()) {
                val novelChapter = NovelChapter()
                novelChapter.title = element.selectFirst("a").text()
                novelChapter.link = passageURL + element.selectFirst("a").attr("href")
                novelChapter.release = element.selectFirst("dt.long_update").text()
                novelChapter.order = x.toDouble()
                novelChapters.add(novelChapter)
            }
            novelPage.novelChapters = novelChapters
        }
        return novelPage
    }


    override fun parseLatest(document: Document): List<Novel> {
        val novels: MutableList<Novel> = ArrayList()
        val elements = document.select("div.searchkekka_box")
        for (element in elements) {
            val novel = Novel()
            run {
                val e = element.selectFirst("div.novel_h").selectFirst("a.tl")
                novel.link = e.attr("href")
                novel.title = e.text()
            }
            novel.imageURL = ""
            novels.add(novel)
        }
        return novels
    }

    override fun parseNovel(document: Document, increment: Int): NovelPage {
        return parseNovel(document)
    }

    override fun getSearchString(query: String): String {
        var s = query
        s = s.replace("\\+".toRegex(), "%2")
        s = s.replace(" ".toRegex(), "\\+")
        s = "$baseURL/search.php?&word=$s"
        return s
    }

    override fun novelPageCombiner(url: String, increment: Int): String {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun parseSearch(document: Document): List<Novel> {
        val novels: MutableList<Novel> = ArrayList()
        val elements = document.select("div.searchkekka_box")
        for (element in elements) {
            val novel = Novel()
            run {
                val e = element.selectFirst("div.novel_h").selectFirst("a.tl")
                novel.link = e.attr("href")
                novel.title = e.text()
            }
            novel.imageURL = ""
            novels.add(novel)
        }
        return novels
    }

}