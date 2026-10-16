#include "partition_problem_naive.h"

#include <vector>

bool PartitionProblem::SubsetSum(int elements, int sum) {

	if (!sum) {
		return true;
	}

	if (elements <= 0 || sum < 0) {
		return false;
	}

	return SubsetSum(elements - 1, sum) || SubsetSum(elements - 1, sum - set_[elements - 1]);

}

bool PartitionProblem::Partition() {

	int set_size = static_cast<int>(set_.size());

	int sum = 0;
	for (int i = 0; i < set_size; i++) {
		sum += set_[i];
	}

	if (sum % 2) {
		return false;
	}

	return SubsetSum(set_size, sum / 2);

}