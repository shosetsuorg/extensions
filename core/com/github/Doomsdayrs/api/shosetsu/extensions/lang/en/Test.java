package com.github.Doomsdayrs.api.shosetsu.extensions.lang.en;

import com.github.Doomsdayrs.api.shosetsu.extensions.lang.en.bestlightnovel.BestLightNovel;
import com.github.Doomsdayrs.api.shosetsu.services.core.dep.Formatter;


import java.io.IOException;

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
 * 03 / June / 2019
 *
 * @author github.com/doomsdayrs
 */
class Test {
    public static void main(String[] args) throws IOException, InterruptedException {
        Formatter formatter = new BestLightNovel(1);
        System.out.println(formatter.parseNovel("https://bestlightnovel.com/novel_888117820"));
    }
}
