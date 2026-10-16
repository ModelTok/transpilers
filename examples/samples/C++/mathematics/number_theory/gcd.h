
#ifndef MEHARA_GCD_H_
#define MEHARA_GCD_H_

#include <concepts>

namespace mehara::mathematics {

template <typename T>
requires std::integral<T> 
T gcd(T a, T b)
{
    if (b == 0) {
        return a;
    }
    return gcd(b, a % b);
}

template <typename T>
requires std::integral<T> 
T gcd(T a, T b, T& x, T& y)
{
    if (b == 0) {
        x = 1;
        y = 0;
        return a;
    }
    T x1, y1;
    auto d = gcd(b, a % b, x1, y1);
    x = y1;
    y = x1 - y1 * (a / b);
    return d;
}

}

#endif
