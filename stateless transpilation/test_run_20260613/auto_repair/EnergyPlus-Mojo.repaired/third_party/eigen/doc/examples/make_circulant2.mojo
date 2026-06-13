# Mojo translation of make_circulant2.cpp
# Uses Mojo's tensor module for dynamic-sized matrices and vectors.

from tensor import Tensor, Shape, DType
from builtin import IndexError
from math import abs as _abs
from sys import print

# Alias for Eigen-like dynamic vector/matrix types
alias VectorXd = Tensor[DType.float64, 1]
alias MatrixXd = Tensor[DType.float64, 2]
alias Index = Int

# Forward declaration of helper types (to match C++ structure)
struct circulant_functor[ArgType: AnyType]:
    var m_vec: ArgType
    def __init__(inout self, arg: ArgType):
        self.m_vec = arg
    def __call__(self, row: Index, col: Index) -> Float64:
        var index = row - col
        if index < 0:
            index += self.m_vec.shape[0]
        return self.m_vec[index]

struct circulant_helper[ArgType: AnyType]:
    alias Scalar = DType.float64  # Simplified; ideally deduced from ArgType scalar type
    alias MatrixType = MatrixXd

struct CwiseNullaryOp[FunctorType: AnyType, MatrixType: AnyType]:
    var functor: FunctorType
    var rows: Index
    var cols: Index
    def __init__(inout self, f: FunctorType, r: Index, c: Index):
        self.functor = f
        self.rows = r
        self.cols = c
    def eval_to_matrix(self) -> MatrixType:
        var mat = MatrixType(Shape(self.rows, self.cols))
        for i in range(self.rows):
            for j in range(self.cols):
                mat[i, j] = self.functor(i, j)
        return mat
    # Allow implicit conversion to MatrixType via assignment operators
    def _to_matrix(inout self) -> MatrixType:
        return self.eval_to_matrix()

# Extension: add NullaryExpr to MatrixType (simulating Eigen's static method)
def NullaryExpr(rows: Index, cols: Index, functor: AnyType) -> CwiseNullaryOp[typeof(functor), MatrixType]:
    return CwiseNullaryOp[typeof(functor), MatrixType](functor, rows, cols)

# But to match the original syntax MatrixType::NullaryExpr, we'll define it as a static method in a 'Matrix' namespace.
# Instead, we can use a standalone function 'makeCirculant' that returns CwiseNullaryOp, as in C++ the return type is such an expression.

# The helper struct is already defined above.

def makeCirculant[ArgType: AnyType](arg: ArgType) -> CwiseNullaryOp[circulant_functor[ArgType], circulant_helper[ArgType].MatrixType]:
    let functor = circulant_functor[ArgType](arg)
    let n = arg.shape[0]
    # Create a CwiseNullaryOp that represents the circulant matrix
    return CwiseNullaryOp[circulant_functor[ArgType], circulant_helper[ArgType].MatrixType](functor, n, n)

def main():
    var vec = VectorXd(Shape(4))
    vec[0] = 1.0
    vec[1] = 2.0
    vec[2] = 4.0
    vec[3] = 8.0
    # In C++: mat = makeCirculant(vec);  Here we need to evaluate the expression explicitly
    var mat: MatrixXd
    let expr = makeCirculant(vec)  # returns CwiseNullaryOp
    mat = expr.eval_to_matrix()
    # Print matrix (Mojo tensor print)
    print(mat)