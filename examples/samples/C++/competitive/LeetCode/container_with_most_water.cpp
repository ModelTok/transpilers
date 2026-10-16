
#include <algorithm>
#include <vector>

int maximum_area(const std::vector<int>& heights)
{
    int maximum_area_ = 0;
    int left_index = 0;
    int right_index = heights.size() - 1;
    while (left_index != right_index) {
        maximum_area_ = std::max(
            maximum_area_, std::min(heights[left_index], heights[right_index]) *
                               (right_index - left_index));
        if (heights[left_index] < heights[right_index]) {
            left_index++;
        }
        else {
            right_index--;
        }
    }
    return maximum_area_;
}
