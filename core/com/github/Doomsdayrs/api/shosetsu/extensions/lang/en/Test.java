package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en;

import com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.bestlightnovel.BestLightNovel;
import com.github.Doomsdayrs.api.shosetsu.services.core.dep.Formatter;


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
        Formatter formatter = new BestLightNovel(1);
        System.out.println(formatter.parseNovel("https://bestlightnovel.com/novel_888141072"));

    }
}
