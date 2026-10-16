#ifndef MEHARA_HAMMING_DISTANCE_H_
#define MEHARA_HAMMING_DISTANCE_H_

#include <vector>

class HammingDistance {

	std::vector<char> sequence1_;
	std::vector<char> sequence2_;

public:

	HammingDistance(std::vector<char>& sequence1, std::vector<char>& sequence2) {
		sequence1_ = sequence1;
		sequence2_ = sequence2;
	}

	int Distance();

};

#endif