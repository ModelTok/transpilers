
#ifndef MEHARA_TOTIENT_FUNCTION_H_
#define MEHARA_TOTIENT_FUNCTION_H_

#include <concepts>
#include <exception>
#include <vector>

namespace mehara::mathematics {

template <typename T>
requires std::integral<T> 
T phi_of(T number)
{
    T result = number;
    for (T i = 2; i * i <= number; i++) {
        if (number % i == 0) {
            while (number % i == 0) {
                number /= i;
            }
            result -= result / i;
        }
    }
    if (number > 1) {
        result -= result / number;
    }
    return result;
}

template <typename T>
requires std::integral<T> 
std::vector<T> phi_sieve(T number)
{
    std::vector<T> phi(number + 1);
    for (T i = 0; i <= number; i++) {
        phi[i] = i;
    }
    for (T i = 2; i <= number; i++) {
        if (phi[i] == i) {
            for (T j = i; j <= number; j += i) {
                phi[j] -= phi[j] / i;
            }
        }
    }
    return phi;
}

template <typename T>
requires std::integral<T> 
std::vector<T> phi_divisor_sum(T number)
{
    std::vector<T> phi(number + 1);
    phi[0] = 0;
    phi[1] = 1;
    for (T i = 2; i <= number; i++) {
        phi[i] = i - 1;
    }
    for (T i = 2; i <= number; i++) {
        for (T j = i * 2; j <= number; j += i) {
            phi[j] -= phi[i];
        }
    }
    return phi;
}

enum class phi_strategy { sieve, divisor_sum };

template <typename T>
requires std::integral<T> std::vector<T>
phi(T number, const phi_strategy& strategy = phi_strategy::sieve)
{
    switch (strategy) {
    case phi_strategy::sieve:
        return phi_sieve(number);
    case phi_strategy::divisor_sum:
        return phi_divisor_sum(number);
    default:
        throw std::exception();
    }
}

}

#endif