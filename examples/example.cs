class MathUtils {
    static int Add(int a, int b) {
        return a + b;
    }

    static int Factorial(int n) {
        int result = 1;
        int i = 1;
        while (i <= n) {
            result = result * i;
            i = i + 1;
        }
        return result;
    }

    static int SumTo(int n) {
        int total = 0;
        for (int i = 0; i < n; i++) {
            total = total + i;
        }
        return total;
    }

    static bool InRange(int x, int lo, int hi) {
        return x >= lo && x <= hi;
    }
}
