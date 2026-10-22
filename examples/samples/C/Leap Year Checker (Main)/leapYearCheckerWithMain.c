#include <stdio.h>
#include <stdbool.h>

bool isLeapYear(int);

int main()
{
    printf("Is Leap Year? \n");

    int year;
    printf("year = ");
    scanf("%d", &year);

    printf(isLeapYear(year) ? "isLeapYear(%d) -> true" : "isLeapYear(%d) -> false", year);

    return 0;
}

bool isLeapYear(int year)
{

    return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) ? true : false;
}