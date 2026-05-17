class MathUtils {
    static int add(int a, int b) {
        return a + b;
    }

    static int max2(int a, int b) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    static int factorial(int n) {
        int result = 1;
        int i = 1;
        while (i <= n) {
            result = result * i;
            i = i + 1;
        }
        return result;
    }

    static int sumTo(int n) {
        int total = 0;
        for (int i = 0; i < n; i++) {
            total = total + i;
        }
        return total;
    }

    static boolean inRange(int x, int lo, int hi) {
        return x >= lo && x <= hi;
    }
}
