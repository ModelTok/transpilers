from main import CALL_SUBTEST, VERIFY, VERIFY_IS_APPROX, EIGEN_DEBUG_VAR, g_repeat
from Eigen.LU import Matrix4f, Matrix4cf, Matrix, PermutationMatrix, Vector4i, NumTraits, type_name
from algorithm import next_permutation
from sys import stderr

def inverse_permutation_4x4[MatrixType: AnyType]():
    alias Scalar = MatrixType.Scalar
    var indices = Vector4i(0, 1, 2, 3)
    for i in range(24):
        var m = PermutationMatrix[4](indices)
        var inv = m.inverse()
        var error = Float64((m * inv - MatrixType.Identity()).norm() / NumTraits[Scalar].epsilon())
        EIGEN_DEBUG_VAR(error)
        VERIFY(error == 0.0)
        next_permutation(indices.data(), indices.data() + 4)

def inverse_general_4x4[MatrixType: AnyType](repeat: Int):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    var error_sum = 0.0
    var error_max = 0.0
    for i in range(repeat):
        var m: MatrixType
        var absdet: RealScalar
        while True:
            m = MatrixType.Random()
            absdet = abs(m.determinant())
            if not (absdet < NumTraits[Scalar].epsilon()):
                break
        var inv = m.inverse()
        var error = Float64((m * inv - MatrixType.Identity()).norm() * absdet / NumTraits[Scalar].epsilon())
        error_sum += error
        error_max = max(error_max, error)
    print("inverse_general_4x4, Scalar = ", type_name[Scalar](), file=stderr)
    var error_avg = error_sum / repeat
    EIGEN_DEBUG_VAR(error_avg)
    EIGEN_DEBUG_VAR(error_max)
    VERIFY(error_avg < (8.0 if NumTraits[Scalar].IsComplex else 1.25))
    VERIFY(error_max < (64.0 if NumTraits[Scalar].IsComplex else 20.0))
    # {
    var s = 5  # internal::random<int>(4,10);
    var i = 0  # internal::random<int>(0,s-4);
    var j = 0  # internal::random<int>(0,s-4);
    var mat = Matrix[Scalar, 5, 5](s, s)
    mat.setRandom()
    var submat = mat.template block[4, 4](i, j)
    var mat_inv = mat.template block[4, 4](i, j).inverse()
    VERIFY_IS_APPROX(mat_inv, submat.inverse())
    mat.template block[4, 4](i, j) = submat.inverse()
    VERIFY_IS_APPROX(mat_inv, (mat.template block[4, 4](i, j)))
    # }

def test_prec_inverse_4x4():
    CALL_SUBTEST_1((inverse_permutation_4x4[Matrix4f]()))
    CALL_SUBTEST_1((inverse_general_4x4[Matrix4f](200000 * g_repeat)))
    CALL_SUBTEST_1((inverse_general_4x4[Matrix[Float32, 4, 4, RowMajor]](200000 * g_repeat)))
    CALL_SUBTEST_2((inverse_permutation_4x4[Matrix[Float64, 4, 4, RowMajor]]()))
    CALL_SUBTEST_2((inverse_general_4x4[Matrix[Float64, 4, 4, ColMajor]](200000 * g_repeat)))
    CALL_SUBTEST_2((inverse_general_4x4[Matrix[Float64, 4, 4, RowMajor]](200000 * g_repeat)))
    CALL_SUBTEST_3((inverse_permutation_4x4[Matrix4cf]()))
    CALL_SUBTEST_3((inverse_general_4x4[Matrix4cf](50000 * g_repeat)))