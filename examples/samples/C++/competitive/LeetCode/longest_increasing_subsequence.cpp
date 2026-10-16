
#include <algorithm>
#include <vector>

int lengthOfLIS(std::vector<int>& sequence)
{
    if (sequence.empty()) {
        return 0;
    }
    std::vector<int> dp(sequence.size(), 1);
    int length_lis = 0;
    for (int i = 0; i < sequence.size(); i++) {
        for (int j = 0; j < i; j++) {
            if (sequence[j] < sequence[i]) {
                dp[i] = std::max(dp[j] + 1, dp[i]);
            }
        }
        length_lis = std::max(dp[i], length_lis);
    }
    return length_lis;
}