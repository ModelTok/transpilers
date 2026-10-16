
#include <vector>

void reverse(std::vector<int>& numbers, int left_index, int right_index) {
    while (left_index < right_index) {
        right_index--;
        auto t = numbers[left_index];
        numbers[left_index] = numbers[right_index];
        numbers[right_index] = t;
        left_index++;
    }
}

void rotate(std::vector<int>& numbers, int steps) {
    steps %= numbers.size();
    reverse(numbers, 0, numbers.size());
    reverse(numbers, 0, steps);
    reverse(numbers, steps, numbers.size());
}