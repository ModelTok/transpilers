
#include "area.h"

#include <math.h>

double area_circle(double radius) {
    return M_PI * pow(radius, 2.0);
}

double area_square(double side) {
    return pow(side, 2.0);
}

double area_rectangle(double length, double width) {
    return length * width;
}
