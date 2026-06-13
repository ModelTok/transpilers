from main import *
from Eigen.Eigenvalues import *

def hessenberg[Scalar: AnyType, Size: Int](size: Int = Size):
    alias MatrixType = Matrix[Scalar, Size, Size]
    for counter in range(g_repeat):
        var m = MatrixType.Random(size, size)
        var hess = HessenbergDecomposition[MatrixType](m)
        var Q = hess.matrixQ()
        var H = hess.matrixH()
        VERIFY_IS_APPROX(m, Q * H * Q.adjoint())
        for row in range(2, size):
            for col in range(0, row-1):
                VERIFY(H[row, col] == (MatrixType.Scalar)(0))
        end
    end
    var A = MatrixType.Random(size, size)
    var cs1 = HessenbergDecomposition[MatrixType]()
    cs1.compute(A)
    var cs2 = HessenbergDecomposition[MatrixType](A)
    VERIFY_IS_EQUAL(cs1.matrixH().eval(), cs2.matrixH().eval())
    var cs1Q = cs1.matrixQ()
    var cs2Q = cs2.matrixQ()
    VERIFY_IS_EQUAL(cs1Q, cs2Q)
    var hessUninitialized = HessenbergDecomposition[MatrixType]()
    VERIFY_RAISES_ASSERT(hessUninitialized.matrixH())
    VERIFY_RAISES_ASSERT(hessUninitialized.matrixQ())
    VERIFY_RAISES_ASSERT(hessUninitialized.householderCoefficients())
    VERIFY_RAISES_ASSERT(hessUninitialized.packedMatrix())
end

def test_hessenberg():
    CALL_SUBTEST_1(( hessenberg[ComplexFloat64, 1]() ))
    CALL_SUBTEST_2(( hessenberg[ComplexFloat64, 2]() ))
    CALL_SUBTEST_3(( hessenberg[ComplexFloat32, 4]() ))
    CALL_SUBTEST_4(( hessenberg[Float32, Dynamic](internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
    CALL_SUBTEST_5(( hessenberg[ComplexFloat64, Dynamic](internal.random[Int](1, EIGEN_TEST_MAX_SIZE)) ))
    CALL_SUBTEST_6(HessenbergDecomposition[MatrixXf](10))
end