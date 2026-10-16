
#include <stdexcept>
#include <unordered_map>
#include <vector>

std::vector<int> two_sum(std::vector<int>& numbers, int target) {
    std::unordered_map<int, int> index_map;
    for (auto index = 0; index < numbers.size(); index++) {
        auto number = numbers[index];
        auto complement = target - number;
        if (index_map.count(complement) == 0) {
            index_map.insert({number, index});
        } else {
            return std::vector<int>{index_map.find(complement)->second, index};
        }
    }
    throw std::logic_error("No solution.");
}
