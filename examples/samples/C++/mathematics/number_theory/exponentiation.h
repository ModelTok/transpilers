
#ifndef MEHARA_EXPONENTIATION_H_
#define MEHARA_EXPONENTIATION_H_

#include <concepts>
#include <vector>

namespace mehara::mathematics {

template <typename T>
requires std::integral<T>
T binary_exponentiation_recursive(T a, T b)
{
    if (b == 0) {
        return 1;
    }
    auto power = binary_exponentiation_recursive(a, b / 2);
    return (b & 1) ? power * power * a : power * power;
}

template <typename T>
requires std::integral<T>
T binary_exponentiation_iterative(T a, T b)
{
    T power = 1;
    while (b > 0) {
        if (b & 1) {
            power = power * a;
        }
        a = a * a;
        b >>= 1;
    }
    return power;
}

template <typename T>
requires std::integral<T>
T binary_exponentiation(T a, T b, bool is_recursive = false)
{
    if (is_recursive) {
        return binary_exponentiation_recursive(a, b);
    }
    else {
        return binary_exponentiation_iterative(a, b);
    }
}

template <typename T>
requires std::integral<T>
T modular_exponentiation_recursive(T a, T b, T m)
{
    if (b == 0) {
        return 1;
    }
    auto power = modular_exponentiation_recursive(a, b / 2, m);
    return (b & 1) ? (power * power % m) * a % m : power * power % m;
}

template <typename T>
requires std::integral<T>
T modular_exponentiation_iterative(T a, T b, T m)
{
    T power = 1;
    while (b > 0) {
        if (b & 1) {
            power = power * a % m;
        }
        a = a * a % m;
        b >>= 1;
    }
    return power;
}

template <typename T>
requires std::integral<T>
T modular_exponentiation(T a, T b, T m, bool is_recursive = false)
{
    if (is_recursive) {
        return modular_exponentiation_recursive(a, b, m);
    }
    else {
        return modular_exponentiation_iterative(a, b, m);
    }
}

}

#endif
