from ...Eigen import *
from limits import epsilon as std_epsilon  # use Mojo stdlib equivalent

var g_repeat: Int = 1  # placeholder, actual value from test framework

def randMatrixUnitary[T: AnyType](size: Int) -> Matrix[T, Dynamic, Dynamic]:
    alias Scalar = T
    alias MatrixType = Matrix[Scalar, Dynamic, Dynamic]
    var Q: MatrixType
    var max_tries: Int = 40
    var is_unitary: Bool = False
    while not is_unitary and max_tries > 0:
        Q = MatrixType.Random(size, size)
        for col in range(size):
            var colVec: MatrixType.ColXpr = Q.col(col)
            for prevCol in range(col):
                var prevColVec: MatrixType.ColXpr = Q.col(prevCol)
                colVec -= colVec.dot(prevColVec) * prevColVec
            Q.col(col) = colVec.normalized()
        for row in range(size):
            var rowVec: MatrixType.RowXpr = Q.row(row)
            for prevRow in range(row):
                var prevRowVec: MatrixType.RowXpr = Q.row(prevRow)
                rowVec -= rowVec.dot(prevRowVec) * prevRowVec
            Q.row(row) = rowVec.normalized()
        is_unitary = Q.isUnitary()
        max_tries -= 1
    if max_tries == 0:
        assert(False, "randMatrixUnitary: Could not construct unitary matrix!")
    return Q

def randMatrixSpecialUnitary[T: AnyType](size: Int) -> Matrix[T, Dynamic, Dynamic]:
    alias Scalar = T
    alias MatrixType = Matrix[Scalar, Dynamic, Dynamic]
    var Q: MatrixType = randMatrixUnitary[Scalar](size)
    Q.col(0) *= numext.conj(Q.determinant())
    return Q

def run_test[MatrixType: AnyType](dim: Int, num_elements: Int):
    from std import abs
    alias Scalar = internal.traits[MatrixType].Scalar
    alias MatrixX = Matrix[Scalar, Dynamic, Dynamic]
    alias VectorX = Matrix[Scalar, Dynamic, 1]
    var c: Scalar = abs(internal.random[Scalar]())
    var R: MatrixX = randMatrixSpecialUnitary[Scalar](dim)
    var t: VectorX = Scalar(50) * VectorX.Random(dim, 1)
    var cR_t: MatrixX = MatrixX.Identity(dim + 1, dim + 1)
    cR_t.block(0, 0, dim, dim) = c * R
    cR_t.block(0, dim, dim, 1) = t
    var src: MatrixX = MatrixX.Random(dim + 1, num_elements)
    src.row(dim) = Matrix[Scalar, 1, Dynamic].Constant(num_elements, Scalar(1))
    var dst: MatrixX = cR_t * src
    var cR_t_umeyama: MatrixX = umeyama(src.block(0, 0, dim, num_elements), dst.block(0, 0, dim, num_elements))
    var error: Scalar = (cR_t_umeyama * src - dst).norm() / dst.norm()
    var eps: Scalar = std_epsilon[Scalar]()
    VERIFY(error < Scalar(40) * eps)

def run_fixed_size_test[Scalar: AnyType, Dimension: Int](num_elements: Int):
    from std import abs
    alias MatrixX = Matrix[Scalar, Dimension + 1, Dynamic]
    alias HomMatrix = Matrix[Scalar, Dimension + 1, Dimension + 1]
    alias FixedMatrix = Matrix[Scalar, Dimension, Dimension]
    alias FixedVector = Matrix[Scalar, Dimension, 1]
    var dim: Int = Dimension
    var c: Scalar = internal.random[Scalar](0.5, 2.0)
    var R: FixedMatrix = randMatrixSpecialUnitary[Scalar](dim)
    var t: FixedVector = Scalar(32) * FixedVector.Random(dim, 1)
    var cR_t: HomMatrix = HomMatrix.Identity(dim + 1, dim + 1)
    cR_t.block(0, 0, dim, dim) = c * R
    cR_t.block(0, dim, dim, 1) = t
    var src: MatrixX = MatrixX.Random(dim + 1, num_elements)
    src.row(dim) = Matrix[Scalar, 1, Dynamic].Constant(num_elements, Scalar(1))
    var dst: MatrixX = cR_t * src
    var src_block: Block[MatrixX, Dimension, Dynamic] = Block[MatrixX, Dimension, Dynamic](src, 0, 0, dim, num_elements)
    var dst_block: Block[MatrixX, Dimension, Dynamic] = Block[MatrixX, Dimension, Dynamic](dst, 0, 0, dim, num_elements)
    var cR_t_umeyama: HomMatrix = umeyama(src_block, dst_block)
    var error: Scalar = (cR_t_umeyama * src - dst).squaredNorm()
    var eps: Scalar = std_epsilon[Scalar]()
    VERIFY(error < Scalar(16) * eps)

def CALL_SUBTEST_1(callable: fn() -> None):
    callable()

def CALL_SUBTEST_2(callable: fn() -> None):
    callable()

def CALL_SUBTEST_3(callable: fn() -> None):
    callable()

def CALL_SUBTEST_4(callable: fn() -> None):
    callable()

def CALL_SUBTEST_5(callable: fn() -> None):
    callable()

def CALL_SUBTEST_6(callable: fn() -> None):
    callable()

def CALL_SUBTEST_7(callable: fn() -> None):
    callable()

def CALL_SUBTEST_8(callable: fn() -> None):
    callable()

def test_umeyama():
    for i in range(g_repeat):
        var num_elements: Int = internal.random[Int](40, 500)
        for dim in range(2, 8):
            CALL_SUBTEST_1(fn() => run_test[MatrixXd](dim, num_elements))
            CALL_SUBTEST_2(fn() => run_test[MatrixXf](dim, num_elements))
        CALL_SUBTEST_3(fn() => run_fixed_size_test[float32, 2](num_elements))
        CALL_SUBTEST_4(fn() => run_fixed_size_test[float32, 3](num_elements))
        CALL_SUBTEST_5(fn() => run_fixed_size_test[float32, 4](num_elements))
        CALL_SUBTEST_6(fn() => run_fixed_size_test[float64, 2](num_elements))
        CALL_SUBTEST_7(fn() => run_fixed_size_test[float64, 3](num_elements))
        CALL_SUBTEST_8(fn() => run_fixed_size_test[float64, 4](num_elements))