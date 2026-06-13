from main import *
from NumTraits import NumTraits
from internal import internal
from Matrix import Matrix
from numext import numext

def get_random_size[T: AnyType]() -> Int:
    const factor: Int = NumTraits[T].ReadCost
    const max_test_size: Int = EIGEN_TEST_MAX_SIZE if EIGEN_TEST_MAX_SIZE > 2 * factor else EIGEN_TEST_MAX_SIZE / factor
    return internal.random[Int](1, max_test_size)

def trmm[Scalar: AnyType, Mode: Int, TriOrder: Int, OtherOrder: Int, ResOrder: Int, OtherCols: Int](rows: Int = get_random_size[Scalar](), cols: Int = get_random_size[Scalar](), otherCols: Int = OtherCols if OtherCols != Dynamic else get_random_size[Scalar]()):
    alias TriMatrix = Matrix[Scalar, Dynamic, Dynamic, TriOrder]
    alias OnTheRight = Matrix[Scalar, Dynamic, OtherCols, ColMajor if OtherCols == 1 else OtherOrder]
    alias OnTheLeft = Matrix[Scalar, OtherCols, Dynamic, RowMajor if OtherCols == 1 else OtherOrder]
    alias ResXS = Matrix[Scalar, Dynamic, OtherCols, ColMajor if OtherCols == 1 else ResOrder]
    alias ResSX = Matrix[Scalar, OtherCols, Dynamic, RowMajor if OtherCols == 1 else ResOrder]
    var mat: TriMatrix = TriMatrix(rows, cols)
    var tri: TriMatrix = TriMatrix(rows, cols)
    var triTr: TriMatrix = TriMatrix(cols, rows)
    var s1tri: TriMatrix = TriMatrix(rows, cols)
    var s1triTr: TriMatrix = TriMatrix(cols, rows)
    var ge_right: OnTheRight = OnTheRight(cols, otherCols)
    var ge_left: OnTheLeft = OnTheLeft(otherCols, rows)
    var ge_sx: ResSX = ResSX()
    var ge_sx_save: ResSX = ResSX()
    var ge_xs: ResXS = ResXS()
    var ge_xs_save: ResXS = ResXS()
    var s1: Scalar = internal.random[Scalar]()
    var s2: Scalar = internal.random[Scalar]()
    mat.setRandom()
    tri = mat.template triangularView[Mode]()
    triTr = mat.transpose().template triangularView[Mode]()
    s1tri = (s1 * mat).template triangularView[Mode]()
    s1triTr = (s1 * mat).transpose().template triangularView[Mode]()
    ge_right.setRandom()
    ge_left.setRandom()
    VERIFY_IS_APPROX(ge_xs = mat.template triangularView[Mode]() * ge_right, tri * ge_right)
    VERIFY_IS_APPROX(ge_sx = ge_left * mat.template triangularView[Mode](), ge_left * tri)
    VERIFY_IS_APPROX(ge_xs.noalias() = mat.template triangularView[Mode]() * ge_right, tri * ge_right)
    VERIFY_IS_APPROX(ge_sx.noalias() = ge_left * mat.template triangularView[Mode](), ge_left * tri)
    if (Mode & UnitDiag) == 0:
        VERIFY_IS_APPROX(ge_xs.noalias() = (s1 * mat.adjoint()).template triangularView[Mode]() * (s2 * ge_left.transpose()), s1 * triTr.conjugate() * (s2 * ge_left.transpose()))
    VERIFY_IS_APPROX(ge_xs.noalias() = (s1 * mat.transpose()).template triangularView[Mode]() * (s2 * ge_left.transpose()), s1triTr * (s2 * ge_left.transpose()))
    VERIFY_IS_APPROX(ge_sx.noalias() = (s2 * ge_left) * (s1 * mat).template triangularView[Mode](), (s2 * ge_left) * s1tri)
    VERIFY_IS_APPROX(ge_sx.noalias() = ge_right.transpose() * mat.adjoint().template triangularView[Mode](), ge_right.transpose() * triTr.conjugate())
    VERIFY_IS_APPROX(ge_sx.noalias() = ge_right.adjoint() * mat.adjoint().template triangularView[Mode](), ge_right.adjoint() * triTr.conjugate())
    ge_xs_save = ge_xs
    if (Mode & UnitDiag) == 0:
        VERIFY_IS_APPROX((ge_xs_save + s1 * triTr.conjugate() * (s2 * ge_left.adjoint())).eval(), ge_xs.noalias() += (s1 * mat.adjoint()).template triangularView[Mode]() * (s2 * ge_left.adjoint()))
    ge_xs_save = ge_xs
    VERIFY_IS_APPROX((ge_xs_save + s1triTr * (s2 * ge_left.adjoint())).eval(), ge_xs.noalias() += (s1 * mat.transpose()).template triangularView[Mode]() * (s2 * ge_left.adjoint()))
    ge_sx.setRandom()
    ge_sx_save = ge_sx
    if (Mode & UnitDiag) == 0:
        VERIFY_IS_APPROX(ge_sx_save - (ge_right.adjoint() * (-s1 * triTr).conjugate()).eval(), ge_sx.noalias() -= (ge_right.adjoint() * (-s1 * mat).adjoint().template triangularView[Mode]()).eval())
    if (Mode & UnitDiag) == 0:
        VERIFY_IS_APPROX(ge_xs = (s1 * mat).adjoint().template triangularView[Mode]() * ge_left.adjoint(), numext.conj(s1) * triTr.conjugate() * ge_left.adjoint())
    VERIFY_IS_APPROX(ge_xs = (s1 * mat).transpose().template triangularView[Mode]() * ge_left.adjoint(), s1triTr * ge_left.adjoint())

def trmv[Scalar: AnyType, Mode: Int, TriOrder: Int](rows: Int = get_random_size[Scalar](), cols: Int = get_random_size[Scalar]()):
    trmm[Scalar, Mode, TriOrder, ColMajor, ColMajor, 1](rows, cols, 1)

def trmm[Scalar: AnyType, Mode: Int, TriOrder: Int, OtherOrder: Int, ResOrder: Int](rows: Int = get_random_size[Scalar](), cols: Int = get_random_size[Scalar](), otherCols: Int = get_random_size[Scalar]()):
    trmm[Scalar, Mode, TriOrder, OtherOrder, ResOrder, Dynamic](rows, cols, otherCols)

def test_product_trmm():
    for i in range(g_repeat):
        CALL_ALL(1, float)
        CALL_ALL(2, double)
        CALL_ALL(3, std.complex[float32]())
        CALL_ALL(4, std.complex[float64]())