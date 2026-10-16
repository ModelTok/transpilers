
#ifndef MEHARA_GRAPH_H_
#define MEHARA_GRAPH_H_

#include <memory>
#include <unordered_set>

namespace mehara::graph {

template <class T> class graph {
  public:
    virtual bool adjacent(std::shared_ptr<T> source_vertex,
                          std::shared_ptr<T> target_vertex) = 0;

    virtual std::unordered_set<std::shared_ptr<T>>
    neighbors(std::shared_ptr<T> vertex) = 0;

    virtual void add_vertex(std::shared_ptr<T> vertex) = 0;

    virtual void remove_vertex(std::shared_ptr<T> vertex) = 0;

    virtual void add_edge(std::shared_ptr<T> source_vertex,
                          std::shared_ptr<T> target_vertex) = 0;

    virtual void remove_edge(std::shared_ptr<T> source_vertex,
                             std::shared_ptr<T> target_vertex) = 0;

    virtual ~graph() {}
};

}

#endif
