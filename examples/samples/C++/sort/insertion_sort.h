
#ifndef MEHARA_INSERTON_SORT_H_
#define MEHARA_INSERTON_SORT_H_

#include <concepts>
#include <vector>

namespace mehara::sort {

template <typename T>
requires std::totally_ordered<T>
void insertion_sort(std::vector<T>& array)
{
    for (auto outer_index = 1; outer_index < array.size(); outer_index++) {
        auto key = array[outer_index];
        auto inner_index = outer_index - 1;
        while (inner_index >= 0 && array[inner_index] > key) {
            array[inner_index + 1] = array[inner_index];
            inner_index = inner_index - 1;
        }
        array[inner_index + 1] = key;
    }
}

}

#endif
