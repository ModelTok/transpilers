
#ifndef MEHARA_QUICK_UNION_H_
#define MEHARA_QUICK_UNION_H_

#include <vector>

class QuickUnion {

  public:
    QuickUnion(int n);

    void Union(int p, int q);

    int Find(int p);

    bool Connected(int p, int q);

    int Count();

  private:
    int count_;
    std::vector<int> parents_;
};

#endif