
int trailing_zeroes(int number) {
    int trailing_zeroes = 0;
    while (number != 0) {
        number /= 5;
        trailing_zeroes += number;
    }
    return trailing_zeroes;
}