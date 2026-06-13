from DEF import Int, Double, Char, Bool, Void, ZeroOrOne, Axis, vl_one, vl_zero
from CONST import *
from vector2 import vector2
from point2 import point2
from point3 import point3
from DElightManagerC import writewndo
from mojo.stdlib.io import StdOut, StdIn
from mojo.stdlib.string import StringWriter, StringReader

struct vector3:
    var elt: Double[3]

    def __init__(self):

    def __init__(self, x: Double, y: Double, z: Double):
        self.elt[0] = x
        self.elt[1] = y
        self.elt[2] = z

    def __init__(self, v: Self):
        self.elt[0] = v[0]
        self.elt[1] = v[1]
        self.elt[2] = v[2]

    def __init__(self, a: point3, b: point3) -> Self:    # WLC
        self.elt[0] = b[0] - a[0]
        self.elt[1] = b[1] - a[1]
        self.elt[2] = b[2] - a[2]

    def __init__(self, k: ZeroOrOne):
        self.elt[0] = k
        self.elt[1] = k
        self.elt[2] = k

    def __init__(self, a: Axis):
        self.MakeUnit(a, vl_one)

    def Elts(self) -> Int:
        return 3

    def __getitem__(self, i: Int) -> Double:
        return self.elt[i]

    def __setitem__(self, i: Int, val: Double):
        self.elt[i] = val

    def Ref(self) -> Pointer[Double]:
        return Pointer(self.elt)

    def __imatmul__(self, a: Self) -> Self:    # operator =
        self.elt[0] = a[0]
        self.elt[1] = a[1]
        self.elt[2] = a[2]
        return self

    def __imatmul__(self, k: ZeroOrOne) -> Self:
        self.elt[0] = k
        self.elt[1] = k
        self.elt[2] = k
        return self

    def __iadd__(self, a: Self) -> Self:
        self.elt[0] += a[0]
        self.elt[1] += a[1]
        self.elt[2] += a[2]
        return self

    def __isub__(self, a: Self) -> Self:
        self.elt[0] -= a[0]
        self.elt[1] -= a[1]
        self.elt[2] -= a[2]
        return self

    def __imul__(self, a: Self) -> Self:
        self.elt[0] *= a[0]
        self.elt[1] *= a[1]
        self.elt[2] *= a[2]
        return self

    def __imul__(self, s: Double) -> Self:
        self.elt[0] *= s
        self.elt[1] *= s
        self.elt[2] *= s
        return self

    def __itruediv__(self, a: Self) -> Self:
        self.elt[0] /= a[0]
        self.elt[1] /= a[1]
        self.elt[2] /= a[2]
        return self

    def __itruediv__(self, s: Double) -> Self:
        self.elt[0] /= s
        self.elt[1] /= s
        self.elt[2] /= s
        return self

    def __eq__(self, a: Self) -> Bool:
        return self.elt[0] == a[0] and self.elt[1] == a[1] and self.elt[2] == a[2]

    def __ne__(self, a: Self) -> Bool:
        return self.elt[0] != a[0] or self.elt[1] != a[1] or self.elt[2] != a[2]

    def __lt__(self, a: Self) -> Bool:
        return (self.elt[0] < a[0]) or ((self.elt[0] == a[0]) and (self.elt[1] < a[1])) or ((self.elt[0] == a[0]) and (self.elt[1] == a[1]) and (self.elt[2] < a[2]))

    def __ge__(self, a: Self) -> Bool:
        return self.elt[0] >= a[0] and self.elt[1] >= a[1] and self.elt[2] >= a[2]

    def __add__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] + a[0]
        result[1] = self.elt[1] + a[1]
        result[2] = self.elt[2] + a[2]
        return result

    def __sub__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] - a[0]
        result[1] = self.elt[1] - a[1]
        result[2] = self.elt[2] - a[2]
        return result

    def __neg__(self) -> Self:
        var result: Self
        result[0] = -self.elt[0]
        result[1] = -self.elt[1]
        result[2] = -self.elt[2]
        return result

    def __mul__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] * a[0]
        result[1] = self.elt[1] * a[1]
        result[2] = self.elt[2] * a[2]
        return result

    def __mul__(self, s: Double) -> Self:
        var result: Self
        result[0] = self.elt[0] * s
        result[1] = self.elt[1] * s
        result[2] = self.elt[2] * s
        return result

    def __truediv__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] / a[0]
        result[1] = self.elt[1] / a[1]
        result[2] = self.elt[2] / a[2]
        return result

    def __truediv__(self, s: Double) -> Self:
        var result: Self
        result[0] = self.elt[0] / s
        result[1] = self.elt[1] / s
        result[2] = self.elt[2] / s
        return result

    def MakeZero(self) -> Self:
        self.elt[0] = vl_zero
        self.elt[1] = vl_zero
        self.elt[2] = vl_zero
        return self

    def MakeUnit(self, i: Int, k: Double = vl_one) -> Self:
        if i == 0:
            self.elt[0] = k
            self.elt[1] = vl_zero
            self.elt[2] = vl_zero
        elif i == 1:
            self.elt[0] = vl_zero
            self.elt[1] = k
            self.elt[2] = vl_zero
        elif i == 2:
            self.elt[0] = vl_zero
            self.elt[1] = vl_zero
            self.elt[2] = k
        else:
            self.elt[0] = 0
            self.elt[1] = 0
            self.elt[2] = 0
        return self

    def MakeBlock(self, k: Double = vl_one) -> Self:
        self.elt[0] = k
        self.elt[1] = k
        self.elt[2] = k
        return self

def __mul__(s: Double, v: vector3) -> vector3:
    return v * s

def dot(a: vector3, b: vector3) -> Double:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

def len(v: vector3) -> Double:
    return sqrt(dot(v, v))

def sqrlen(v: vector3) -> Double:
    return dot(v, v)

def norm(v: vector3) -> vector3:
    if sqrlen(v) > 0.0:
        return v / len(v)
    return vector3(0, 0, 0)

def normalize(v: vector3) -> Void:
    v /= len(v)

def cross(a: vector3, b: vector3) -> vector3:
    var result: vector3
    result[0] = a[1] * b[2] - a[2] * b[1]
    result[1] = a[2] * b[0] - a[0] * b[2]
    result[2] = a[0] * b[1] - a[1] * b[0]
    return result

def proj(v: vector3) -> vector2:
    var result: vector2
    if v[2] != 0:
        result[0] = v[0] / v[2]
        result[1] = v[1] / v[2]
    else:
        result[0] = v[0]
        result[1] = v[1]
    return result

# Stream operators
def operator<<(s: OStream, v: vector3) -> OStream:
    var w: Int = s.width()
    s << '[' << v[0] << ' ' << setw(w) << v[1] << ' ' << setw(w) << v[2] << ']'
    return s

def operator>>(s: IStream, v: vector3) -> IStream:
    var result: vector3
    var c: Char
    var osstream: StringWriter
    while s >> c and isspace(c):

    if s.eof():
        return s
    if s.fail():
        osstream << "vector3:ReadError1: unrecoverable failbit\n"
        writewndo(osstream.str(), "e")
        return s
    if c != '[':
        s.putback(c)
        s.clear(ios.failbit)
        return s
    s >> result[0] >> result[1] >> result[2]
    if !s:
        osstream << "vector3:ReadError2: Expected number\n"
        writewndo(osstream.str(), "e")
        return s
    while s >> c and isspace(c):

    if c != ']':
        s.clear(ios.failbit)
        osstream << "vector3:ReadError3: Expected ']' - got '" << c << "'" << "\n"
        writewndo(osstream.str(), "e")
        return s
    v = result
    return s