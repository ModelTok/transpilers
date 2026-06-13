from main import *
from Eigen import *

struct my_exception:
    def __init__(inout self):

    def __del__(owned self):

@value
class ScalarWithExceptions:
    var v: Pointer[Float32]
    var instances: StaticInt
    var countdown: StaticInt

    def __init__(inout self):
        self.init()

    def __init__(inout self, _v: Float32):
        self.init()
        self.v.store(_v)

    def __init__(inout self, other: Self):
        self.init()
        self.v.store(other.v.load())

    def __del__(owned self):
        del self.v
        ScalarWithExceptions.instances -= 1

    def init(inout self):
        self.v = Pointer[Float32].alloc(1)
        ScalarWithExceptions.instances += 1

    def __add__(self, other: Self) -> Self:
        ScalarWithExceptions.countdown -= 1
        if ScalarWithExceptions.countdown <= 0:
            raise my_exception()
        return ScalarWithExceptions(self.v.load() + other.v.load())

    def __sub__(self, other: Self) -> Self:
        return ScalarWithExceptions(self.v.load() - other.v.load())

    def __mul__(self, other: Self) -> Self:
        return ScalarWithExceptions(self.v.load() * other.v.load())

    def __iadd__(inout self, other: Self) -> Self:
        self.v.store(self.v.load() + other.v.load())
        return self

    def __isub__(inout self, other: Self) -> Self:
        self.v.store(self.v.load() - other.v.load())
        return self

    def __copyinit__(inout self, other: Self):
        self.v = Pointer[Float32].alloc(1)
        self.v.store(other.v.load())
        ScalarWithExceptions.instances += 1

    def __moveinit__(inout self, owned other: Self):
        self.v = other.v
        ScalarWithExceptions.instances += 1

    def __eq__(self, other: Self) -> Bool:
        return self.v.load() == other.v.load()

    def __ne__(self, other: Self) -> Bool:
        return self.v.load() != other.v.load()

def real(x: ScalarWithExceptions) -> ScalarWithExceptions:
    return x

def imag(x: ScalarWithExceptions) -> ScalarWithExceptions:
    return ScalarWithExceptions(0.0)

def conj(x: ScalarWithExceptions) -> ScalarWithExceptions:
    return x

ScalarWithExceptions.instances = 0
ScalarWithExceptions.countdown = 0

def CHECK_MEMLEAK(OP: fn() raises):
    ScalarWithExceptions.countdown = 100
    var before = ScalarWithExceptions.instances
    var exception_thrown = False
    try:
        OP()
    except my_exception:
        exception_thrown = True
        if ScalarWithExceptions.instances != before:
            print("memory leak detected in ", "OP")
    if not exception_thrown:
        print(" no exception thrown in ", "OP")

def memoryleak() raises:
    alias VectorType = Eigen.Matrix[ScalarWithExceptions, Eigen.Dynamic, 1]
    alias MatrixType = Eigen.Matrix[ScalarWithExceptions, Eigen.Dynamic, Eigen.Dynamic]
    var n = 50
    var v0 = VectorType(n)
    var v1 = VectorType(n)
    var m0 = MatrixType(n, n)
    var m1 = MatrixType(n, n)
    var m2 = MatrixType(n, n)
    v0.setOnes()
    v1.setOnes()
    m0.setOnes()
    m1.setOnes()
    m2.setOnes()
    CHECK_MEMLEAK(fn() raises: v0 = m0 * m1 * v1)
    CHECK_MEMLEAK(fn() raises: m2 = m0 * m1 * m2)
    CHECK_MEMLEAK(fn() raises: (v0 + v1).dot(v0 + v1))
    if ScalarWithExceptions.instances != 0:
        print("global memory leak detected in ", "OP")

def test_exceptions() raises:
    CALL_SUBTEST(fn() raises: memoryleak())