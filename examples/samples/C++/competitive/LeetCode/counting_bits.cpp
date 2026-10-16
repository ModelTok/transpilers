
#include <vector>

std::vector<int> count_bits(int number) {
    std::vector<int> bits(number + 1, 0);
    for(auto i = 0; i <= number; i++) {
        bits[i] = bits[i >> 1] + (i & 1);
    }
    return bits;
}