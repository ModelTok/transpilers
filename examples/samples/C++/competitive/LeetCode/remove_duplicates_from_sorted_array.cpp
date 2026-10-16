
#include <vector>

int remove_duplicates(std::vector<int>& numbers) {
    if (numbers.empty()) {
        return 0;
    }
    int unique_index = 0;
    for (int index = unique_index + 1; index < numbers.size(); index++) {
        if (numbers[unique_index] != numbers[index]) {
            unique_index++;
            numbers[unique_index] = numbers[index];
        }
    }
    return unique_index + 1;
}