package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.box_novel;

import com.github.Doomsdayrs.api.shosetsu.services.core.dep.ScrapeFormat;
import com.github.Doomsdayrs.api.shosetsu.services.core.objects.*;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
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
 * novelreader-extensions
 * 11 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
//TODO
public class BoxNovel extends ScrapeFormat {
    private final String baseURL = "https://boxnovel.com";

    public BoxNovel(int id) {
        super(id);
    }

    public BoxNovel(int id, Request.Builder builder) {
        super(id, builder);
    }

    public BoxNovel(int id, OkHttpClient client) {
        super(id, client);
    }

    public BoxNovel(int id, Request.Builder builder, OkHttpClient client) {
        super(id, builder, client);
    }

    @Override
    public String getName() {
        return "BoxNovel";
    }

    @Override
    public String getImageURL() {
        return "https://boxnovel.com/wp-content/uploads/2018/04/BoxNovel-1.png";
    }

    @Override
    public String getNovelPassage(Document document) {
        Elements paragraphs = document.select("div.text-left").select("p");
        StringBuilder stringBuilder = new StringBuilder();

        for (Element element : paragraphs)
            stringBuilder.append(element.toString()).append("\n");

        return stringBuilder
                .toString()
                .replaceAll("<p>", "")
                .replaceAll("</p>", "");
    }

    @Override
    public String getLatestURL(int i) {
        return baseURL + "/novel/page/" + i + "/?m_orderby=latest";
    }


    /**
     * TITLE:YES
     * IMAGEURL: YES
     * DESCRIPTION: YES
     * GENRES: YES
     * AUTHORS: YES
     * STATUS: YES
     * TAGS: NO
     * ARTISTS: YES
     * LANGUAGE: NO
     * MAXCHAPTERPAGE: NO
     * NOVELCHAPTERS: YES
     */
    @Override
    public NovelPage parseNovel(Document document) {
        NovelPage novelPage = new NovelPage();
        novelPage.imageURL = document.selectFirst("div.summary_image").selectFirst("img.img-responsive").attr("src");
        novelPage.title = document.selectFirst("h3").text();
        novelPage.description = document.selectFirst("p").text();

        {
            Elements elements = document.selectFirst("div.post-content").select("div.post-content_item");
            for (int x = 0; x < elements.size(); x++) {
                Elements subElements;
                switch (x) {
                    case 0:
                    case 2:
                    case 1:
                        break;
                    case 3://AUTHORS
                        subElements = elements.get(x).select("a");
                        String[] authors = new String[subElements.size()];
                        for (int y = 0; y < subElements.size(); y++) {
                            authors[y] = subElements.get(y).text();
                        }
                        novelPage.authors = authors;
                        break;
                    case 4:
                        subElements = elements.get(x).select("a");
                        String[] artists = new String[subElements.size()];
                        for (int y = 0; y < subElements.size(); y++) {
                            artists[y] = subElements.get(y).text();
                        }
                        novelPage.artists = artists;
                        break;
                    case 5:
                        subElements = elements.get(x).select("a");
                        String[] genres = new String[subElements.size()];
                        for (int y = 0; y < subElements.size(); y++) {
                            genres[y] = subElements.get(y).text();
                        }
                        novelPage.genres = genres;
                        break;
                    case 6:
                        break;
                }
            }
            elements = document.selectFirst("div.post-status").select("div.post-content_item");
            for (int x = 0; x < elements.size(); x++) {
                switch (x) {
                    case 0:
                    case 2:
                        break;
                    case 1:
                        String stat = elements.get(x).select("div.summary-content").text();
                        switch (stat) {
                            case "OnGoing":
                                novelPage.status = Stati.PUBLISHING;
                                break;
                            case "Completed":
                                novelPage.status = Stati.COMPLETED;
                                break;
                        }
                        break;
                }
            }

        }

        // Chapters
        {
            novelPage.novelChapters = new ArrayList<>();
            Elements elements = document.select("li.wp-manga-chapter");
            int a = elements.size();
            for (Element element : elements) {
                NovelChapter novelChapter = new NovelChapter();
                novelChapter.link = element.selectFirst("a").attr("href");
                novelChapter.title = element.selectFirst("a").text();
                novelChapter.release = element.selectFirst("i").text();
                novelChapter.order = a;
                a--;
                novelPage.novelChapters.add(novelChapter);
            }
            Collections.reverse(novelPage.novelChapters);
        }
        return novelPage;
    }

    @Override
    public String novelPageCombiner(String s, int i) {
        return null;
    }

    @Override
    public List<Novel> parseLatest(Document document) {
        List<Novel> novels = new ArrayList<>();
        Elements novelsHTML = document.select("div.col-xs-12.col-md-6");
        for (Element novelHTML : novelsHTML) {
            Novel novel = new Novel();
            Element data = novelHTML.selectFirst("a");
            novel.title = data.attr("title");
            novel.link = data.attr("href");
            novel.imageURL = data.selectFirst("img").attr("src");
            novels.add(novel);
        }
        return novels;
    }

    @Override
    public String getSearchString(String s) {
        s = s.replaceAll("\\+", "%2");
        s = s.replaceAll(" ", "\\+");

        //Turns query into a URL
        s = baseURL + "/?s=" + s + "&post_type=wp-manga";
        return s;
    }

    @Override
    public List<Novel> parseSearch(Document document) {
        Elements novelsHTML = document.select("div.c-tabs-item__content");
        List<Novel> novels = new ArrayList<>();
        for (Element novelHTML : novelsHTML) {
            Novel novel = new Novel();
            Element data = novelHTML.selectFirst("a");
            novel.title = data.attr("title");
            novel.link = data.attr("href");
            novel.imageURL = data.selectFirst("img").attr("src");
            novels.add(novel);
        }
        return novels;
    }







    @Deprecated
    public String getNovelPassage(String s) throws IOException {
        return null;
    }

    @Deprecated
    public NovelPage parseNovel(String s) throws IOException {
        return null;
    }

    @Deprecated
    public NovelPage parseNovel(String s, int i) throws IOException {
        return null;
    }

    @Deprecated
    public List<Novel> parseLatest(String s) throws IOException {
        return null;
    }

    @Deprecated
    public List<Novel> search(String s) throws IOException {
        return null;
    }

    @Override
    public NovelGenre[] getGenres() {
        return new NovelGenre[0];
    }
}
