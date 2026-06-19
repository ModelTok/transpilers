from std.math import sqrt, exp, log, log10, sin, cos, tan, atan, atan2, pow, floor, ceil, trunc

comptime Real64 = Float64
comptime Int64 = Int
comptime SMALL = 1e-10

def pow_2(x: Float64) -> Float64: return x * x
def pow_3(x: Float64) -> Float64: return x * x * x
def pow_4(x: Float64) -> Float64: return (x*x) * (x*x)
def pow_5(x: Float64) -> Float64: return (x*x) * (x*x) * x
def pow_6(x: Float64) -> Float64: return (x*x*x) * (x*x*x)
def pow_7(x: Float64) -> Float64: return (x*x*x) * (x*x*x) * x
def root_4(x: Float64) -> Float64: return sqrt(sqrt(x))
def root_8(x: Float64) -> Float64: return sqrt(sqrt(sqrt(x)))
def mod(a: Float64, b: Float64) -> Float64: return a - b * trunc(a / b)
def sign(a: Float64, b: Float64) -> Float64:
    return abs(a) if b >= 0.0 else -abs(a)
def radians(x: Float64) -> Float64: return x * 0.0174532925199432958
def pvstar(T: Float64) -> Float64: return 611.65   # domain dependency stub (real fn lives elsewhere)

struct Constant:
    comptime Pi = 3.14159265358979324
    comptime TwoPi = 6.28318530717958648
    comptime PiOvr2 = 1.57079632679489662
    comptime Kelvin = 273.15
    comptime StefanBoltzmann = 5.6697e-8
    comptime Sigma = 5.6697e-8                 # EP alias for Stefan-Boltzmann
    comptime DegToRad = 0.0174532925199432958
    comptime RadToDeg = 57.2957795130823209
    comptime UniversalGasConstant = 8314.462175   # J/(kmol*K)
    comptime Gravity = 9.807                   # m/s^2

struct DataPrecisionGlobals:
    comptime EXP_LowerLimit = -20.0
    comptime constant_zero = 0.0
    comptime constant_one = 1.0

struct TARCOGParams:
    comptime MMax = 100
    comptime NMax = 100

# ObjexxFCL-style 1-based dense arrays (List-backed). C++ uses call syntax
# `a(i)`; the model maps that to Mojo subscript `a[i]`. Both are 1-based, so the
# shim mirrors ep_oracle.h's Array1D/Array2D exactly.
struct Array1D(Copyable, Movable):
    var _d: List[Float64]
    def __init__(out self, n: Int = 0, fill: Float64 = 0.0):
        self._d = List[Float64]()
        for _ in range(n):
            self._d.append(fill)
    def __getitem__(self, i: Int) raises -> Float64:
        return self._d[i - 1]
    def __setitem__(mut self, i: Int, v: Float64) raises:
        self._d[i - 1] = v
    def size(self) -> Int:
        return len(self._d)
    def __len__(self) -> Int:
        return len(self._d)

struct Array2D(Copyable, Movable):
    var _d: List[Float64]
    var _rows: Int
    var _cols: Int
    def __init__(out self, rows: Int = 0, cols: Int = 0, fill: Float64 = 0.0):
        self._rows = rows
        self._cols = cols
        self._d = List[Float64]()
        for _ in range(rows * cols):
            self._d.append(fill)
    def __getitem__(self, i: Int, j: Int) raises -> Float64:
        return self._d[(i - 1) * self._cols + (j - 1)]
    def __setitem__(mut self, i: Int, j: Int, v: Float64) raises:
        self._d[(i - 1) * self._cols + (j - 1)] = v
    def size(self) -> Int:
        return len(self._d)
