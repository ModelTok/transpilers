from memory import memset_zero
from sys import print
from math import sqrt

struct MatrixXf:
    var data: Pointer[Float32]
    var rows: Int
    var cols: Int

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = Pointer[Float32].alloc(rows * cols)
        memset_zero(self.data, rows * cols)

    def __del__(owned self):
        self.data.free()

    def __getitem__(self, row: Int, col: Int) -> Float32:
        return self.data[row * self.cols + col]

    def __setitem__(inout self, row: Int, col: Int, val: Float32):
        self.data[row * self.cols + col] = val

    def col(self, j: Int) -> VectorXf:
        var result = VectorXf(self.rows)
        for i in range(self.rows):
            result[i] = self[i, j]
        return result

    def colwise(inout self) -> ColwiseReturn:
        return ColwiseReturn(self)

    def print_matrix(self):
        for i in range(self.rows):
            for j in range(self.cols):
                print(self[i, j], end=" ")
            print()

struct VectorXf:
    var data: Pointer[Float32]
    var size: Int

    def __init__(inout self, size: Int):
        self.size = size
        self.data = Pointer[Float32].alloc(size)
        memset_zero(self.data, size)

    def __del__(owned self):
        self.data.free()

    def __getitem__(self, i: Int) -> Float32:
        return self.data[i]

    def __setitem__(inout self, i: Int, val: Float32):
        self.data[i] = val

    def __sub__(self, other: VectorXf) -> VectorXf:
        var result = VectorXf(self.size)
        for i in range(self.size):
            result[i] = self[i] - other[i]
        return result

    def squaredNorm(self) -> Float32:
        var s: Float32 = 0.0
        for i in range(self.size):
            s += self[i] * self[i]
        return s

    def print_vector(self):
        for i in range(self.size):
            print(self[i])

struct ColwiseReturn:
    var mat: MatrixXf

    def __init__(inout self, mat: MatrixXf):
        self.mat = mat

    def __sub__(self, v: VectorXf) -> ColwiseSubReturn:
        return ColwiseSubReturn(self.mat, v)

struct ColwiseSubReturn:
    var mat: MatrixXf
    var v: VectorXf

    def __init__(inout self, mat: MatrixXf, v: VectorXf):
        self.mat = mat
        self.v = v

    def colwise(self) -> ColwiseSquaredNormReturn:
        return ColwiseSquaredNormReturn(self.mat, self.v)

struct ColwiseSquaredNormReturn:
    var mat: MatrixXf
    var v: VectorXf

    def __init__(inout self, mat: MatrixXf, v: VectorXf):
        self.mat = mat
        self.v = v

    def squaredNorm(self) -> VectorXf:
        var result = VectorXf(self.mat.cols)
        for j in range(self.mat.cols):
            var col_vec = self.mat.col(j)
            var diff = col_vec - self.v
            result[j] = diff.squaredNorm()
        return result

    def minCoeff(self, index: Pointer[Int]) -> Float32:
        var min_val: Float32 = 1e30
        for j in range(self.mat.cols):
            var col_vec = self.mat.col(j)
            var diff = col_vec - self.v
            var norm = diff.squaredNorm()
            if norm < min_val:
                min_val = norm
                index[0] = j
        return min_val

def main():
    var m = MatrixXf(2, 4)
    var v = VectorXf(2)
    m[0, 0] = 1.0
    m[0, 1] = 23.0
    m[0, 2] = 6.0
    m[0, 3] = 9.0
    m[1, 0] = 3.0
    m[1, 1] = 11.0
    m[1, 2] = 7.0
    m[1, 3] = 2.0
    v[0] = 2.0
    v[1] = 3.0
    var index = Int(0)
    var index_ptr = Pointer[Int].address_of(index)
    (m.colwise() - v).colwise().squaredNorm().minCoeff(index_ptr)
    print("Nearest neighbour is column ", index, ":")
    var col_vec = m.col(index)
    col_vec.print_vector()