#ifndef MEHARA_THE_COIN_CHANGE_TABULATION_H_
#define MEHARA_THE_COIN_CHANGE_TABULATION_H_

#include <vector>

class TheCoinChangeProblem {

	std::vector<int> coin_denominations_;

	int Combinations(int coins, int amount);

public:

	TheCoinChangeProblem(std::vector<int> coin_denominations) {
		coin_denominations_ = coin_denominations;
	}

	int Combinations(int amount);

};

#endif