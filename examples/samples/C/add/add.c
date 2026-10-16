
#include "add.h"

double add2(double number1, double number2) {
    return number1 + number2;
}

double addN(double* numbers, int size) {
    double sum = 0.0;
    for (int index = 0; index < size; index++) {
        sum += *(numbers + index);
    }
    return sum;
}
