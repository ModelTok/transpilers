from WCECommon import SquareMatrix
from testing import expect_eq, expect_approx_eq

struct TestMatrixMultiplication:
    def SetUp(self) raises:

def Test1() raises:
    print("Begin Test: Test matrix multiplication (3 x 3).")
    let n: UInt = 3
    let a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = SquareMatrix(
        List[List[Float64]](
            List[Float64](6.0, 8.0, 5.0),
            List[Float64](3.0, 5.0, 6.0),
            List[Float64](1.0, 2.0, 3.0)
        )
    )
    var mult = a * b
    expect_eq(n, mult.size())
    let multCorrect = SquareMatrix(
        List[List[Float64]](
            List[Float64](42.0, 65.0, 65.0),
            List[Float64](76.0, 112.0, 100.0),
            List[Float64](40.0, 61.0, 59.0)
        )
    )
    for i in range(n):
        for j in range(n):
            expect_approx_eq(mult[i, j], multCorrect[i, j], 1e-6)

def Test2() raises:
    print("Begin Test: Test matrix and vector multiplication (3 x 3) and (1 x 3).")
    let n: Int = 3
    let a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = List[Float64](8.0, 4.0, 6.0)
    var mult = a * b
    expect_eq(n, mult.size())
    let multCorrect = List[Float64](98.0, 120.0, 86.0)
    for i in range(n):
        expect_approx_eq(mult[i], multCorrect[i], 1e-6)

def Test3() raises:
    print("Begin Test: Test matrix and vector multiplication (3 x 3) and (1 x 3).")
    let n: Int = 3
    let a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = List[Float64](8.0, 4.0, 6.0)
    var mult = a * b
    expect_eq(n, mult.size())
    let multCorrect1 = List[Float64](98.0, 120.0, 86.0)
    for i in range(n):
        expect_approx_eq(mult[i], multCorrect1[i], 1e-6)
    mult = b * a
    let multCorrect2 = List[Float64](88.0, 74.0, 130.0)
    for i in range(n):
        expect_approx_eq(mult[i], multCorrect2[i], 1e-6)

def Test4() raises:
    print("Begin Test: Test matrix multiplication (3 x 3).")
    let n: UInt = 3
    var a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = SquareMatrix(
        List[List[Float64]](
            List[Float64](6.0, 8.0, 5.0),
            List[Float64](3.0, 5.0, 6.0),
            List[Float64](1.0, 2.0, 3.0)
        )
    )
    a *= b
    expect_eq(n, a.size())
    let multCorrect = SquareMatrix(
        List[List[Float64]](
            List[Float64](42.0, 65.0, 65.0),
            List[Float64](76.0, 112.0, 100.0),
            List[Float64](40.0, 61.0, 59.0)
        )
    )
    for i in range(n):
        for j in range(n):
            expect_approx_eq(a[i, j], multCorrect[i, j], 1e-6)

def Test5() raises:
    print("Begin Test: Test matrix mmultRow.")
    let n: Int = 3
    var a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = List[Float64](8.0, 4.0, 6.0)
    var mult = a.mmultRows(b)
    expect_eq(n, mult.size())
    let multCorrect = SquareMatrix(
        List[List[Float64]](
            List[Float64](32.0, 12.0, 54.0),
            List[Float64](64.0, 32.0, 24.0),
            List[Float64](32.0, 12.0, 42.0)
        )
    )
    for i in range(n):
        for j in range(n):
            expect_approx_eq(mult[i, j], multCorrect[i, j], 1e-6)

def Test6() raises:
    print("Begin Test: Test matrix and vector multiplication exception.")
    let a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = List[Float64](8.0, 4.0)
    try:
        var mult = a * b
    except Error as e:
        expect_eq(str(e), "Vector and matrix do not have same size.")

def Test7() raises:
    print("Begin Test: Test matrix and vector multiplication exception.")
    let a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = List[Float64](8.0, 4.0)
    try:
        var mult = b * a
    except Error as e:
        expect_eq(str(e), "Vector and matrix do not have same size.")

def Test8() raises:
    print("Begin Test: Test matrix multiplication exception.")
    let a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = SquareMatrix(
        List[List[Float64]](
            List[Float64](6.0, 8.0),
            List[Float64](3.0, 5.0)
        )
    )
    try:
        var mult = a * b
    except Error as e:
        expect_eq(str(e), "Matrices must be identical in size.")

def TestMultRowsException() raises:
    print("Begin Test: Test matrix mmultRow exception.")
    var a = SquareMatrix(
        List[List[Float64]](
            List[Float64](4.0, 3.0, 9.0),
            List[Float64](8.0, 8.0, 4.0),
            List[Float64](4.0, 3.0, 7.0)
        )
    )
    let b = List[Float64](8.0, 4.0)
    try:
        var mult = a.mmultRows(b)
    except Error as e:
        expect_eq(str(e), "Vector and matrix do not have same size.")

def main() raises:
    let testObj = TestMatrixMultiplication()
    testObj.SetUp()
    Test1()
    Test2()
    Test3()
    Test4()
    Test5()
    Test6()
    Test7()
    Test8()
    TestMultRowsException()