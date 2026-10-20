// Copyright 2024 Aman Mehara
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

} // namespace mehara::graph
