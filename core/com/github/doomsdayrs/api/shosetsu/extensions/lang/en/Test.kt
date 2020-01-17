package com.github.doomsdayrs.api.shosetsu.extensions.lang.en

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.ResponseBody
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.luaj.vm2.LuaValue
import org.luaj.vm2.lib.jse.JsePlatform
import java.io.IOException
import java.net.URL


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
            val globals: LuaValue = JsePlatform.standardGlobals();
            globals.get("dofile").call(LuaValue.valueOf("./BestLightNovel.lua"));
            val luaFormatter: LuaFormatter = LuaFormatter(globals)
            println(luaFormatter.name)
            println(luaFormatter.formatterID)
            println(luaFormatter.imageURL)
            println(luaFormatter.getLatestURL(0))
            //   println(luaFormatter.getNovelPassage(docFromURL("https://bestlightnovel.com/novel_888153453/chapter_286")))
            println(luaFormatter.getSearchString("search a b c"))
            print(luaFormatter.parseNovel(docFromURL("https://bestlightnovel.com/novel_888153453")))
        }
    }
}