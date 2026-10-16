
#ifndef MEHARA_TRANSITIVE_CLOSURE_H_
#define MEHARA_TRANSITIVE_CLOSURE_H_

#include <vector>

namespace mehara::graph {

std::vector<std::vector<bool>>
transitive_closure(const std::vector<std::vector<int>>& adjacency_list);

}

#endif