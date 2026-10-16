#include "longest_common_subsequence.h"

#include <algorithm>
#include <deque>
#include <vector>

std::deque<char> LongestCommonSubsequence(std::vector<char> sequence1, std::vector<char> sequence2) {

	int sequence1_size = static_cast<int>(sequence1.size());
	int sequence2_size = static_cast<int>(sequence2.size());

	std::vector<std::vector<int>> table(sequence1_size + 1, std::vector<int>(sequence2_size + 1, 0));

	for (int index1 = 0; index1 < sequence1_size; index1++) {
		for (int index2 = 0; index2 < sequence2_size; index2++) {
			if (sequence1[index1] == sequence2[index2]) {
				table[index1 + 1][index2 + 1] = 1 + table[index1][index2];
			}
			else {
				table[index1 + 1][index2 + 1] = std::max(table[index1][index2 + 1], table[index1 + 1][index2]);
			}
		}
	}

	std::deque<char> longest_common_subsequence;

	int index1 = sequence1_size - 1;
	int index2 = sequence2_size - 1;

	while (index1 >= 0 && index2 >= 0) {
		if (sequence1[index1] == sequence2[index2]) {
			longest_common_subsequence.push_front(sequence1[index1]);
			index1--;
			index2--;
		}
		else {
			if (table[index1][index2 + 1] > table[index1 + 1][index2]) {
				index1--;
			}
			else {
				index2--;
			}
		}
	}

	return longest_common_subsequence;

}