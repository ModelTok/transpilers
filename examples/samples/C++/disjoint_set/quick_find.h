
#ifndef MEHARA_QUICK_FIND_H_
#define MEHARA_QUICK_FIND_H_

#include <vector>

class QuickFind {

  public:
    QuickFind(int n);

    void Union(int p, int q);

    int Find(int p);

    bool Connected(int p, int q);

    int Count();

  private:
    int count_;
    std::vector<int> identifiers_;
};

#endif