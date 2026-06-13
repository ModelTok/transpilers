from Eigen import Tensor, RowMajor

def VERIFY_IS_APPROX(a: Float32, b: Float32):
    # approximate comparison
    assert abs(a - b) < 1e-5

def CALL_SUBTEST(f: fn() -> None):
    f()

def test_compound_assignment():
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    var mat3 = Tensor[Float32, 3](2, 3, 7)
    mat1.setRandom()
    mat2.setRandom()
    mat3 = mat1
    mat3 += mat2
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat3[i, j, k], mat1[i, j, k] + mat2[i, j, k])

def test_cxx11_tensor_lvalue():
    CALL_SUBTEST(test_compound_assignment)