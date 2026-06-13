from memory import Pointer
from sys import print

struct MatrixXf:
    var data: List[List[Float32]]
    def __init__(inout self, rows: Int, cols: Int):
        self.data = List[List[Float32]](capacity=rows)
        for i in range(rows):
            self.data.append(List[Float32](capacity=cols))
    def __lshift__(inout self, values: List[Float32]) -> Self:
        var idx = 0
        for r in range(self.data.size):
            for c in range(self.data[r].size):
                self.data[r][c] = values[idx]
                idx += 1
        return self
    def colwise(self) -> Colwise:
        return Colwise(self)

struct Colwise:
    var mat: MatrixXf
    def __init__(inout self, mat: MatrixXf):
        self.mat = mat
    def maxCoeff(self) -> List[Float32]:
        var result = List[Float32]()
        if self.mat.data.size == 0:
            return result
        let cols = self.mat.data[0].size
        for c in range(cols):
            var max_val = self.mat.data[0][c]
            for r in range(1, self.mat.data.size):
                if self.mat.data[r][c] > max_val:
                    max_val = self.mat.data[r][c]
            result.append(max_val)
        return result

def main():
    var mat = MatrixXf(2, 4)
    mat << [1, 2, 6, 9, 3, 1, 7, 2]
    print("Column's maximum:")
    print(mat.colwise().maxCoeff())