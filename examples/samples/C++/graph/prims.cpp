
#include <bits/stdc++.h>
using namespace std;
typedef pair<int, int> pair_int;

#define inf INT_MAX
const int V = 4;
vector<pair<int, int>> graph[V];

void addEdge(int source, int target, int weight)
{
    graph[source].push_back(make_pair(target, weight));
    graph[target].push_back(make_pair(source, weight));
}
void prims()
{
    priority_queue<pair<int, int>, vector<pair<int, int>>,
                   greater<pair<int, int>>>
        pq;
    int source = 0;
    vector<int> distance(V, inf);
    distance[0] = 0;
    vector<int> parent(V, -1);
    parent[0] = 0;
    vector<bool> visited(V, false);
    pq.push(make_pair(0, source));

    while (!pq.empty()) {
        int source = pq.top().second;
        pq.pop();
        visited[source] = true;
        for (auto neighbour : graph[source]) {
            int v = neighbour.first;
            int current_dist = neighbour.second;
            if (visited[v] != true && distance[v] > current_dist) {
                pq.push(make_pair(distance[v], v));
                distance[v] = current_dist;
                parent[v] = source;
            }
        }
    }
    for (int i = 0; i < V; ++i) {
        cout << parent[i] << " " << i << endl;
    }
}

int main()
{
    addEdge(0, 1, 1);
    addEdge(0, 2, 4);
    addEdge(0, 3, 3);
    addEdge(1, 3, 2);
    addEdge(2, 3, 5);
    prims();
    return 0;
}

