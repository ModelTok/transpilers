from main import *
from Eigen.Core import *

using Eigen

def run_matrix_tests[Scalar: AnyType, Storage: Int]():
    alias MatrixType = Matrix[Scalar, Eigen.Dynamic, Eigen.Dynamic, Storage]
    var m: MatrixType
    var n: MatrixType
    m = n = MatrixType.Random(50,50)
    m.conservativeResize(1,50)
    VERIFY_IS_APPROX(m, n.block(0,0,1,50))
    m = n = MatrixType.Random(50,50)
    m.conservativeResize(50,1)
    VERIFY_IS_APPROX(m, n.block(0,0,50,1))
    m = n = MatrixType.Random(50,50)
    m.conservativeResize(50,50)
    VERIFY_IS_APPROX(m, n.block(0,0,50,50))
    for i in range(0, 25):
        var rows: Index = internal.random[Index](1,50)
        var cols: Index = internal.random[Index](1,50)
        m = n = MatrixType.Random(50,50)
        m.conservativeResize(rows,cols)
        VERIFY_IS_APPROX(m, n.block(0,0,rows,cols))
    for i in range(0, 25):
        var rows: Index = internal.random[Index](50,75)
        var cols: Index = internal.random[Index](50,75)
        m = n = MatrixType.Random(50,50)
        m.conservativeResizeLike(MatrixType.Zero(rows,cols))
        VERIFY_IS_APPROX(m.block(0,0,n.rows(),n.cols()), n)
        VERIFY( rows<=50 or m.block(50,0,rows-50,cols).sum() == Scalar(0) )
        VERIFY( cols<=50 or m.block(0,50,rows,cols-50).sum() == Scalar(0) )

def run_vector_tests[Scalar: AnyType]():
    alias VectorType = Matrix[Scalar, 1, Eigen.Dynamic]
    var m: VectorType
    var n: VectorType
    m = n = VectorType.Random(50)
    m.conservativeResize(1)
    VERIFY_IS_APPROX(m, n.segment(0,1))
    m = n = VectorType.Random(50)
    m.conservativeResize(50)
    VERIFY_IS_APPROX(m, n.segment(0,50))
    m = n = VectorType.Random(50)
    m.conservativeResize(m.rows(),1)
    VERIFY_IS_APPROX(m, n.segment(0,1))
    m = n = VectorType.Random(50)
    m.conservativeResize(m.rows(),50)
    VERIFY_IS_APPROX(m, n.segment(0,50))
    for i in range(0, 50):
        var size: Int = internal.random[Int](1,50)
        m = n = VectorType.Random(50)
        m.conservativeResize(size)
        VERIFY_IS_APPROX(m, n.segment(0,size))
        m = n = VectorType.Random(50)
        m.conservativeResize(m.rows(), size)
        VERIFY_IS_APPROX(m, n.segment(0,size))
    for i in range(0, 50):
        var size: Int = internal.random[Int](50,100)
        m = n = VectorType.Random(50)
        m.conservativeResizeLike(VectorType.Zero(size))
        VERIFY_IS_APPROX(m.segment(0,50), n)
        VERIFY( size<=50 or m.segment(50,size-50).sum() == Scalar(0) )
        m = n = VectorType.Random(50)
        m.conservativeResizeLike(Matrix[Scalar,Dynamic,Dynamic].Zero(1,size))
        VERIFY_IS_APPROX(m.segment(0,50), n)
        VERIFY( size<=50 or m.segment(50,size-50).sum() == Scalar(0) )

def test_conservative_resize():
    for i in range(0, g_repeat):
        CALL_SUBTEST_1((run_matrix_tests[Int, Eigen.RowMajor]()))
        CALL_SUBTEST_1((run_matrix_tests[Int, Eigen.ColMajor]()))
        CALL_SUBTEST_2((run_matrix_tests[Float32, Eigen.RowMajor]()))
        CALL_SUBTEST_2((run_matrix_tests[Float32, Eigen.ColMajor]()))
        CALL_SUBTEST_3((run_matrix_tests[Float64, Eigen.RowMajor]()))
        CALL_SUBTEST_3((run_matrix_tests[Float64, Eigen.ColMajor]()))
        CALL_SUBTEST_4((run_matrix_tests[Complex[Float32], Eigen.RowMajor]()))
        CALL_SUBTEST_4((run_matrix_tests[Complex[Float32], Eigen.ColMajor]()))
        CALL_SUBTEST_5((run_matrix_tests[Complex[Float64], Eigen.RowMajor]()))
        CALL_SUBTEST_6((run_matrix_tests[Complex[Float64], Eigen.ColMajor]()))
        CALL_SUBTEST_1((run_vector_tests[Int]()))
        CALL_SUBTEST_2((run_vector_tests[Float32]()))
        CALL_SUBTEST_3((run_vector_tests[Float64]()))
        CALL_SUBTEST_4((run_vector_tests[Complex[Float32]]()))
        CALL_SUBTEST_5((run_vector_tests[Complex[Float64]]()))