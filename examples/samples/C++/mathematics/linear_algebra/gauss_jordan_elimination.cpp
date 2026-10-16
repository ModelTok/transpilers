
#include "gauss_jordan_elimination.h"

#include <cmath>
#include <unordered_map>
#include <vector>

namespace mehara::mathematics::linalg {

const double epsilon = 1E-9;

bool is_solution(const std::vector<std::vector<double>>& augmented_matrix,
                 const std::vector<double>& solution)
{
    int m = augmented_matrix[0].size() - 1;
    for (const auto& row : augmented_matrix) {
        double sum = 0;
        for (int i = 0; i < m; i++) {
            sum += solution[i] * row[i];
        }
        if (abs(sum - row[m]) > epsilon) {
            return false;
        }
    }
    return true;
}

int gauss_jordan_elimination(std::vector<std::vector<double>> augmented_matrix,
                             std::vector<double>& solution)
{
    int n = augmented_matrix.size();
    int m = augmented_matrix[0].size() - 1;
    std::unordered_map<int, int> pivots;

    int row = 0;
    int col = 0;
    for (int row = 0, col = 0; col < m && row < n; col++) {
        auto pivot = row;
        for (int i = row + 1; i < n; i++) {
            if (abs(augmented_matrix[pivot][col]) < abs(augmented_matrix[i][col])) {
                pivot = i;
            }
        }
        if (abs(augmented_matrix[pivot][col]) < epsilon) {
            continue;
        }
        if (pivot != row) {
            swap(augmented_matrix[pivot], augmented_matrix[row]);
        }
        pivots[col] = row;
        for (int i = 0; i < n; i++) {
            if (row != i) {
                auto multiplier = augmented_matrix[i][col] / augmented_matrix[row][col];
                for (int j = 0; j <= m; j++) {
                    augmented_matrix[i][j] -= multiplier * augmented_matrix[row][j];
                }
            }
        }
        row++;
    }

    solution.assign(n, 0);
    for (int i = 0; i < m; i++) {
        const auto& it = pivots.find(i);
        if (it != pivots.end()) {
            solution[i] = augmented_matrix[it->second][m] / augmented_matrix[it->second][i];
        }
    }
    if (!is_solution(augmented_matrix, solution)) {
        return 0;
    }
    for (int i = 0; i < m; i++) {
        if (pivots.find(i) == pivots.end()) {
            return 2;
        }
    }
    return 1;
}

}
