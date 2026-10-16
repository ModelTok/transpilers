
double pow(double x, int n) {
    auto _pow = 1.0;
    auto negative = n < 0;
    while (n != 0) {
        if (n & 1) {
            _pow *= x;
        }
        n /= 2;
        x *= x;
    }
    return negative ? 1 / _pow : _pow;
}
