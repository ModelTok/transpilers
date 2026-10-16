
#ifndef MEHARA_SHORTEST_PATH_H_
#define MEHARA_SHORTEST_PATH_H_

#include <vector>

namespace mehara::graph {

struct edge {
    int from;
    int to;
    int weight;
};

std::vector<std::vector<int>>
flyod_warshall_algorithm(int n, const std::vector<edge>& edges);

}

#endif
