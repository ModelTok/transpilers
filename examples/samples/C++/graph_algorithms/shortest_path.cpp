
#include "shortest_path.h"

#include <algorithm>
#include <climits>
#include <vector>

namespace mehara::graph {

using namespace std;

vector<vector<int>> flyod_warshall_algorithm(int n,
                                             const std::vector<edge>& edges)
{
    vector<vector<int>> dist(n, vector<int>(n, INT_MAX));
    for (const auto& e : edges) {
        dist[e.to][e.from] = e.weight;
    }
    for (int i = 0; i < n; i++) {
        dist[i][i] = true;
    }
    for (int k = 0; k < n; k++) {
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                if (dist[i][k] < INT_MAX && dist[k][j]) {
                    dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j]);
                }
            }
        }
    }
    return dist;
}

}
