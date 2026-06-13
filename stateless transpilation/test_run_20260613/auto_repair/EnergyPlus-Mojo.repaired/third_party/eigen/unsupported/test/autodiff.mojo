// Translation of C++ autodiff test to Mojo. Faithful 1:1, no refactoring.
// Original: third_party/eigen/unsupported/test/autodiff.cpp

// Replacements for macros and Eigen types are assumed to be available.

// Define constants to replicate preprocessor conditions.
alias EIGEN_HAS_VARIADIC_TEMPLATES = True
alias EIGEN_TEST_PART_5 = True

// Forward declarations for Eigen-like types (stubs).
// In a real Mojo environment, these would come from appropriate modules.
struct Vector2f { ... }
struct Vector2d { ... }
struct VectorXd { ... }
struct Vector4d { ... }
struct Matrix4d { ... }
struct Matrix2d { ... }
struct Matrix[Scalar, rows: Int, cols: Int] { ... }
struct AutoDiffScalar[DerType] { ... }
struct AutoDiffJacobian[Func] { ... }
func VERIFY_IS_APPROX(a, b): ...
func CALL_SUBTEST(fn): ...
var g_repeat: Int = 1 // assumed

// Helper for  functions
from math import pow, sqrt, sin, cos, exp, min

def foo[Scalar: DType](x: Scalar, y: Scalar) -> Scalar:
    # using namespace std;  // dropped
    # EIGEN_ASM_COMMENT("mybegin")
    return x * 2 - 1 + Scalar(pow(1 + x, 2)) + 2 * sqrt(y * y + 0) - 4 * sin(0 + x) + 2 * cos(y + 0) - exp(Scalar(-0.5) * x * x + 0)
    # EIGEN_ASM_COMMENT("myend")

def foo[Vector: type](p: Vector) -> Vector.Scalar:
    alias Scalar = Vector.Scalar
    return (p - Vector(Scalar(-1), Scalar(1.))).norm() + (p.array() * p.array()).sum() + p.dot(p)

struct TestFunc1[_Scalar: DType, NX: Int = Dynamic, NY: Int = Dynamic]:
    alias Scalar = _Scalar
    enum InputsAtCompileTime = NX
    enum ValuesAtCompileTime = NY
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
    def __call__[T: DType](self, x: Matrix[T, InputsAtCompileTime, 1], _v: Matrix[T, ValuesAtCompileTime, 1]*) -> None:
        var v = _v[]
        v[0] = 2 * x[0] * x[0] + x[0] * x[1]
        v[1] = 3 * x[1] * x[0] + 0.5 * x[1] * x[1]
        if self.inputs() > 2:
            v[0] += 0.5 * x[2]
            v[1] += x[2]
        if self.values() > 2:
            v[2] = 3 * x[1] * x[0] * x[0]
        if self.inputs() > 2 and self.values() > 2:
            v[2] *= x[2]
    def __call__(self, x: InputType*, v: ValueType*, _j: JacobianType*) -> None:
        self(x, v)
        if _j:
            var j = _j[]
            j(0, 0) = 4 * x[0] + x[1]
            j(1, 0) = 3 * x[1]
            j(0, 1) = x[0]
            j(1, 1) = 3 * x[0] + 2 * 0.5 * x[1]
            if self.inputs() > 2:
                j(0, 2) = 0.5
                j(1, 2) = 1
            if self.values() > 2:
                j(2, 0) = 3 * x[1] * 2 * x[0]
                j(2, 1) = 3 * x[0] * x[0]
            if self.inputs() > 2 and self.values() > 2:
                j(2, 0) *= x[2]
                j(2, 1) *= x[2]
                j(2, 2) = 3 * x[1] * x[0] * x[0]
                j(2, 2) = 3 * x[1] * x[0] * x[0]

# if EIGEN_HAS_VARIADIC_TEMPLATES:
struct integratorFunctor[Scalar: DType]:
    alias InputType = Matrix[Scalar, 2, 1]
    alias ValueType = Matrix[Scalar, 2, 1]
    var _gain: Scalar
    def __init__(inout self, gain: Scalar):
        self._gain = gain
    def __init__(inout self, f: Self):
        self._gain = f._gain
    def __call__[T1: type, T2: type](self, input: T1, output: T2*, dt: Scalar) -> None:
        var o = output[]
        o[0] = input[0] + input[1] * dt * self._gain
        o[1] = input[1] * self._gain
    def __call__[T1: type, T2: type, T3: type](self, input: T1, output: T2*, jacobian: T3*, dt: Scalar) -> None:
        var o = output[]
        o[0] = input[0] + input[1] * dt * self._gain
        o[1] = input[1] * self._gain
        if jacobian:
            var j = jacobian[]
            j(0, 0) = 1
            j(0, 1) = dt * self._gain
            j(1, 0) = 0
            j(1, 1) = self._gain

def forward_jacobian_cpp11[Func: type](f: Func):
    alias Scalar = Func.ValueType.Scalar
    alias ValueType = Func.ValueType
    alias InputType = Func.InputType
    alias JacobianType = AutoDiffJacobian[Func].JacobianType
    var x = InputType.Random(InputType.RowsAtCompileTime)
    var y: ValueType
    var yref: ValueType
    var j: JacobianType
    var jref: JacobianType
    var dt = internal.random[double]()
    jref.setZero()
    yref.setZero()
    f(x, &yref, &jref, dt)
    var autoj = AutoDiffJacobian[Func](f)
    autoj(x, &y, &j, dt)
    VERIFY_IS_APPROX(y, yref)
    VERIFY_IS_APPROX(j, jref)
# end

def forward_jacobian[Func: type](f: Func):
    var x = Func.InputType.Random(f.inputs())
    var y = Func.ValueType(f.values())
    var yref = Func.ValueType(f.values())
    var j = Func.JacobianType(f.values(), f.inputs())
    var jref = Func.JacobianType(f.values(), f.inputs())
    jref.setZero()
    yref.setZero()
    f(x, &yref, &jref)
    j.setZero()
    y.setZero()
    var autoj = AutoDiffJacobian[Func](f)
    autoj(x, &y, &j)
    VERIFY_IS_APPROX(y, yref)
    VERIFY_IS_APPROX(j, jref)

def test_autodiff_scalar[_](_: Int):
    var p = Vector2f.Random()
    alias AD = AutoDiffScalar[Vector2f]
    var ax = AD(p.x(), Vector2f.UnitX())
    var ay = AD(p.y(), Vector2f.UnitY())
    var res = foo[AD](ax, ay)
    VERIFY_IS_APPROX(res.value(), foo[float32](p.x(), p.y()))

def test_autodiff_vector[_](_: Int):
    var p = Vector2f.Random()
    alias AD = AutoDiffScalar[Vector2f]
    alias VectorAD = Matrix[AD, 2, 1]
    var ap = p.cast[AD]()
    ap.x().derivatives() = Vector2f.UnitX()
    ap.y().derivatives() = Vector2f.UnitY()
    var res = foo[VectorAD](ap)
    VERIFY_IS_APPROX(res.value(), foo[Vector2f](p))

def test_autodiff_jacobian[_](_: Int):
    CALL_SUBTEST( forward_jacobian(TestFunc1[float64, 2, 2]()) )
    CALL_SUBTEST( forward_jacobian(TestFunc1[float64, 2, 3]()) )
    CALL_SUBTEST( forward_jacobian(TestFunc1[float64, 3, 2]()) )
    CALL_SUBTEST( forward_jacobian(TestFunc1[float64, 3, 3]()) )
    CALL_SUBTEST( forward_jacobian(TestFunc1[float64](3, 3)) )
# if EIGEN_HAS_VARIADIC_TEMPLATES:
    CALL_SUBTEST( forward_jacobian_cpp11(integratorFunctor[float64](10)) )
# end

def test_autodiff_hessian[_](_: Int):
    alias AD = AutoDiffScalar[VectorXd]
    alias VectorAD = Matrix[AD, Eigen.Dynamic, 1]
    alias ADD = AutoDiffScalar[VectorAD]
    alias VectorADD = Matrix[ADD, Eigen.Dynamic, 1]
    var x = VectorADD(2)
    var s1 = internal.random[float64]()
    var s2 = internal.random[float64]()
    var s3 = internal.random[float64]()
    var s4 = internal.random[float64]()
    x(0).value() = s1
    x(1).value() = s2
    x(0).derivatives().resize(2)
    x(0).derivatives().setZero()
    x(0).derivatives()(0) = 1
    x(1).derivatives().resize(2)
    x(1).derivatives().setZero()
    x(1).derivatives()(1) = 1
    x(0).value().derivatives() = VectorXd.Unit(2, 0)
    x(1).value().derivatives() = VectorXd.Unit(2, 1)
    for idx in range(2):
        x(0).derivatives()(idx).derivatives() = VectorXd.Zero(2)
        x(1).derivatives()(idx).derivatives() = VectorXd.Zero(2)
    var y = sin(AD(s3)*x(0) + AD(s4)*x(1))
    VERIFY_IS_APPROX(y.value().derivatives()(0), y.derivatives()(0).value())
    VERIFY_IS_APPROX(y.value().derivatives()(1), y.derivatives()(1).value())
    VERIFY_IS_APPROX(y.value().derivatives()(0), s3*cos(s1*s3+s2*s4))
    VERIFY_IS_APPROX(y.value().derivatives()(1), s4*cos(s1*s3+s2*s4))
    VERIFY_IS_APPROX(y.derivatives()(0).derivatives(), -sin(s1*s3+s2*s4)*Vector2d(s3*s3, s4*s3))
    VERIFY_IS_APPROX(y.derivatives()(1).derivatives(), -sin(s1*s3+s2*s4)*Vector2d(s3*s4, s4*s4))
    var z = x(0)*x(1)
    VERIFY_IS_APPROX(z.derivatives()(0).derivatives(), Vector2d(0, 1))
    VERIFY_IS_APPROX(z.derivatives()(1).derivatives(), Vector2d(1, 0))

def bug_1222() -> float64:
    alias AD = AutoDiffScalar[Vector3d]
    var _cv1_3 = 1.0
    var chi_3 = AD(1.0)
    var denom = chi_3 + _cv1_3
    return denom.value()

# ifdef EIGEN_TEST_PART_5
def bug_1223() -> float64:
    alias AD = AutoDiffScalar[Vector3d]
    var _cv1_3 = 1.0
    var chi_3 = AD(1.0)
    var denom = AD(1.0)
    #define EIGEN_TEST_SPACE
    var t = min(denom / chi_3, 1.0)
    var t2 = min(denom / (chi_3 * _cv1_3), 1.0)
    return t.value() + t2.value()

def bug_1260():
    var A = Matrix4d.Ones()
    var v = Vector4d.Ones()
    A * v

def bug_1261() -> float64:
    alias AD = AutoDiffScalar[Matrix2d]
    alias VectorAD = Matrix[AD, 2, 1]
    var v = VectorAD(0., 0.)
    var maxVal = v.maxCoeff()
    var minVal = v.minCoeff()
    return maxVal.value() + minVal.value()

def bug_1264() -> float64:
    alias AD = AutoDiffScalar[Vector2d]
    var s = AD(0.)
    var v1 = Matrix[AD, 3, 1](0., 0., 0.)
    var v2 = (s + 3.0) * v1
    return v2(0).value()
# end

def test_autodiff():
    for i in range(g_repeat):
        CALL_SUBTEST_1( test_autodiff_scalar[1]() )
        CALL_SUBTEST_2( test_autodiff_vector[1]() )
        CALL_SUBTEST_3( test_autodiff_jacobian[1]() )
        CALL_SUBTEST_4( test_autodiff_hessian[1]() )
    CALL_SUBTEST_5( bug_1222() )
    CALL_SUBTEST_5( bug_1223() )
    CALL_SUBTEST_5( bug_1260() )
    CALL_SUBTEST_5( bug_1261() )