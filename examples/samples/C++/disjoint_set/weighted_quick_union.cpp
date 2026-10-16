
#include "weighted_quick_union.h"

#include <vector>

WeightedQuickUnion::WeightedQuickUnion(int n) {
    count_ = n;
    for (int i = 0; i < n; i++) {
        parents_.push_back(i);
        size_.push_back(1);
    }
}

void WeightedQuickUnion::Union(int p, int q) {
    int parent_p = Find(p);
    int parent_q = Find(q);

    if (parent_p == parent_q)
        return;

    if (size_[parents_[p]] < size_[parents_[q]]) {
        parents_[parent_p] = parent_q;
        size_[parent_q] += size_[parent_p];
    } else {
        parents_[parent_q] = parent_p;
        size_[parent_p] += size_[parent_q];
    }

    count_--;
}

int WeightedQuickUnion::Find(int p) {
    if (parents_[p] != p) {
        return Find(parents_[p]);
    }
    return parents_[p];
}

bool WeightedQuickUnion::Connected(int p, int q) {
    return Find(p) == Find(q);
}

int WeightedQuickUnion::Count() {
    return count_;
}