
#ifndef MEHARA_SEARCH_H_
#define MEHARA_SEARCH_H_

#include <concepts>
#include <vector>

namespace mehara {

template <typename T>
requires std::totally_ordered<T>
bool binary_search_iterative(const std::vector<T>& data, T key, int& index)
{
    int left = 0;
    int right = data.size() - 1;
    while (left <= right) {
        int mid = left + (right - left) / 2;
        if (data[mid] < key) {
            left = mid + 1;
        }
        else if (data[mid] > key) {
            right = mid - 1;
        }
        else {
            index = mid;
            return true;
        }
    }
    return false;
}

template <typename T>
requires std::totally_ordered<T>
bool binary_search_recursive(const std::vector<T>& data, T key, int& index, int left, int right)
{
    if (left <= right) {
        int mid = left + (right - left) / 2;
        if (data[mid] < key) {
            return binary_search_recursive(data, key, index, mid + 1, right);
        }
        else if (data[mid] > key) {
            return binary_search_recursive(data, key, index, left, mid - 1);
        }
        else {
            index = mid;
            return true;
        }
    }
    else {
        return false;
    }
}

template <typename T>
requires std::totally_ordered<T>
bool binary_search(const std::vector<T>& data, T key, int& index, bool is_recursive = true)
{
    if (is_recursive) {
        return binary_search_recursive(data, key, index, 0, data.size() - 1);
    }
    else {
        return binary_search_iterative(data, key, index);
    }
}

template <typename T>
requires std::equality_comparable<T>
bool linear_search(const std::vector<T>& data, T key, int& index)
{
    for (int i = 0; i < data.size(); i++) {
        if (data[i] == key) {
            index = i;
            return true;
        }
    }
    return false;
}

}

#endif
