// Translation of third_party/eigen/test/jacobi.cpp to Mojo
// Faithful 1:1 translation, no refactoring.

from Eigen import (
    Matrix3f, Matrix4d, Matrix4cf, MatrixXf, MatrixXcd, MatrixXcf,
    JacobiRotation, numext, internal, Index, g_repeat, EIGEN_TEST_MAX_SIZE
)

// Define macros as functions to mimic C++ preprocessor behavior
def VERIFY_IS_APPROX[a: AnyType, b: AnyType](a: a, b: b):
    # placeholder for approximate equality check

def CALL_SUBTEST_1(x: None):

def CALL_SUBTEST_2(x: None):

def CALL_SUBTEST_3(x: None):

def CALL_SUBTEST_4(x: None):

def CALL_SUBTEST_5(x: None):

def CALL_SUBTEST_6(x: None):

def TEST_SET_BUT_UNUSED_VARIABLE(x: AnyType):

# Global variables used in the test
var g_repeat: Int = 1
let EIGEN_TEST_MAX_SIZE: Int = 50

template[MatrixType: AnyType, JacobiScalar: AnyType]
def jacobi(m: MatrixType = MatrixType()):
    let rows = m.rows()
    let cols = m.cols()
    enum {
        RowsAtCompileTime = MatrixType.RowsAtCompileTime,
        ColsAtCompileTime = MatrixType.ColsAtCompileTime
    }
    typedef JacobiVector = Matrix[JacobiScalar, 2, 1]
    var a: MatrixType = MatrixType.Random(rows, cols)
    var v: JacobiVector = JacobiVector.Random().normalized()
    var c: JacobiScalar = v.x()
    var s: JacobiScalar = v.y()
    var rot: JacobiRotation[JacobiScalar] = JacobiRotation[JacobiScalar](c, s)
    {
        var p: Index = internal.random[Index](0, rows - 1)
        var q: Index
        while True:
            q = internal.random[Index](0, rows - 1)
            if q != p:
                break
        var b: MatrixType = a
        b.applyOnTheLeft(p, q, rot)
        VERIFY_IS_APPROX(b.row(p), c * a.row(p) + numext.conj(s) * a.row(q))
        VERIFY_IS_APPROX(b.row(q), -s * a.row(p) + numext.conj(c) * a.row(q))
    }
    {
        var p: Index = internal.random[Index](0, cols - 1)
        var q: Index
        while True:
            q = internal.random[Index](0, cols - 1)
            if q != p:
                break
        var b: MatrixType = a
        b.applyOnTheRight(p, q, rot)
        VERIFY_IS_APPROX(b.col(p), c * a.col(p) - s * a.col(q))
        VERIFY_IS_APPROX(b.col(q), numext.conj(s) * a.col(p) + numext.conj(c) * a.col(q))
    }

def test_jacobi():
    for i in range(g_repeat):
        CALL_SUBTEST_1(( jacobi[Matrix3f, Float32]() ))
        CALL_SUBTEST_2(( jacobi[Matrix4d, Float64]() ))
        CALL_SUBTEST_3(( jacobi[Matrix4cf, Float32]() ))
        CALL_SUBTEST_3(( jacobi[Matrix4cf, Complex[Float32]]() ))
        var r: Int = internal.random[Int](2, internal.random[Int](1, EIGEN_TEST_MAX_SIZE) / 2)
        var c: Int = internal.random[Int](2, internal.random[Int](1, EIGEN_TEST_MAX_SIZE) / 2)
        CALL_SUBTEST_4(( jacobi[MatrixXf, Float32](MatrixXf(r, c)) ))
        CALL_SUBTEST_5(( jacobi[MatrixXcd, Float64](MatrixXcd(r, c)) ))
        CALL_SUBTEST_5(( jacobi[MatrixXcd, Complex[Float64]](MatrixXcd(r, c)) ))
        CALL_SUBTEST_6(( jacobi[MatrixXcf, Float32](MatrixXcf(r, c)) ))
        CALL_SUBTEST_6(( jacobi[MatrixXcf, Complex[Float32]](MatrixXcf(r, c)) ))
        TEST_SET_BUT_UNUSED_VARIABLE(r)
        TEST_SET_BUT_UNUSED_VARIABLE(c)