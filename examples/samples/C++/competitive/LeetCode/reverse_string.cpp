
#include <string>

std::string reverse_string(std::string str) {
    int left_index = 0;
    int right_index = str.size() - 1;
    while (left_index < right_index) {
        auto t = str[left_index];
        str[left_index] = str[right_index];
        str[right_index] = t;
        left_index++;
        right_index--;
    }
    return str;
}