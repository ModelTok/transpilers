from linalg import random_matrix, random_vector, transpose, matmul, ldlt_factor, ldlt_solve
from tensor import Tensor

struct MatrixXf:
    var data: Tensor[Float32]
    var rows: Int
    var cols: Int

    @staticmethod
    def Random(rows: Int, cols: Int) -> Self:
        return Self{data: random_matrix[Float32](rows, cols), rows: rows, cols: cols}

    def transpose(self) -> Self:
        var t = transpose(self.data)
        return Self{data: t, rows: self.cols, cols: self.rows}

    def __mul__(self, other: Self) -> Self:
        var m = matmul(self.data, other.data)
        return Self{data: m, rows: self.rows, cols: other.cols}

    def __mul__(self, other: VectorXf) -> VectorXf:
        # When multiplying matrix by VectorXf, treat vector as column matrix
        var v_as_mat = other.data.reshape(self.cols, 1)
        var m = matmul(self.data, v_as_mat)
        var result_vec = m.flatten()
        return VectorXf{data: result_vec, size: self.rows}

    def ldlt(self) -> LDLTFact:
        var fact = ldlt_factor(self.data)
        return LDLTFact{factor: fact, mat: self.data}

struct VectorXf:
    var data: Tensor[Float32]
    var size: Int

    @staticmethod
    def Random(size: Int) -> Self:
        return Self{data: random_vector[Float32](size), size: size}

    def transpose(self) -> Self:
        # For vector, transpose is same data (row vector)
        return Self{data: self.data, size: self.size}

    def __mul__(self, other: MatrixXf) -> MatrixXf:
        # row vector * matrix
        var v_as_row = self.data.reshape(1, self.size)
        var m = matmul(v_as_row, other.data)
        return MatrixXf{data: m, rows: 1, cols: other.cols}

    def __mul__(self, other: VectorXf) -> MatrixXf:
        # outer product? not used here, but for completeness
        # Not needed for this snippet
        raise Error("unimplemented")

struct LDLTFact:
    var factor: LDltFactor[Float32]  # type from linalg
    var mat: Tensor[Float32]  # not used but keep for potential info

    def solve(self, b: VectorXf) -> VectorXf:
        var result = ldlt_solve(self.factor, b.data)
        return VectorXf{data: result, size: result.shape[0]}

def main() raises:
    var A = MatrixXf.Random(3, 2)
    var b = VectorXf.Random(3)
    var AtA = A.transpose() * A
    var Atb = A.transpose() * b
    var solution = AtA.ldlt().solve(Atb)
    print("The solution using normal equations is:\n", solution.data)