from third_party.eigen.CXX11.Tensor import Tensor, Dimensions

alias ColMajor: Int = 0
alias RowMajor: Int = 1

def VERIFY_IS_EQUAL(a: Int, b: Int):
    if a != b:
        print("FAIL: ", a, " != ", b)
        abort()

def VERIFY_RAISES_ASSERT(expr: fn() -> None):
    try:
        expr()
        print("Expected assertion but none raised")
        abort()
    except:

def test_dimension_failures[data_layout: Int]():
    var left = Tensor[Int, 3, data_layout](2, 3, 1)
    var right = Tensor[Int, 3, data_layout](3, 3, 1)
    left.setRandom()
    right.setRandom()
    var concatenation = left.concatenate(right, 0)
    VERIFY_RAISES_ASSERT(fn():
        left.concatenate(right, 1)
    )
    VERIFY_RAISES_ASSERT(fn():
        left.concatenate(right, 2)
    )
    VERIFY_RAISES_ASSERT(fn():
        left.concatenate(right, 3)
    )
    VERIFY_RAISES_ASSERT(fn():
        left.concatenate(right, -1)
    )

def test_static_dimension_failure[data_layout: Int]():
    var left = Tensor[Int, 2, data_layout](2, 3)
    var right = Tensor[Int, 3, data_layout](2, 3, 1)
    const CXX11_TENSOR_CONCATENATION_STATIC_DIMENSION_FAILURE: Bool = False
    if CXX11_TENSOR_CONCATENATION_STATIC_DIMENSION_FAILURE:
        var concatenation = left.concatenate(right, 0)
    var concatenation = left.reshape(Tensor[Int, 3].Dimensions(2, 3, 1)).concatenate(right, 0)
    var alternative = left.concatenate(right.reshape(Tensor[Int, 2].Dimensions(2, 3)), 0)

def test_simple_concatenation[data_layout: Int]():
    var left = Tensor[Int, 3, data_layout](2, 3, 1)
    var right = Tensor[Int, 3, data_layout](2, 3, 1)
    left.setRandom()
    right.setRandom()
    var concatenation = left.concatenate(right, 0)
    VERIFY_IS_EQUAL(concatenation.dimension(0), 4)
    VERIFY_IS_EQUAL(concatenation.dimension(1), 3)
    VERIFY_IS_EQUAL(concatenation.dimension(2), 1)
    for j in range(3):
        for i in range(2):
            VERIFY_IS_EQUAL(concatenation(i, j, 0), left(i, j, 0))
        for i in range(2, 4):
            VERIFY_IS_EQUAL(concatenation(i, j, 0), right(i - 2, j, 0))
    concatenation = left.concatenate(right, 1)
    VERIFY_IS_EQUAL(concatenation.dimension(0), 2)
    VERIFY_IS_EQUAL(concatenation.dimension(1), 6)
    VERIFY_IS_EQUAL(concatenation.dimension(2), 1)
    for i in range(2):
        for j in range(3):
            VERIFY_IS_EQUAL(concatenation(i, j, 0), left(i, j, 0))
        for j in range(3, 6):
            VERIFY_IS_EQUAL(concatenation(i, j, 0), right(i, j - 3, 0))
    concatenation = left.concatenate(right, 2)
    VERIFY_IS_EQUAL(concatenation.dimension(0), 2)
    VERIFY_IS_EQUAL(concatenation.dimension(1), 3)
    VERIFY_IS_EQUAL(concatenation.dimension(2), 2)
    for i in range(2):
        for j in range(3):
            VERIFY_IS_EQUAL(concatenation(i, j, 0), left(i, j, 0))
            VERIFY_IS_EQUAL(concatenation(i, j, 1), right(i, j, 0))

def test_concatenation_as_lvalue():
    var t1 = Tensor[Int, 2](2, 3)
    var t2 = Tensor[Int, 2](2, 3)
    t1.setRandom()
    t2.setRandom()
    var result = Tensor[Int, 2](4, 3)
    result.setRandom()
    t1.concatenate(t2, 0).assign(result)
    for i in range(2):
        for j in range(3):
            VERIFY_IS_EQUAL(t1(i, j), result(i, j))
            VERIFY_IS_EQUAL(t2(i, j), result(i+2, j))

def test_cxx11_tensor_concatenation():
    test_dimension_failures[ColMajor]()
    test_dimension_failures[RowMajor]()
    test_static_dimension_failure[ColMajor]()
    test_static_dimension_failure[RowMajor]()
    test_simple_concatenation[ColMajor]()
    test_simple_concatenation[RowMajor]()
    test_concatenation_as_lvalue()