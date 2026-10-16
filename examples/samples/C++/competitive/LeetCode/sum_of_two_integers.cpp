
int get_sum(int x, int y)
{
    unsigned int carry = x & y;
    unsigned int sum = x ^ y;
    while (carry) {
        carry = sum & (carry << 1);
        sum ^= carry << 1;
    }
    return sum;
}
