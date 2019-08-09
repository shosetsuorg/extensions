package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.kiss_novel;

import com.github.Doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat;
import com.github.Doomsdayrs.api.shosetsu.services.core.objects.*;
import okhttp3.OkHttpClient;
import okhttp3.Request;

import java.util.List;
//TODO, complete this
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
 * 30 / May / 2019
 *
 * @author github.com/doomsdayrs
 */
@Deprecated
public class KissNovel extends ScrapeFormat {
    private final String baseURL = "https://kiss-novel.com";

    public KissNovel(int id) {
        super(id);
    }

    public KissNovel(int id, Request.Builder builder) {
        super(id, builder);
    }

    public KissNovel(int id, OkHttpClient client) {
        super(id, client);
    }

    public KissNovel(int id, Request.Builder builder, OkHttpClient client) {
        super(id, builder, client);
    }


    @Override
    public int getID() {
        return 0;
    }

    @Override
    public String getName() {
        return "KissNovel";
    }

    @Override
    public String getImageURL() {
        return null;
    }


    public String getNovelPassage(String responseBody) {
        return null;
    }

    public NovelPage parseNovel(String URL) {
        return null;
    }

    public NovelPage parseNovel(String URL, int increment) {
        return null;
    }

    public String getLatestURL(int page) {
        return baseURL + "/list/"+page;
    }

    public List<Novel> parseLatest(String responseBody) {
        return null;
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
