from main import VERIFY_IS_APPROX, CALL_SUBTEST
from NumericalDiff import NumericalDiff, Central
from Matrix import Matrix

alias Dynamic: Int = -1
alias VectorXd = Matrix[Float64, Dynamic, 1]
alias MatrixXd = Matrix[Float64, Dynamic, Dynamic]

struct Functor[_Scalar: AnyRegType, NX: Int = Dynamic, NY: Int = Dynamic]:
    alias Scalar = _Scalar
    alias InputsAtCompileTime = NX
    alias ValuesAtCompileTime = NY
    alias InputType = Matrix[Scalar, InputsAtCompileTime, 1]
    alias ValueType = Matrix[Scalar, ValuesAtCompileTime, 1]
    alias JacobianType = Matrix[Scalar, ValuesAtCompileTime, InputsAtCompileTime]

    var m_inputs: Int
    var m_values: Int

    def __init__(self):
        self.m_inputs = InputsAtCompileTime
        self.m_values = ValuesAtCompileTime

    def __init__(self, inputs: Int, values: Int):
        self.m_inputs = inputs
        self.m_values = values

    def inputs(self) -> Int:
        return self.m_inputs

    def values(self) -> Int:
        return self.m_values


struct my_functor:
    var inputs_: Int
    var values_: Int

    def __init__(self):
        self.inputs_ = 3
        self.values_ = 15

    def inputs(self) -> Int:
        return self.inputs_

    def values(self) -> Int:
        return self.values_

    def __call__(self, x: VectorXd, fvec: VectorXd) -> Int:
        var tmp1: Float64
        var tmp2: Float64
        var tmp3: Float64
        var y: StaticArray[Float64, 15] = [1.4e-1, 1.8e-1, 2.2e-1, 2.5e-1, 2.9e-1, 3.2e-1, 3.5e-1,
            3.9e-1, 3.7e-1, 5.8e-1, 7.3e-1, 9.6e-1, 1.34, 2.1, 4.39]
        for i in range(self.values()):
            tmp1 = Float64(i + 1)
            tmp2 = Float64(16 - i - 1)
            if i >= 8:
                tmp3 = tmp2
            else:
                tmp3 = tmp1
            fvec[i] = y[i] - (x[0] + tmp1 / (x[1] * tmp2 + x[2] * tmp3))
        return 0

    def actual_df(self, x: VectorXd, fjac: MatrixXd) -> Int:
        var tmp1: Float64
        var tmp2: Float64
        var tmp3: Float64
        var tmp4: Float64
        for i in range(self.values()):
            tmp1 = Float64(i + 1)
            tmp2 = Float64(16 - i - 1)
            if i >= 8:
                tmp3 = tmp2
            else:
                tmp3 = tmp1
            tmp4 = (x[1] * tmp2 + x[2] * tmp3)
            tmp4 = tmp4 * tmp4
            fjac[i, 0] = -1.0
            fjac[i, 1] = tmp1 * tmp2 / tmp4
            fjac[i, 2] = tmp1 * tmp3 / tmp4
        return 0


def test_forward():
    var x = VectorXd(3)
    var jac = MatrixXd(15, 3)
    var actual_jac = MatrixXd(15, 3)
    var functor = my_functor()
    x = [0.082, 1.13, 2.35]
    functor.actual_df(x, actual_jac)
    var numDiff = NumericalDiff[my_functor](functor)
    numDiff.df(x, jac)
    VERIFY_IS_APPROX(jac, actual_jac)


def test_central():
    var x = VectorXd(3)
    var jac = MatrixXd(15, 3)
    var actual_jac = MatrixXd(15, 3)
    var functor = my_functor()
    x = [0.082, 1.13, 2.35]
    functor.actual_df(x, actual_jac)
    var numDiff = NumericalDiff[my_functor, Central](functor)
    numDiff.df(x, jac)
    VERIFY_IS_APPROX(jac, actual_jac)


def test_NumericalDiff():
    CALL_SUBTEST(test_forward())
    CALL_SUBTEST(test_central())