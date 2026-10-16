
#include <vector>

int missing_number(const std::vector<int>& numbers) {
    int sum = (numbers.size() * (numbers.size() + 1)) / 2;
    for (const auto& number : numbers) {
        sum -= number;
    }
    return sum;
}