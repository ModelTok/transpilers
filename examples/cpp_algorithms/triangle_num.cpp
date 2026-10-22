int triangle_num(int n) {
    int total = 0;
    for (int i = 1; i <= n; i++) {
        total = total + i;
    }
    return total;
}
