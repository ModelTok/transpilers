#include "subset_sum_problem_naive.h"

#include <vector>

bool SubsetSumProblem::SubsetSum(int elements, int sum) {

	if (!sum) {
		return true;
	}

	if (elements <= 0 || sum < 0) {
		return false;
	}

	return SubsetSum(elements - 1, sum) || SubsetSum(elements - 1, sum - set_[elements - 1]);

}

bool SubsetSumProblem::SubsetSum(int sum) {

	int set_size = static_cast<int>(set_.size());

	return SubsetSum(set_size, sum);

}