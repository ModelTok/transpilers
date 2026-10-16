
#include <cmath>

int sqrt(int x) {
    auto k = x;
    while (k > 0) {
        auto k_plus_1 = (k + x / k) / 2;
        if (k_plus_1 == k || k_plus_1 == k + 1) {
            break;
        }
        k = k_plus_1;
    }
    return k;
}
