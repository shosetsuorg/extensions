package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en;

import com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.novel_full.NovelFull;
import com.github.Doomsdayrs.api.shosetsu.services.core.dep.Formatter;
import com.github.Doomsdayrs.api.shosetsu.services.core.objects.NovelChapter;
import com.github.Doomsdayrs.api.shosetsu.services.core.objects.NovelPage;

import java.io.IOException;

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
 * 03 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
class Test {
    public static void main(String[] args) throws IOException, InterruptedException {
        Formatter formatter = new NovelFull(1);

        NovelPage novelPage = formatter.parseNovel("http://novelfull.com/my-cold-and-elegant-ceo-wife.html");

        //     ArrayList<NovelChapter> novelChapters = new ArrayList<>(novelPage.novelChapters);
        for (int x = 1; x < novelPage.maxChapterPage; x++) {
            if (x==39){
                System.out.println("Check");
            }

            novelPage = formatter.parseNovel("http://novelfull.com/my-cold-and-elegant-ceo-wife.html", x);
            //  novelChapters.addAll(novelPage.novelChapters);
            for (NovelChapter novelChapter : novelPage.novelChapters) {
                System.out.println(novelChapter);
            }
        }


    }
}
