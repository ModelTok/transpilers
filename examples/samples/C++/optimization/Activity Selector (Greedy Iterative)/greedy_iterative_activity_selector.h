#ifndef MEHARA_GREEDY_ITERATIVE_ACTIVITY_SELECTOR_H_
#define MEHARA_GREEDY_ITERATIVE_ACTIVITY_SELECTOR_H_

#include <vector>

#include "activity.h"

class GreedyIterativeActivitySelector {

	std::vector<Activity> activities_;

public:

	GreedyIterativeActivitySelector(std::vector<Activity> activities) {
		activities_ = activities;
	}

	std::vector<Activity> select();

};

#endif