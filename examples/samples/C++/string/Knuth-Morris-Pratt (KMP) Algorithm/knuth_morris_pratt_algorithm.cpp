#include "knuth_morris_pratt_algorithm.h"

#include <string>
#include <vector>

KMPAlgorithm::KMPAlgorithm(std::string pattern) {

	pattern_ = pattern;
	dfa_ = std::vector<std::vector<int>>(256, std::vector<int>(pattern_.size(), 0));

	dfa_[pattern_[0]][0] = 1;

	for (int state_x = 0, pattern_index = 1; pattern_index < pattern_.size(); pattern_index++) {

		for (int radix_index = 0; radix_index < dfa_.size(); radix_index++) {
			dfa_[radix_index][pattern_index] = dfa_[radix_index][state_x];
		}

		dfa_[pattern_[pattern_index]][pattern_index] = pattern_index + 1;
		state_x = dfa_[pattern_[pattern_index]][state_x];

	}

}

int KMPAlgorithm::Search(std::string text) {

	int pattern_index, text_index;

	for (pattern_index = 0, text_index = 0; pattern_index < pattern_.size() && text_index < text.size(); text_index++) {
		pattern_index = dfa_[text[text_index]][pattern_index];
	}

	if (pattern_index == pattern_.size()) {
		return text_index - pattern_index;
	}

	return text.size();

}