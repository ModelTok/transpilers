#ifndef MEHARA_LONGEST_INCREASING_SUBSEQUENCE_TABULATION_H_
#define MEHARA_LONGEST_INCREASING_SUBSEQUENCE_TABULATION_H_

#include <vector>

class LongestIncreasingSubsequence {

	std::vector<int> sequence_;
	std::vector<int> table_;
	int length_;

public:
	LongestIncreasingSubsequence(std::vector<int> sequence);

	int Length();

};

#endif