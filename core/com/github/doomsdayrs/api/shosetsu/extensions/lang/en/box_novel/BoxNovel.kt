@file:Suppress("unused")

package com.github.doomsdayrs.api.shosetsu.extensions.lang.en.box_novel

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
 * shosetsu-extensions
 * 11 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
class BoxNovel : ScrapeFormat(2) {
    private val baseURL = "https://boxnovel.com"

    override val name: String = "BoxNovel"

    override val imageURL: String = "https://boxnovel.com/wp-content/uploads/2018/04/BoxNovel-1.png"

    override fun getNovelPassage(document: Document): String {
        val paragraphs = document.select("div.text-left").select("p")
        val stringBuilder = StringBuilder()
        for (element in paragraphs) stringBuilder.append(element.toString()).append("\n")
        return stringBuilder
                .toString()
                .replace("<p>".toRegex(), "")
                .replace("</p>".toRegex(), "")
    }

    override fun getLatestURL(page: Int): String {
        return "$baseURL/novel/page/$page/?m_orderby=latest"
    }

    /**
     * TITLE:YES
     * IMAGEURL: YES
     * DESCRIPTION: YES
     * GENRES: YES
     * AUTHORS: YES
     * STATUS: YES
     * TAGS: NO
     * ARTISTS: YES
     * LANGUAGE: NO
     * MAXCHAPTERPAGE: NO
     * NOVELCHAPTERS: YES
     */
    override fun parseNovel(document: Document): NovelPage {
        val novelPage = NovelPage()
        novelPage.imageURL = document.selectFirst("div.summary_image").selectFirst("img.img-responsive").attr("src")
        novelPage.title = document.selectFirst("h3").text()
        novelPage.description = document.selectFirst("p").text()
        run {
            var elements = document.selectFirst("div.post-content").select("div.post-content_item")
            for (x in elements.indices) {
                var subElements: Elements
                when (x) {
                    0, 2, 1 -> {
                    }
                    3 -> {
                        subElements = elements[x].select("a")
                        val authors: ArrayList<String> = arrayListOf()
                        for (element: Element in subElements) authors.add(element.text())
                        novelPage.authors = authors.toArray(arrayOf(""))
                    }
                    4 -> {
                        subElements = elements[x].select("a")
                        val artists: ArrayList<String> = arrayListOf()
                        for (element: Element in subElements) artists.add(element.text())
                        novelPage.artists = artists.toArray(arrayOf(""))
                    }
                    5 -> {
                        subElements = elements[x].select("a")
                        val genres: ArrayList<String> = arrayListOf()
                        for (element: Element in subElements) genres.add(element.text())
                        novelPage.genres = genres.toArray(arrayOf(""))
                    }
                    6 -> {
                    }
                }
            }
            elements = document.selectFirst("div.post-status").select("div.post-content_item")
            for (x in elements.indices) {
                when (x) {
                    0, 2 -> {
                    }
                    1 -> {
                        when (elements[x].select("div.summary-content").text()) {
                            "OnGoing" -> novelPage.status = NovelStatus.PUBLISHING
                            "Completed" -> novelPage.status = NovelStatus.COMPLETED
                        }
                    }
                }
            }
        }
        // Chapters
        run {
            val novelChapters: ArrayList<NovelChapter> = arrayListOf()
            val elements = document.select("li.wp-manga-chapter")
            var a = elements.size
            for (element in elements) {
                val novelChapter = NovelChapter()
                novelChapter.link = element.selectFirst("a").attr("href")
                novelChapter.title = element.selectFirst("a").text()
                novelChapter.release = element.selectFirst("i").text()
                novelChapter.order = a.toDouble()
                a--
                novelChapters.add(novelChapter)
            }
            novelChapters.reverse()
            novelPage.novelChapters = novelChapters
        }
        return novelPage
    }

    override fun parseNovel(document: Document, increment: Int): NovelPage {
        return parseNovel(document)
    }

    override fun parseLatest(document: Document): List<Novel> {
        val novels: MutableList<Novel> = ArrayList()
        val novelsHTML = document.select("div.col-xs-12.col-md-6")
        for (novelHTML in novelsHTML) {
            val novel = Novel()
            val data = novelHTML.selectFirst("a")
            novel.title = data.attr("title")
            novel.link = data.attr("href")
            novel.imageURL = data.selectFirst("img").attr("src")
            novels.add(novel)
        }
        return novels
    }

    override fun getSearchString(query: String): String {
        var s = query
        s = s.replace("\\+".toRegex(), "%2")
        s = s.replace(" ".toRegex(), "\\+")
        //Turns query into a URL
        s = "$baseURL/?s=$s&post_type=wp-manga"
        return s
    }

    override fun novelPageCombiner(url: String, increment: Int): String {
        return ""
    }

    override fun parseSearch(document: Document): List<Novel> {
        val novelsHTML = document.select("div.c-tabs-item__content")
        val novels: MutableList<Novel> = ArrayList()
        for (novelHTML in novelsHTML) {
            val novel = Novel()
            val data = novelHTML.selectFirst("a")
            novel.title = data.attr("title")
            novel.link = data.attr("href")
            novel.imageURL = data.selectFirst("img").attr("src")
            novels.add(novel)
        }
        return novels
    }

    override val genres: Array<NovelGenre> = arrayOf()
}