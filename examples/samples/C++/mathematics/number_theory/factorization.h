
#ifndef MEHARA_FACTORIZATION_H_
#define MEHARA_FACTORIZATION_H_

#include <concepts>
#include <vector>

namespace mehara::mathematics {

template <typename T>
requires std::integral<T> 
std::vector<T> trial_division(T number)
{
    std::vector<T> factorization;
    for (T divisor = 2; divisor * divisor <= number; divisor++) {
        while (number % divisor == 0) {
            factorization.push_back(divisor);
            number /= divisor;
        }
    }
    if (number > 1) {
        factorization.push_back(number);
    }
    return factorization;
}

template <typename T>
requires std::integral<T> std::vector<T> 
factorize(T number, const std::vector<T>& primes)
{
    std::vector<T> factorization;
    for (const auto& divisor : primes) {
        if (divisor * divisor > number) {
            break;
        }
        while (number % divisor == 0) {
            factorization.push_back(divisor);
            number /= divisor;
        }
    }
    if (number > 1) {
        factorization.push_back(number);
    }
    return factorization;
}

}

#endif
