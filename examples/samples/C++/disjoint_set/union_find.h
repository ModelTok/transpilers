
#ifndef MEHARA_UNION_FIND_H_
#define MEHARA_UNION_FIND_H_

#include <vector>

class UnionFind {

  public:
    UnionFind(int n);

    void Union(int p, int q);

    int Find(int p);

    bool Connected(int p, int q);

    int Count();

  private:
    int count_;
    std::vector<int> parents_;
    std::vector<int> rank_;
};

#endif