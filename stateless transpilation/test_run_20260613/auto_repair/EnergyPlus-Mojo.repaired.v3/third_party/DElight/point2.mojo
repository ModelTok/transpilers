from DEF import *
from CONST import *
from vector2 import vector2
from point2 import point2
from DElightManagerC import writewndo

from memory import memset
from math import sqrt
from sys import isspace

@value
struct point2:
    var elt: StaticTuple[Float64, 2]

    def __init__(inout self):
        self.elt[0] = 0.0
        self.elt[1] = 0.0

    def __init__(inout self, x: Float64, y: Float64):
        self.elt[0] = x
        self.elt[1] = y

    def __init__(inout self, other: Self):
        self.elt[0] = other.elt[0]
        self.elt[1] = other.elt[1]

    def __init__(inout self, k: ZeroOrOne):
        self.elt[0] = k
        self.elt[1] = k

    def __init__(inout self, k: Axis):
        self.MakeUnit(k, vl_one)

    def __getitem__(inout self, i: Int) -> Float64:
        return self.elt[i]

    def __getitem__(self, i: Int) -> Float64:
        return self.elt[i]

    def __setitem__(inout self, i: Int, val: Float64):
        self.elt[i] = val

    def Elts(self) -> Int:
        return 2

    def Ref(self) -> Pointer[Float64]:
        return Pointer[Float64](address_of(self.elt[0]))

    def Set(inout self, x: Float64, y: Float64) -> Self:
        self.elt[0] = x
        self.elt[1] = y
        return self

    def __copyinit__(inout self, other: Self):
        self.elt[0] = other.elt[0]
        self.elt[1] = other.elt[1]

    def __moveinit__(inout self, owned other: Self):
        self.elt[0] = other.elt[0]
        self.elt[1] = other.elt[1]

    def __del__(owned self):

    def __iadd__(inout self, a: vector2) -> Self:
        self.elt[0] += a[0]
        self.elt[1] += a[1]
        return self

    def __isub__(inout self, a: vector2) -> Self:
        self.elt[0] -= a[0]
        self.elt[1] -= a[1]
        return self

    def __imul__(inout self, s: Float64) -> Self:
        self.elt[0] *= s
        self.elt[1] *= s
        return self

    def __itruediv__(inout self, s: Float64) -> Self:
        self.elt[0] /= s
        self.elt[1] /= s
        return self

    def __lt__(self, a: Self) -> Bool:
        return (self.elt[0] < a[0]) or ((self.elt[0] == a[0]) and (self.elt[1] < a[1]))

    def __eq__(self, a: Self) -> Bool:
        return self.elt[0] == a[0] and self.elt[1] == a[1]

    def __ne__(self, a: Self) -> Bool:
        return self.elt[0] != a[0] or self.elt[1] != a[1]

    def __add__(self, a: vector2) -> Self:
        var result: Self
        result[0] = self.elt[0] + a[0]
        result[1] = self.elt[1] + a[1]
        return result

    def __sub__(self, a: vector2) -> Self:
        var result: Self
        result[0] = self.elt[0] - a[0]
        result[1] = self.elt[1] - a[1]
        return result

    def __sub__(self, a: Self) -> vector2:
        var result: vector2
        result[0] = self.elt[0] - a[0]
        result[1] = self.elt[1] - a[1]
        return result

    def __neg__(self) -> Self:
        var result: Self
        result[0] = -self.elt[0]
        result[1] = -self.elt[1]
        return result

    def __mul__(self, s: Float64) -> Self:
        var result: Self
        result[0] = self.elt[0] * s
        result[1] = self.elt[1] * s
        return result

    def __truediv__(self, s: Float64) -> Self:
        var result: Self
        result[0] = self.elt[0] / s
        result[1] = self.elt[1] / s
        return result

    def MakeZero(inout self) -> Self:
        self.elt[0] = vl_zero
        self.elt[1] = vl_zero
        return self

    def MakeUnit(inout self, i: Int, k: Float64 = vl_one) -> Self:
        if i == 0:
            self.elt[0] = k
            self.elt[1] = vl_zero
        elif i == 1:
            self.elt[0] = vl_zero
            self.elt[1] = k
        else:
            self.elt[0] = 0.0
            self.elt[1] = 0.0
        return self

    def MakeBlock(inout self, k: Float64 = vl_one) -> Self:
        self.elt[0] = k
        self.elt[1] = k
        return self

def __mul__(s: Float64, p: point2) -> point2:
    return p * s

def dist(a: point2, b: point2) -> Float64:
    return sqrt(sqrdist(a, b))

def sqrdist(a: point2, b: point2) -> Float64:
    return (b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1])

def dot(a: point2, b: point2) -> Float64:
    return a[0] * b[0] + a[1] * b[1]

def cross(a: point2) -> point2:
    var result: point2
    result[0] = a[1]
    result[1] = -a[0]
    return result

def operator_lt(s: point2, p: point2) -> Bool:
    return s < p

def operator_eq(s: point2, p: point2) -> Bool:
    return s == p

def operator_ne(s: point2, p: point2) -> Bool:
    return s != p

def operator_add(s: point2, v: vector2) -> point2:
    return s + v

def operator_sub(s: point2, v: vector2) -> point2:
    return s - v

def operator_sub(s: point2, p: point2) -> vector2:
    return s - p

def operator_neg(s: point2) -> point2:
    return -s

def operator_mul(s: point2, d: Float64) -> point2:
    return s * d

def operator_div(s: point2, d: Float64) -> point2:
    return s / d

def operator_mul(d: Float64, s: point2) -> point2:
    return s * d

def operator_ostream(s: String, p: point2) -> String:
    var w: Int = 0  # width not directly supported, simplified
    return s + "[" + str(p[0]) + " " + str(p[1]) + "]"

def operator_istream(s: String, inout p: point2) -> String:
    var result: point2
    var c: UInt8
    var osstream: String = ""
    var idx: Int = 0
    # skip spaces
    while idx < len(s) and isspace(s[idx]):
        idx += 1
    if idx >= len(s):
        return s
    c = s[idx]
    if c != ord('['):
        # putback not possible, return fail
        return s
    idx += 1
    # parse two numbers
    var num_str: String = ""
    while idx < len(s) and not isspace(s[idx]) and s[idx] != ']':
        num_str += chr(s[idx])
        idx += 1
    result[0] = atof(num_str)
    # skip spaces
    while idx < len(s) and isspace(s[idx]):
        idx += 1
    num_str = ""
    while idx < len(s) and not isspace(s[idx]) and s[idx] != ']':
        num_str += chr(s[idx])
        idx += 1
    result[1] = atof(num_str)
    # skip to ]
    while idx < len(s) and isspace(s[idx]):
        idx += 1
    if idx >= len(s) or s[idx] != ord(']'):
        osstream += "point2:ReadError3: Expected ']' - got '" + chr(s[idx]) + "'\n"
        writewndo(osstream, "e")
        return s
    p = result
    return s