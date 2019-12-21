package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.bestlightnovel;

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

/**
 * novelreaderextensions
 * 02 / 08 / 2019
 *
 * @author github.com/doomsdayrs
 */
public class BestLightNovel extends ScrapeFormat {
    private final String baseURL = "https://bestlightnovel.com";

    public BestLightNovel() {
        super(5);
    }

    public BestLightNovel(Request.Builder builder) {
        super(5, builder);
    }

    public BestLightNovel(OkHttpClient client) {
        super(5, client);
    }

    public BestLightNovel(Request.Builder builder, OkHttpClient client) {
        super(5, builder, client);
    }

    @Override
    public String getName() {
        return "BestLightNovel";
    }

    @Override
    public String getImageURL() {
        return null;
    }

    @Override
    public String getLatestURL(int i) {
        if (i <= 0)
            i = 1;
        return baseURL + "/novel_list?type=latest&category=all&state=all&page=" + i;
    }


    @Override
    public String getNovelPassage(Document document) {
        Elements elements = document.selectFirst("div.vung_doc").select("p");
        StringBuilder stringBuilder = new StringBuilder();
        if (elements.size() != 0) {
            for (Element element : elements)
                stringBuilder.append(element.text()).append("\n");
        } else stringBuilder.append("NOT YET TRANSLATED");
        return stringBuilder.toString();
    }

    /**
     * TITLE:YES
     * IMAGEURL: YES
     * DESCRIPTION: YES
     * GENRES: YES
     * AUTHORS: YES
     * STATUS: YES
     * TAGS: NO
     * ARTISTS: NO
     * LANGUAGE: NO
     * MAXCHAPTERPAGE: NO
     * NOVELCHAPTERS: YES
     */

    @Override
    public NovelPage parseNovel(Document document) {
        NovelPage novelPage = new NovelPage();
        // Image
        {
            Element element = document.selectFirst("div.truyen_info_left");
            novelPage.imageURL = element.selectFirst("img").attr("src");
        }
        // Bulk data
        {
            Element element = document.selectFirst("ul.truyen_info_right");
            Elements elements = element.select("li");
            StringBuilder stringBuilder = new StringBuilder("");
            String text;
            Element subElement;
            Elements subElements;
            String[] strings;
            for (int x = 0; x < elements.size(); x++) {
                Element e = elements.get(x);
                switch (x) {
                    case 0:
                        novelPage.title = e.selectFirst("h1").text();
                        break;

                    case 1:
                        stringBuilder = new StringBuilder("");
                        subElements = e.select("a");
                        strings = new String[subElements.size()];
                        for (int y = 0; y < strings.length; y++)
                            strings[y] = subElements.get(y).text();
                        novelPage.authors = strings;
                        break;

                    case 2:
                        stringBuilder = new StringBuilder("");
                        subElements = e.select("a");
                        strings = new String[subElements.size()];
                        for (int y = 0; y < strings.length; y++)
                            strings[y] = subElements.get(y).text();
                        novelPage.genres = strings;
                        break;

                    case 3:
                        subElement = e.selectFirst("a");
                        text = subElement.text();
                        switch (text) {
                            case "ongoing":
                                novelPage.status = Stati.PUBLISHING;
                                break;
                            case "completed":
                                novelPage.status = Stati.COMPLETED;
                                break;
                            default:
                                break;
                        }
                        break;

                    default:
                        break;
                }
            }
        }
        // Description
        {
            Elements elements = document.selectFirst("div.entry-header").select("div");
            for (Element div : elements) {
                if (div.id().equals("noidungm")) {
                    String unformatted = div.text();
                    unformatted = unformatted.replaceAll("<br>", "\n");
                    novelPage.description = unformatted;
                }
            }
        }
        // Chapters
        {
            Element e = document.selectFirst("div.chapter-list");
            novelPage.novelChapters = new ArrayList<>();

            if (e != null) {
                Elements chapters = e.select("div.row");
                List<NovelChapter> novelChapters = new ArrayList<>();
                int y = 0;
                for (Element row : chapters) {
                    NovelChapter novelChapter = new NovelChapter();
                    Elements elements = row.select("span");
                    for (int x = 0; x < elements.size(); x++) {
                        switch (x) {
                            case 0:
                                Element titleLink = elements.get(x).selectFirst("a");
                                novelChapter.title = titleLink.attr("title");
                                novelChapter.link = titleLink.attr("href");
                                break;
                            case 1:
                                novelChapter.release = elements.get(x).text();
                                break;
                        }
                    }
                    novelChapter.order = y;
                    y++;
                    novelChapters.add(novelChapter);
                }
                Collections.reverse(novelChapters);
                novelPage.novelChapters = novelChapters;
            }
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
    public NovelPage parseNovel(Document document, int i) {
        return parseNovel(document);
    }

    @Override
    public String getSearchString(String s) {
        s = s.replaceAll(" ", "_");
        s = baseURL + "/search_novels/" + s;
        return s;
    }

    @Override
    public List<Novel> parseSearch(Document document) {
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
