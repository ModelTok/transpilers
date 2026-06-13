from main import *
from unsupported.Eigen.MatrixFunctions import *
from math import pi as EIGEN_PI

def VERIFY_IS_APPROX_ABS(a: AnyType, b: AnyType):
    VERIFY(test_isApprox_abs(a, b))

def test_isApprox_abs[Type1: AnyType, Type2: AnyType](a: Type1, b: Type2) -> Bool:
    return ((a - b).array().abs() < test_precision[Type1.RealScalar]()).all()

def randomMatrixWithRealEivals[MatrixType: AnyType](size: MatrixType.Index) -> MatrixType:
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    var diag: MatrixType = MatrixType.Zero(size, size)
    for i in range(size):
        diag[i, i] = Scalar(RealScalar(internal.random[int](0, 2))) + internal.random[Scalar]() * Scalar(RealScalar(0.01))
    var A: MatrixType = MatrixType.Random(size, size)
    var QRofA: HouseholderQR[MatrixType] = HouseholderQR[MatrixType](A)
    return QRofA.householderQ().inverse() * diag * QRofA.householderQ()

struct randomMatrixWithImagEivals[MatrixType: AnyType, IsComplex: Int = NumTraits[internal.traits[MatrixType].Scalar].IsComplex]:
    @staticmethod
    def run(size: MatrixType.Index) -> MatrixType:
        ...

@register_passable("trivial")
struct randomMatrixWithImagEivals[MatrixType: AnyType, 0]:
    @staticmethod
    def run(size: MatrixType.Index) -> MatrixType:
        alias Scalar = MatrixType.Scalar
        var diag: MatrixType = MatrixType.Zero(size, size)
        var i: Index = 0
        while i < size:
            var randomInt: Index = internal.random[Index](-1, 1)
            if randomInt == 0 or i == size - 1:
                diag[i, i] = internal.random[Scalar]() * Scalar(0.01)
                i += 1
            else:
                var alpha: Scalar = Scalar(randomInt) + internal.random[Scalar]() * Scalar(0.01)
                diag[i, i + 1] = alpha
                diag[i + 1, i] = -alpha
                i += 2
        var A: MatrixType = MatrixType.Random(size, size)
        var QRofA: HouseholderQR[MatrixType] = HouseholderQR[MatrixType](A)
        return QRofA.householderQ().inverse() * diag * QRofA.householderQ()

@register_passable("trivial")
struct randomMatrixWithImagEivals[MatrixType: AnyType, 1]:
    @staticmethod
    def run(size: MatrixType.Index) -> MatrixType:
        alias Scalar = MatrixType.Scalar
        alias RealScalar = MatrixType.RealScalar
        var imagUnit: Scalar = Scalar(0, 1)
        var diag: MatrixType = MatrixType.Zero(size, size)
        for i in range(size):
            diag[i, i] = Scalar(RealScalar(internal.random[Index](-1, 1))) * imagUnit + internal.random[Scalar]() * Scalar(RealScalar(0.01))
        var A: MatrixType = MatrixType.Random(size, size)
        var QRofA: HouseholderQR[MatrixType] = HouseholderQR[MatrixType](A)
        return QRofA.householderQ().inverse() * diag * QRofA.householderQ()

def testMatrixExponential[MatrixType: AnyType](A: MatrixType):
    alias Scalar = internal.traits[MatrixType].Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias ComplexScalar = Complex[RealScalar]
    VERIFY_IS_APPROX(A.exp(), A.matrixFunction(internal.stem_function_exp[ComplexScalar]))

def testMatrixLogarithm[MatrixType: AnyType](A: MatrixType):
    alias Scalar = internal.traits[MatrixType].Scalar
    alias RealScalar = NumTraits[Scalar].Real
    var scaledA: MatrixType
    var maxImagPartOfSpectrum: RealScalar = A.eigenvalues().imag().cwiseAbs().maxCoeff()
    if maxImagPartOfSpectrum >= RealScalar(0.9 * EIGEN_PI):
        scaledA = A * RealScalar(0.9 * EIGEN_PI) / maxImagPartOfSpectrum
    else:
        scaledA = A
    var expA: MatrixType = scaledA.exp()
    var logExpA: MatrixType = expA.log()
    VERIFY_IS_APPROX(logExpA, scaledA)

def testHyperbolicFunctions[MatrixType: AnyType](A: MatrixType):
    VERIFY_IS_APPROX_ABS(A.sinh(), (A.exp() - (-A).exp()) / 2)
    VERIFY_IS_APPROX_ABS(A.cosh(), (A.exp() + (-A).exp()) / 2)

def testGonioFunctions[MatrixType: AnyType](A: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias ComplexScalar = Complex[RealScalar]
    alias ComplexMatrix = Matrix[ComplexScalar, MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime, MatrixType.Options]
    var imagUnit: ComplexScalar = ComplexScalar(0, 1)
    var two: ComplexScalar = ComplexScalar(2, 0)
    var Ac: ComplexMatrix = A.template cast[ComplexScalar]()
    var exp_iA: ComplexMatrix = (imagUnit * Ac).exp()
    var exp_miA: ComplexMatrix = (-imagUnit * Ac).exp()
    var sinAc: ComplexMatrix = A.sin().template cast[ComplexScalar]()
    VERIFY_IS_APPROX_ABS(sinAc, (exp_iA - exp_miA) / (two * imagUnit))
    var cosAc: ComplexMatrix = A.cos().template cast[ComplexScalar]()
    VERIFY_IS_APPROX_ABS(cosAc, (exp_iA + exp_miA) / 2)

def testMatrix[MatrixType: AnyType](A: MatrixType):
    testMatrixExponential(A)
    testMatrixLogarithm(A)
    testHyperbolicFunctions(A)
    testGonioFunctions(A)

def testMatrixType[MatrixType: AnyType](m: MatrixType):
    var size: Index = m.rows()
    for i in range(g_repeat):
        testMatrix(MatrixType.Random(size, size).eval())
        testMatrix(randomMatrixWithRealEivals[MatrixType](size))
        testMatrix(randomMatrixWithImagEivals[MatrixType].run(size))

def test_matrix_function():
    CALL_SUBTEST_1(testMatrixType(Matrix[float32, 1, 1]()))
    CALL_SUBTEST_2(testMatrixType(Matrix3cf()))
    CALL_SUBTEST_3(testMatrixType(MatrixXf(8, 8)))
    CALL_SUBTEST_4(testMatrixType(Matrix2d()))
    CALL_SUBTEST_5(testMatrixType(Matrix[float64, 5, 5, RowMajor]()))
    CALL_SUBTEST_6(testMatrixType(Matrix4cd()))
    CALL_SUBTEST_7(testMatrixType(MatrixXd(13, 13)))