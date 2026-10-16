
#ifndef MEHARA_SELECTION_SORT_H_
#define MEHARA_SELECTION_SORT_H_

#include <algorithm>
#include <concepts>
#include <vector>

namespace mehara::sort {

template <typename T>
requires std::totally_ordered<T>
void selection_sort(std::vector<T>& array)
{
    for (auto outer_index = 0; outer_index < array.size() - 1; outer_index++) {
        auto minimum_index = outer_index;
        for (auto inner_index = outer_index + 1; inner_index < array.size();
             inner_index++) {
            if (array[minimum_index] > array[inner_index]) {
                minimum_index = inner_index;
            }
        }
        if (minimum_index != outer_index) {
            std::swap(array[minimum_index], array[outer_index]);
        }
    }
}

}

#endif
