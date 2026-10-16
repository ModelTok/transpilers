
#include "determinant.h"

#include <cmath>
#include <iostream>
#include <vector>

namespace mehara::mathematics::linalg {

double compute_determinant(std::vector<std::vector<double>> matrix)
{
    const double epsilon = 1E-9;
    int dimensions = matrix.size();
    double determinant = 1;
    for (int i = 0; i < dimensions; i++) {
        int row = i;
        for (int j = i + 1; j < dimensions; j++) {
            if (abs(matrix[row][i]) < abs(matrix[j][i])) {
                row = j;
            }
        }
        if (row != i) {
            swap(matrix[row], matrix[i]);
            determinant *= -1;
        }
        if (abs(matrix[i][i]) < epsilon) {
            return 0;
        }
        determinant *= matrix[i][i];
        for (int j = i + 1; j < dimensions; j++) {
            auto multiplier = matrix[j][i] / matrix[i][i];
            if (abs(matrix[j][i]) > epsilon) {
                for (int k = i; k < dimensions; k++) {
                    matrix[j][k] -= multiplier * matrix[i][k];
                }
            }
        }
    }
    return determinant;
}

}
