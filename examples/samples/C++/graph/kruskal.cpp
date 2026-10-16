
#include <bits/stdc++.h>
#define INF INT_MAX
using namespace std;

int number_of_nodes, number_of_edges;
int parent[1000];
struct Edge {
    int source, target, weight;
};

bool compare(Edge u, Edge v) { return u.weight < v.weight; }
int find(int p)
{
    if (parent[p] == p) {
        return p;
    }
    return find(parent[p]);
}

void kruskal(vector<Edge> edges)
{
    sort(edges.begin(), edges.end(), compare);
    iota(parent, parent + number_of_nodes, 0);
    vector<Edge> MST;

    for (int i = 0; i < number_of_edges; i++) {
        Edge edge = edges[i];
        int u = find(edge.source);
        int v = find(edge.target);
        if (u != v) {
            MST.push_back(edge);
            parent[u] = v;
        }
    }
    for (int i = 0; i < MST.size(); ++i) {
        cout << MST[i].source << " " << MST[i].target << "\n";
    }
}
int main()
{
    number_of_nodes = 4;
    number_of_edges = 5;

    vector<Edge> edges;

    Edge edge1, edge2, edge3, edge4, edge5;

    edge1.source = 0;
    edge1.target = 1;
    edge1.weight = 1;
    edge2.source = 0;
    edge2.target = 2;
    edge2.weight = 4;
    edge3.source = 0;
    edge3.target = 3;
    edge3.weight = 3;
    edge4.source = 2;
    edge4.target = 3;
    edge4.weight = 5;
    edge5.source = 1;
    edge5.target = 3;
    edge5.weight = 2;
    edges.push_back(edge1);
    edges.push_back(edge2);
    edges.push_back(edge3);
    edges.push_back(edge4);
    edges.push_back(edge5);
    kruskal(edges);
    return 0;
}

