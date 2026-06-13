from Eigen import Tensor, DimPair, DefaultDevice, TensorEvaluator, array, Map, Matrix, internal
from Eigen import ColMajor, RowMajor  # assume these are defined as 0 and 1

# Use Float32 for float
alias Float = Float32

# Define test macros as functions
def VERIFY_IS_EQUAL(a: Int, b: Int):
    assert a == b, "VERIFY_IS_EQUAL failed"

def VERIFY_IS_APPROX(a: Float, b: Float):
    assert abs(a - b) < 1e-6, "VERIFY_IS_APPROX failed"

def VERIFY_IS_APPROX(a: Float64, b: Float64):
    assert abs(a - b) < 1e-12, "VERIFY_IS_APPROX failed"

# For matrix comparison
def VERIFY(a: Bool):
    assert a, "VERIFY failed"

# Static assert: use compile-time check (if possible)
def EIGEN_STATIC_ASSERT(condition: Bool, message: String):
    assert condition, message

# CALL_SUBTEST: just call the function
def CALL_SUBTEST(f: fn() -> None):
    f()

# setCpuCacheSizes: stub
def setCpuCacheSizes(a: Int, b: Int, c: Int):

# Dummy value for Dynamic
alias Dynamic = 0  # Not used in Mojo but keep name

def test_evals[DataLayout: Int]():
    var mat1 = Tensor[Float, 2, DataLayout](2, 3)
    var mat2 = Tensor[Float, 2, DataLayout](2, 3)
    var mat3 = Tensor[Float, 2, DataLayout](3, 2)
    mat1.setRandom()
    mat2.setRandom()
    mat3.setRandom()
    var mat4 = Tensor[Float, 2, DataLayout](3, 3)
    mat4.setZero()
    var dims3 = array[DimPair, 1](DimPair(0, 0))
    type Evaluator = TensorEvaluator[typeof(mat1.contract(mat2, dims3)), DefaultDevice]
    var eval = Evaluator(mat1.contract(mat2, dims3), DefaultDevice())
    eval.evalTo(mat4.data())
    EIGEN_STATIC_ASSERT(Evaluator.NumDims == 2, "YOU_MADE_A_PROGRAMMING_MISTAKE")
    VERIFY_IS_EQUAL(eval.dimensions()[0], 3)
    VERIFY_IS_EQUAL(eval.dimensions()[1], 3)
    VERIFY_IS_APPROX(mat4(0,0), mat1(0,0)*mat2(0,0) + mat1(1,0)*mat2(1,0))
    VERIFY_IS_APPROX(mat4(0,1), mat1(0,0)*mat2(0,1) + mat1(1,0)*mat2(1,1))
    VERIFY_IS_APPROX(mat4(0,2), mat1(0,0)*mat2(0,2) + mat1(1,0)*mat2(1,2))
    VERIFY_IS_APPROX(mat4(1,0), mat1(0,1)*mat2(0,0) + mat1(1,1)*mat2(1,0))
    VERIFY_IS_APPROX(mat4(1,1), mat1(0,1)*mat2(0,1) + mat1(1,1)*mat2(1,1))
    VERIFY_IS_APPROX(mat4(1,2), mat1(0,1)*mat2(0,2) + mat1(1,1)*mat2(1,2))
    VERIFY_IS_APPROX(mat4(2,0), mat1(0,2)*mat2(0,0) + mat1(1,2)*mat2(1,0))
    VERIFY_IS_APPROX(mat4(2,1), mat1(0,2)*mat2(0,1) + mat1(1,2)*mat2(1,1))
    VERIFY_IS_APPROX(mat4(2,2), mat1(0,2)*mat2(0,2) + mat1(1,2)*mat2(1,2))
    var mat5 = Tensor[Float, 2, DataLayout](2, 2)
    mat5.setZero()
    var dims4 = array[DimPair, 1](DimPair(1, 1))
    type Evaluator2 = TensorEvaluator[typeof(mat1.contract(mat2, dims4)), DefaultDevice]
    var eval2 = Evaluator2(mat1.contract(mat2, dims4), DefaultDevice())
    eval2.evalTo(mat5.data())
    EIGEN_STATIC_ASSERT(Evaluator2.NumDims == 2, "YOU_MADE_A_PROGRAMMING_MISTAKE")
    VERIFY_IS_EQUAL(eval2.dimensions()[0], 2)
    VERIFY_IS_EQUAL(eval2.dimensions()[1], 2)
    VERIFY_IS_APPROX(mat5(0,0), mat1(0,0)*mat2(0,0) + mat1(0,1)*mat2(0,1) + mat1(0,2)*mat2(0,2))
    VERIFY_IS_APPROX(mat5(0,1), mat1(0,0)*mat2(1,0) + mat1(0,1)*mat2(1,1) + mat1(0,2)*mat2(1,2))
    VERIFY_IS_APPROX(mat5(1,0), mat1(1,0)*mat2(0,0) + mat1(1,1)*mat2(0,1) + mat1(1,2)*mat2(0,2))
    VERIFY_IS_APPROX(mat5(1,1), mat1(1,0)*mat2(1,0) + mat1(1,1)*mat2(1,1) + mat1(1,2)*mat2(1,2))
    var mat6 = Tensor[Float, 2, DataLayout](2, 2)
    mat6.setZero()
    var dims6 = array[DimPair, 1](DimPair(1, 0))
    type Evaluator3 = TensorEvaluator[typeof(mat1.contract(mat3, dims6)), DefaultDevice]
    var eval3 = Evaluator3(mat1.contract(mat3, dims6), DefaultDevice())
    eval3.evalTo(mat6.data())
    EIGEN_STATIC_ASSERT(Evaluator3.NumDims == 2, "YOU_MADE_A_PROGRAMMING_MISTAKE")
    VERIFY_IS_EQUAL(eval3.dimensions()[0], 2)
    VERIFY_IS_EQUAL(eval3.dimensions()[1], 2)
    VERIFY_IS_APPROX(mat6(0,0), mat1(0,0)*mat3(0,0) + mat1(0,1)*mat3(1,0) + mat1(0,2)*mat3(2,0))
    VERIFY_IS_APPROX(mat6(0,1), mat1(0,0)*mat3(0,1) + mat1(0,1)*mat3(1,1) + mat1(0,2)*mat3(2,1))
    VERIFY_IS_APPROX(mat6(1,0), mat1(1,0)*mat3(0,0) + mat1(1,1)*mat3(1,0) + mat1(1,2)*mat3(2,0))
    VERIFY_IS_APPROX(mat6(1,1), mat1(1,0)*mat3(0,1) + mat1(1,1)*mat3(1,1) + mat1(1,2)*mat3(2,1))

def test_scalar[DataLayout: Int]():
    var vec1 = Tensor[Float, 1, DataLayout](6)
    var vec2 = Tensor[Float, 1, DataLayout](6)
    vec1.setRandom()
    vec2.setRandom()
    var dims = array[DimPair, 1](DimPair(0, 0))
    var scalar = vec1.contract(vec2, dims)
    var expected: Float = 0.0
    for i in range(6):
        expected += vec1(i) * vec2(i)
    VERIFY_IS_APPROX(scalar(), expected)

def test_multidims[DataLayout: Int]():
    var mat1 = Tensor[Float, 3, DataLayout](2, 2, 2)
    var mat2 = Tensor[Float, 4, DataLayout](2, 2, 2, 2)
    mat1.setRandom()
    mat2.setRandom()
    var mat3 = Tensor[Float, 3, DataLayout](2, 2, 2)
    mat3.setZero()
    var dims = array[DimPair, 2](DimPair(1, 2), DimPair(2, 3))
    type Evaluator = TensorEvaluator[typeof(mat1.contract(mat2, dims)), DefaultDevice]
    var eval = Evaluator(mat1.contract(mat2, dims), DefaultDevice())
    eval.evalTo(mat3.data())
    EIGEN_STATIC_ASSERT(Evaluator.NumDims == 3, "YOU_MADE_A_PROGRAMMING_MISTAKE")
    VERIFY_IS_EQUAL(eval.dimensions()[0], 2)
    VERIFY_IS_EQUAL(eval.dimensions()[1], 2)
    VERIFY_IS_EQUAL(eval.dimensions()[2], 2)
    VERIFY_IS_APPROX(mat3(0,0,0), mat1(0,0,0)*mat2(0,0,0,0) + mat1(0,1,0)*mat2(0,0,1,0) +
                                mat1(0,0,1)*mat2(0,0,0,1) + mat1(0,1,1)*mat2(0,0,1,1))
    VERIFY_IS_APPROX(mat3(0,0,1), mat1(0,0,0)*mat2(0,1,0,0) + mat1(0,1,0)*mat2(0,1,1,0) +
                                mat1(0,0,1)*mat2(0,1,0,1) + mat1(0,1,1)*mat2(0,1,1,1))
    VERIFY_IS_APPROX(mat3(0,1,0), mat1(0,0,0)*mat2(1,0,0,0) + mat1(0,1,0)*mat2(1,0,1,0) +
                                mat1(0,0,1)*mat2(1,0,0,1) + mat1(0,1,1)*mat2(1,0,1,1))
    VERIFY_IS_APPROX(mat3(0,1,1), mat1(0,0,0)*mat2(1,1,0,0) + mat1(0,1,0)*mat2(1,1,1,0) +
                                mat1(0,0,1)*mat2(1,1,0,1) + mat1(0,1,1)*mat2(1,1,1,1))
    VERIFY_IS_APPROX(mat3(1,0,0), mat1(1,0,0)*mat2(0,0,0,0) + mat1(1,1,0)*mat2(0,0,1,0) +
                                mat1(1,0,1)*mat2(0,0,0,1) + mat1(1,1,1)*mat2(0,0,1,1))
    VERIFY_IS_APPROX(mat3(1,0,1), mat1(1,0,0)*mat2(0,1,0,0) + mat1(1,1,0)*mat2(0,1,1,0) +
                                mat1(1,0,1)*mat2(0,1,0,1) + mat1(1,1,1)*mat2(0,1,1,1))
    VERIFY_IS_APPROX(mat3(1,1,0), mat1(1,0,0)*mat2(1,0,0,0) + mat1(1,1,0)*mat2(1,0,1,0) +
                                mat1(1,0,1)*mat2(1,0,0,1) + mat1(1,1,1)*mat2(1,0,1,1))
    VERIFY_IS_APPROX(mat3(1,1,1), mat1(1,0,0)*mat2(1,1,0,0) + mat1(1,1,0)*mat2(1,1,1,0) +
                                mat1(1,0,1)*mat2(1,1,0,1) + mat1(1,1,1)*mat2(1,1,1,1))
    var mat4 = Tensor[Float, 2, DataLayout](2, 2)
    var mat5 = Tensor[Float, 3, DataLayout](2, 2, 2)
    mat4.setRandom()
    mat5.setRandom()
    var mat6 = Tensor[Float, 1, DataLayout](2)
    mat6.setZero()
    var dims2 = array[DimPair, 2](DimPair(0, 1), DimPair(1, 0))
    type Evaluator2 = TensorEvaluator[typeof(mat4.contract(mat5, dims2)), DefaultDevice]
    var eval2 = Evaluator2(mat4.contract(mat5, dims2), DefaultDevice())
    eval2.evalTo(mat6.data())
    EIGEN_STATIC_ASSERT(Evaluator2.NumDims == 1, "YOU_MADE_A_PROGRAMMING_MISTAKE")
    VERIFY_IS_EQUAL(eval2.dimensions()[0], 2)
    VERIFY_IS_APPROX(mat6(0), mat4(0,0)*mat5(0,0,0) + mat4(1,0)*mat5(0,1,0) +
                   mat4(0,1)*mat5(1,0,0) + mat4(1,1)*mat5(1,1,0))
    VERIFY_IS_APPROX(mat6(1), mat4(0,0)*mat5(0,0,1) + mat4(1,0)*mat5(0,1,1) +
                   mat4(0,1)*mat5(1,0,1) + mat4(1,1)*mat5(1,1,1))

def test_holes[DataLayout: Int]():
    var t1 = Tensor[Float, 4, DataLayout](2, 5, 7, 3)
    var t2 = Tensor[Float, 5, DataLayout](2, 7, 11, 13, 3)
    t1.setRandom()
    t2.setRandom()
    var dims = array[DimPair, 2](DimPair(0, 0), DimPair(3, 4))
    var result = t1.contract(t2, dims)
    VERIFY_IS_EQUAL(result.dimension(0), 5)
    VERIFY_IS_EQUAL(result.dimension(1), 7)
    VERIFY_IS_EQUAL(result.dimension(2), 7)
    VERIFY_IS_EQUAL(result.dimension(3), 11)
    VERIFY_IS_EQUAL(result.dimension(4), 13)
    for i in range(5):
        for j in range(5):
            for k in range(5):
                for l in range(5):
                    for m in range(5):
                        VERIFY_IS_APPROX(result(i, j, k, l, m),
                                        t1(0, i, j, 0) * t2(0, k, l, m, 0) +
                                        t1(1, i, j, 0) * t2(1, k, l, m, 0) +
                                        t1(0, i, j, 1) * t2(0, k, l, m, 1) +
                                        t1(1, i, j, 1) * t2(1, k, l, m, 1) +
                                        t1(0, i, j, 2) * t2(0, k, l, m, 2) +
                                        t1(1, i, j, 2) * t2(1, k, l, m, 2))

def test_full_redux[DataLayout: Int]():
    var t1 = Tensor[Float, 2, DataLayout](2, 2)
    var t2 = Tensor[Float, 3, DataLayout](2, 2, 2)
    t1.setRandom()
    t2.setRandom()
    var dims = array[DimPair, 2](DimPair(0, 0), DimPair(1, 1))
    var result = t1.contract(t2, dims)
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_APPROX(result(0), t1(0, 0) * t2(0, 0, 0) +  t1(1, 0) * t2(1, 0, 0)
                              + t1(0, 1) * t2(0, 1, 0) +  t1(1, 1) * t2(1, 1, 0))
    VERIFY_IS_APPROX(result(1), t1(0, 0) * t2(0, 0, 1) +  t1(1, 0) * t2(1, 0, 1)
                              + t1(0, 1) * t2(0, 1, 1) +  t1(1, 1) * t2(1, 1, 1))
    dims[0] = DimPair(1, 0)
    dims[1] = DimPair(2, 1)
    result = t2.contract(t1, dims)
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_APPROX(result(0), t1(0, 0) * t2(0, 0, 0) +  t1(1, 0) * t2(0, 1, 0)
                              + t1(0, 1) * t2(0, 0, 1) +  t1(1, 1) * t2(0, 1, 1))
    VERIFY_IS_APPROX(result(1), t1(0, 0) * t2(1, 0, 0) +  t1(1, 0) * t2(1, 1, 0)
                              + t1(0, 1) * t2(1, 0, 1) +  t1(1, 1) * t2(1, 1, 1))

def test_contraction_of_contraction[DataLayout: Int]():
    var t1 = Tensor[Float, 2, DataLayout](2, 2)
    var t2 = Tensor[Float, 2, DataLayout](2, 2)
    var t3 = Tensor[Float, 2, DataLayout](2, 2)
    var t4 = Tensor[Float, 2, DataLayout](2, 2)
    t1.setRandom()
    t2.setRandom()
    t3.setRandom()
    t4.setRandom()
    var dims = array[DimPair, 1](DimPair(1, 0))
    var contract1 = t1.contract(t2, dims)
    var diff = t3 - contract1
    var contract2 = t1.contract(t4, dims)
    var result = contract2.contract(diff, dims)
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_EQUAL(result.dimension(1), 2)
    var m1 = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]](t1.data(), 2, 2)
    var m2 = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]](t2.data(), 2, 2)
    var m3 = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]](t3.data(), 2, 2)
    var m4 = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]](t4.data(), 2, 2)
    var expected = (m1 * m4) * (m3 - m1 * m2)
    VERIFY_IS_APPROX(result(0, 0), expected(0, 0))
    VERIFY_IS_APPROX(result(0, 1), expected(0, 1))
    VERIFY_IS_APPROX(result(1, 0), expected(1, 0))
    VERIFY_IS_APPROX(result(1, 1), expected(1, 1))

def test_expr[DataLayout: Int]():
    var mat1 = Tensor[Float, 2, DataLayout](2, 3)
    var mat2 = Tensor[Float, 2, DataLayout](3, 2)
    mat1.setRandom()
    mat2.setRandom()
    var mat3 = Tensor[Float, 2, DataLayout](2,2)
    var dims = array[DimPair, 1](DimPair(1, 0))
    mat3 = mat1.contract(mat2, dims)
    VERIFY_IS_APPROX(mat3(0,0), mat1(0,0)*mat2(0,0) + mat1(0,1)*mat2(1,0) + mat1(0,2)*mat2(2,0))
    VERIFY_IS_APPROX(mat3(0,1), mat1(0,0)*mat2(0,1) + mat1(0,1)*mat2(1,1) + mat1(0,2)*mat2(2,1))
    VERIFY_IS_APPROX(mat3(1,0), mat1(1,0)*mat2(0,0) + mat1(1,1)*mat2(1,0) + mat1(1,2)*mat2(2,0))
    VERIFY_IS_APPROX(mat3(1,1), mat1(1,0)*mat2(0,1) + mat1(1,1)*mat2(1,1) + mat1(1,2)*mat2(2,1))

def test_out_of_order_contraction[DataLayout: Int]():
    var mat1 = Tensor[Float, 3, DataLayout](2, 2, 2)
    var mat2 = Tensor[Float, 3, DataLayout](2, 2, 2)
    mat1.setRandom()
    mat2.setRandom()
    var mat3 = Tensor[Float, 2, DataLayout](2, 2)
    var dims = array[DimPair, 2](DimPair(2, 0), DimPair(0, 2))
    mat3 = mat1.contract(mat2, dims)
    VERIFY_IS_APPROX(mat3(0, 0),
                     mat1(0,0,0)*mat2(0,0,0) + mat1(1,0,0)*mat2(0,0,1) +
                     mat1(0,0,1)*mat2(1,0,0) + mat1(1,0,1)*mat2(1,0,1))
    VERIFY_IS_APPROX(mat3(1, 0),
                     mat1(0,1,0)*mat2(0,0,0) + mat1(1,1,0)*mat2(0,0,1) +
                     mat1(0,1,1)*mat2(1,0,0) + mat1(1,1,1)*mat2(1,0,1))
    VERIFY_IS_APPROX(mat3(0, 1),
                     mat1(0,0,0)*mat2(0,1,0) + mat1(1,0,0)*mat2(0,1,1) +
                     mat1(0,0,1)*mat2(1,1,0) + mat1(1,0,1)*mat2(1,1,1))
    VERIFY_IS_APPROX(mat3(1, 1),
                     mat1(0,1,0)*mat2(0,1,0) + mat1(1,1,0)*mat2(0,1,1) +
                     mat1(0,1,1)*mat2(1,1,0) + mat1(1,1,1)*mat2(1,1,1))
    var dims2 = array[DimPair, 2](DimPair(0, 2), DimPair(2, 0))
    mat3 = mat1.contract(mat2, dims2)
    VERIFY_IS_APPROX(mat3(0, 0),
                     mat1(0,0,0)*mat2(0,0,0) + mat1(1,0,0)*mat2(0,0,1) +
                     mat1(0,0,1)*mat2(1,0,0) + mat1(1,0,1)*mat2(1,0,1))
    VERIFY_IS_APPROX(mat3(1, 0),
                     mat1(0,1,0)*mat2(0,0,0) + mat1(1,1,0)*mat2(0,0,1) +
                     mat1(0,1,1)*mat2(1,0,0) + mat1(1,1,1)*mat2(1,0,1))
    VERIFY_IS_APPROX(mat3(0, 1),
                     mat1(0,0,0)*mat2(0,1,0) + mat1(1,0,0)*mat2(0,1,1) +
                     mat1(0,0,1)*mat2(1,1,0) + mat1(1,0,1)*mat2(1,1,1))
    VERIFY_IS_APPROX(mat3(1, 1),
                     mat1(0,1,0)*mat2(0,1,0) + mat1(1,1,0)*mat2(0,1,1) +
                     mat1(0,1,1)*mat2(1,1,0) + mat1(1,1,1)*mat2(1,1,1))

def test_consistency[DataLayout: Int]():
    var mat1 = Tensor[Float, 3, DataLayout](4, 3, 5)
    var mat2 = Tensor[Float, 5, DataLayout](3, 2, 1, 5, 4)
    mat1.setRandom()
    mat2.setRandom()
    var mat3 = Tensor[Float, 4, DataLayout](5, 2, 1, 5)
    var mat4 = Tensor[Float, 4, DataLayout](2, 1, 5, 5)
    var dims1 = array[DimPair, 2](DimPair(0, 4), DimPair(1, 0))
    var dims2 = array[DimPair, 2](DimPair(4, 0), DimPair(0, 1))
    mat3 = mat1.contract(mat2, dims1)
    mat4 = mat2.contract(mat1, dims2)
    if DataLayout == ColMajor:
        for i in range(5):
            for j in range(10):
                VERIFY_IS_APPROX(mat3.data()[i + 5 * j], mat4.data()[j + 10 * i])
    else:
        for i in range(5):
            for j in range(10):
                VERIFY_IS_APPROX(mat3.data()[10 * i + j], mat4.data()[i + 5 * j])

def test_large_contraction[DataLayout: Int]():
    var t_left = Tensor[Float, 4, DataLayout](30, 50, 8, 31)
    var t_right = Tensor[Float, 5, DataLayout](8, 31, 7, 20, 10)
    var t_result = Tensor[Float, 5, DataLayout](30, 50, 7, 20, 10)
    t_left.setRandom()
    t_right.setRandom()
    t_left += t_left.constant(1.0)
    t_right += t_right.constant(1.0)
    type MapXf = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]]
    var m_left = MapXf(t_left.data(), 1500, 248)
    var m_right = MapXf(t_right.data(), 248, 1400)
    var m_result = Matrix[Float, Dynamic, Dynamic, DataLayout](1500, 1400)
    var dims = array[DimPair, 2](DimPair(2, 0), DimPair(3, 1))
    t_result = t_left.contract(t_right, dims)
    m_result = m_left * m_right
    for i in range(t_result.dimensions().TotalSize()):
        VERIFY(&t_result.data()[i] != &m_result.data()[i])
        VERIFY_IS_APPROX(t_result.data()[i], m_result.data()[i])

def test_matrix_vector[DataLayout: Int]():
    var t_left = Tensor[Float, 2, DataLayout](30, 50)
    var t_right = Tensor[Float, 1, DataLayout](50)
    var t_result = Tensor[Float, 1, DataLayout](30)
    t_left.setRandom()
    t_right.setRandom()
    type MapXf = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]]
    var m_left = MapXf(t_left.data(), 30, 50)
    var m_right = MapXf(t_right.data(), 50, 1)
    var m_result = Matrix[Float, Dynamic, Dynamic, DataLayout](30, 1)
    var dims = array[DimPair, 1](DimPair(1, 0))
    t_result = t_left.contract(t_right, dims)
    m_result = m_left * m_right
    for i in range(t_result.dimensions().TotalSize()):
        VERIFY(internal.isApprox(t_result(i), m_result(i, 0), 1))

def test_tensor_vector[DataLayout: Int]():
    var t_left = Tensor[Float, 3, DataLayout](7, 13, 17)
    var t_right = Tensor[Float, 2, DataLayout](1, 7)
    t_left.setRandom()
    t_right.setRandom()
    type DimensionPair = Tensor[Float, 1, DataLayout].DimensionPair
    var dim_pair01 = array[DimensionPair, 1](DimensionPair(0, 1))
    var t_result = t_left.contract(t_right, dim_pair01)
    type MapXf = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]]
    var m_left = MapXf(t_left.data(), 7, 13*17)
    var m_right = MapXf(t_right.data(), 1, 7)
    var m_result = m_left.transpose() * m_right.transpose()
    for i in range(t_result.dimensions().TotalSize()):
        VERIFY(internal.isApprox(t_result(i), m_result(i, 0), 1))

def test_small_blocking_factors[DataLayout: Int]():
    var t_left = Tensor[Float, 4, DataLayout](30, 5, 3, 31)
    var t_right = Tensor[Float, 5, DataLayout](3, 31, 7, 20, 1)
    t_left.setRandom()
    t_right.setRandom()
    t_left += t_left.constant(1.0)
    t_right += t_right.constant(1.0)
    setCpuCacheSizes(896, 1920, 2944)
    var dims = array[DimPair, 2](DimPair(2, 0), DimPair(3, 1))
    var t_result: Tensor[Float, 5, DataLayout]
    t_result = t_left.contract(t_right, dims)
    var m_left = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]](t_left.data(), 150, 93)
    var m_right = Map[Matrix[Float, Dynamic, Dynamic, DataLayout]](t_right.data(), 93, 140)
    var m_result = m_left * m_right
    for i in range(t_result.dimensions().TotalSize()):
        VERIFY_IS_APPROX(t_result.data()[i], m_result.data()[i])

def test_tensor_product[DataLayout: Int]():
    var mat1 = Tensor[Float, 2, DataLayout](2, 3)
    var mat2 = Tensor[Float, 2, DataLayout](4, 1)
    mat1.setRandom()
    mat2.setRandom()
    var result = mat1.contract(mat2, array[DimPair, 0]())
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_EQUAL(result.dimension(1), 3)
    VERIFY_IS_EQUAL(result.dimension(2), 4)
    VERIFY_IS_EQUAL(result.dimension(3), 1)
    for i in range(result.dimension(0)):
        for j in range(result.dimension(1)):
            for k in range(result.dimension(2)):
                for l in range(result.dimension(3)):
                    VERIFY_IS_APPROX(result(i, j, k, l), mat1(i, j) * mat2(k, l))

def test_const_inputs[DataLayout: Int]():
    var in1 = Tensor[Float, 2, DataLayout](2, 3)
    var in2 = Tensor[Float, 2, DataLayout](3, 2)
    in1.setRandom()
    in2.setRandom()
    var mat1 = TensorMap[Tensor[const Float, 2, DataLayout]](in1.data(), 2, 3)
    var mat2 = TensorMap[Tensor[const Float, 2, DataLayout]](in2.data(), 3, 2)
    var mat3 = Tensor[Float, 2, DataLayout](2,2)
    var dims = array[DimPair, 1](DimPair(1, 0))
    mat3 = mat1.contract(mat2, dims)
    VERIFY_IS_APPROX(mat3(0,0), mat1(0,0)*mat2(0,0) + mat1(0,1)*mat2(1,0) + mat1(0,2)*mat2(2,0))
    VERIFY_IS_APPROX(mat3(0,1), mat1(0,0)*mat2(0,1) + mat1(0,1)*mat2(1,1) + mat1(0,2)*mat2(2,1))
    VERIFY_IS_APPROX(mat3(1,0), mat1(1,0)*mat2(0,0) + mat1(1,1)*mat2(1,0) + mat1(1,2)*mat2(2,0))
    VERIFY_IS_APPROX(mat3(1,1), mat1(1,0)*mat2(0,1) + mat1(1,1)*mat2(1,1) + mat1(1,2)*mat2(2,1))

def test_cxx11_tensor_contraction():
    CALL_SUBTEST(test_evals[ColMajor]())
    CALL_SUBTEST(test_evals[RowMajor]())
    CALL_SUBTEST(test_scalar[ColMajor]())
    CALL_SUBTEST(test_scalar[RowMajor]())
    CALL_SUBTEST(test_multidims[ColMajor]())
    CALL_SUBTEST(test_multidims[RowMajor]())
    CALL_SUBTEST(test_holes[ColMajor]())
    CALL_SUBTEST(test_holes[RowMajor]())
    CALL_SUBTEST(test_full_redux[ColMajor]())
    CALL_SUBTEST(test_full_redux[RowMajor]())
    CALL_SUBTEST(test_contraction_of_contraction[ColMajor]())
    CALL_SUBTEST(test_contraction_of_contraction[RowMajor]())
    CALL_SUBTEST(test_expr[ColMajor]())
    CALL_SUBTEST(test_expr[RowMajor]())
    CALL_SUBTEST(test_out_of_order_contraction[ColMajor]())
    CALL_SUBTEST(test_out_of_order_contraction[RowMajor]())
    CALL_SUBTEST(test_consistency[ColMajor]())
    CALL_SUBTEST(test_consistency[RowMajor]())
    CALL_SUBTEST(test_large_contraction[ColMajor]())
    CALL_SUBTEST(test_large_contraction[RowMajor]())
    CALL_SUBTEST(test_matrix_vector[ColMajor]())
    CALL_SUBTEST(test_matrix_vector[RowMajor]())
    CALL_SUBTEST(test_tensor_vector[ColMajor]())
    CALL_SUBTEST(test_tensor_vector[RowMajor]())
    CALL_SUBTEST(test_small_blocking_factors[ColMajor]())
    CALL_SUBTEST(test_small_blocking_factors[RowMajor]())
    CALL_SUBTEST(test_tensor_product[ColMajor]())
    CALL_SUBTEST(test_tensor_product[RowMajor]())
    CALL_SUBTEST(test_const_inputs[ColMajor]())
    CALL_SUBTEST(test_const_inputs[RowMajor]())