// Iterative Fibonacci — two-accumulator update.
int fib_iter(int n) {
    int a = 0;
    int b = 1;
    int i = 0;
    while (i < n) {
        int next = a + b;
        a = b;
        b = next;
        i = i + 1;
    }
    return a;
}
