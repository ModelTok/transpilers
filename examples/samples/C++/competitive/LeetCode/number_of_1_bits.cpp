
#include <cstdint>

int hamming_weight(std::uint_fast32_t number) {
    int one_bits = 0;
    while (number != 0) {
        one_bits++;
        number &= (number - 1);
    }
    return one_bits;
}