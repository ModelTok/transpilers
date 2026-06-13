# Eigen equivalent in Mojo
# MatrixXf: simple 2D matrix of Float32
struct MatrixXf:
    var _data: List[List[Float32]]
    var _rows: Int
    var _cols: Int

    def __init__(inout self, rows: Int, cols: Int):
        self._rows = rows
        self._cols = cols
        self._data = List[List[Float32]]()
        for i in range(rows):
            self._data.append(List[Float32]())
            for j in range(cols):
                self._data[i].append(0.0)

    def __setitem__(inout self, i: Int, j: Int, val: Float32):
        self._data[i][j] = val

    def __getitem__(self, i: Int, j: Int) -> Float32:
        return self._data[i][j]

    # Find max coefficient and its indices
    def maxCoeff(inout self, inout maxRow: Int, inout maxCol: Int) -> Float32:
        var max_val: Float32 = -1e38
        for i in range(self._rows):
            for j in range(self._cols):
                if self._data[i][j] > max_val:
                    max_val = self._data[i][j]
                    maxRow = i
                    maxCol = j
        return max_val

    # Find min coefficient and its indices
    def minCoeff(inout self, inout minRow: Int, inout minCol: Int) -> Float32:
        var min_val: Float32 = 1e38
        for i in range(self._rows):
            for j in range(self._cols):
                if self._data[i][j] < min_val:
                    min_val = self._data[i][j]
                    minRow = i
                    minCol = j
        return min_val

# Alias for Index (integer)
alias Index = Int

def main():
    var m = MatrixXf(2,2)
    m[0,0] = 1
    m[0,1] = 2
    m[1,0] = 3
    m[1,1] = 4

    var maxRow: Index = 0
    var maxCol: Index = 0
    var max: Float32 = m.maxCoeff(maxRow, maxCol)

    var minRow: Index = 0
    var minCol: Index = 0
    var min: Float32 = m.minCoeff(minRow, minCol)

    print("Max:", max, ", at:", maxRow, ",", maxCol)
    print("Min:", min, ", at:", minRow, ",", minCol)