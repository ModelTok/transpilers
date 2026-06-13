from memory import ptr
from sys import print

struct MatrixXd:
    var rows_: Int
    var cols_: Int
    var data: Pointer[Float64]

    def __init__(inout self, rows: Int, cols: Int):
        self.rows_ = rows
        self.cols_ = cols
        self.data = Pointer[Float64].alloc(rows * cols)

    def __del__(owned self):
        self.data.free()

    def rows(self) -> Int:
        return self.rows_

    def cols(self) -> Int:
        return self.cols_

    def size(self) -> Int:
        return self.rows_ * self.cols_

    def resize(inout self, new_rows: Int, new_cols: Int):
        self.data.free()
        self.rows_ = new_rows
        self.cols_ = new_cols
        self.data = Pointer[Float64].alloc(new_rows * new_cols)

struct VectorXd:
    var size_: Int
    var data: Pointer[Float64]

    def __init__(inout self, size: Int):
        self.size_ = size
        self.data = Pointer[Float64].alloc(size)

    def __del__(owned self):
        self.data.free()

    def size(self) -> Int:
        return self.size_

    def rows(self) -> Int:
        return self.size_

    def cols(self) -> Int:
        return 1

    def resize(inout self, new_size: Int):
        self.data.free()
        self.size_ = new_size
        self.data = Pointer[Float64].alloc(new_size)

def main():
    var m = MatrixXd(2, 5)
    m.resize(4, 3)
    print("The matrix m is of size ", end="")
    print(m.rows(), "x", m.cols())
    print("It has ", m.size(), " coefficients")
    var v = VectorXd(2)
    v.resize(5)
    print("The vector v is of size ", v.size())
    print("As a matrix, v is of size ", end="")
    print(v.rows(), "x", v.cols())