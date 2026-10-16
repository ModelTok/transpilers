
#include <cctype>
#include <iostream>

int main()
{
    int size;
    std::cin >> size;
    int set_[26] = {0};
    char c;
    for (auto i = 0; i < size; i++) {
        std::cin >> c;
        if (c >= 'A' && c <= 'Z') {
            set_[c - 'A']++;
        }
        else if (c >= 'a' && c <= 'z') {
            set_[c - 'a']++;
        }
    }
    for (auto i = 0; i < 26; i++) {
        if (set_[i] == 0) {
            std::cout << "NO\n";
            return 0;
        }
    }
    std::cout << "YES\n";
    return 0;
}