
#include <cstdint>

std::uint_fast32_t reverse_bits(std::uint_fast32_t number) {
    std::uint_fast32_t reverse = 0;
    for (int index = 0; index < 32; index++) {
        reverse <<= 1;
        reverse ^= (number & 1);
        number >>= 1;
    }
    return reverse;
}