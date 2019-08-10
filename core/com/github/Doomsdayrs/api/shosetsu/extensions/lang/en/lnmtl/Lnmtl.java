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
