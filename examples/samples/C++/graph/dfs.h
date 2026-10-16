
#ifndef MEHARA_DFS_H_
#define MEHARA_DFS_H_

#include <exception>
#include <memory>
#include <stack>
#include <unordered_set>

#include "graph.h"

namespace mehara::graph {

enum class dfs_strategy { iterative, recursive };

template <class T>
void dfs(graph<T>& graph, std::shared_ptr<T> vertex,
         dfs_strategy dfs_strategy = dfs_strategy::iterative) {

    switch (dfs_strategy) {
    case dfs_strategy::iterative:
        iterative_dfs(graph, vertex);
        break;
    case dfs_strategy::recursive:
        recursive_dfs(graph, vertex);
        break;
    default:
        throw std::exception();
    }
}

template <class T>
void iterative_dfs(graph<T>& graph, std::shared_ptr<T> vertex) {

    std::unordered_set<std::shared_ptr<T>> visited;
    std::stack<std::shared_ptr<T>> frontier;

    frontier.push(vertex);

    while (!frontier.empty()) {
        vertex = frontier.top();
        frontier.pop();

        while (!visited.count(vertex)) {
            visited.insert(vertex);

            for (auto neighbor : graph.neighbors(vertex)) {
                frontier.push(neighbor);
            }
        }
    }
}

template <class T>
void recursive_dfs(graph<T>& graph, std::shared_ptr<T> vertex,
                   std::unordered_set<std::shared_ptr<T>>& visited =
                       std::unordered_set<std::shared_ptr<T>>()) {

    visited.insert(vertex);

    for (auto neighbor : graph.neighbors(vertex)) {
        if (!visited.count(neighbor)) {
            recursive_dfs(graph, neighbor, visited);
        }
    }
}

}

#endif
