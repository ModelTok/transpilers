// this test covers the following files:
// Replicate.cpp

from ...Eigen import Matrix, Vector2f, Vector3d, Vector4f, VectorXf, VectorXcd, internal, Dynamic, Index

alias Float32 = F32
alias Float64 = F64

const val Dynamic: Int = -1
typealias Scalar = Float64   # generic placeholder; overridden per context

var g_repeat: Int = 1

def VERIFY_IS_APPROX(a: AnyType, b: AnyType) -> None:
    let tol: Float64 = 1e-6
    # simplified approximation check – assume .norm() exists
    assert ((a - b).norm() < tol)

def CALL_SUBTEST_1(body: fn() -> None) -> None:
    body()

def CALL_SUBTEST_2(body: fn() -> None) -> None:
    body()

def CALL_SUBTEST_3(body: fn() -> None) -> None:
    body()

def CALL_SUBTEST_4(body: fn() -> None) -> None:
    body()

def CALL_SUBTEST_5(body: fn() -> None) -> None:
    body()

def CALL_SUBTEST_6(body: fn() -> None) -> None:
    body()

def replicate[MatrixType: AnyType](m: MatrixType) -> None:
    alias Scalar = MatrixType.Scalar
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias MatrixX = Matrix[Scalar, Dynamic, Dynamic]
    alias VectorX = Matrix[Scalar, Dynamic, 1]

    var rows: Index = m.rows()
    var cols: Index = m.cols()

    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = MatrixType.Random(rows, cols)

    var v1: VectorType = VectorType.Random(rows)

    var x1: MatrixX
    var x2: MatrixX
    var vx1: VectorX

    var f1: Int = internal.random[Int](1, 10)
    var f2: Int = internal.random[Int](1, 10)

    x1.resize(rows * f1, cols * f2)
    for j in range(f2):
        for i in range(f1):
            x1.block(i * rows, j * cols, rows, cols) = m1
    VERIFY_IS_APPROX(x1, m1.replicate(f1, f2))

    x2.resize(2 * rows, 3 * cols)
    # x2 << m2, m2, m2, m2, m2, m2;
    for i in range(2):
        for j in range(3):
            x2.block(i * rows, j * cols, rows, cols) = m2
    VERIFY_IS_APPROX(x2, m2.replicate[2, 3]())

    x2.resize(rows, 3 * cols)
    # x2 << m2, m2, m2;
    for j in range(3):
        x2.block(0, j * cols, rows, cols) = m2
    VERIFY_IS_APPROX(x2, m2.replicate[1, 3]())

    vx1.resize(3 * rows, cols)
    # vx1 << m2, m2, m2;
    for i in range(3):
        vx1.block(i * rows, 0, rows, cols) = m2
    VERIFY_IS_APPROX(vx1 + vx1, vx1 + m2.replicate[3, 1]())

    vx1 = m2 + (m2.colwise().replicate(1))
    if m2.cols() == 1:
        VERIFY_IS_APPROX(m2.coeff(0), m2.replicate[3, 1]().coeff(m2.rows()))

    x2.resize(rows, f1)
    for j in range(f1):
        x2.col(j) = v1
    VERIFY_IS_APPROX(x2, v1.rowwise().replicate(f1))

    vx1.resize(rows * f2)
    for j in range(f2):
        vx1.segment(j * rows, rows) = v1
    VERIFY_IS_APPROX(vx1, v1.colwise().replicate(f2))

def test_array_replicate() -> None:
    for _ in range(g_repeat):
        CALL_SUBTEST_1(lambda: replicate(Matrix[Float32, 1, 1]()))
        CALL_SUBTEST_2(lambda: replicate(Vector2f()))
        CALL_SUBTEST_3(lambda: replicate(Vector3d()))
        CALL_SUBTEST_4(lambda: replicate(Vector4f()))
        CALL_SUBTEST_5(lambda: replicate(VectorXf(16)))
        CALL_SUBTEST_6(lambda: replicate(VectorXcd(10)))