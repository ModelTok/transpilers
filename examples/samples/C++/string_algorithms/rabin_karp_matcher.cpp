
#include "rabin_karp_matcher.h"
#include "../mathematics/number_theory/exponentiation.h"

#include <cmath>
#include <string>
#include <vector>

namespace mehara::string {

std::vector<int> rabin_karp_matcher(const std::string& text,
                                    const std::string& pattern, int radix,
                                    int prime)
{
    std::vector<int> matches;
    int n = text.size();
    int m = pattern.size();
    int h = mathematics::modular_exponentiation(radix, m - 1, prime);
    int pattern_hash = 0;
    int rolling_hash = 0;
    for (int i = 0; i < m; i++) {
        pattern_hash = (radix * pattern_hash + pattern[i]) % prime;
        rolling_hash = (radix * rolling_hash + text[i]) % prime;
    }
    for (int i = 0; i <= n - m; i++) {
        if (pattern_hash == rolling_hash) {
            bool match = true;
            for (int j = 0; j < m; j++) {
                if (pattern[j] != text[i + j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                matches.push_back(i);
            }
        }
        if (i < n - m) {
            rolling_hash =
                (radix * (rolling_hash - text[i] * h) + text[i + m]) % prime;
            if (rolling_hash < 0) {
                rolling_hash += prime;
            }
        }
    }
    return matches;
}

}
