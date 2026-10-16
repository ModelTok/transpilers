
#include <algorithm>
#include <stdexcept>
#include <vector>

void sort_colors(std::vector<int>& colors) {

    auto zero_index = 0;
    auto one_index = 0;
    int two_index = colors.size() - 1;

    while (one_index <= two_index) {
        switch (colors[one_index]) {
        case 0:
            std::swap(colors[zero_index], colors[one_index]);
            zero_index++;
            one_index++;
            break;
        case 1:
            one_index++;
            break;
        case 2:
            std::swap(colors[two_index], colors[one_index]);
            two_index--;
            break;
        default:
            throw std::invalid_argument("Unknown color.");
        }
    }
}