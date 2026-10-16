#ifndef MEHARA_SUBSET_SUM_PROBLEM_NAIVE_H_
#define MEHARA_SUBSET_SUM_PROBLEM_NAIVE_H_

#include <vector>

class SubsetSumProblem {

	std::vector<int> set_;

	bool SubsetSum(int elements, int sum);

public:

	SubsetSumProblem(std::vector<int>& set) {
		set_ = set;
	}

	bool SubsetSum(int sum);

};

#endif