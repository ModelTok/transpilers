
#include <vector>

int majority_element(const std::vector<int>& numbers) {
    int _majority_element;
    int count = 0;
    for (const auto& number : numbers) {
        if (count == 0) {
            _majority_element = number;
        }
        count += (_majority_element == number) ? 1 : -1;
    }
    return _majority_element;
}