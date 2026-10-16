#include "the_coin_change_problem_tabulation.h"

#include <vector>

int TheCoinChangeProblem::Combinations(int coins, int amount) {

	int coin_denominations_size = static_cast<int>(coin_denominations_.size());

	std::vector<std::vector<int>> table(coin_denominations_size, std::vector<int>(amount + 1, 0));

	for (int i = 0; i < coin_denominations_size; i++) {
		table[i][0] = 1;
	}

	for (int i = 0; i < coin_denominations_size; i++) {
		for (int j = 1; j <= amount; j++) {

			int combinations_excluding_current = 0;
			if (i > 0) {
				combinations_excluding_current = table[i - 1][j];
			}

			int combinations_including_current = 0;
			if (j >= coin_denominations_[i]) {
				combinations_including_current = table[i][j - coin_denominations_[i]];
			}

			table[i][j] = combinations_excluding_current + combinations_including_current;

		}
	}

	return table[coin_denominations_size - 1][amount];

}

int TheCoinChangeProblem::Combinations(int amount)
{

	int coins = static_cast<int>(coin_denominations_.size());

	return Combinations(coins, amount);

}