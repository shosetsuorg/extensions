package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.lnmtl;


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
 * com.github.Doomsdayrs.api.novelreader_core.extensions.lang.en.lnmtl
 * 11 / 06 / 2019
 *
 * @author github.com/doomsdayrs
 */
//TODO
@Deprecated
public class Lnmtl extends ScrapeFormat {
    private final String baseURL = "https://lnmtl.com";

    public Lnmtl(int id) {
        super(id);
    }

    public Lnmtl(int id, Request.Builder builder) {
        super(id, builder);
    }

    public Lnmtl(int id, OkHttpClient client) {
        super(id, client);
    }

    public Lnmtl(int id, Request.Builder builder, OkHttpClient client) {
        super(id, builder, client);
    }

    @Override
    public String getName() {
        return null;
    }

    @Override
    public String getImageURL() {
        return null;
    }



    @Override
    public String getNovelPassage(String s) throws IOException {
        return null;
    }

    @Override
    public NovelPage parseNovel(String s) throws IOException {
        return null;
    }

    @Override
    public NovelPage parseNovel(String s, int i) throws IOException {
        return null;
    }

    /**
     * @param i Ignored, This site does not have an incrementation
     * @return baseURL
     */
    @Override
    public String getLatestURL(int i) {
        return baseURL;
    }

    @Override
    public List<Novel> parseLatest(String s) throws IOException {
        if (!s.contains(baseURL))
            s = baseURL + s;
        List<Novel> novels = new ArrayList<>();
        Document document = docFromURL(s);
        Elements elements = document.select("div.panel.panel-default.panel-chapter");
        for (Element element : elements) {
            Novel novel = new Novel();
            Element linkTitle = element.selectFirst("a");
            novel.title = linkTitle.text();
            novel.link = linkTitle.attr("href");
            novels.add(novel);
        }
        return novels;
    }

    @Override
    public List<Novel> search(String s) throws IOException {
        return null;
    }

    @Override
    public NovelGenre[] getGenres() {
        return new NovelGenre[0];
    }
}
