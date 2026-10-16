
#include <vector>

int single_number(const std::vector<int>& numbers) {
    int single_number = 0;
    for (const auto& number : numbers) {
        single_number ^= number;
    }
    return single_number;
}