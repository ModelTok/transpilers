from main import main, VERIFY, VERIFY_IS_APPROX, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor, RowMajor

def test_comparison_sugar():
    var t = Tensor[int32, 3](6, 7, 5)
    t.setRandom()
    t[0,0,0] = 0
    var b = Tensor[bool, 0]()
    #define TEST_TENSOR_EQUAL(e1, e2) \
      b = ((e1) == (e2)).all();       \
      VERIFY(b())
    #define TEST_OP(op) TEST_TENSOR_EQUAL(t op 0, t op t.constant(0))
    TEST_OP(==);
    TEST_OP(!=);
    TEST_OP(<=);
    TEST_OP(>=);
    TEST_OP(<);
    TEST_OP(>);
    #undef TEST_OP
    #undef TEST_TENSOR_EQUAL

def test_scalar_sugar_add_mul():
    var A = Tensor[float32, 3](6, 7, 5)
    var B = Tensor[float32, 3](6, 7, 5)
    A.setRandom()
    B.setRandom()
    const alpha = 0.43
    const beta = 0.21
    const gamma = 0.14
    var R = A.constant(gamma) + A * A.constant(alpha) + B * B.constant(beta)
    var S = A * alpha + B * beta + gamma
    var T = gamma + alpha * A + beta * B
    for i in range(6*7*5):
        VERIFY_IS_APPROX(R[i], S[i])
        VERIFY_IS_APPROX(R[i], T[i])

def test_scalar_sugar_sub_div():
    var A = Tensor[float32, 3](6, 7, 5)
    var B = Tensor[float32, 3](6, 7, 5)
    A.setRandom()
    B.setRandom()
    const alpha = 0.43
    const beta = 0.21
    const gamma = 0.14
    const delta = 0.32
    var R = A.constant(gamma) - A / A.constant(alpha) - B.constant(beta) / B - A.constant(delta)
    var S = gamma - A / alpha - beta / B - delta
    for i in range(6*7*5):
        VERIFY_IS_APPROX(R[i], S[i])

def test_cxx11_tensor_sugar():
    CALL_SUBTEST(test_comparison_sugar())
    CALL_SUBTEST(test_scalar_sugar_add_mul())
    CALL_SUBTEST(test_scalar_sugar_sub_div())