
public class LongestCommonSubsequence {

    private final String firstString;
    private final String secondString;

    private final int[][] table;

    public LongestCommonSubsequence(
            final String firstString,
            final String secondString
    ) {
        this.firstString = firstString;
        this.secondString = secondString;

        table = new int[firstString.length() + 1][secondString.length() + 1];

        tabulate();
    }

    private void tabulate() {
        for (int i = 1; i <= firstString.length(); i++) {
            for (int j = 1; j <= secondString.length(); j++) {
                if (firstString.charAt(i - 1) == secondString.charAt(j - 1)) {
                    table[i][j] = 1 + table[i - 1][j - 1];
                 } else {
                    table[i][j] = Math.max(table[i][j - 1], table[i - 1][j]);
                }
            }
        }
    }

    public int getLength() {
        return table[firstString.length()][secondString.length()];
    }

    public String getSubsequence() {
        return recurse(firstString.length(), secondString.length());
    }

    private String recurse(int i, int j) {
        if (i == 0 || j == 0) {
            return "";
        }
        if (firstString.charAt(i - 1) == secondString.charAt(j - 1)) {
            return recurse(i - 1, j - 1) + firstString.charAt(i - 1);
        }
        if (table[i][j - 1] > table[i - 1][j]) {
            return recurse(i, j - 1);
        }
        return recurse(i - 1, j);
    }

}