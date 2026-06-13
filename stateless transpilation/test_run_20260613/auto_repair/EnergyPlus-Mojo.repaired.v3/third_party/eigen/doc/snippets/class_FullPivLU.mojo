from memory import memset_zero
from math import random
from tensor import Tensor, TensorShape
from sys import print

alias Matrix5x3 = Tensor[DType.float64, 5, 3]
alias Matrix5x5 = Tensor[DType.float64, 5, 5]

def main() raises:
    var m = Matrix5x3()
    for i in range(5):
        for j in range(3):
            m[i, j] = random[DType.float64]() * 2.0 - 1.0
    print("Here is the matrix m:")
    print(m)
    var lu = FullPivLU[Matrix5x3](m)
    print("Here is, up to permutations, its LU decomposition matrix:")
    print(lu.matrixLU())
    print("Here is the L part:")
    var l = Matrix5x5()
    memset_zero(l.data, l.size)
    for i in range(5):
        l[i, i] = 1.0
    for i in range(5):
        for j in range(3):
            if i > j:
                l[i, j] = lu.matrixLU()[i, j]
    print(l)
    print("Here is the U part:")
    var u = Matrix5x3()
    for i in range(5):
        for j in range(3):
            if i <= j:
                u[i, j] = lu.matrixLU()[i, j]
            else:
                u[i, j] = 0.0
    print(u)
    print("Let us now reconstruct the original matrix m:")
    var reconstructed = Matrix5x3()
    var p_inv = lu.permutationP().inverse()
    var q_inv = lu.permutationQ().inverse()
    # Compute p_inv * l * u * q_inv
    var temp1 = Matrix5x5()
    for i in range(5):
        for j in range(5):
            temp1[i, j] = 0.0
            for k in range(5):
                temp1[i, j] += p_inv[i, k] * l[k, j]
    var temp2 = Matrix5x3()
    for i in range(5):
        for j in range(3):
            temp2[i, j] = 0.0
            for k in range(5):
                temp2[i, j] += temp1[i, k] * u[k, j]
    for i in range(5):
        for j in range(3):
            reconstructed[i, j] = 0.0
            for k in range(5):
                reconstructed[i, j] += temp2[i, k] * q_inv[k, j]
    print(reconstructed)

struct FullPivLU[MatrixType: TensorShape]:
    var m_lu: MatrixType
    var m_p: Tensor[DType.int64, _]
    var m_q: Tensor[DType.int64, _]
    var m_rows: Int
    var m_cols: Int

    def __init__(inout self, matrix: MatrixType):
        self.m_rows = matrix.shape[0]
        self.m_cols = matrix.shape[1]
        self.m_lu = matrix
        self.m_p = Tensor[DType.int64, self.m_rows]()
        self.m_q = Tensor[DType.int64, self.m_cols]()
        for i in range(self.m_rows):
            self.m_p[i] = i
        for i in range(self.m_cols):
            self.m_q[i] = i
        var min_dim = min(self.m_rows, self.m_cols)
        for k in range(min_dim):
            var max_row = k
            var max_col = k
            var max_val = abs(self.m_lu[k, k])
            for i in range(k, self.m_rows):
                for j in range(k, self.m_cols):
                    if abs(self.m_lu[i, j]) > max_val:
                        max_val = abs(self.m_lu[i, j])
                        max_row = i
                        max_col = j
            if max_val == 0.0:
                continue
            if max_row != k:
                for j in range(self.m_cols):
                    var tmp = self.m_lu[k, j]
                    self.m_lu[k, j] = self.m_lu[max_row, j]
                    self.m_lu[max_row, j] = tmp
                var tmp_p = self.m_p[k]
                self.m_p[k] = self.m_p[max_row]
                self.m_p[max_row] = tmp_p
            if max_col != k:
                for i in range(self.m_rows):
                    var tmp = self.m_lu[i, k]
                    self.m_lu[i, k] = self.m_lu[i, max_col]
                    self.m_lu[i, max_col] = tmp
                var tmp_q = self.m_q[k]
                self.m_q[k] = self.m_q[max_col]
                self.m_q[max_col] = tmp_q
            for i in range(k + 1, self.m_rows):
                self.m_lu[i, k] /= self.m_lu[k, k]
                for j in range(k + 1, self.m_cols):
                    self.m_lu[i, j] -= self.m_lu[i, k] * self.m_lu[k, j]

    def matrixLU(self) -> MatrixType:
        return self.m_lu

    def permutationP(self) -> PermutationMatrix:
        return PermutationMatrix(self.m_p, self.m_rows)

    def permutationQ(self) -> PermutationMatrix:
        return PermutationMatrix(self.m_q, self.m_cols)

struct PermutationMatrix:
    var indices: Tensor[DType.int64, _]
    var size: Int

    def __init__(inout self, ind: Tensor[DType.int64, _], n: Int):
        self.indices = ind
        self.size = n

    def inverse(self) -> PermutationMatrix:
        var inv_indices = Tensor[DType.int64, self.size]()
        for i in range(self.size):
            inv_indices[self.indices[i]] = i
        return PermutationMatrix(inv_indices, self.size)

    def __getitem__(self, i: Int, j: Int) -> DType.float64:
        if i == self.indices[j]:
            return 1.0
        else:
            return 0.0