package com.github.doomsdayrs.api.shosetsu.extensions.lang.en;


import java.util.Arrays;

/**
 * com.github.doomsdayrs.api.shosetsu.extensions.lang.en
 * 17 / January / 2020
 *
 * @author github.com/doomsdayrs
 */
public class StringArray {
    public String[] strings;

    public void setSize(int size){
        strings = new String[size];
        Arrays.fill(strings, "");
    }

    public String[] getStrings() {
        return strings;
    }

    public void setStrings(String[] strings) {
        this.strings = strings;
    }

    public void setPosition(int index, String value){
        strings[index] = value;
    }
}
