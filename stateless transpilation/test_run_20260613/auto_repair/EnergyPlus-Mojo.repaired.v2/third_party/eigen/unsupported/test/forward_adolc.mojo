from main import *
from Eigen.Dense import *
from Eigen.AdolcForward import *

alias NUMBER_DIRECTIONS: Int = 16

def foo[Vector: AnyType](p: Vector) -> Vector::Scalar:
    alias Scalar = Vector::Scalar
    return (p - Vector(Scalar(-1), Scalar(1.))).norm() + (p.array().sqrt().abs() * p.array().sin()).sum() + p.dot(p)

struct TestFunc1[_Scalar: AnyType, NX: Int = Dynamic, NY: Int = Dynamic]:
    alias Scalar = _Scalar
    enum InputsAtCompileTime: Int = NX
    enum ValuesAtCompileTime: Int = NY
    alias InputType = Matrix[Scalar, InputsAtCompileTime, 1]
    alias ValueType = Matrix[Scalar, ValuesAtCompileTime, 1]
    alias JacobianType = Matrix[Scalar, ValuesAtCompileTime, InputsAtCompileTime]

    var m_inputs: Int
    var m_values: Int

    def __init__(inout self):
        self.m_inputs = InputsAtCompileTime
        self.m_values = ValuesAtCompileTime

    def __init__(inout self, inputs: Int, values: Int):
        self.m_inputs = inputs
        self.m_values = values

    def inputs(self) -> Int:
        return self.m_inputs

    def values(self) -> Int:
        return self.m_values

    def __call__[T: AnyType](self, x: Matrix[T, InputsAtCompileTime, 1], _v: Pointer[Matrix[T, ValuesAtCompileTime, 1]]) -> None:
        # Pointer dereference to get v
        var v: Matrix[T, ValuesAtCompileTime, 1] = _v.load()
        v[0] = 2 * x[0] * x[0] + x[0] * x[1]
        v[1] = 3 * x[1] * x[0] + 0.5 * x[1] * x[1]
        if self.inputs() > 2:
            v[0] += 0.5 * x[2]
            v[1] += x[2]
        if self.values() > 2:
            v[2] = 3 * x[1] * x[0] * x[0]
        if self.inputs() > 2 and self.values() > 2:
            v[2] *= x[2]
        _v.store(v)

    def __call__(self, x: InputType, v: Pointer[ValueType], _j: Pointer[JacobianType]) -> None:
        # call the first operator()
        self.__call__(x, v)
        if _j:
            var j: JacobianType = _j.load()
            j[0, 0] = 4 * x[0] + x[1]
            j[1, 0] = 3 * x[1]
            j[0, 1] = x[0]
            j[1, 1] = 3 * x[0] + 2 * 0.5 * x[1]
            if self.inputs() > 2:
                j[0, 2] = 0.5
                j[1, 2] = 1
            if self.values() > 2:
                j[2, 0] = 3 * x[1] * 2 * x[0]
                j[2, 1] = 3 * x[0] * x[0]
            if self.inputs() > 2 and self.values() > 2:
                j[2, 0] *= x[2]
                j[2, 1] *= x[2]
                j[2, 2] = 3 * x[1] * x[0] * x[0]
                j[2, 2] = 3 * x[1] * x[0] * x[0]
            _j.store(j)

def adolc_forward_jacobian[Func: AnyType](f: Func) -> None:
    var x: Func.InputType = Func.InputType.Random(f.inputs())
    var y: Func.ValueType = Func.ValueType(f.values())
    var yref: Func.ValueType = Func.ValueType(f.values())
    var j: Func.JacobianType = Func.JacobianType(f.values(), f.inputs())
    var jref: Func.JacobianType = Func.JacobianType(f.values(), f.inputs())
    jref.setZero()
    yref.setZero()
    f(x, Pointer[Func.ValueType](address_of(yref)), Pointer[Func.JacobianType](address_of(jref)))
    j.setZero()
    y.setZero()
    var autoj: AdolcForwardJacobian[Func] = AdolcForwardJacobian[Func](f)
    autoj(x, Pointer[Func.ValueType](address_of(y)), Pointer[Func.JacobianType](address_of(j)))
    VERIFY_IS_APPROX(y, yref)
    VERIFY_IS_APPROX(j, jref)

def test_forward_adolc() -> None:
    adtl.setNumDir(NUMBER_DIRECTIONS)
    for i in range(g_repeat):
        CALL_SUBTEST(adolc_forward_jacobian(TestFunc1[float64, 2, 2]()))
        CALL_SUBTEST(adolc_forward_jacobian(TestFunc1[float64, 2, 3]()))
        CALL_SUBTEST(adolc_forward_jacobian(TestFunc1[float64, 3, 2]()))
        CALL_SUBTEST(adolc_forward_jacobian(TestFunc1[float64, 3, 3]()))
        CALL_SUBTEST(adolc_forward_jacobian(TestFunc1[float64](3, 3)))
    # Block for ADOLC specific tests
    var x: Matrix[adtl.adouble, 2, 1]
    foo[Matrix[adtl.adouble, 2, 1]](x)
    var A: Matrix[adtl.adouble, Dynamic, Dynamic] = Matrix[adtl.adouble, Dynamic, Dynamic](4, 4)
    A.selfadjointView[Lower]().eigenvalues()