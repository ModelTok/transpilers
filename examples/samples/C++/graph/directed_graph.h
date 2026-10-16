
#ifndef MEHARA_DIRECTED_GRAPH_H_
#define MEHARA_DIRECTED_GRAPH_H_

#include <memory>
#include <unordered_map>
#include <unordered_set>

#include "graph.h"

namespace mehara::graph {

template <class T> class directed_graph : public graph<T> {
  public:
    bool adjacent(std::shared_ptr<T> source_vertex,
                  std::shared_ptr<T> target_vertex) override;

    std::unordered_set<std::shared_ptr<T>>
    neighbors(std::shared_ptr<T> vertex) override;

    void add_vertex(std::shared_ptr<T> vertex) override;

    void remove_vertex(std::shared_ptr<T> vertex) override;

    void add_edge(std::shared_ptr<T> source_vertex,
                  std::shared_ptr<T> target_vertex) override;

    void remove_edge(std::shared_ptr<T> source_vertex,
                     std::shared_ptr<T> target_vertex) override;

  private:
    std::unordered_map<std::shared_ptr<T>,
                       std::unordered_set<std::shared_ptr<T>>>
        adjacency_list_;
};

template <class T>
bool directed_graph<T>::adjacent(std::shared_ptr<T> source_vertex,
                                 std::shared_ptr<T> target_vertex) {
    return adjacency_list_.count(source_vertex) &&
           adjacency_list_.find(source_vertex)->second.count(target_vertex);
}

template <class T>
std::unordered_set<std::shared_ptr<T>>
directed_graph<T>::neighbors(std::shared_ptr<T> vertex) {
    if (adjacency_list_.count(vertex)) {
        return adjacency_list_.find(vertex)->second;
    } else {
        throw std::invalid_argument("Vertex not found in the Graph.");
    }
}

template <class T>
void directed_graph<T>::add_vertex(std::shared_ptr<T> vertex) {
    adjacency_list_.insert(
        std::make_pair<>(vertex, std::unordered_set<std::shared_ptr<T>>()));
}

template <class T>
void directed_graph<T>::remove_vertex(std::shared_ptr<T> vertex) {
    if (adjacency_list_.count(vertex)) {
        adjacency_list_.erase(vertex);
        for (auto entry : adjacency_list_) {
            entry.second.erase(vertex);
        }
    }
}

template <class T>
void directed_graph<T>::add_edge(std::shared_ptr<T> source_vertex,
                                 std::shared_ptr<T> target_vertex) {
    if (adjacency_list_.count(source_vertex) &&
        adjacency_list_.count(target_vertex)) {
        adjacency_list_.find(source_vertex)->second.insert(target_vertex);
    } else {
        throw std::invalid_argument("Vertex not found in the Graph.");
    }
}

template <class T>
void directed_graph<T>::remove_edge(std::shared_ptr<T> source_vertex,
                                    std::shared_ptr<T> target_vertex) {
    if (adjacency_list_.count(source_vertex)) {
        adjacency_list_.find(source_vertex)->second.erase(target_vertex);
    }
}

}

#endif
