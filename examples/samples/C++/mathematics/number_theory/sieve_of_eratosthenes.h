
#ifndef MEHARA_SIEVE_OF_ERATOSTHENES_H_
#define MEHARA_SIEVE_OF_ERATOSTHENES_H_

#include <concepts>
#include <vector>

namespace mehara::mathematics {

template <typename T>
requires std::integral<T> 
std::vector<char> sieve_of_eratosthenes(T number)
{
    std::vector<char> is_prime(number + 1, true);
    is_prime[0] = is_prime[1] = false;
    for (T i = 2; i * i <= number; i++) {
        if (is_prime[i]) {
            for (T j = i * 2; j <= number; j += i) {
                is_prime[j] = false;
            }
        }
    }
    return is_prime;
}

}

#endif
