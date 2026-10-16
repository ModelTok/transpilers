#include "subset_sum_problem_tabulation.h"

#include <vector>

bool SubsetSumProblem::SubsetSum(int elements, int sum) {

	std::vector<std::vector<bool>> table(elements + 1, std::vector<bool>(sum + 1, false));

	for (int i = 0; i <= elements; i++) {
		table[i][0] = true;
	}

	for (int element_index = 1; element_index <= elements; element_index++) {
		for (int sum_index = 1; sum_index <= sum; sum_index++) {
			bool sum_excluding_current = table[element_index - 1][sum_index];

			bool sum_including_current = false;
			if (sum_index >= set_[element_index - 1]) {
				sum_including_current = table[element_index - 1][sum_index - set_[element_index - 1]];
			}

			table[element_index][sum_index] = sum_excluding_current || sum_including_current;
		}
	}

	return table[elements][sum];

}

bool SubsetSumProblem::SubsetSum(int sum) {

	int set_size = static_cast<int>(set_.size());

	return SubsetSum(set_size, sum);

}