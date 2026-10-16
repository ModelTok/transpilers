#include "hamming_distance.h"

#include <stdexcept>
#include <vector>

int HammingDistance::Distance() {

	if (sequence1_.size() != sequence2_.size()) {
		throw std::invalid_argument("Sequences are of different size.");
	}

	int sequence_size = static_cast<int>(sequence1_.size());

	int distance = 0;
	for (int sequence_index = 0; sequence_index < sequence_size; sequence_index++) {
		if (sequence1_[sequence_index] != sequence2_[sequence_index]) {
			distance = distance + 1;
		}
	}

	return distance;
}