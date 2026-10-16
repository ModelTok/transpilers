#include "levenshtein_distance_naive.h"

#include <algorithm>
#include <vector>

int LevenshteinDistance::Distance() {

	int sequence1_size = static_cast<int>(sequence1_.size());
	int sequence2_size = static_cast<int>(sequence2_.size());

	std::vector<std::vector<int>> table(sequence1_size + 1, std::vector<int>(sequence2_size + 1, 0));

	for (int sequence1_index = 0; sequence1_index <= sequence1_size; sequence1_index++) {
		table[sequence1_index][0] = sequence1_index;
	}

	for (int sequence2_index = 0; sequence2_index <= sequence2_size; sequence2_index++) {
		table[0][sequence2_index] = sequence2_index;
	}

	for (int sequence1_index = 1; sequence1_index <= sequence1_size; sequence1_index++) {
		for (int sequence2_index = 1; sequence2_index <= sequence2_size; sequence2_index++) {

			int indicator = (sequence1_[sequence1_index - 1] == sequence2_[sequence2_index - 1]) ? 0 : 1;

			table[sequence1_index][sequence2_index] = std::min(
				std::min(
					1 + table[sequence1_index - 1][sequence2_index],
					1 + table[sequence1_index][sequence2_index - 1]
				),
				indicator + table[sequence1_index - 1][sequence1_index - 1]
			);
		}
	}

	return table[sequence1_size][sequence2_size];

}