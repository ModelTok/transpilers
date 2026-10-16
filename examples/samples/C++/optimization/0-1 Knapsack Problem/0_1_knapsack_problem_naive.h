#ifndef MEHARA_0_1_KNAPSACK_PROBLEM_NAIVE_H_
#define MEHARA_0_1_KNAPSACK_PROBLEM_NAIVE_H_

#include <vector>

#include "item.h"

class ZeroOneKnapsackProblem {

	std::vector<Item> items_;

	int MaximumValue(int items, int weight);

public:

	ZeroOneKnapsackProblem(std::vector<Item>& items) {
		items_ = items;
	}

	int MaximumValue(int weight);

};

#endif