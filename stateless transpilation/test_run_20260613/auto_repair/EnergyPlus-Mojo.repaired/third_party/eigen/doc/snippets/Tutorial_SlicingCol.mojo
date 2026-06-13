from memory.unsafe import DTypePointer
from random import rand
from sys import info as sys_info

# Include Eigen-like functionality via Mojo's SIMD and matrix modules
# NOTE: This is a 1:1 translation, using Mojo's built-in types where possible

# Define a simple Matrix class to approximate Eigen::MatrixXf behavior
struct MatrixXf:
    var data: DTypePointer[DType.float32]
    var rows: Int
    var cols: Int

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = DTypePointer[DType.float32].alloc(rows * cols)

    def __init__(inout self, other: MatrixXf):
        self.rows = other.rows
        self.cols = other.cols
        self.data = DTypePointer[DType.float32].alloc(self.rows * self.cols)
        for i in range(self.rows * self.cols):
            self.data.store(i, other.data.load(i))

    def __del__(owned self):
        self.data.free()

    @staticmethod
    def Random(rows: Int, cols: Int) -> MatrixXf:
        var mat = MatrixXf(rows, cols)
        for i in range(rows * cols):
            mat.data.store(i, (rand[DType.float32]() * 2.0 - 1.0))
        return mat

    def data(self) -> DTypePointer[DType.float32]:
        return self.data

    def rows(self) -> Int:
        return self.rows

    def cols(self) -> Int:
        return self.cols

    def outerStride(self) -> Int:
        # Column-major by default (stride = rows)
        return self.rows

# Row-major version
struct RowMajorMatrixXf:
    var data: DTypePointer[DType.float32]
    var rows: Int
    var cols: Int

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = DTypePointer[DType.float32].alloc(rows * cols)

    def __init__(inout self, other: MatrixXf):
        self.rows = other.rows
        self.cols = other.cols
        self.data = DTypePointer[DType.float32].alloc(self.rows * self.cols)
        # Convert from column-major to row-major
        for i in range(self.rows):
            for j in range(self.cols):
                self.data.store(i * self.cols + j, other.data.load(j * other.rows + i))

    def __del__(owned self):
        self.data.free()

    def data(self) -> DTypePointer[DType.float32]:
        return self.data

    def rows(self) -> Int:
        return self.rows

    def cols(self) -> Int:
        return self.cols

    def outerStride(self) -> Int:
        # Row-major (stride = cols)
        return self.cols

# Map struct (simplified, just stores pointer and dimensions)
struct Map[T: AnyType]:
    var data: DTypePointer[DType.float32]
    var rows: Int
    var cols: Int
    var outerStride: Int

    def __init__(inout self, data_ptr: DTypePointer[DType.float32], rows: Int, cols: Int, stride: Int):
        self.data = data_ptr
        self.rows = rows
        self.cols = cols
        self.outerStride = stride

# OuterStride struct (placeholder for the OuterStride<> type)
struct OuterStride:
    var stride: Int
    def __init__(inout self, s: Int):
        self.stride = s

# Stride struct for Map
struct Stride[T: AnyType]:
    var innerStride: Int
    var outerStride: Int

# Helper to simulate cout
def print(msg: String):
    print(msg, end="")

def print_mat(mat: MatrixXf):
    for i in range(mat.rows):
        for j in range(mat.cols):
            print(mat.data.load(j * mat.rows + i), end=" ")
        print()

def print_mat_row_major(mat: RowMajorMatrixXf):
    for i in range(mat.rows):
        for j in range(mat.cols):
            print(mat.data.load(i * mat.cols + j), end=" ")
        print()

def print_map_map(mat: Map[MatrixXf]):
    for i in range(mat.rows):
        for j in range(mat.cols):
            var idx = j * mat.outerStride + i
            print(mat.data.load(idx), end=" ")
        print()

def main() raises:
    var M1 = MatrixXf.Random(3,8)
    print("Column major input:")
    print_mat(M1)
    print()
    var M2 = Map[MatrixXf](M1.data(), M1.rows(), (M1.cols() + 2) // 3, OuterStride(M1.outerStride() * 3))
    print("1 column over 3:")
    print_map_map(M2)
    print()
    var M3 = RowMajorMatrixXf(M1)
    print("Row major input:")
    print_mat_row_major(M3)
    print()
    var M4 = Map[RowMajorMatrixXf](M3.data(), M3.rows(), (M3.cols() + 2) // 3,
                                    Stride[DType](M3.outerStride(), 3))
    print("1 column over 3:")
    print_map_map(M4)
    print()