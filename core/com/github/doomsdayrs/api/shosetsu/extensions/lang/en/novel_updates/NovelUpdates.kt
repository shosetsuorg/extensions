package com.github.doomsdayrs.api.shosetsu.extensions.lang.en.novel_updates

import com.github.doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat
import com.github.doomsdayrs.api.shosetsu.services.core.objects.Novel
import com.github.doomsdayrs.api.shosetsu.services.core.objects.NovelGenre
import com.github.doomsdayrs.api.shosetsu.services.core.objects.NovelPage
import org.jsoup.nodes.Document
import java.io.IOException
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
 * novelreader-extensions
 * 29 / May / 2019
 *
 * @author github.com/doomsdayrs
 */
@Deprecated("not enough time to complete")
class NovelUpdates : ScrapeFormat() {
    private val baseURL = "https://www.novelupdates.com"

    val iD: Int
        get() = 0
    override val genres: Array<NovelGenre>
        get() = TODO("not implemented") //To change initializer of created properties use File | Settings | File Templates.
    override val imageURL: String
        get() = TODO("not implemented") //To change initializer of created properties use File | Settings | File Templates.

    override val name: String
        get() = "NovelUpdates"


    @Throws(IOException::class)
    fun getNovelPassage(responseBody: String?): String? {
        val document = docFromURL(responseBody!!)
        return null
    }

    @Throws(IOException::class)
    fun parseNovel(URL: String?): NovelPage? {
        val document = docFromURL(URL!!)
        val chapters = document.select("table")[1].select("tr")
        for (element in chapters) {
            val elements = element.select("td")
        }
        return null
    }

    fun parseNovel(responseBody: String?, increment: Int): NovelPage? {
        return null
    }

    override fun getLatestURL(page: Int): String {
        return if (page > 1) "$baseURL/?pg=$page" else baseURL
    }

    override fun getNovelPassage(document: Document): String {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun getSearchString(query: String): String {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun novelPageCombiner(url: String, increment: Int): String {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun parseLatest(document: Document): List<Novel> {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun parseNovel(document: Document): NovelPage {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun parseNovel(document: Document, increment: Int): NovelPage {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun parseSearch(document: Document): List<Novel> {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    @Throws(IOException::class)
    fun parseLatest(URL: String?): List<Novel> {
        val novels: MutableList<Novel> = ArrayList()
        val document = docFromURL(URL!!)
        val elements = document.select("table")
        for (y in elements.indices) {
            if (y != 0) {
                val element = elements[y]
                for (element1 in element.select("tr")) {
                    val elements1 = element1.select("a")
                    var title: String? = null
                    var link: String? = null
                    for (x in elements1.indices) {
                        val element2 = elements1[x]
                        if (x == 0) {
                            title = element2.attr("title")
                            link = element2.attr("href")
                        }
                    }
                    if (title != null && link != null) {
                        val novel = Novel()
                        novel.link = link
                        novel.title = title
                        novels.add(novel)
                    }
                }
            }
        }
        return novels
    }

}