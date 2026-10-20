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

} // namespace mehara::graph
