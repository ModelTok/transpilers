#include "greedy_fractional_knapsack_problem.h"

#include <algorithm>
#include <vector>

#include "item.h"

int GreedyFractionalKnapsackProblem::MaximumValue(int weight) {

	int item_size = static_cast<int>(items_.size());

	std::sort(items_.begin(), items_.end(), [](Item& i1, Item& i2) {
		return (double)i1.Value() / i1.Weight() > (double)i2.Value() / i2.Weight();
	});

	double maximum_value = 0;
	int weight_remaining = weight;
	for (int item_index = 0; item_index < item_size; item_index++) {
		int current_value = items_[item_index].Value();
		int current_weight = items_[item_index].Weight();
		if (weight_remaining >= current_weight) {
			maximum_value += current_value;
			weight_remaining -= current_weight;
		}
		else {
			maximum_value += (double)current_value * weight_remaining / current_weight;
			break;
		}
	}

	return maximum_value;

}