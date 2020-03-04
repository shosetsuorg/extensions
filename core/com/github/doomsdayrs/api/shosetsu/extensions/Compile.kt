package com.github.doomsdayrs.api.shosetsu.extensions

import org.json.JSONObject
import java.io.*
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException


/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 * ====================================================================
 */
/**
 * shosetsu-extensions
 * 20 / 01 / 2020
 *
 * @author github.com/doomsdayrs
 */
object Compile {
    fun getContent(file: File): String {
        val builder = StringBuilder()
        val br = BufferedReader(FileReader(file))
        var line = br.readLine()
        while (line != null) {
            builder.append(line).append("\n")
            line = br.readLine()
        }
        return builder.toString()
    }

    private fun md5(s: String): String? {
        try {
            // Create MD5 Hash
            val digest = MessageDigest.getInstance("MD5")
            digest.update(s.toByteArray())
            val messageDigest = digest.digest()
            // Create Hex String
            val hexString = StringBuffer()
            for (i in messageDigest.indices)
                hexString.append(Integer.toHexString(0xFF and messageDigest[i].toInt()))
            return hexString.toString()
        } catch (e: NoSuchAlgorithmException) {
            e.printStackTrace()
        }
        return ""
    }

    private fun getMeta(s: String): JSONObject = JSONObject(s.dropWhile { it != '{' }.takeWhile { it != '\n' })

    @JvmStatic
    fun main(args: Array<String>) {
        val formFile = File("formatters.json")
        val formatters = JSONObject(getContent(formFile))
        val keys = formatters.keys()

        keys.forEach {
            if (it != "libraries") {
                println("\n============ $it ============")
                val form = formatters.getJSONObject(it)
                println("Before:\t$form")
                val content = getContent(File("src/${form.getString("lang")}/$it.lua"))
                val meta = getMeta(content)
                val hash = md5(content)
                form.put("md5", hash)
                form.put("id", meta.getInt("id"))
                form.put("version", meta.getString("version"))

                println("After:\t$form")
                formatters.put(it, form)
            }
        }


        val writer = BufferedWriter(FileWriter(formFile))
        writer.write(formatters.toString(2))
        writer.close()
    }
}