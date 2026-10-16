
#include <climits>
#include <vector>

int coin_change(const std::vector<int>& coins, int remaining,
                std::vector<int>& count)
{
    if (remaining < 0) {
        return -1;
    }
    if (remaining == 0) {
        return 0;
    }
    if (count[remaining - 1] != INT_MAX) {
        return count[remaining - 1];
    }
    int minimum = INT_MAX;
    for (const auto& coin : coins) {
        auto result = coin_change(coins, remaining - coin, count);
        if (result >= 0 && result < minimum) {
            minimum = result + 1;
        }
    }
    count[remaining - 1] = (minimum == INT_MAX) ? -1 : minimum;
    return count[remaining - 1];
}

int coin_change(const std::vector<int>& coins, int amount)
{
    if (amount == 0) {
        return 0;
    }
    std::vector<int> count(amount, INT_MAX);
    return coin_change(coins, amount, count);
}