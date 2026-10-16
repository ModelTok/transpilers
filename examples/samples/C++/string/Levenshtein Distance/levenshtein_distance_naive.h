#ifndef MEHARA_LEVENSHTEIN_DISTANCE_NAIVE_H_
#define MEHARA_LEVENSHTEIN_DISTANCE_NAIVE_H_

#include <vector>

class LevenshteinDistance {

	std::vector<char> sequence1_;
	std::vector<char> sequence2_;

	int Distance(int sequence1_index, int sequence2_index);

public:

	LevenshteinDistance(std::vector<char>& sequence1, std::vector<char>& sequence2) {
		sequence1_ = sequence1;
		sequence2_ = sequence2;
	}

	int Distance();

};

#endif