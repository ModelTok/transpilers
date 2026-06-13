// This file is a faithful 1:1 translation of the C++ test file "redux.cpp" to Mojo.
// No refactoring has been performed; all names, logic, and comments are preserved.

alias TEST_ENABLE_TEMPORARY_TRACKING = True
alias EIGEN_CACHEFRIENDLY_PRODUCT_THRESHOLD = 8

from main import *  // provides test macros and Eigen-like types

def matrixRedux[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m1_for_prod: MatrixType = MatrixType.Ones(rows, cols) + RealScalar(0.2) * m1
    VERIFY_IS_MUCH_SMALLER_THAN(MatrixType.Zero(rows, cols).sum(), Scalar(1))
    // the float() here to shut up excessive MSVC warning about int->complex conversion being lossy
    VERIFY_IS_APPROX(MatrixType.Ones(rows, cols).sum(), Scalar(float(rows*cols)))
    var s: Scalar = Scalar(0)
    var p: Scalar = Scalar(1)
    var minc: RealScalar = numext.real(m1.coeff(0))
    var maxc: RealScalar = numext.real(m1.coeff(0))
    for j in range(cols):
        for i in range(rows):
            s += m1(i,j)
            p *= m1_for_prod(i,j)
            minc = min(numext.real(minc), numext.real(m1(i,j)))
            maxc = max(numext.real(maxc), numext.real(m1(i,j)))
    var mean: Scalar = s / Scalar(RealScalar(rows*cols))
    VERIFY_IS_APPROX(m1.sum(), s)
    VERIFY_IS_APPROX(m1.mean(), mean)
    VERIFY_IS_APPROX(m1_for_prod.prod(), p)
    VERIFY_IS_APPROX(m1.real().minCoeff(), numext.real(minc))
    VERIFY_IS_APPROX(m1.real().maxCoeff(), numext.real(maxc))
    var r0: Int = internal.random[Int](0, rows-1)
    var c0: Int = internal.random[Int](0, cols-1)
    var r1: Int = internal.random[Int](r0+1, rows) - r0
    var c1: Int = internal.random[Int](c0+1, cols) - c0
    VERIFY_IS_APPROX(m1.block(r0,c0,r1,c1).sum(), m1.block(r0,c0,r1,c1).eval().sum())
    VERIFY_IS_APPROX(m1.block(r0,c0,r1,c1).mean(), m1.block(r0,c0,r1,c1).eval().mean())
    VERIFY_IS_APPROX(m1_for_prod.block(r0,c0,r1,c1).prod(), m1_for_prod.block(r0,c0,r1,c1).eval().prod())
    VERIFY_IS_APPROX(m1.block(r0,c0,r1,c1).real().minCoeff(), m1.block(r0,c0,r1,c1).real().eval().minCoeff())
    VERIFY_IS_APPROX(m1.block(r0,c0,r1,c1).real().maxCoeff(), m1.block(r0,c0,r1,c1).real().eval().maxCoeff())
    const R1: Int = MatrixType.RowsAtCompileTime >= 2 ? MatrixType.RowsAtCompileTime / 2 : 6
    const C1: Int = MatrixType.ColsAtCompileTime >= 2 ? MatrixType.ColsAtCompileTime / 2 : 6
    if R1 <= rows - r0 and C1 <= cols - c0:
        VERIFY_IS_APPROX( (m1.template block[R1,C1](r0,c0).sum()), m1.block(r0,c0,R1,C1).sum() )
    VERIFY_IS_APPROX(m1.block(r0,c0,0,0).sum(), Scalar(0))
    VERIFY_IS_APPROX(m1.block(r0,c0,0,0).prod(), Scalar(1))
    VERIFY_EVALUATION_COUNT( (m1.matrix()*m1.matrix().transpose()).sum(), (MatrixType.IsVectorAtCompileTime and MatrixType.SizeAtCompileTime != 1 ? 0 : 1) )
    var m2: Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime](rows, rows)
    m2.setRandom()
    VERIFY_EVALUATION_COUNT( ((m1.matrix()*m1.matrix().transpose()) + m2).sum(), (MatrixType.IsVectorAtCompileTime and MatrixType.SizeAtCompileTime != 1 ? 0 : 1) )

def vectorRedux[VectorType: AnyType](w: VectorType):
    using std.abs  // keep the using for clarity; in Mojo we use `abs` directly
    alias Scalar = VectorType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    var size: Int = w.size()
    var v: VectorType = VectorType.Random(size)
    // see comment above declaration of m1_for_prod
    var v_for_prod: VectorType = VectorType.Ones(size) + Scalar(0.2) * v
    for i in range(1, size):
        var s: Scalar = Scalar(0)
        var p: Scalar = Scalar(1)
        var minc: RealScalar = numext.real(v.coeff(0))
        var maxc: RealScalar = numext.real(v.coeff(0))
        for j in range(i):
            s += v[j]
            p *= v_for_prod[j]
            minc = min(minc, numext.real(v[j]))
            maxc = max(maxc, numext.real(v[j]))
        VERIFY_IS_MUCH_SMALLER_THAN(abs(s - v.head(i).sum()), Scalar(1))
        VERIFY_IS_APPROX(p, v_for_prod.head(i).prod())
        VERIFY_IS_APPROX(minc, v.real().head(i).minCoeff())
        VERIFY_IS_APPROX(maxc, v.real().head(i).maxCoeff())
    for i in range(size-1):
        var s: Scalar = Scalar(0)
        var p: Scalar = Scalar(1)
        var minc: RealScalar = numext.real(v.coeff(i))
        var maxc: RealScalar = numext.real(v.coeff(i))
        for j in range(i, size):
            s += v[j]
            p *= v_for_prod[j]
            minc = min(minc, numext.real(v[j]))
            maxc = max(maxc, numext.real(v[j]))
        VERIFY_IS_MUCH_SMALLER_THAN(abs(s - v.tail(size-i).sum()), Scalar(1))
        VERIFY_IS_APPROX(p, v_for_prod.tail(size-i).prod())
        VERIFY_IS_APPROX(minc, v.real().tail(size-i).minCoeff())
        VERIFY_IS_APPROX(maxc, v.real().tail(size-i).maxCoeff())
    for i in range(size/2):
        var s: Scalar = Scalar(0)
        var p: Scalar = Scalar(1)
        var minc: RealScalar = numext.real(v.coeff(i))
        var maxc: RealScalar = numext.real(v.coeff(i))
        for j in range(i, size-i):
            s += v[j]
            p *= v_for_prod[j]
            minc = min(minc, numext.real(v[j]))
            maxc = max(maxc, numext.real(v[j]))
        VERIFY_IS_MUCH_SMALLER_THAN(abs(s - v.segment(i, size-2*i).sum()), Scalar(1))
        VERIFY_IS_APPROX(p, v_for_prod.segment(i, size-2*i).prod())
        VERIFY_IS_APPROX(minc, v.real().segment(i, size-2*i).minCoeff())
        VERIFY_IS_APPROX(maxc, v.real().segment(i, size-2*i).maxCoeff())
    VERIFY_IS_APPROX(v.head(0).sum(), Scalar(0))
    VERIFY_IS_APPROX(v.tail(0).prod(), Scalar(1))
    VERIFY_RAISES_ASSERT(v.head(0).mean())
    VERIFY_RAISES_ASSERT(v.head(0).minCoeff())
    VERIFY_RAISES_ASSERT(v.head(0).maxCoeff())

def test_redux():
    var maxsize: Int = min(100, EIGEN_TEST_MAX_SIZE)
    TEST_SET_BUT_UNUSED_VARIABLE(maxsize)
    for i in range(g_repeat):
        CALL_SUBTEST_1( matrixRedux(Matrix[float32, 1, 1]()) )
        CALL_SUBTEST_1( matrixRedux(Array[float32, 1, 1]()) )
        CALL_SUBTEST_2( matrixRedux(Matrix2f()) )
        CALL_SUBTEST_2( matrixRedux(Array2f()) )
        CALL_SUBTEST_2( matrixRedux(Array22f()) )
        CALL_SUBTEST_3( matrixRedux(Matrix4d()) )
        CALL_SUBTEST_3( matrixRedux(Array4d()) )
        CALL_SUBTEST_3( matrixRedux(Array44d()) )
        CALL_SUBTEST_4( matrixRedux(MatrixXcf(internal.random[Int](1,maxsize), internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_4( matrixRedux(ArrayXXcf(internal.random[Int](1,maxsize), internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_5( matrixRedux(MatrixXd(internal.random[Int](1,maxsize), internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_5( matrixRedux(ArrayXXd(internal.random[Int](1,maxsize), internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_6( matrixRedux(MatrixXi(internal.random[Int](1,maxsize), internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_6( matrixRedux(ArrayXXi(internal.random[Int](1,maxsize), internal.random[Int](1,maxsize))) )
    for i in range(g_repeat):
        CALL_SUBTEST_7( vectorRedux(Vector4f()) )
        CALL_SUBTEST_7( vectorRedux(Array4f()) )
        CALL_SUBTEST_5( vectorRedux(VectorXd(internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_5( vectorRedux(ArrayXd(internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_8( vectorRedux(VectorXf(internal.random[Int](1,maxsize))) )
        CALL_SUBTEST_8( vectorRedux(ArrayXf(internal.random[Int](1,maxsize))) )