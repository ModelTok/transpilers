
#include <string>

int integer_value(char symbol)
{
    switch (symbol) {
    case 'I':
        return 1;
        break;
    case 'V':
        return 5;
        break;
    case 'X':
        return 10;
        break;
    case 'L':
        return 50;
        break;
    case 'C':
        return 100;
        break;
    case 'D':
        return 500;
        break;
    case 'M':
        return 1000;
        break;
    default:
        return -1;
    }
}

int roman_to_integer(const std::string& roman)
{
    int integer = 0;
    int successor = 0;
    for (int index = roman.size() - 1; index >= 0; index--) {
        auto current = integer_value(roman[index]);
        integer += current >= successor ? current : (-1 * current);
        successor = current;
    }
    return integer;
}