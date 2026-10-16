
#include <unordered_map>
#include <vector>

int four_sum_count(const std::vector<int>& A, const std::vector<int>& B,
                   const std::vector<int>& C, const std::vector<int>& D) {

    std::unordered_map<int, int> frequency;
    for (const auto& _a : A) {
        for (const auto& _b : B) {
            frequency[_a + _b]++;
        }
    }
    auto _tuples = 0;
    for (const auto& _c : C) {
        for (const auto& _d : D) {
            auto it = frequency.find(-(_c + _d));
            if (it != frequency.end()) {
                _tuples += it->second;
            }
        }
    }

    return _tuples;
}
