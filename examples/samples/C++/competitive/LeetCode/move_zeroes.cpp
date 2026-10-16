
#include <algorithm>
#include <vector>

void move_zeroes(std::vector<int>& numbers) {
    auto non_zero_index = 0;
    for (auto index = 0; index < numbers.size(); index++) {
        if (numbers[index] != 0) {
            std::swap(numbers[non_zero_index], numbers[index]);
            non_zero_index += 1;
        }
    }
}
