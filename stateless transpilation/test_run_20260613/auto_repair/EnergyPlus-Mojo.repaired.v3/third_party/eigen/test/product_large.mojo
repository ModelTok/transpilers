from product import product
from internal import random, computeProductBlockingSizes, setCpuCacheSizes, l1CacheSize, l2CacheSize
from Matrix import Matrix, MatrixXf, MatrixXd, MatrixXi, MatrixXcf, VectorXf, VectorType
from Macros import VERIFY_IS_APPROX, VERIFY, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6
from util import g_repeat, EIGEN_TEST_MAX_SIZE, EIGEN_HAS_OPENMP

def test_aliasing[T: AnyType]():
    var rows: Int = random(1, 12)
    var cols: Int = random(1, 12)
    alias MatrixType = Matrix[T, Dynamic, Dynamic]
    alias VectorType = Matrix[T, Dynamic, 1]
    var x: VectorType = VectorType(cols)
    x.setRandom()
    var z: VectorType = VectorType(x)
    var y: VectorType = VectorType(rows)
    y.setZero()
    var A: MatrixType = MatrixType(rows, cols)
    A.setRandom()
    VERIFY_IS_APPROX(x = y + A * x, A * z)     # OK because "y + A*x" is marked as "assume-aliasing"
    x = z
    VERIFY_IS_APPROX(x = T(1.) * (A * x), A * z) # OK because 1*(A*x) is replaced by (1*A*x) which is a Product<> expression
    x = z
    x = z

def test_product_large():
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(product(MatrixXf(random(1, EIGEN_TEST_MAX_SIZE), random(1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_2(product(MatrixXd(random(1, EIGEN_TEST_MAX_SIZE), random(1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_3(product(MatrixXi(random(1, EIGEN_TEST_MAX_SIZE), random(1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_4(product(MatrixXcf(random(1, EIGEN_TEST_MAX_SIZE / 2), random(1, EIGEN_TEST_MAX_SIZE / 2))))
        CALL_SUBTEST_5(product(Matrix[float32, Dynamic, Dynamic, RowMajor](random(1, EIGEN_TEST_MAX_SIZE), random(1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_1(test_aliasing[float32]())
    #if defined EIGEN_TEST_PART_6
    {
        var N: Int = 1000000
        var v: VectorXf = VectorXf.Ones(N)
        var m: MatrixXf = MatrixXf.Ones(N, 3)
        m = (v + v).asDiagonal() * m
        VERIFY_IS_APPROX(m, MatrixXf.Constant(N, 3, 2))
    }
    {
        var a: MatrixXf = MatrixXf.Random(10, 4)
        var b: MatrixXf = MatrixXf.Random(4, 10)
        var c: MatrixXf = MatrixXf(a)
        VERIFY_IS_APPROX((a = a * b), (c * b).eval())
    }
    {
        var l1: Int = random(10000, 20000)
        var l2: Int = random(100000, 200000)
        var l3: Int = random(1000000, 2000000)
        setCpuCacheSizes(l1, l2, l3)
        VERIFY(l1 == l1CacheSize())
        VERIFY(l2 == l2CacheSize())
        var k1: Int = random(10, 100) * 16
        var m1: Int = random(10, 100) * 16
        var n1: Int = random(10, 100) * 16
        computeProductBlockingSizes[float32, float32, Int](k1, m1, n1, 1)
    }
    {
        var mat1: MatrixXf = MatrixXf(10, 32)
        mat1.setRandom()
        var mat2: MatrixXf = MatrixXf(32, 32)
        mat2.setRandom()
        var r1: MatrixXf = mat1.row(2) * mat2.transpose()
        VERIFY_IS_APPROX(r1, (mat1.row(2) * mat2.transpose()).eval())
        var r2: MatrixXf = mat1.row(2) * mat2
        VERIFY_IS_APPROX(r2, (mat1.row(2) * mat2).eval())
    }
    {
        var A: MatrixXd = MatrixXd(10, 10)
        var B: MatrixXd
        var C: MatrixXd
        A.setRandom()
        C = MatrixXd(A)
        for k in range(0, 79):
            C = C * A
        B.noalias() = (((A * A) * (A * A)) * ((A * A) * (A * A)) * ((A * A) * (A * A)) * ((A * A) * (A * A)) * ((A * A) * (A * A))) * (((A * A) * (A * A)) * ((A * A) * (A * A)) * ((A * A) * (A * A)) * ((A * A) * (A * A)) * ((A * A) * (A * A)))
        VERIFY_IS_APPROX(B, C)
    }
    #endif
    #if defined EIGEN_HAS_OPENMP
    omp_set_dynamic(1)
    for i in range(0, g_repeat):
        CALL_SUBTEST_6(product(Matrix[float32, Dynamic, Dynamic](random(1, EIGEN_TEST_MAX_SIZE), random(1, EIGEN_TEST_MAX_SIZE))))
    #endif