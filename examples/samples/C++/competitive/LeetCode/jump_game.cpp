
#include <vector>

bool can_jump(const std::vector<int>& numbers) {
    auto current_good_index = numbers.size() - 1;
    for (auto index = numbers.size() - 1; index >= 0; index--) {
        if (index + numbers[index] >= current_good_index) {
            current_good_index = index;
        }
    }
    return current_good_index == 0;
}