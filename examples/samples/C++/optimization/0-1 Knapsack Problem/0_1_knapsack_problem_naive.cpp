#include "0_1_knapsack_problem_naive.h"

#include <algorithm>
#include <vector>

#include "item.h"

int ZeroOneKnapsackProblem::MaximumValue(int items, int weight) {

	if (items <= 0 || weight <= 0) {
		return 0;
	}

	int value_excluding_current = MaximumValue(items - 1, weight);

	int value_including_current = 0;
	if (weight >= items_[items - 1].Weight()) {
		value_including_current = items_[items - 1].Value() + MaximumValue(items - 1, weight - items_[items - 1].Weight());
	}

	return std::max(value_excluding_current, value_including_current);

}

int ZeroOneKnapsackProblem::MaximumValue(int weight) {

	int item_size = static_cast<int>(items_.size());

	return MaximumValue(item_size, weight);

}