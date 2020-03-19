package app.shosetsu.ext;

import org.json.JSONObject;

import javax.swing.*;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;

/**
 * com.github.doomsdayrs.api.shosetsu.extensions
 * 30 / January / 2020
 *
 * @author github.com/doomsdayrs
 */
class FormatterController {
    private JList formatterSelection;
    private JTextField nameOfFormatter;
    private JSpinner v1S;
    private JSpinner v2S;
    private JSpinner v3S;
    private JTextField imageURL;
    private JButton button1;
    private JButton button2;
    private JComboBox langS;
    private JTextField id;
    private JSplitPane FORM;

    public JSONObject jsonObject = new JSONObject();
    public ArrayList<String> keys = new ArrayList();

    private FormatterController() throws IOException {
        File formFile = new File("formatters.json");
        if (formFile.exists()) {
            jsonObject = new JSONObject(getContent(formFile));
            keys = getKeyListFromJSON(jsonObject);
            ListModel listModel = new ListModel(keys.toArray(new String[]{}));
            formatterSelection.setModel(listModel);
            formatterSelection.addListSelectionListener(listSelectionEvent -> {
                String k = keys.get(formatterSelection.getSelectedIndex());
                System.out.println(k);
                setData(k, jsonObject.getJSONObject(k));
            });
        } else System.out.println("Form doesn't exist");
    }

    public void setData(String name, JSONObject jsonObject) {
        System.out.println(jsonObject);
        nameOfFormatter.setText(name);
        String[] v = jsonObject.getString("version").split("\\.");
        v1S.setValue(Integer.parseInt(v[0]));
        v2S.setValue(Integer.parseInt(v[1]));
        v3S.setValue(Integer.parseInt(v[2]));
        imageURL.setText(jsonObject.getString("imageURL"));
        id.setText(String.valueOf(jsonObject.getInt("id")));
        langS.setSelectedItem(jsonObject.getString("lang"));
    }

    private static ArrayList<String> getKeyListFromJSON(JSONObject jsonObject) {
        System.out.println("Creating List from:\t" + jsonObject.toString());
        ArrayList<String> strings = new ArrayList<>();
        Iterator<String> keys = jsonObject.keys();
        for (; keys.hasNext(); ) {
            String key = keys.next();
            if (!(key.equals("comments") || key.equals("libraries")))
                strings.add(key);
        }
        return strings;
    }

    private static class ListModel extends AbstractListModel<String> {

        private final String[] list;

        private ListModel(String[] array) {
            this.list = array;
        }

        @Override
        public int getSize() {
            return list.length;
        }

        @Override
        public String getElementAt(int i) {
            return list[i];
        }
    }

    private static String getContent(File file) throws IOException {
        StringBuilder builder = new StringBuilder();
        BufferedReader br = new BufferedReader(new FileReader(file));
        String line = br.readLine();
        while (line != null) {
            builder.append(line).append("\n");
            line = br.readLine();
        }
        return builder.toString();
    }


    public static void main(String[] args) throws IOException {
        JFrame frame = new JFrame("Formatter Controller");
        frame.setContentPane(new FormatterController().FORM);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }
}
