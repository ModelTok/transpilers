
#ifndef MEHARA_LCM_H_
#define MEHARA_LCM_H_

#include "gcd.h"

namespace mehara::mathematics {

int lcm(int a, int b) { return a / gcd(a, b) * b; }

}

#endif