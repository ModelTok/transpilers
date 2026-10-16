#include <vector>

using namespace std;

class MergeSort {

	void merge(vector<int> &a, vector<int> &auxiliary, int begin, int middle, int end) {

		int i = begin;
		int j = middle + 1;

		for (int k = begin; k <= end; k++) {
			if (i <= middle && (j > end || a[i] <= a[j])) {
				auxiliary[k] = a[i++];
			}
			else {
				auxiliary[k] = a[j++];
			}
		}

	}

	void sort(vector<int> &a, vector<int> &auxiliary, int begin, int end) {

		if (end <= begin) {
			return;
		}

		int middle = begin + (end - begin) / 2;
		sort(auxiliary, a, begin, middle);
		sort(auxiliary, a, middle + 1, end);
		merge(auxiliary, a, begin, middle, end);

	}

public:

	void sort(vector<int> &a) {
		vector<int> auxiliary(a);
		sort(a, auxiliary, 0, a.size() - 1);
	}

};