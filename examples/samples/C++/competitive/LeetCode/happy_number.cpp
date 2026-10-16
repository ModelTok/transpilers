
#include <cmath>
#include <unordered_set>

bool is_happy(int number) {
    std::unordered_set<int> generated;
    while (generated.insert(number).second) {
        auto _sum = 0;
        while (number > 0) {
            _sum += std::pow(number % 10, 2);
            number = number / 10;
        }
        number = _sum;
    }
    return number == 1;
}
