
#include "union_find.h"

#include <vector>

UnionFind::UnionFind(int n) {
    count_ = n;
    for (int i = 0; i < n; i++) {
        parents_.push_back(i);
        rank_.push_back(0);
    }
}

void UnionFind::Union(int p, int q) {
    int parent_p = Find(p);
    int parent_q = Find(q);

    if (parent_p == parent_q)
        return;

    if (rank_[parents_[p]] < rank_[parents_[q]]) {
        parents_[parent_p] = parent_q;
    } else if (rank_[parents_[p]] > rank_[parents_[q]]) {
        parents_[parent_q] = parent_p;
    } else {
        parents_[parent_q] = parent_p;
        rank_[parent_p]++;
    }

    count_--;
}

int UnionFind::Find(int p) {
    if (parents_[p] != p) {
        parents_[p] = Find(parents_[p]);
    }
    return parents_[p];
}

bool UnionFind::Connected(int p, int q) {
    return Find(p) == Find(q);
}

int UnionFind::Count() {
    return count_;
}