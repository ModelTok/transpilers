
#include "transitive_closure.h"

#include <vector>

namespace mehara::graph {

using namespace std;

vector<vector<bool>>
transitive_closure(const vector<vector<int>>& adjacency_list)
{
    int n = adjacency_list.size();
    vector<vector<bool>> tc(n, vector<bool>(n, false));
    for (int i = 0; i < n; i++) {
        for (const auto& neighbour : adjacency_list[i]) {
            tc[i][neighbour] = true;
        }
    }
    for (int i = 0; i < n; i++) {
        tc[i][i] = true;
    }
    for (int k = 0; k < n; k++) {
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                tc[i][j] = tc[i][j] || (tc[i][k] && tc[k][j]);
            }
        }
    }
    return tc;
}

}
