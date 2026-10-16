
#include "quick_find.h"

#include <vector>

QuickFind::QuickFind(int n) {
    count_ = n;
    for (int i = 0; i < n; i++) {
        identifiers_.push_back(i);
    }
}

void QuickFind::Union(int p, int q) {
    int identifier_p = identifiers_[p];
    int identifier_q = identifiers_[q];

    if (identifier_p == identifier_q)
        return;

    for (int i = 0; i < identifiers_.size(); i++) {
        if (identifiers_[i] == identifier_p) {
            identifiers_[i] = identifier_q;
        }
    }

    count_--;
}

int QuickFind::Find(int p) {
    return identifiers_[p];
}

bool QuickFind::Connected(int p, int q) {
    return identifiers_[p] == identifiers_[q];
}

int QuickFind::Count() {
    return count_;
}