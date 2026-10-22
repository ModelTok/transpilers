#include <stdio.h>
#include <stdbool.h>

bool isLeapYear(int year)
{

    return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) ? true : false;
}