
#ifndef MEHARA_BUBBLE_SORT_H_
#define MEHARA_BUBBLE_SORT_H_

#include <algorithm>
#include <concepts>
#include <vector>

namespace mehara::sort {

template <typename T>
requires std::totally_ordered<T>
void bubble_sort(std::vector<T>& array)
{
    auto swapped = false;
    do {
        swapped = false;
        for (auto index = 0; index < array.size() - 1; index++) {
            if (array[index] > array[index + 1]) {
                std::swap(array[index], array[index + 1]);
                swapped = true;
            }
        }
    } while (swapped == true);
}

}

#endif
