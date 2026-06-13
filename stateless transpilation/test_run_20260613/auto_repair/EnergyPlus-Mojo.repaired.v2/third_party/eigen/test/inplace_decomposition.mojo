from main import *
from Eigen.LU import *
from Eigen.Cholesky import *
from Eigen.QR import *

def inplace[DecType: AnyType, MatrixType: AnyType](square: Bool = False, SPD: Bool = False):
    alias Scalar = MatrixType.Scalar
    alias RhsType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias ResType = Matrix[Scalar, MatrixType.ColsAtCompileTime, 1]
    var rows: Index = MatrixType.RowsAtCompileTime if MatrixType.RowsAtCompileTime != Dynamic else internal.random[Index](2, EIGEN_TEST_MAX_SIZE // 2)
    var cols: Index = MatrixType.ColsAtCompileTime if MatrixType.ColsAtCompileTime != Dynamic else (rows if square else internal.random[Index](2, rows))
    var A: MatrixType = MatrixType.Random(rows, cols)
    var b: RhsType = RhsType.Random(rows)
    var x: ResType = ResType(cols)
    if SPD:
        assert(square)
        A.topRows(cols) = A.topRows(cols).adjoint() * A.topRows(cols)
        A.diagonal().array() += 1e-3
    var A0: MatrixType = A
    var A1: MatrixType = A
    var dec: DecType = DecType(A)
    VERIFY_IS_NOT_APPROX(A, A0)
    if rows == cols:
        VERIFY_IS_APPROX(A0 * (x = dec.solve(b)), b)
    else:
        VERIFY_IS_APPROX(A0.transpose() * A0 * (x = dec.solve(b)), A0.transpose() * b)
    A.setRandom()
    if rows == cols:
        VERIFY_IS_NOT_APPROX(A0 * (x = dec.solve(b)), b)
    else:
        VERIFY_IS_NOT_APPROX(A0.transpose() * A0 * (x = dec.solve(b)), A0.transpose() * b)
    A = A0
    dec.compute(A1)
    VERIFY_IS_EQUAL(A0, A1)
    VERIFY_IS_NOT_APPROX(A, A0)
    if rows == cols:
        VERIFY_IS_APPROX(A0 * (x = dec.solve(b)), b)
    else:
        VERIFY_IS_APPROX(A0.transpose() * A0 * (x = dec.solve(b)), A0.transpose() * b)

def test_inplace_decomposition():
    EIGEN_UNUSED alias Matrix43d = Matrix[float64, 4, 3]
    for i in range(g_repeat):
        CALL_SUBTEST_1(( inplace[LLT[Ref[MatrixXd]], MatrixXd](True, True) ))
        CALL_SUBTEST_1(( inplace[LLT[Ref[Matrix4d]], Matrix4d](True, True) ))
        CALL_SUBTEST_2(( inplace[LDLT[Ref[MatrixXd]], MatrixXd](True, True) ))
        CALL_SUBTEST_2(( inplace[LDLT[Ref[Matrix4d]], Matrix4d](True, True) ))
        CALL_SUBTEST_3(( inplace[PartialPivLU[Ref[MatrixXd]], MatrixXd](True, False) ))
        CALL_SUBTEST_3(( inplace[PartialPivLU[Ref[Matrix4d]], Matrix4d](True, False) ))
        CALL_SUBTEST_4(( inplace[FullPivLU[Ref[MatrixXd]], MatrixXd](True, False) ))
        CALL_SUBTEST_4(( inplace[FullPivLU[Ref[Matrix4d]], Matrix4d](True, False) ))
        CALL_SUBTEST_5(( inplace[HouseholderQR[Ref[MatrixXd]], MatrixXd](False, False) ))
        CALL_SUBTEST_5(( inplace[HouseholderQR[Ref[Matrix43d]], Matrix43d](False, False) ))
        CALL_SUBTEST_6(( inplace[ColPivHouseholderQR[Ref[MatrixXd]], MatrixXd](False, False) ))
        CALL_SUBTEST_6(( inplace[ColPivHouseholderQR[Ref[Matrix43d]], Matrix43d](False, False) ))
        CALL_SUBTEST_7(( inplace[FullPivHouseholderQR[Ref[MatrixXd]], MatrixXd](False, False) ))
        CALL_SUBTEST_7(( inplace[FullPivHouseholderQR[Ref[Matrix43d]], Matrix43d](False, False) ))
        CALL_SUBTEST_8(( inplace[CompleteOrthogonalDecomposition[Ref[MatrixXd]], MatrixXd](False, False) ))
        CALL_SUBTEST_8(( inplace[CompleteOrthogonalDecomposition[Ref[Matrix43d]], Matrix43d](False, False) ))