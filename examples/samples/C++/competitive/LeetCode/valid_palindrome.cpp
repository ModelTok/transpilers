
#include <cctype>
#include <string>

bool is_palindrome(const std::string& str) {
    int left_index = 0;
    int right_index = str.size() - 1;

    while (left_index < right_index) {
        while (left_index < right_index && !std::isalnum(str[left_index])) {
            left_index++;
        }
        while (left_index < right_index && !std::isalnum(str[right_index])) {
            right_index--;
        }
        if (left_index < right_index &&
            std::tolower(str[left_index]) != std::tolower(str[right_index])) {
            return false;
        }
        left_index++;
        right_index--;
    }

    return true;
}