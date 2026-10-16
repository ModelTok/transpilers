
#include <vector>

int lower_bound(const std::vector<int>& numbers, int target)
{
    int index = 0;
    int count = numbers.size();
    while (count > 0) {
        auto step = count / 2;
        if (numbers[index + step] < target) {
            index += step + 1;
            count -= step + 1;
        }
        else {
            count = step;
        }
    }
    return index;
}

int upper_bound(const std::vector<int>& numbers, int target)
{
    int index = 0;
    int count = numbers.size();
    while (count > 0) {
        auto step = count / 2;
        if (!(target < numbers[index + step])) {
            index += (step + 1);
            count -= step + 1;
        }
        else {
            count = step;
        }
    }
    return index;
}

std::vector<int> search_range(const std::vector<int>& numbers, int target)
{
    auto first = lower_bound(numbers, target);
    if (first == numbers.size() || numbers[first] != target) {
        return {-1, -1};
    }
    auto last = upper_bound(numbers, target);
    return {first, last - 1};
}