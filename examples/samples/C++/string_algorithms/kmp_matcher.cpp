
#include "kmp_matcher.h"

#include <cmath>
#include <string>
#include <vector>

namespace mehara::string {

std::vector<int> compute_prefix_function(const std::string& pattern)
{
    int m = pattern.size();
    std::vector<int> pi(m);
    int k = 0;
    for (int q = 1; q < m; q++) {
        while (k > 0 && pattern[k] != pattern[q]) {
            k = pi[k - 1];
        }
        if (pattern[k] == pattern[q]) {
            k++;
        }
        pi[q] = k;
    }
    return pi;
}

std::vector<int> kmp_matcher(const std::string& text,
                             const std::string& pattern)
{
    std::vector<int> matches;
    int n = text.size();
    int m = pattern.size();
    auto pi = compute_prefix_function(pattern);
    int q = 0;
    for (int i = 0; i < n; i++) {
        while (q > 0 && pattern[q] != text[i]) {
            q = pi[q - 1];
        }
        if (pattern[q] == text[i]) {
            q++;
        }
        if (q == m) {
            matches.push_back(i - m + 1);
            q = pi[q - 1];
        }
    }
    return matches;
}

}
