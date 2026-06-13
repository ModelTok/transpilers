alias EIGEN_STACK_ALLOCATION_LIMIT = 0
alias EIGEN_RUNTIME_NO_MALLOC = True

from ...main import main
from ...Eigen.Cholesky import *
from ...Eigen.Eigenvalues import *
from ...Eigen.LU import *
from ...Eigen.QR import *
from ...Eigen.SVD import *

# Test macros (placeholders for real implementation)
def VERIFY_IS_APPROX[T: type](a: T, b: T):
    # In real Eigen, this uses a.isApprox(b) or equivalent

def VERIFY_RAISES_ASSERT(body: fn() -> None):
    try:
        body()
        # If no error, assertion should fail
        assert(False, "Expected assertion but none raised")
    except:

def CALL_SUBTEST_1(body: fn() -> None): body()
def CALL_SUBTEST_2(body: fn() -> None): body()
def CALL_SUBTEST_3(body: fn() -> None): body()
def CALL_SUBTEST_4(body: fn() -> None): body()
def CALL_SUBTEST_5(body: fn() -> None): body()
def CALL_SUBTEST_6(body: fn() -> None): body()
def CALL_SUBTEST_7(body: fn() -> None): body()
def CALL_SUBTEST_8(body: fn() -> None): body()

def nomalloc[MatrixType: type](m: MatrixType):
    /* this test check no dynamic memory allocation are issued with fixed-size matrices
    */
    type Scalar = MatrixType.Scalar
    let rows = m.rows()
    let cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType(rows, cols)
    let s1 = internal.random[Scalar]()
    let r = internal.random[Index](0, rows - 1)
    let c = internal.random[Index](0, cols - 1)
    VERIFY_IS_APPROX((m1 + m2) * s1, s1 * m1 + s1 * m2)
    VERIFY_IS_APPROX((m1 + m2)[r, c], m1[r, c] + m2[r, c])
    VERIFY_IS_APPROX(m1.cwiseProduct(m1.block(0, 0, rows, cols)), (m1.array() * m1.array()).matrix())
    VERIFY_IS_APPROX((m1 * m1.transpose()) * m2, m1 * (m1.transpose() * m2))
    m2.col(0).noalias() = m1 * m1.col(0)
    m2.col(0).noalias() -= m1.adjoint() * m1.col(0)
    m2.col(0).noalias() -= m1 * m1.row(0).adjoint()
    m2.col(0).noalias() -= m1.adjoint() * m1.row(0).adjoint()
    m2.row(0).noalias() = m1.row(0) * m1
    m2.row(0).noalias() -= m1.row(0) * m1.adjoint()
    m2.row(0).noalias() -= m1.col(0).adjoint() * m1
    m2.row(0).noalias() -= m1.col(0).adjoint() * m1.adjoint()
    VERIFY_IS_APPROX(m2, m2)
    m2.col(0).noalias() = m1.triangularView[Upper]() * m1.col(0)
    m2.col(0).noalias() -= m1.adjoint().triangularView[Upper]() * m1.col(0)
    m2.col(0).noalias() -= m1.triangularView[Upper]() * m1.row(0).adjoint()
    m2.col(0).noalias() -= m1.adjoint().triangularView[Upper]() * m1.row(0).adjoint()
    m2.row(0).noalias() = m1.row(0) * m1.triangularView[Upper]()
    m2.row(0).noalias() -= m1.row(0) * m1.adjoint().triangularView[Upper]()
    m2.row(0).noalias() -= m1.col(0).adjoint() * m1.triangularView[Upper]()
    m2.row(0).noalias() -= m1.col(0).adjoint() * m1.adjoint().triangularView[Upper]()
    VERIFY_IS_APPROX(m2, m2)
    m2.col(0).noalias() = m1.selfadjointView[Upper]() * m1.col(0)
    m2.col(0).noalias() -= m1.adjoint().selfadjointView[Upper]() * m1.col(0)
    m2.col(0).noalias() -= m1.selfadjointView[Upper]() * m1.row(0).adjoint()
    m2.col(0).noalias() -= m1.adjoint().selfadjointView[Upper]() * m1.row(0).adjoint()
    m2.row(0).noalias() = m1.row(0) * m1.selfadjointView[Upper]()
    m2.row(0).noalias() -= m1.row(0) * m1.adjoint().selfadjointView[Upper]()
    m2.row(0).noalias() -= m1.col(0).adjoint() * m1.selfadjointView[Upper]()
    m2.row(0).noalias() -= m1.col(0).adjoint() * m1.adjoint().selfadjointView[Upper]()
    VERIFY_IS_APPROX(m2, m2)
    m2.selfadjointView[Lower]().rankUpdate(m1.col(0), -1)
    m2.selfadjointView[Upper]().rankUpdate(m1.row(0), -1)
    m2.selfadjointView[Lower]().rankUpdate(m1.col(0), m1.col(0))  # rank-2
    m2.selfadjointView[Lower]().rankUpdate(m1)
    m2 += m2.triangularView[Upper]() * m1
    m2.triangularView[Upper]() = m2 * m2
    m1 += m1.selfadjointView[Lower]() * m2
    VERIFY_IS_APPROX(m2, m2)

def ctms_decompositions[Scalar: type]():
    alias maxSize = 16
    alias size = 12
    type Matrix = Eigen.Matrix[Scalar, Eigen.Dynamic, Eigen.Dynamic, 0, maxSize, maxSize]
    type Vector = Eigen.Matrix[Scalar, Eigen.Dynamic, 1, 0, maxSize, 1]
    type ComplexMatrix = Eigen.Matrix[Eigen.complex[Scalar], Eigen.Dynamic, Eigen.Dynamic, 0, maxSize, maxSize]
    let A = Matrix.Random(size, size)
    let B = Matrix.Random(size, size)
    var X = Matrix(size, size)
    let complexA = ComplexMatrix.Random(size, size)
    let saA = A.adjoint() * A
    let b = Vector.Random(size)
    var x = Vector(size)
    var LLT = Eigen.LLT[Matrix]()
    LLT.compute(A)
    X = LLT.solve(B)
    x = LLT.solve(b)
    var LDLT = Eigen.LDLT[Matrix]()
    LDLT.compute(A)
    X = LDLT.solve(B)
    x = LDLT.solve(b)
    var hessDecomp = Eigen.HessenbergDecomposition[ComplexMatrix]()
    hessDecomp.compute(complexA)
    var cSchur = Eigen.ComplexSchur[ComplexMatrix](size)
    cSchur.compute(complexA)
    var cEigSolver = Eigen.ComplexEigenSolver[ComplexMatrix]()
    cEigSolver.compute(complexA)
    var eigSolver = Eigen.EigenSolver[Matrix]()
    eigSolver.compute(A)
    var saEigSolver = Eigen.SelfAdjointEigenSolver[Matrix](size)
    saEigSolver.compute(saA)
    var tridiag = Eigen.Tridiagonalization[Matrix]()
    tridiag.compute(saA)
    var ppLU = Eigen.PartialPivLU[Matrix]()
    ppLU.compute(A)
    X = ppLU.solve(B)
    x = ppLU.solve(b)
    var fpLU = Eigen.FullPivLU[Matrix]()
    fpLU.compute(A)
    X = fpLU.solve(B)
    x = fpLU.solve(b)
    var hQR = Eigen.HouseholderQR[Matrix]()
    hQR.compute(A)
    X = hQR.solve(B)
    x = hQR.solve(b)
    var cpQR = Eigen.ColPivHouseholderQR[Matrix]()
    cpQR.compute(A)
    X = cpQR.solve(B)
    x = cpQR.solve(b)
    var fpQR = Eigen.FullPivHouseholderQR[Matrix]()
    fpQR.compute(A)
    x = fpQR.solve(b)
    var jSVD = Eigen.JacobiSVD[Matrix]()
    jSVD.compute(A, ComputeFullU | ComputeFullV)

def test_zerosized():
    var A = Eigen.MatrixXd()
    var v = Eigen.VectorXd()
    var A0 = Eigen.ArrayXXd(0, 0)
    var v0 = Eigen.ArrayXd(0)
    A = A0
    v = v0

def test_reference[MatrixType: type](m: MatrixType):
    type Scalar = MatrixType.Scalar
    alias Flag = MatrixType.IsRowMajor ? Eigen.RowMajor : Eigen.ColMajor
    alias TransposeFlag = not MatrixType.IsRowMajor ? Eigen.RowMajor : Eigen.ColMajor
    let rows = m.rows()
    let cols = m.cols()
    type MatrixX = Eigen.Matrix[Scalar, Eigen.Dynamic, Eigen.Dynamic, Flag]
    type MatrixXT = Eigen.Matrix[Scalar, Eigen.Dynamic, Eigen.Dynamic, TransposeFlag]
    type Ref = Eigen.Ref[const MatrixX]
    type RefT = Eigen.Ref[const MatrixXT]
    let r1 = Ref(m)
    let r2 = Ref(m.block(rows // 3, cols // 4, rows // 2, cols // 2))
    let r3 = RefT(m.transpose())
    let r4 = RefT(m.topLeftCorner(rows // 2, cols // 2).transpose())
    VERIFY_RAISES_ASSERT(fn() => { var r5 = RefT(m) })
    VERIFY_RAISES_ASSERT(fn() => { var r6 = Ref(m.transpose()) })
    VERIFY_RAISES_ASSERT(fn() => { var r7 = Ref(Scalar(2) * m) })
    let r8 = Ref(r1)
    let r9 = RefT(r3)
    var r10 = Eigen.Ref[const MatrixX, Unaligned, Stride[Dynamic, Dynamic]](r8)
    var r11 = Eigen.Ref[const MatrixX, Unaligned, Stride[Dynamic, Dynamic]](m)
    type RefAligned = Eigen.Ref[const MatrixX, Aligned]
    VERIFY_RAISES_ASSERT(fn() => { var r12 = RefAligned(r10) })
    VERIFY_RAISES_ASSERT(fn() => { var r13 = Ref(r10) })  # r10 has more dynamic strides

def test_nomalloc():
    var M1 = MatrixXd.Random(3, 3)
    var R1 = Ref[const MatrixXd](2.0 * M1)  # Ref requires temporary
    internal.set_is_malloc_allowed(False)
    VERIFY_RAISES_ASSERT(fn() => { var dummy = MatrixXd(MatrixXd.Random(3, 3)) })
    CALL_SUBTEST_1(fn() => nomalloc[Matrix[float32, 1, 1]](Matrix[float32, 1, 1]()))
    CALL_SUBTEST_2(fn() => nomalloc[Matrix4d](Matrix4d()))
    CALL_SUBTEST_3(fn() => nomalloc[Matrix[float32, 32, 32]](Matrix[float32, 32, 32]()))
    CALL_SUBTEST_4(fn() => ctms_decompositions[float32]())
    CALL_SUBTEST_5(fn() => test_zerosized())
    CALL_SUBTEST_6(fn() => test_reference[Matrix[float32, 32, 32]](Matrix[float32, 32, 32]()))
    CALL_SUBTEST_7(fn() => test_reference[const MatrixXd](R1))
    CALL_SUBTEST_8(fn() => { var R2 = Ref[MatrixXd](M1.topRows[2]()); test_reference(R2) })