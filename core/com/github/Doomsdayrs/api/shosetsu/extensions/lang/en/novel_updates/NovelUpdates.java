package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.novel_updates;

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
 * 29 / May / 2019
 *
 * @author github.com/doomsdayrs
 */
@Deprecated
//TODO Create very complicated and advanced dynamic resource selector
public class NovelUpdates extends ScrapeFormat {
    private final String baseURL = "https://www.novelupdates.com";

    public NovelUpdates(int id) {
        super(id);
    }

    public NovelUpdates(int id, Request.Builder builder) {
        super(id, builder);
    }

    public NovelUpdates(int id, OkHttpClient client) {
        super(id, client);
    }

    public NovelUpdates(int id, Request.Builder builder, OkHttpClient client) {
        super(id, builder, client);
    }


    @Override
    public int getID() {
        return 0;
    }

    @Override
    public String getName() {
        return "NovelUpdates";
    }

    @Override
    public String getImageURL() {
        return null;
    }


    public String getNovelPassage(String responseBody) throws IOException {
        Document document = docFromURL(responseBody);
        return null;
    }

    public NovelPage parseNovel(String URL) throws IOException {
        Document document = docFromURL(URL);
        Elements chapters = document.select("table").get(1).select("tr");
        for (Element element : chapters) {
            Elements elements = element.select("td");
        }
        return null;
    }

    public NovelPage parseNovel(String responseBody, int increment) {
        return null;
    }

    public String getLatestURL(int page) {
        if (page > 1)
            return baseURL + "/?pg=" + page;
        else return baseURL;
    }

    public List<Novel> parseLatest(String URL) throws IOException {
        List<Novel> novels = new ArrayList<>();
        Document document = docFromURL(URL);
        Elements elements = document.select("table");
        for (int y = 0; y < elements.size(); y++) {
            if (y != 0) {
                Element element = elements.get(y);
                for (Element element1 : element.select("tr")) {
                    Elements elements1 = element1.select("a");
                    String title = null;
                    String link = null;
                    for (int x = 0; x < elements1.size(); x++) {
                        Element element2 = elements1.get(x);

                        if (x == 0) {
                            title = element2.attr("title");
                            link = element2.attr("href");
                        }

                    }

                    if (title != null && link != null) {
                        Novel novel = new Novel();
                        novel.link = link;
                        novel.title = title;
                        novels.add(novel);

                    }
                }
            }
        }
        return novels;
    }

    @Override
    public List<Novel> search(String query) {
        return null;
    }

    @Override
    public NovelGenre[] getGenres() {
        return new NovelGenre[0];
    }
}
