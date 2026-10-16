
#include <vector>

int count_primes(int number) {

    if (number < 2) {
        return 0;
    }

    auto primes = 0;
    std::vector<bool> is_prime(number, true);

    is_prime[0] = false;
    is_prime[1] = false;

    for (auto index = 2; index * index < number; index++) {
        if (is_prime[index]) {
            auto multiple = 2 * index;
            while (multiple < number) {
                is_prime[multiple] = false;
                multiple += index;
            }
        }
    }

    for (const bool& _b : is_prime) {
        if (_b) {
            primes += 1;
        }
    }

    return primes;
}