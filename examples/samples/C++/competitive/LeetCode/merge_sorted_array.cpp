
#include <vector>

void merge(std::vector<int>& array_1, int size_1, std::vector<int>& array_2,
           int size_2) {
    int index = size_1 + size_2 - 1;
    int index_1 = size_1 - 1;
    int index_2 = size_2 - 1;

    while (index_1 >= 0 && index_2 >= 0) {
        array_1[index--] = (array_1[index_1] >= array_2[index_2])
                               ? array_1[index_1--]
                               : array_2[index_2--];
    }

    while (index_1 >= 0) {
        array_1[index--] = array_1[index_1--];
    }

    while (index_2 >= 0) {
        array_1[index--] = array_2[index_2--];
    }
}