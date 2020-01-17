package com.github.doomsdayrs.api.shosetsu.extensions.lang.en

import com.github.doomsdayrs.api.shosetsu.services.core.objects.*

/**
 * com.github.doomsdayrs.api.shosetsu.extensions.lang.en
 * 17 / January / 2020
 *
 * @author github.com/doomsdayrs
 */
class LuaSupport {

    companion object {
        val buffer: ArrayList<String> = ArrayList()
        fun printBuffer() {
            if (buffer.size > 0)
                for (buf in buffer)
                    println(buf)
            else println("Empty buffer")
            buffer.clear()
        }
    }

    /**
     * type Type of NovelStatus {0:PUBLISHING,1:COMPLETED,2:PAUSED,3:UNKNOWN}
     */
    fun getStatus(type: Int): NovelStatus {
        return when (type) {
            0 -> NovelStatus.PUBLISHING
            1 -> NovelStatus.COMPLETED
            2 -> NovelStatus.PAUSED
            else -> NovelStatus.UNKNOWN
        }
    }

    fun getGAL(): Array<NovelGenre> {
        return arrayOf()
    }

    fun reverseAL(array: ArrayList<Any>): ArrayList<Any> {
        array.reverse();
        return array
    }

    fun getNAL(): ArrayList<Novel> {
        return ArrayList()
    }

    fun getCAL(): ArrayList<NovelChapter> {
        return ArrayList()
    }

    val chapterArrayList: ArrayList<NovelChapter>
        get() = ArrayList()

    val novelPage: NovelPage
        get() = NovelPage()

    val stringArray: StringArray
        get() = StringArray()

    fun getNovel(): Novel {
        return Novel()
    }


    fun getNovelChapter(): NovelChapter {
        return NovelChapter()
    }

    fun printOut(any: Any?) {
        if (any != null)
            buffer.add("LUA:\t$any")
    }
}