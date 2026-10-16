
#ifndef MEHARA_HEAP_SORT_H_
#define MEHARA_HEAP_SORT_H_

#include <algorithm>
#include <concepts>
#include <vector>

namespace mehara::sort {

template <typename T>
requires std::totally_ordered<T>
void sink(std::vector<T>& array, int index, int heap_size)
{
    while (2 * index + 1 < heap_size) {
        int child_index = 2 * index + 1;
        if (child_index < heap_size - 1 &&
            array[child_index] < array[child_index + 1]) {
            child_index++;
        }
        if (!(array[index] < array[child_index])) {
            break;
        }
        std::swap(array[index], array[child_index]);
        index = child_index;
    }
}

template <typename T>
requires std::totally_ordered<T>
void heap_sort(std::vector<T>& array)
{
    int _heap_size = array.size();
    for (int index = _heap_size / 2 - 1; index >= 0; index--) {
        sink(array, index, _heap_size);
    }
    while (_heap_size > 0) {
        std::swap(array[0], array[_heap_size - 1]);
        sink(array, 0, --_heap_size);
    }
}

}

#endif
