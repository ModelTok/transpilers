#ifndef MEHARA_ITEM_H_
#define MEHARA_ITEM_H_

class Item {

	int value_;
	int weight_;

public:

	Item(int value, int weight) {
		value_ = value;
		weight_ = weight;
	}

	int Value() {
		return value_;
	}

	int Weight() {
		return weight_;
	}

};

#endif