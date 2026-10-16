#include "the_coin_change_problem_naive.h"

#include <vector>

int TheCoinChangeProblem::Combinations(int coins, int amount) {

	if (amount == 0) {
		return 1;
	}

	if (coins <= 0 || amount < 0) {
		return 0;
	}

	int combinations_excluding_current = Combinations(coins - 1, amount);
	int combinations_including_current = Combinations(coins, amount - coin_denominations_[coins - 1]);

	return combinations_excluding_current + combinations_including_current;

}

int TheCoinChangeProblem::Combinations(int amount)
{

	int coins = static_cast<int>(coin_denominations_.size());

	return Combinations(coins, amount);

}