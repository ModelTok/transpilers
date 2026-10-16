#ifndef MEHARA_ACTIVITY_H_
#define MEHARA_ACTIVITY_H_

class Activity {

	int start_time_;
	int finish_time_;

public:

	Activity(int start_time, int finish_time) {
		start_time_ = start_time;
		finish_time_ = finish_time;
	}

	int StartTime() {
		return start_time_;
	}

	int FinishTime() {
		return finish_time_;
	}

};

#endif