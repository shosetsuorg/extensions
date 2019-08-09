package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.novel_online_free;

import com.github.Doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat;
import com.github.Doomsdayrs.api.shosetsu.services.core.objects.*;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

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
 * novelreader-extensions
 * 11 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
@Deprecated
// Reasoning for the above, needs to use multiple formatters to work, sites link each other
public class NovelOnlineFree extends ScrapeFormat {
    private final String baseURL = "https://novelonlinefree.com";

    public NovelOnlineFree(int id) {
        super(id);
    }

    public NovelOnlineFree(int id, Request.Builder builder) {
        super(id, builder);
    }

    public NovelOnlineFree(int id, OkHttpClient client) {
        super(id, client);
    }

    public NovelOnlineFree(int id, Request.Builder builder, OkHttpClient client) {
        super(id, builder, client);
    }


    @Override
    public String getName() {
        return "Novel online free";
    }

    @Override
    public String getImageURL() {
        return null;
    }

    @Override
    public String getNovelPassage(String s) throws IOException {
        s = verify(baseURL, s);
        Document document = docFromURL(s);
        Elements elements = document.selectFirst("div.vung_doc").select("p");
        StringBuilder stringBuilder = new StringBuilder();
        for (Element element : elements)
            stringBuilder.append(element.text()).append("\n");
        return stringBuilder.toString();
    }

    @Override
    public NovelPage parseNovel(String s) throws IOException {
        return null;
    }

    @Override
    public NovelPage parseNovel(String s, int i) throws IOException {
        return null;
    }

    @Override
    public String getLatestURL(int i) {
        if (i <= 0)
            i = 1;
        return "https://novelonlinefree.com/novel_list?type=latest&category=all&state=all&page=" + i;
    }

    @Override
    public List<Novel> parseLatest(String s) throws IOException {
        s = verify(baseURL, s);
        Document document = docFromURL(s);
        List<Novel> novels = new ArrayList<>();
        Elements elements = document.select("div.update_item.list_category");
        for (Element element : elements) {
            Novel novel = new Novel();
            {
                Element e = element.selectFirst("h3.nowrap").selectFirst("a");
                novel.title = e.attr("title");
                novel.link = e.attr("href");
            }
            novel.imageURL = element.selectFirst("img").attr("src");
            novels.add(novel);
        }
        return novels;
    }

    @Override
    public List<Novel> search(String s) throws IOException {
        s = s.replaceAll(" ", "_");
        s = baseURL + "/search_novels/" + s;
        List<Novel> novels = new ArrayList<>();
        Document document = docFromURL(s);
        Elements elements = document.select("div.update_item.list_category");
        for (Element element : elements) {
            Novel novel = new Novel();
            {
                Element e = element.selectFirst("h3.nowrap").selectFirst("a");
                novel.title = e.attr("title");
                novel.link = e.attr("href");
            }
            novel.imageURL = element.selectFirst("img").attr("src");
            novels.add(novel);
        }

        return novels;
    }

    @Override
    public NovelGenre[] getGenres() {
        return new NovelGenre[0];
    }
}
