#include "0_1_knapsack_problem_tabulation.h"

#include <algorithm>
#include <vector>

#include "item.h"

int ZeroOneKnapsackProblem::MaximumValue(int items, int weight) {

	std::vector<std::vector<int>> table(items + 1, std::vector<int>(weight + 1, 0));

	for (int item_index = 1; item_index <= items; item_index++) {
		for (int weight_index = 0; weight_index <= weight; weight_index++) {

			int value_excluding_current = table[item_index - 1][weight_index];

			int value_including_current = 0;
			if (weight_index >= items_[item_index - 1].Weight()) {
				value_including_current = items_[item_index - 1].Value() + table[item_index - 1][weight_index - items_[item_index - 1].Weight()];
			}

			table[item_index][weight_index] = std::max(value_excluding_current, value_including_current);

		}
	}

	return table[items][weight];

}

int ZeroOneKnapsackProblem::MaximumValue(int weight) {

	int item_size = static_cast<int>(items_.size());

	return MaximumValue(item_size, weight);

}