package com.github.doomsdayrs.api.shosetsu.extensions.lang.en.web_novel

import com.github.doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat
import com.github.doomsdayrs.api.shosetsu.services.core.objects.Novel
import com.github.doomsdayrs.api.shosetsu.services.core.objects.NovelGenre
import com.github.doomsdayrs.api.shosetsu.services.core.objects.NovelPage
import okhttp3.OkHttpClient
import okhttp3.Request
import org.jsoup.nodes.Document
import java.io.IOException

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
 * 11 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
//TODO, When you scrape your competitor
@Deprecated("")
class WebNovel : ScrapeFormat() {
    override val genres: Array<NovelGenre>
        get() = TODO("not implemented") //To change initializer of created properties use File | Settings | File Templates.
    override val imageURL: String
        get() = TODO("not implemented") //To change initializer of created properties use File | Settings | File Templates.
    override val name: String
        get() = TODO("not implemented") //To change initializer of created properties use File | Settings | File Templates.

    override fun getLatestURL(page: Int): String {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
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
}