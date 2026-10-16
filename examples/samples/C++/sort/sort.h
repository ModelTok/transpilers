
#ifndef MEHARA_SORT_H_
#define MEHARA_SORT_H_

#include <concepts>
#include <exception>
#include <vector>

#include "bubble_sort.h"
#include "heap_sort.h"
#include "insertion_sort.h"
#include "merge_sort.h"
#include "quick_sort.h"
#include "selection_sort.h"

namespace mehara::sort {

enum class strategy {
    bubble_sort,
    heap_sort,
    insertion_sort,
    merge_sort,
    quick_sort,
    selection_sort
};

template <typename T>
requires std::totally_ordered<T> 
void sort(std::vector<T>& array, strategy strategy)
{
    switch (strategy) {
    case strategy::bubble_sort:
        bubble_sort(array);
        break;
    case strategy::heap_sort:
        heap_sort(array);
        break;
    case strategy::insertion_sort:
        insertion_sort(array);
        break;
    case strategy::merge_sort:
        merge_sort(array);
        break;
    case strategy::quick_sort:
        quick_sort(array);
        break;
    case strategy::selection_sort:
        selection_sort(array);
        break;
    default:
        throw std::exception();
    }
}

}

#endif
