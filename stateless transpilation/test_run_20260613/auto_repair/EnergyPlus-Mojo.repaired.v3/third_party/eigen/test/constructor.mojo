from main import *
from internal import random

struct Wrapper[MatrixType: AnyType]:
    var m_mat: MatrixType

    def __init__(inout self, x: MatrixType):
        self.m_mat = x

    def __get__(self) -> MatrixType:
        return self.m_mat

    def __set__(inout self) -> MatrixType:
        return self.m_mat

def ctor_init1[MatrixType: AnyType](m: MatrixType):
    let rows = m.rows()
    let cols = m.cols()
    let m0 = MatrixType.Random(rows, cols)
    VERIFY_EVALUATION_COUNT(MatrixType(m0), 1)
    VERIFY_EVALUATION_COUNT(MatrixType(m0 + m0), 1)
    VERIFY_EVALUATION_COUNT(MatrixType(m0.block(0, 0, rows, cols)), 1)
    let wrapper = Wrapper[MatrixType](m0)
    VERIFY_EVALUATION_COUNT(MatrixType(wrapper), 1)

def test_constructor():
    for i in range(g_repeat):
        CALL_SUBTEST_1(ctor_init1[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_1(ctor_init1[Matrix4d]())
        CALL_SUBTEST_1(ctor_init1[MatrixXcf](random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE)))
        CALL_SUBTEST_1(ctor_init1[MatrixXi](random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE)))
    {
        let a = Matrix[Index, 1, 1](123)
        VERIFY_IS_EQUAL(a[0], 123)
    }
    {
        let a = Matrix[Index, 1, 1](123.0)
        VERIFY_IS_EQUAL(a[0], 123)
    }
    {
        let a = Matrix[float32, 1, 1](123)
        VERIFY_IS_EQUAL(a[0], 123.0)
    }
    {
        let a = Array[Index, 1, 1](123)
        VERIFY_IS_EQUAL(a[0], 123)
    }
    {
        let a = Array[Index, 1, 1](123.0)
        VERIFY_IS_EQUAL(a[0], 123)
    }
    {
        let a = Array[float32, 1, 1](123)
        VERIFY_IS_EQUAL(a[0], 123.0)
    }
    {
        let a = Array[Index, 3, 3](123)
        VERIFY_IS_EQUAL(a[4], 123)
    }
    {
        let a = Array[Index, 3, 3](123.0)
        VERIFY_IS_EQUAL(a[4], 123)
    }
    {
        let a = Array[float32, 3, 3](123)
        VERIFY_IS_EQUAL(a[4], 123.0)
    }