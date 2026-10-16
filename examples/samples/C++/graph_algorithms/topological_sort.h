
#ifndef MEHARA_TOPOLOGICAL_SORT_H_
#define MEHARA_TOPOLOGICAL_SORT_H_

#include <deque>
#include <vector>

namespace mehara::graph {

std::deque<int>
dfs_topological_sort(const std::vector<std::vector<int>>& adjacency_list);

std::deque<int> kahns_algorithm_topological_sort(
    const std::vector<std::vector<int>>& adjacency_list);

}

#endif
