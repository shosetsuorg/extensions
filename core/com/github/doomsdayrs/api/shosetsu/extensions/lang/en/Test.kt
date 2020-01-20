package com.github.doomsdayrs.api.shosetsu.extensions.lang.en

import com.github.doomsdayrs.api.shosetsu.services.core.dep.LuaFormatter
import com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.ResponseBody
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.luaj.vm2.LuaValue
import org.luaj.vm2.lib.jse.CoerceJavaToLua
import org.luaj.vm2.lib.jse.JsePlatform
import java.io.File
import java.io.IOException
import java.net.URL
import java.util.concurrent.TimeUnit


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
 * 03 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
internal class Test {

    companion object {
        // The below is methods robbed from ScrapeFormat class
        private val builder: Request.Builder = Request.Builder()
        private val client: OkHttpClient = OkHttpClient()

        @Throws(IOException::class)
        private fun request(url: String?): ResponseBody? {
            println(url)
            val u = URL(url)
            val request = builder.url(u).build()
            return client.newCall(request).execute().body()
        }

        @Throws(IOException::class)
        private fun docFromURL(URL: String): Document {
            return Jsoup.parse(request(URL)!!.string())
        }

        @Throws(IOException::class, InterruptedException::class)
        @JvmStatic
        fun main(args: Array<String>) {
            val formatters = arrayOf(
                    "src/main/resources/src/BestLightNovel.lua"
            )
            for (format in formatters){
                println("========== $format ==========")

                val luaFormatter = LuaFormatter(File(format))

                // Data
                println(luaFormatter.genres)
                println(luaFormatter.name)
                println(luaFormatter.formatterID)
                println(luaFormatter.imageURL)

                // Latest
                TimeUnit.SECONDS.sleep(1)
                val list = luaFormatter.parseLatest(docFromURL(luaFormatter.getLatestURL(1)))
                println()

                // Search
                TimeUnit.SECONDS.sleep(1)
                println(luaFormatter.parseSearch(docFromURL(luaFormatter.getSearchString("reinca"))))
                println()

                // Novel
                TimeUnit.SECONDS.sleep(1)
                val novel = luaFormatter.parseNovel(docFromURL(luaFormatter.novelPageCombiner(list[0].link,2)),2)
                println(novel)

                // Parse novel passage
                TimeUnit.SECONDS.sleep(1)
                println(luaFormatter.getNovelPassage(docFromURL(novel.novelChapters[0].link)))
                println()

                println("DEBUG")
                LuaSupport.printBuffer()
            }

        }
    }
}