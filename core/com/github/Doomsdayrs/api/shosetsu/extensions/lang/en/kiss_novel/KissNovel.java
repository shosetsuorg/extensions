package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.kiss_novel;

import com.github.Doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat;
import com.github.Doomsdayrs.api.shosetsu.services.core.objects.*;
import okhttp3.OkHttpClient;
import okhttp3.Request;

import java.util.List;
//TODO, complete this
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
