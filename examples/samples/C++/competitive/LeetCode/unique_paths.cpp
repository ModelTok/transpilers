
#include <vector>

int unique_paths(int rows, int columns) {

    std::vector<std::vector<int>> _unique_paths(rows,
                                                std::vector<int>(columns, 0));

    _unique_paths[0][0] = 1;
    for (auto row_index = 1; row_index < rows; row_index++) {
        _unique_paths[row_index][0] = _unique_paths[row_index - 1][0];
    }
    for (auto column_index = 1; column_index < columns; column_index++) {
        _unique_paths[0][column_index] = _unique_paths[0][column_index - 1];
    }

    for (auto row_index = 1; row_index < rows; row_index++) {
        for (auto column_index = 1; column_index < columns; column_index++) {
            _unique_paths[row_index][column_index] =
                _unique_paths[row_index - 1][column_index] +
                _unique_paths[row_index][column_index - 1];
        }
    }

    return _unique_paths[rows - 1][columns - 1];
}