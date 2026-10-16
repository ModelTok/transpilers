#ifndef MEHARA_KNUTH_MORRIS_PRATT_ALGORITHM_H_
#define MEHARA_KNUTH_MORRIS_PRATT_ALGORITHM_H_

#include <string>
#include <vector>

class KMPAlgorithm {

	std::string pattern_;
	std::vector<std::vector<int>> dfa_;

public:
	KMPAlgorithm(std::string pattern);

	int Search(std::string text);

};

#endif