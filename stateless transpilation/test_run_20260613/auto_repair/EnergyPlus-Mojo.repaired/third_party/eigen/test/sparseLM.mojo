from math import pow
from ..main import VERIFY_IS_EQUAL, CALL_SUBTEST_1
from ...Eigen.Core import Matrix, Dynamic, VectorBlock, SparseFunctor
from ...Eigen.LevenbergMarquardt import LevenbergMarquardt, LevenbergMarquardtSpace

alias Scalar = AnyType  # placeholder; will be parameterized

@value
struct sparseGaussianTest[Scalar: AnyType](SparseFunctor[Scalar, Int]):
    typealias VectorType = Matrix[Scalar, Dynamic, 1]
    typealias Base = SparseFunctor[Scalar, Int]
    typealias JacobianType = Base.JacobianType

    var m_x: VectorType
    var m_y: VectorType

    def __init__(inout self, inputs: Int, values: Int):
        SparseFunctor.__init__(self, inputs, values)

    def model(self, uv: VectorType, x: VectorType) -> VectorType:
        var y: VectorType
        let m = self.values()
        let n = self.inputs()
        assert uv.size() % 2 == 0
        assert uv.size() == n
        assert x.size() == m
        y.setZero(m)
        let half = n // 2
        let u = uv[0:half]
        let v = uv[half:n]
        var coeff: Scalar
        for j in range(m):
            for i in range(half):
                coeff = (x[j] - i) / v[i]
                coeff *= coeff
                if coeff < 1.0 and coeff > 0.0:
                    y[j] += u[i] * pow(1.0 - coeff, 2)
        return y

    def initPoints(inout self, uv_ref: VectorType, x: VectorType):
        self.m_x = x
        self.m_y = self.model(uv_ref, x)

    def __call__(self, uv: VectorType, fvec: VectorType) -> Int:
        let m = self.values()
        let n = self.inputs()
        assert uv.size() % 2 == 0
        assert uv.size() == n
        let half = n // 2
        let u = uv[0:half]
        let v = uv[half:n]
        fvec = self.m_y
        var coeff: Scalar
        for j in range(m):
            for i in range(half):
                coeff = (self.m_x[j] - i) / v[i]
                coeff *= coeff
                if coeff < 1.0 and coeff > 0.0:
                    fvec[j] -= u[i] * pow(1.0 - coeff, 2)
        return 0

    def df(self, uv: VectorType, fjac: JacobianType) -> Int:
        let m = self.values()
        let n = self.inputs()
        assert n == uv.size()
        assert fjac.rows() == m
        assert fjac.cols() == n
        let half = n // 2
        let u = uv[0:half]
        let v = uv[half:n]
        var coeff: Scalar
        for col in range(half):
            for row in range(m):
                coeff = (self.m_x[row] - col) / v[col]
                coeff = coeff * coeff
                if coeff < 1.0 and coeff > 0.0:
                    fjac.coeffRef(row, col) = -(1.0 - coeff) * (1.0 - coeff)
        for col in range(half):
            for row in range(m):
                coeff = (self.m_x[row] - col) / v[col]
                coeff = coeff * coeff
                if coeff < 1.0 and coeff > 0.0:
                    fjac.coeffRef(row, col + half) = -4.0 * (u[col] / v[col]) * coeff * (1.0 - coeff)
        return 0

def test_sparseLM_T[T: AnyType]() raises:
    typealias VectorType = Matrix[T, Dynamic, 1]
    let inputs: Int = 10
    let values: Int = 2000
    var sparse_gaussian = sparseGaussianTest[T](inputs, values)
    var uv = VectorType(inputs)
    var uv_ref = VectorType(inputs)
    var x = VectorType(values)
    uv_ref = [-2, 1, 4, 8, 6, 1.8, 1.2, 1.1, 1.9, 3]
    x.setRandom()
    x = 10.0 * x
    x = x.array() + 10
    sparse_gaussian.initPoints(uv_ref, x)
    var u = uv[0:inputs // 2]
    var v = uv[inputs // 2:inputs]
    v.setOnes()
    u.setOnes()
    var lm = LevenbergMarquardt[sparseGaussianTest[T]](sparse_gaussian)
    let info: Int
    VERIFY_IS_EQUAL(info, 1)
    let maxiter: Int = 200
    var iter: Int = 0
    var Err = Matrix[T, values, maxiter]()
    var Mod = Matrix[T, values, maxiter]()
    var status: LevenbergMarquardtSpace.Status
    status = lm.minimizeInit(uv)
    if status == LevenbergMarquardtSpace.ImproperInputParameters:
        return

def test_sparseLM() raises:
    CALL_SUBTEST_1(test_sparseLM_T[Float64]())