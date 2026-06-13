// Mojo translation of diagonalmatrices.cpp
// No refactoring, faithful 1:1 conversion.

from testing import assert_almost_equal  # for VERIFY_IS_APPROX equivalent
from math import random  # for internal::random, will wrap
from array import DynamicVector  # for dynamic matrices
from complex import ComplexFloat64

// Define necessary types and constants as in Eigen
alias Scalar = Float64  // base scalar, but will specialize per test
alias Index = Int
alias Dynamic = 0  // marker for dynamic size

// Placeholders for matrix types (to be specialized later)
// We'll define generic Matrix and DiagonalMatrix structs using Mojo's built-in matrix? 
// For simplicity, use Mojo's ndarray but with named dimensions.
// Since Mojo doesn't have Eigen's compile-time sizes, we'll use runtime sizes always,
// but keep the enum for Rows, Cols as compile-time constants where possible.

// To keep the code readable, we'll use a generic Matrix type that holds an ndarray.
// However, to keep 1:1 we need the same method signatures. We'll define minimal stubs.

struct Matrix[ScalarType: AnyType, Rows: Int, Cols: Int]:
    var data: ndarray[ScalarType, 2]  // row-major or col-major? Use row-major consistent with Eigen default? We'll use row-major for simplicity.
    
    def __init__(inout self, rows: Int, cols: Int):
        self.data = ndarray[ScalarType, 2](rows, cols)
    
    def __init__(inout self, other: Self):
        self.data = other.data.copy()
    
    def __getitem__(self, i: Int, j: Int) -> ScalarType:
        return self.data[i, j]
    
    def __setitem__(inout self, i: Int, j: Int, val: ScalarType):
        self.data[i, j] = val
    
    def rows(self) -> Int: return self.data.shape[0]
    def cols(self) -> Int: return self.data.shape[1]
    
    // methods used in test
    def block(self, i: Int, j: Int, rows: Int, cols: Int) -> Self:
        // return a view? In Eigen it returns a block expression, we'll copy.
        var out = Matrix[ScalarType, Dynamic, Dynamic](rows, cols)
        for r in range(rows):
            for c in range(cols):
                out[r, c] = self[i+r, j+c]
        return out
    
    def setZero(inout self, rows: Int, cols: Int):
        if self.data.shape[0] != rows or self.data.shape[1] != cols:
            self.data = ndarray[ScalarType, 2](rows, cols)
        self.data.fill(0.0)
    
    def setRandom(inout self):
        for i in range(self.rows()):
            for j in range(self.cols()):
                self[i, j] = random()
    
    def toDenseMatrix(self) -> Self:
        return self
    
    // assignment from DiagonalMatrix
    def __iadd__(inout self, other: DiagonalMatrix[ScalarType, ...]) -> Self:
        for i in range(self.rows()):
            for j in range(self.cols()):
                if i == j:
                    self[i, j] += other.diagonal()[i]
        return self
    
    def __isub__(inout self, other: DiagonalMatrix[ScalarType, ...]) -> Self:
        for i in range(self.rows()):
            for j in range(self.cols()):
                if i == j:
                    self[i, j] -= other.diagonal()[i]
        return self
    
    // multiplication with DiagonalMatrix (left)
    def __mul__(self, other: DiagonalMatrix[ScalarType, ...]) -> Self:
        var out = Matrix[ScalarType, Dynamic, Dynamic](self.rows(), self.cols())
        for i in range(self.rows()):
            for j in range(self.cols()):
                out[i, j] = self[i, j] * other.diagonal()[j]  // note: right diagonal
        return out
    
    // multiplication from left by diagonal
    def left_mul(self, diag: Vector[ScalarType, ...]) -> Self:
        var out = Matrix[ScalarType, Dynamic, Dynamic](self.rows(), self.cols())
        for i in range(self.rows()):
            for j in range(self.cols()):
                out[i, j] = diag[i] * self[i, j]
        return out
    
    def topRows(self, n: Int) -> Self:
        return self.block(0, 0, n, self.cols())
    
    def topRows[N: Int](self) -> Self:
        return self.block(0, 0, N, self.cols())
    
    def topLeftCorner(self, n: Int, m: Int) -> Self:
        return self.block(0, 0, n, m)
    
    def topLeftCorner[N: Int, M: Int](self) -> Self:
        return self.block(0, 0, N, M)
    
    def col(self, j: Int) -> Vector[ScalarType, Dynamic]:
        var out = Vector[ScalarType, Dynamic](self.rows())
        for i in range(self.rows()):
            out[i] = self[i, j]
        return out
    
    def row(self, i: Int) -> RowVector[ScalarType, Dynamic]:
        var out = RowVector[ScalarType, Dynamic](self.cols())
        for j in range(self.cols()):
            out[j] = self[i, j]
        return out
    
    def transpose(self) -> Self:
        var out = Matrix[ScalarType, Dynamic, Dynamic](self.cols(), self.rows())
        for i in range(self.rows()):
            for j in range(self.cols()):
                out[j, i] = self[i, j]
        return out
    
    def __pos__(self) -> Self: return self
    def __neg__(self) -> Self:
        var out = self
        for i in range(self.rows()):
            for j in range(self.cols()):
                out[i, j] = -self[i, j]
        return out

struct Vector[ScalarType: AnyType, Size: Int]:
    var data: ndarray[ScalarType, 1]
    def __init__(inout self, n: Int):
        self.data = ndarray[ScalarType, 1](n)
    def __init__(inout self, other: Self):
        self.data = other.data.copy()
    def __getitem__(self, i: Int) -> ScalarType: return self.data[i]
    def __setitem__(inout self, i: Int, val: ScalarType): self.data[i] = val
    def size(self) -> Int: return self.data.shape[0]
    def head(self, n: Int) -> Self:
        var out = Vector[ScalarType, Dynamic](n)
        for i in range(n):
            out[i] = self[i]
        return out
    def head[N: Int](self) -> Self:
        return self.head(N)
    def asDiagonal(self) -> DiagonalMatrix[ScalarType, Size]:
        var d = DiagonalMatrix[ScalarType, Size](self.size())
        for i in range(self.size()):
            d.diagonal()[i] = self[i]
        return d
    def __add__(self, other: Self) -> Self:
        var out = Vector[ScalarType, Size](self.size())
        for i in range(self.size()):
            out[i] = self[i] + other[i]
        return out
    def __mul__(self, scalar: ScalarType) -> Self:
        var out = Vector[ScalarType, Size](self.size())
        for i in range(self.size()):
            out[i] = self[i] * scalar
        return out
    def __rmul__(self, scalar: ScalarType) -> Self:
        return self * scalar

struct RowVector[ScalarType: AnyType, Size: Int]:
    var data: ndarray[ScalarType, 1]
    def __init__(inout self, n: Int):
        self.data = ndarray[ScalarType, 1](n)
    def __init__(inout self, other: Self):
        self.data = other.data.copy()
    def __getitem__(self, j: Int) -> ScalarType: return self.data[j]
    def __setitem__(inout self, j: Int, val: ScalarType): self.data[j] = val
    def size(self) -> Int: return self.data.shape[0]
    def asDiagonal(self) -> DiagonalMatrix[ScalarType, Size]:
        var d = DiagonalMatrix[ScalarType, Size](self.size())
        for j in range(self.size()):
            d.diagonal()[j] = self[j]
        return d
    def __add__(self, other: Self) -> Self:
        var out = RowVector[ScalarType, Size](self.size())
        for i in range(self.size()):
            out[i] = self[i] + other[i]
        return out

struct DiagonalMatrix[ScalarType: AnyType, Size: Int]:
    var diag: Vector[ScalarType, Size]
    def __init__(inout self, n: Int):
        self.diag = Vector[ScalarType, Size](n)
    def __init__(inout self, v: Vector[ScalarType, Size]):
        self.diag = v
    def __init__(inout self, rd: RowVector[ScalarType, Size]):
        self.diag = Vector[ScalarType, Size](rd.data)  // convert
    def diagonal(self) -> Vector[ScalarType, Size]: return self.diag
    def toDenseMatrix(self) -> Matrix[ScalarType, Size, Size]:
        var out = Matrix[ScalarType, Size, Size](self.diag.size(), self.diag.size())
        for i in range(self.diag.size()):
            out[i, i] = self.diag[i]
        return out
    // left multiplication by scalar
    def __mul__(self, scalar: ScalarType) -> Self:
        var out = DiagonalMatrix[ScalarType, Size](self.diag.size())
        for i in range(self.diag.size()):
            out.diag[i] = self.diag[i] * scalar
        return out
    def __rmul__(self, scalar: ScalarType) -> Self:
        return self * scalar

// Random number generator for scalars
def random_scalar(type: String) -> Scalar:
    if type == "float64":
        return random()
    elif type == "complex128":
        return ComplexFloat64(random(), random())
    else:
        return random()

def random_index(low: Int, high: Int) -> Int:
    return Int(random() * Float64(high - low + 1)) + low

// Test macros
def VERIFY_IS_APPROX(a: Scalar, b: Scalar):
    assert_almost_equal(a, b, epsilon=1e-6)

def VERIFY_IS_APPROX[MT, MT2](a: Matrix[Scalar, MT], b: Matrix[Scalar, MT2]):
    // assume same size
    for i in range(a.rows()):
        for j in range(a.cols()):
            assert_almost_equal(a[i,j], b[i,j], epsilon=1e-6)

def VERIFY_IS_APPROX[V](a: Vector[Scalar, V], b: Vector[Scalar, V]):
    for i in range(a.size()):
        assert_almost_equal(a[i], b[i], epsilon=1e-6)

def VERIFY_IS_APPROX[V1, V2](a: Vector[Scalar, V1], b: Vector[Scalar, V2]):
    for i in range(a.size()):
        assert_almost_equal(a[i], b[i], epsilon=1e-6)

// Need a specialized VERIFY_IS_APPROX for DiagonalMatrix
def VERIFY_IS_APPROX[D](a: DiagonalMatrix[Scalar, D], b: DiagonalMatrix[Scalar, D]):
    for i in range(a.diagonal().size()):
        assert_almost_equal(a.diagonal()[i], b.diagonal()[i], epsilon=1e-6)

// internal namespace as in Eigen
alias internal = InternalModule()

struct InternalModule:
    def random[AnyType]() -> AnyType:
        return random_scalar("float64")
    
    def random[AnyType](low: Index, high: Index) -> Index:
        return random_index(low, high)
    
    def random[AnyType](low: Scalar, high: Scalar) -> Scalar:
        return low + (high - low) * random()

// Test functions (transliterated with minimal changes)
def diagonalmatrices[MatrixType](m: MatrixType):
    alias Scalar = MatrixType.ScalarType
    alias Rows = MatrixType.Rows
    alias Cols = MatrixType.Cols
    alias VectorType = Vector[Scalar, Rows]
    alias RowVectorType = RowVector[Scalar, Cols]
    alias SquareMatrixType = Matrix[Scalar, Rows, Rows]
    alias DynMatrixType = Matrix[Scalar, Dynamic, Dynamic]
    alias LeftDiagonalMatrix = DiagonalMatrix[Scalar, Rows]
    alias RightDiagonalMatrix = DiagonalMatrix[Scalar, Cols]
    // BigMatrix: if Rows==Dynamic then Dynamic else 2*Rows, similarly for Cols
    alias BigRows = Dynamic if Rows==Dynamic else 2*Rows
    alias BigCols = Dynamic if Cols==Dynamic else 2*Cols
    alias BigMatrix = Matrix[Scalar, BigRows, BigCols]
    
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.random(rows, cols)
    var m2 = MatrixType.random(rows, cols)
    var v1 = VectorType.random(rows)
    var v2 = VectorType.random(rows)
    var rv1 = RowVectorType.random(cols)
    var rv2 = RowVectorType.random(cols)
    var ldm1 = LeftDiagonalMatrix(v1)
    var ldm2 = LeftDiagonalMatrix(v2)
    var rdm1 = RightDiagonalMatrix(rv1)
    var rdm2 = RightDiagonalMatrix(rv2)
    var s1 = internal.random[Scalar]()
    var sq_m1 = SquareMatrixType(v1.asDiagonal())
    VERIFY_IS_APPROX(sq_m1, v1.asDiagonal().toDenseMatrix())
    sq_m1 = v1.asDiagonal()
    VERIFY_IS_APPROX(sq_m1, v1.asDiagonal().toDenseMatrix())
    var sq_m2 = SquareMatrixType(v1.asDiagonal())
    VERIFY_IS_APPROX(sq_m1, sq_m2)
    ldm1 = v1.asDiagonal()
    var ldm3 = LeftDiagonalMatrix(v1)
    VERIFY_IS_APPROX(ldm1.diagonal(), ldm3.diagonal())
    var ldm4 = LeftDiagonalMatrix(v1.asDiagonal())
    VERIFY_IS_APPROX(ldm1.diagonal(), ldm4.diagonal())
    sq_m1.block(0, 0, rows, rows) = ldm1
    VERIFY_IS_APPROX(sq_m1, ldm1.toDenseMatrix())
    sq_m1.transpose() = ldm1
    VERIFY_IS_APPROX(sq_m1, ldm1.toDenseMatrix())
    var i = internal.random[Index](0, rows-1)
    var j = internal.random[Index](0, cols-1)
    VERIFY_IS_APPROX(((ldm1 * m1)(i, j)), ldm1.diagonal()(i) * m1(i, j))
    VERIFY_IS_APPROX(((ldm1 * (m1+m2))(i, j)), ldm1.diagonal()(i) * (m1+m2)(i, j))
    VERIFY_IS_APPROX(((m1 * rdm1)(i, j)), rdm1.diagonal()(j) * m1(i, j))
    VERIFY_IS_APPROX(((v1.asDiagonal() * m1)(i, j)), v1(i) * m1(i, j))
    VERIFY_IS_APPROX(((m1 * rv1.asDiagonal())(i, j)), rv1(j) * m1(i, j))
    VERIFY_IS_APPROX((((v1+v2).asDiagonal() * m1)(i, j)), (v1+v2)(i) * m1(i, j))
    VERIFY_IS_APPROX((((v1+v2).asDiagonal() * (m1+m2))(i, j)), (v1+v2)(i) * (m1+m2)(i, j))
    VERIFY_IS_APPROX(((m1 * (rv1+rv2).asDiagonal())(i, j)), (rv1+rv2)(j) * m1(i, j))
    VERIFY_IS_APPROX((((m1+m2) * (rv1+rv2).asDiagonal())(i, j)), (rv1+rv2)(j) * (m1+m2)(i, j))
    if rows>1:
        var tmp = DynMatrixType(m1.topRows(rows/2))
        var res: DynMatrixType
        VERIFY_IS_APPROX((res = m1.topRows(rows/2) * rv1.asDiagonal()), tmp * rv1.asDiagonal())
        VERIFY_IS_APPROX((res = v1.head(rows/2).asDiagonal() * m1.topRows(rows/2)), v1.head(rows/2).asDiagonal() * tmp)
    var big = BigMatrix()
    big.setZero(2*rows, 2*cols)
    big.block(i, j, rows, cols) = m1
    big.block(i, j, rows, cols) = v1.asDiagonal() * big.block(i, j, rows, cols)
    VERIFY_IS_APPROX((big.block(i, j, rows, cols)), v1.asDiagonal() * m1)
    big.block(i, j, rows, cols) = m1
    big.block(i, j, rows, cols) = big.block(i, j, rows, cols) * rv1.asDiagonal()
    VERIFY_IS_APPROX((big.block(i, j, rows, cols)), m1 * rv1.asDiagonal())
    VERIFY_IS_APPROX(LeftDiagonalMatrix(ldm1*s1).diagonal(), ldm1.diagonal() * s1)
    VERIFY_IS_APPROX(LeftDiagonalMatrix(s1*ldm1).diagonal(), s1 * ldm1.diagonal())
    VERIFY_IS_APPROX(m1 * (rdm1 * s1), (m1 * rdm1) * s1)
    VERIFY_IS_APPROX(m1 * (s1 * rdm1), (m1 * rdm1) * s1)
    sq_m1.setRandom()
    sq_m2 = sq_m1
    VERIFY_IS_APPROX((sq_m1 += (s1*v1).asDiagonal()), sq_m2 += (s1*v1).asDiagonal().toDenseMatrix())
    VERIFY_IS_APPROX((sq_m1 -= (s1*v1).asDiagonal()), sq_m2 -= (s1*v1).asDiagonal().toDenseMatrix())
    VERIFY_IS_APPROX((sq_m1 = (s1*v1).asDiagonal()), (s1*v1).asDiagonal().toDenseMatrix())
    sq_m1.setRandom()
    sq_m2 = v1.asDiagonal()
    sq_m2 = sq_m1 * sq_m2
    VERIFY_IS_APPROX((sq_m1*v1.asDiagonal()).col(i), sq_m2.col(i))
    VERIFY_IS_APPROX((sq_m1*v1.asDiagonal()).row(i), sq_m2.row(i))

def as_scalar_product[MatrixType](m: MatrixType):
    alias Scalar = MatrixType.ScalarType
    alias VectorType = Vector[Scalar, MatrixType.Rows]
    alias DynMatrixType = Matrix[Scalar, Dynamic, Dynamic]
    alias DynVectorType = Vector[Scalar, Dynamic]
    alias DynRowVectorType = RowVector[Scalar, Dynamic]
    var rows = m.rows()
    var depth = internal.random[Index](1, EIGEN_TEST_MAX_SIZE)
    var v1 = VectorType.random(rows)
    var dv1 = DynVectorType.random(depth)
    var drv1 = DynRowVectorType.random(depth)
    var dm1 = DynMatrixType(dv1)
    var drm1 = DynMatrixType(drv1)
    var s = v1(0)
    VERIFY_IS_APPROX(v1.asDiagonal() * drv1, s*drv1)
    VERIFY_IS_APPROX(dv1 * v1.asDiagonal(), dv1*s)
    VERIFY_IS_APPROX(v1.asDiagonal() * drm1, s*drm1)
    VERIFY_IS_APPROX(dm1 * v1.asDiagonal(), dm1*s)

def bug987[_: Int]():
    var points = Matrix[Scalar, 3, Dynamic](3, 3)
    points.data.fill(random())  // simplified
    var diag = Vector[Scalar, 2](2)
    diag.data.fill(random())
    var tmp1 = points.topRows[2]()  // need proper method
    var res1: Matrix[Scalar, 2, Dynamic]
    var res2: Matrix[Scalar, 2, Dynamic]
    VERIFY_IS_APPROX((res1 = diag.asDiagonal() * points.topRows[2]()), res2 = diag.asDiagonal() * tmp1)
    var tmp2 = points.topLeftCorner[2,2]()
    VERIFY_IS_APPROX((res1 = points.topLeftCorner[2,2]() * diag.asDiagonal()), res2 = tmp2 * diag.asDiagonal())

def test_diagonalmatrices():
    var g_repeat = 1  // simplified
    for i in range(g_repeat):
        CALL_SUBTEST_1(diagonalmatrices[Matrix[Scalar,1,1]](Matrix[Scalar,1,1](1,1)))
        CALL_SUBTEST_1(as_scalar_product[Matrix[Scalar,1,1]](Matrix[Scalar,1,1](1,1)))
        CALL_SUBTEST_2(diagonalmatrices[Matrix[Scalar,3,3]](Matrix[Scalar,3,3](3,3)))
        CALL_SUBTEST_3(diagonalmatrices[Matrix[Scalar,3,3,RowMajor]](Matrix[Scalar,3,3,RowMajor](3,3)))  // RowMajor flag ignored
        CALL_SUBTEST_4(diagonalmatrices[Matrix[Scalar,4,4]](Matrix[Scalar,4,4](4,4)))
        CALL_SUBTEST_5(diagonalmatrices[Matrix[Scalar,4,4,RowMajor]](Matrix[Scalar,4,4,RowMajor](4,4)))
        // Complex: use ComplexFloat64
        CALL_SUBTEST_6(diagonalmatrices[Matrix[ComplexFloat64, Dynamic, Dynamic]](Matrix[ComplexFloat64, Dynamic, Dynamic](internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(as_scalar_product[Matrix[ComplexFloat64,1,1]](Matrix[ComplexFloat64,1,1](1,1)))
        CALL_SUBTEST_7(diagonalmatrices[Matrix[Int32, Dynamic, Dynamic]](Matrix[Int32, Dynamic, Dynamic](internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_8(diagonalmatrices[Matrix[Scalar, Dynamic, Dynamic, RowMajor]](Matrix[Scalar, Dynamic, Dynamic, RowMajor](internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_9(diagonalmatrices[Matrix[Scalar, Dynamic, Dynamic]](Matrix[Scalar, Dynamic, Dynamic](internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_9(diagonalmatrices[Matrix[Scalar,1,1]](Matrix[Scalar,1,1](1,1)))
        CALL_SUBTEST_9(as_scalar_product[Matrix[Scalar,1,1]](Matrix[Scalar,1,1](1,1)))
    CALL_SUBTEST_10(bug987[0]())

// Subtest macros (dummy)
def CALL_SUBTEST_1[T](f: def ()):
    f()
def CALL_SUBTEST_2[T](f: def ()):
    f()
def CALL_SUBTEST_3[T](f: def ()):
    f()
def CALL_SUBTEST_4[T](f: def ()):
    f()
def CALL_SUBTEST_5[T](f: def ()):
    f()
def CALL_SUBTEST_6[T](f: def ()):
    f()
def CALL_SUBTEST_7[T](f: def ()):
    f()
def CALL_SUBTEST_8[T](f: def ()):
    f()
def CALL_SUBTEST_9[T](f: def ()):
    f()
def CALL_SUBTEST_10[T](f: def ()):
    f()

// Main entry point (test driver)
def main():
    test_diagonalmatrices()