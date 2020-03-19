package app.shosetsu.ext

import com.github.doomsdayrs.api.shosetsu.services.core.dep.LuaFormatter
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.ResponseBody
import org.json.JSONObject
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
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
            return client.newCall(request).execute().body
        }

        @Throws(IOException::class)
        private fun docFromURL(URL: String): Document {
            return Jsoup.parse(request(URL)!!.string())
        }

        @Throws(IOException::class, InterruptedException::class)
        @JvmStatic
        fun main(args: Array<String>) {
            val formFile = File("formatters.json")
            val formatters = JSONObject(Compile.getContent(formFile))
            val keys = formatters.keys()
            keys.forEach {
                if (it != "comments") {
                    println("\n=============================")
                    println(it)
                    val form = formatters.getJSONObject(it)
                    val luaFormatter = LuaFormatter(File("./src/${form.getString("lang")}/$it.lua"))
                    // Data
                    println(luaFormatter.genres)
                    println(luaFormatter.name)
                    println(luaFormatter.formatterID)
                    println(luaFormatter.imageURL)
                    // Latest
                    TimeUnit.SECONDS.sleep(1)
                    val list = luaFormatter.parseLatest(docFromURL(luaFormatter.getLatestURL(1)))
                    for (novel in list)
                        println(novel)
                    // Search
                    TimeUnit.SECONDS.sleep(1)
                    println(luaFormatter.parseSearch(docFromURL(luaFormatter.getSearchString("reinca"))))
                    println()

                    // Novel
                    TimeUnit.SECONDS.sleep(1)
                    val novel = luaFormatter.parseNovel(docFromURL(luaFormatter.novelPageCombiner(list[0].link, 2)), 2)
                    println(novel)

                    // Parse novel passage
                    TimeUnit.SECONDS.sleep(1)
                    println(luaFormatter.getNovelPassage(docFromURL(novel.novelChapters[0].link)))
                    println()
                }
            }
        }
    }
}