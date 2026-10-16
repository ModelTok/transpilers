#include <stdexcept>

using namespace std;

class MaxPriorityQueue {

	struct Node {
		int priority;
		Node *next;
		Node *previous;
	};

	Node *head_;
	Node *tail_;
	int size_;

public:

	MaxPriorityQueue() {
		tail_ = NULL;
		head_ = tail_;
		size_ = 0;
	}

	void Insert(int priority) {

		Node *current = new Node();
		current->priority = priority;

		if (size_ == 0) {
			tail_ = current;
			head_ = tail_;
		}
		else {
			tail_->next = current;
			current->previous = tail_;
			tail_ = current;
		}

		size_++;

	}

	int ExtractMaximum() {

		if (size_ == 0) {
			throw underflow_error("Max-Priority Queue is already empty.");
		}

		Node *current = head_;
		Node *maximum = current;
		while (current != NULL) {
			if (current->priority > maximum->priority) {
				maximum = current;
			}
			current = current->next;
		}

		if (maximum->previous != NULL) {
			maximum->previous->next = maximum->next;
		}
		else {
			head_ = maximum->next;
		}

		if (maximum->next != NULL) {
			maximum->next->previous = maximum->previous;
		}
		else {
			tail_ = maximum->previous;
		}

		int priority = maximum->priority;
		delete(maximum);
		size_;

		return priority;

	}

	int Maximum() {

		if (size_ == 0) {
			throw underflow_error("Max-Priority Queue is already empty.");
		}

		Node *current = head_;
		Node *maximum = current;
		while (current != NULL) {
			if (current->priority > maximum->priority) {
				maximum = current;
			}
			current = current->next;
		}

		return maximum->priority;

	}

	void IncreasePriority(int position, int priority) {

		if (size_ <= position) {
			throw out_of_range("Out of Range.");
		}

		Node *current = head_;
		int index = 0;
		while (index < position) {
			current = current->next;
			index++;
		}

		if (current->priority > priority) {
			throw invalid_argument("New priority cannot be less than existing priority.");
		}

		current->priority = priority;

	}

};