
#include <string>
#include <vector>

std::vector<std::string> fizz_buzz(int n) {
    std::vector<std::string> fizz_buzz;
    for (auto i = 1; i <= n; i++) {
        std::string str;

        if (i % 3 == 0) {
            str += "Fizz";
        }
        if (i % 5 == 0) {
            str += "Buzz";
        }

        if (str.empty()) {
            fizz_buzz.push_back(std::to_string(i));
        } else {
            fizz_buzz.push_back(str);
        }
    }
    return fizz_buzz;
}