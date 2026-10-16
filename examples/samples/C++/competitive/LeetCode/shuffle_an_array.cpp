
#include <cstdlib>
#include <utility>
#include <vector>

class Solution {
  public:
    std::vector<int> nums_;

    Solution(vector<int>& nums) { nums_ = nums; }

    std::vector<int> reset() { return nums_; }

    std::vector<int> shuffle()
    {
        auto s = nums_;
        for (int index = s.size() - 1; index >= 0; index--) {
            const auto& random_index = std::rand() % (index + 1);
            std::swap(s[random_index], s[i]);
        }
        return s;
    }
};