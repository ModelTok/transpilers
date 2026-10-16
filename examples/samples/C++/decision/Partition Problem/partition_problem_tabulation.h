#ifndef MEHARA_PARTITION_PROBLEM_TABULATION_H_
#define MEHARA_PARTITION_PROBLEM_TABULATION_H_

#include <vector>

class PartitionProblem {

	std::vector<int> set_;

	bool SubsetSum(int elements, int sum);

public:

	PartitionProblem(std::vector<int>& set) {
		set_ = set;
	}

	bool Partition();

};

#endif