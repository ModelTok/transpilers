#include"longest_common_subsequence_naive.h"

#include <algorithm>
#include <vector>

int LongestCommonSubsequenceLength(std::vector<char>& sequence1, std::vector<char>& sequence2, int index1, int index2) {

	if (index1 < 0 || index2 < 0) {
		return 0;
	}

	if (sequence1[index1] == sequence2[index2]) {
		return 1 + LongestCommonSubsequenceLength(sequence1, sequence2, index1 - 1, index2 - 1);
	}
	else {
		return std::max(
			LongestCommonSubsequenceLength(sequence1, sequence2, index1 - 1, index2),
			LongestCommonSubsequenceLength(sequence1, sequence2, index1, index2 - 1)
		);
	}

}