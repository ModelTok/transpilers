
#ifndef MEHARA_QUICK_SORT_H_
#define MEHARA_QUICK_SORT_H_

#include <algorithm>
#include <concepts>
#include <vector>

namespace mehara::sort {

template <typename T>
requires std::totally_ordered<T>
int partition(std::vector<T>& array, int begin, int end)
{
    auto pivot = array[end];
    auto i = begin;
    for (auto j = i; j < end; j++) {
        if (array[j] < pivot) {
            std::swap(array[i], array[j]);
            i += 1;
        }
    }
    std::swap(array[i], array[end]);
    return i;
}

template <typename T>
requires std::totally_ordered<T>
void quick_sort(std::vector<T>& array, int begin, int end)
{
    if (begin <= end) {
        auto _partition = partition(array, begin, end);
        quick_sort(array, begin, _partition - 1);
        quick_sort(array, _partition + 1, end);
    }
}

template <typename T>
requires std::totally_ordered<T>
void quick_sort(std::vector<T>& array)
{
    auto begin = 0;
    auto end = array.size() - 1;

    quick_sort(array, begin, end);
}

}

#endif
