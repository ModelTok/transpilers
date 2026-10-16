
#ifndef MEHARA_GAUSS_JORDAN_ELIMINATION_H_
#define MEHARA_GAUSS_JORDAN_ELIMINATION_H_

#include <vector>

namespace mehara::mathematics::linalg {

int gauss_jordan_elimination(std::vector<std::vector<double>> augmented_matrix,
                             std::vector<double>& solution);

}

#endif
