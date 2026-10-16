#include "longest_increasing_subsequence_tabulation.h"

#include <algorithm>
#include <vector>

LongestIncreasingSubsequence::LongestIncreasingSubsequence(std::vector<int> sequence) {

	length_ = 0;
	sequence_ = sequence;
	table_ = std::vector<int>(sequence_.size() + 1, 1);

	for (int sequence_index = 0; sequence_index < sequence_.size(); sequence_index++) {
		for (int previous_index = 0; previous_index < sequence_index; previous_index++) {
			if (sequence_[sequence_index] > sequence_[previous_index] && table_[sequence_index] < table_[previous_index] + 1) {
				table_[sequence_index] = table_[previous_index] + 1;
			}
		}
	}

	for (int sequence_index = 0; sequence_index < sequence_.size(); sequence_index++) {
		length_ = std::max(length_, table_[sequence_index]);
	}

}

int LongestIncreasingSubsequence::Length() {
	return length_;
}