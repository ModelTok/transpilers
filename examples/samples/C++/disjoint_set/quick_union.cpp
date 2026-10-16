
#include "quick_union.h"

#include <vector>

QuickUnion::QuickUnion(int n) {
    count_ = n;
    for (int i = 0; i < n; i++) {
        parents_.push_back(i);
    }
}

void QuickUnion::Union(int p, int q) {
    int parent_p = Find(p);
    int parent_q = Find(q);

    if (parent_p == parent_q)
        return;

    parents_[parent_p] = parent_q;

    count_--;
}

int QuickUnion::Find(int p) {
    if (parents_[p] != p) {
        return Find(parents_[p]);
    }
    return parents_[p];
}

bool QuickUnion::Connected(int p, int q) {
    return Find(p) == Find(q);
}

int QuickUnion::Count() {
    return count_;
}