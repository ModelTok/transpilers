from main import *
from Eigen.Core import *

def bandmatrix[MatrixType: AnyType](_m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias DenseMatrixType = Matrix[Scalar, Dynamic, Dynamic]
    var rows = _m.rows()
    var cols = _m.cols()
    var supers = _m.supers()
    var subs = _m.subs()
    var m = MatrixType(rows, cols, supers, subs)
    var dm1 = DenseMatrixType(rows, cols)
    dm1.setZero()
    m.diagonal().setConstant(123)
    dm1.diagonal().setConstant(123)
    for i in range(1, m.supers() + 1):
        m.diagonal(i).setConstant(RealScalar(i))
        dm1.diagonal(i).setConstant(RealScalar(i))
    for i in range(1, m.subs() + 1):
        m.diagonal(-i).setConstant(-RealScalar(i))
        dm1.diagonal(-i).setConstant(-RealScalar(i))
    VERIFY_IS_APPROX(dm1, m.toDenseMatrix())
    for i in range(0, cols):
        m.col(i).setConstant(RealScalar(i + 1))
        dm1.col(i).setConstant(RealScalar(i + 1))
    var d = min(rows, cols)
    var a = max[Index](0, cols - d - supers)
    var b = max[Index](0, rows - d - subs)
    if a > 0:
        dm1.block(0, d + supers, rows, a).setZero()
    dm1.block(0, supers + 1, cols - supers - 1 - a, cols - supers - 1 - a).triangularView[Upper]().setZero()
    dm1.block(subs + 1, 0, rows - subs - 1 - b, rows - subs - 1 - b).triangularView[Lower]().setZero()
    if b > 0:
        dm1.block(d + subs, 0, b, cols).setZero()
    VERIFY_IS_APPROX(dm1, m.toDenseMatrix())

def test_bandmatrix():
    for i in range(0, 10 * g_repeat):
        var rows = internal.random[Index](1, 10)
        var cols = internal.random[Index](1, 10)
        var sups = internal.random[Index](0, cols - 1)
        var subs = internal.random[Index](0, rows - 1)
        CALL_SUBTEST(bandmatrix(BandMatrix[float32](rows, cols, sups, subs)))