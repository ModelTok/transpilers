from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST_2
from Eigen.LevenbergMarquardt import LevenbergMarquardt, LevenbergMarquardtSpace, DenseFunctor
from memory.buffer import NDBuffer
from math import exp, pow

struct DenseLM[Scalar: AnyRegType](DenseFunctor[Scalar]):
    alias Base = DenseFunctor[Scalar]
    alias JacobianType = Base.JacobianType
    alias VectorType = Matrix[Scalar, Dynamic, 1]

    var m_x: VectorType
    var m_y: VectorType

    def __init__(inout self, n: Int, m: Int):
        DenseFunctor.__init__(self, n, m)
        self.m_x = VectorType()
        self.m_y = VectorType()

    def model[type: AnyRegType](inout self, uv: VectorType, x: VectorType) -> VectorType:
        var y: VectorType
        let m = Base.values(self)
        let n = Base.inputs(self)
        eigen_assert(uv.size() % 2 == 0)
        eigen_assert(uv.size() == n)
        eigen_assert(x.size() == m)
        y.setZero(m)
        let half = n // 2
        var u = VectorBlock[VectorType](uv, 0, half)
        var v = VectorBlock[VectorType](uv, half, half)
        for j in range(m):
            for i in range(half):
                y[j] += u[i] * exp(-((x[j] - i) * (x[j] - i)) / (v[i] * v[i]))
        return y

    def initPoints(inout self, uv_ref: VectorType, x: VectorType):
        self.m_x = x
        self.m_y = self.model(uv_ref, x)

    def __call__(inout self, uv: VectorType, fvec: VectorType) -> Int:
        let m = Base.values(self)
        let n = Base.inputs(self)
        eigen_assert(uv.size() % 2 == 0)
        eigen_assert(uv.size() == n)
        eigen_assert(fvec.size() == m)
        let half = n // 2
        var u = VectorBlock[VectorType](uv, 0, half)
        var v = VectorBlock[VectorType](uv, half, half)
        for j in range(m):
            fvec[j] = self.m_y[j]
            for i in range(half):
                fvec[j] -= u[i] * exp(-((self.m_x[j] - i) * (self.m_x[j] - i)) / (v[i] * v[i]))
        return 0

    def df(inout self, uv: VectorType, fjac: JacobianType) -> Int:
        let m = Base.values(self)
        let n = Base.inputs(self)
        eigen_assert(n == uv.size())
        eigen_assert(fjac.rows() == m)
        eigen_assert(fjac.cols() == n)
        let half = n // 2
        var u = VectorBlock[VectorType](uv, 0, half)
        var v = VectorBlock[VectorType](uv, half, half)
        for j in range(m):
            for i in range(half):
                fjac.coeffRef(j, i) = -exp(-((self.m_x[j] - i) * (self.m_x[j] - i)) / (v[i] * v[i]))
                fjac.coeffRef(j, i + half) = -2.0 * u[i] * (self.m_x[j] - i) * (self.m_x[j] - i) / (pow(v[i], 3)) * exp(-((self.m_x[j] - i) * (self.m_x[j] - i)) / (v[i] * v[i]))
        return 0

def test_minimizeLM[FunctorType: AnyRegType, VectorType: AnyRegType](inout functor: FunctorType, inout uv: VectorType) -> Int:
    var lm = LevenbergMarquardt[FunctorType](functor)
    var info: LevenbergMarquardtSpace.Status
    info = lm.minimize(uv)
    VERIFY_IS_EQUAL(info, 1)
    return info

def test_lmder[FunctorType: AnyRegType, VectorType: AnyRegType](inout functor: FunctorType, inout uv: VectorType) -> Int:
    alias Scalar = VectorType.Scalar
    var info: LevenbergMarquardtSpace.Status
    var lm = LevenbergMarquardt[FunctorType](functor)
    info = lm.lmder1(uv)
    VERIFY_IS_EQUAL(info, 1)
    return info

def test_minimizeSteps[FunctorType: AnyRegType, VectorType: AnyRegType](inout functor: FunctorType, inout uv: VectorType) -> Int:
    var info: LevenbergMarquardtSpace.Status
    var lm = LevenbergMarquardt[FunctorType](functor)
    info = lm.minimizeInit(uv)
    if info == LevenbergMarquardtSpace.ImproperInputParameters:
        return info
    while True:
        info = lm.minimizeOneStep(uv)
        if info != LevenbergMarquardtSpace.Running:
            break
    VERIFY_IS_EQUAL(info, 1)
    return info

def test_denseLM_T[T: AnyRegType]():
    alias VectorType = Matrix[T, Dynamic, 1]
    let inputs: Int = 10
    let values: Int = 1000
    var dense_gaussian = DenseLM[T](inputs, values)
    var uv = VectorType(inputs)
    var uv_ref = VectorType(inputs)
    var x = VectorType(values)
    uv_ref = [-2, 1, 4, 8, 6, 1.8, 1.2, 1.1, 1.9, 3]
    x.setRandom()
    x = 10 * x
    x = x + 10
    dense_gaussian.initPoints(uv_ref, x)
    var u = VectorBlock[VectorType](uv, 0, inputs // 2)
    var v = VectorBlock[VectorType](uv, inputs // 2, inputs // 2)
    u.setOnes()
    v.setOnes()
    test_minimizeLM(dense_gaussian, uv)
    u.setOnes()
    v.setOnes()
    test_lmder(dense_gaussian, uv)
    v.setOnes()
    u.setOnes()
    test_minimizeSteps(dense_gaussian, uv)

def test_denseLM():
    CALL_SUBTEST_2(test_denseLM_T[Float64]())