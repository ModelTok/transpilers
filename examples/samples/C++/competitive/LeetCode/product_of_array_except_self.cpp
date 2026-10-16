
#include <vector>

std::vector<int> product_except_self(const std::vector<int>& numbers)
{
    std::vector<int> result(numbers.size());
    result[0] = 1;
    for (int i = 1; i < numbers.size(); i++) {
        result[i] = result[i - 1] * numbers[i - 1];
    }
    int product_to_right = 1;
    for (int i = numbers.size() - 1; i >= 0; i--) {
        result[i] *= product_to_right;
        product_to_right *= numbers[i];
    }
    return result;
}