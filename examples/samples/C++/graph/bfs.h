
#ifndef MEHARA_BFS_H_
#define MEHARA_BFS_H_

#include <exception>
#include <memory>
#include <queue>
#include <unordered_set>

#include "graph.h"

namespace mehara::graph {

template <class T> void bfs(graph<T>& graph, std::shared_ptr<T> vertex) {

    std::unordered_set<std::shared_ptr<T>> visited;
    std::queue<std::shared_ptr<T>> frontier;

    visited.insert(vertex);
    frontier.push(vertex);

    while (!frontier.empty()) {
        vertex = frontier.top();
        frontier.pop();

        for (auto neighbor : graph.neighbors(vertex)) {
            while (!visited.count(vertex)) {
                visited.insert(vertex);
                frontier.push(neighbor);
            }
        }
    }
}

}

#endif
