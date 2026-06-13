from memory import memset
from tensor import Tensor
from random import rand, seed

# Simulate VERIFY_IS_EQUAL: check equality and print error if not
def VERIFY_IS_EQUAL[T: EqualityComparable](a: T, b: T) raises:
    if a != b:
        raise Error("VERIFY_IS_EQUAL failed: " + str(a) + " != " + str(b))

# Simulate CALL_SUBTEST (just call the function directly)
def CALL_SUBTEST(test_fn: fn() raises) raises:
    test_fn()

# Generate random bool (approximate)
def random_bool() -> Bool:
    return rand() % 2 == 0

# Identity function for internal::random<bool> (used in test_equality)
def internal_random_bool() -> Bool:
    return random_bool()

def test_orderings() raises:
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    var lt = Tensor[Bool, 3](2, 3, 7)
    var le = Tensor[Bool, 3](2, 3, 7)
    var gt = Tensor[Bool, 3](2, 3, 7)
    var ge = Tensor[Bool, 3](2, 3, 7)
    mat1.set_random()
    mat2.set_random()
    lt = mat1 < mat2
    le = mat1 <= mat2
    gt = mat1 > mat2
    ge = mat1 >= mat2
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(lt[i, j, k], mat1[i, j, k] < mat2[i, j, k])
                VERIFY_IS_EQUAL(le[i, j, k], mat1[i, j, k] <= mat2[i, j, k])
                VERIFY_IS_EQUAL(gt[i, j, k], mat1[i, j, k] > mat2[i, j, k])
                VERIFY_IS_EQUAL(ge[i, j, k], mat1[i, j, k] >= mat2[i, j, k])

def test_equality() raises:
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    mat1.set_random()
    mat2.set_random()
    for i in range(2):
        for j in range(3):
            for k in range(7):
                if internal_random_bool():
                    mat2[i, j, k] = mat1[i, j, k]
    var eq = Tensor[Bool, 3](2, 3, 7)
    var ne = Tensor[Bool, 3](2, 3, 7)
    eq = (mat1 == mat2)
    ne = (mat1 != mat2)
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(eq[i, j, k], mat1[i, j, k] == mat2[i, j, k])
                VERIFY_IS_EQUAL(ne[i, j, k], mat1[i, j, k] != mat2[i, j, k])

def test_cxx11_tensor_comparisons() raises:
    CALL_SUBTEST(test_orderings)
    CALL_SUBTEST(test_equality)