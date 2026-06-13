from stdlib import print
from memory import DTypePointer
from tensor import Tensor
from vector import DynamicVector

struct MatrixXf:
    var rows: Int
    var cols: Int
    var data: DynamicVector[Float32]

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = DynamicVector[Float32](size=rows*cols)

    def __rshift__(inout self, values: List[Float32]):   # Mimics Eigen << comma initializer
        var idx: Int = 0
        for i in range(self.rows):
            for j in range(self.cols):
                self.data[i * self.cols + j] = values[idx]
                idx += 1

    def data(inout self) -> DTypePointer[Float32]:
        return self.data.data()

    def __str__(self) -> String:
        var s = ""
        for i in range(self.rows):
            for j in range(self.cols):
                s += str(self.data[i * self.cols + j])
                if j < self.cols - 1:
                    s += " "
            if i < self.rows - 1:
                s += "\n"
        return s

struct Map[Type: AnyType]:
    var row_map: Int
    var col_map: Int
    var mat: Type
    var data_ptr: DTypePointer[Float32]

    def __init__(inout self, data_ptr: DTypePointer[Float32], rows: Int, cols: Int):
        self.data_ptr = data_ptr
        self.row_map = rows
        self.col_map = cols

    def __str__(self) -> String:
        var s = ""
        for i in range(self.row_map):
            for j in range(self.col_map):
                s += str(self.data_ptr.load(i * self.col_map + j))
                if j < self.col_map - 1:
                    s += " "
            if i < self.row_map - 1:
                s += "\n"
        return s

def main():
    var M1 = MatrixXf(2,6)  # Column-major storage
    M1 >> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  # Mimics M1 << ...
    var M2 = Map[MatrixXf](M1.data(), 6, 2)
    print("M2:")
    print(M2)