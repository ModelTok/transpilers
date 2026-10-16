
int reverse(int number) {
    int reverse = 0;
    while (number != 0) {
        int digit = number % 10;
        number /= 10;
        if (reverse > INT_MAX / 10 ||
            (reverse == INT_MAX / 10 && digit > INT_MAX % 10) ||
            reverse < INT_MIN / 10 ||
            (reverse == INT_MIN / 10 && digit < INT_MIN % 10)) {
            return 0;
        }
        reverse = reverse * 10 + digit;
    }
    return reverse;
}