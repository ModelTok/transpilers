
#include <unordered_set>
#include <vector>

bool contains_duplicate(const std::vector<int>& numbers) {
    std::unordered_set<int> unique_numbers;
    for (const auto& number : numbers) {
        if (unique_numbers.count(number)) {
            return true;
        } else {
            unique_numbers.insert(number);
        }
    }
    return false;
}