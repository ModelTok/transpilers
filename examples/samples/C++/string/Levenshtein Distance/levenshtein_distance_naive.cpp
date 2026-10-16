#include "levenshtein_distance_naive.h"

#include <algorithm>
#include <vector>

int LevenshteinDistance::Distance(int sequence1_index, int sequence2_index) {

	if (!std::min(sequence1_index, sequence2_index)) {
		return std::max(sequence1_index, sequence2_index);
	}

	int indicator = (sequence1_[sequence1_index - 1] == sequence2_[sequence2_index - 1]) ? 0 : 1;

	return std::min(
		std::min(
			1 + Distance(sequence1_index - 1, sequence2_index),
			1 + Distance(sequence1_index, sequence2_index - 1)
		),
		indicator + Distance(sequence1_index - 1, sequence2_index - 1)
	);
}

int LevenshteinDistance::Distance() {

	int sequence1_size = static_cast<int>(sequence1_.size());
	int sequence2_size = static_cast<int>(sequence2_.size());

	return Distance(sequence1_size, sequence2_size);

}