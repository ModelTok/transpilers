#ifndef MEHARA_GREEDY_FRACTIONAL_KNAPSACK_PROBLEM_H_
#define MEHARA_GREEDY_FRACTIONAL_KNAPSACK_PROBLEM_H_

#include <vector>

#include "item.h"

class GreedyFractionalKnapsackProblem {

	std::vector<Item> items_;

public:

	GreedyFractionalKnapsackProblem(std::vector<Item> items) {
		items_ = items;
	}

	int MaximumValue(int weight);

};

#endif