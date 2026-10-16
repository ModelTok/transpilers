
#include <utility>
#include <vector>

void permute(std::vector<int>& numbers, int begin,
             std::vector<std::vector<int>>& permutations)
{
    if (begin >= numbers.size()) {
        permutations.push_back(numbers);
    }
    else {
        for (auto i = begin; i < numbers.size(); i++) {
            std::swap(numbers[begin], numbers[i]);
            permute(numbers, begin + 1, permutations);
            std::swap(numbers[begin], numbers[i]);
        }
    }
}

std::vector<std::vector<int>> permute(std::vector<int>& numbers)
{
    std::vector<std::vector<int>> permutations;
    permute(numbers, 0, permutations);
    return permutations;
}
