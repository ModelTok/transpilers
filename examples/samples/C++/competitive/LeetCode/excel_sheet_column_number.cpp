
#include <string>

int title_to_number(const std::string& column_title) {
    int column_number = 0;
    for (const auto& letter : column_title) {
        column_number = column_number * 26 + (letter - '@');
    }
    return column_number;
}