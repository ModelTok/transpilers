
#include "reverse.h"

namespace mehara::mathematics {

int reverse(int number) {
    int reverse = 0;
    while (number) {
        reverse = reverse * 10 + number % 10;
        number = number / 10;
    }
    return reverse;
}

}
