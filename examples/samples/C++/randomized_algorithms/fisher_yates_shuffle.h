
#ifndef MEHARA_FISHER_YATES_SHUFFLE_H_
#define MEHARA_FISHER_YATES_SHUFFLE_H_

#include <cstdlib>
#include <utility>
#include <vector>

namespace mehara::random {

template <typename T>
void fisher_yates_shuffle(std::vector<T>& sequence)
{
    for (auto target_index = sequence.size() - 1; target_index > 0;
         target_index--) {
        const auto& random_index = std::rand() % (target_index + 1);
        if (random_index != target_index) {
            std::swap(sequence[random_index], sequence[target_index]);
        }
    }
}

}

#endif
