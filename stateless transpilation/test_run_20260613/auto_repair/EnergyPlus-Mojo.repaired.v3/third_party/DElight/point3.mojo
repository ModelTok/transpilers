from DEF import *
from CONST import *
from vector2 import *
from point2 import *
from vector3 import *
from point3 import *
from DElightManagerC import *

from memory import memset_zero
from math import sqrt
from sys import isspace

@value
struct point3:
    var elt: SIMD[f64, 3]

    def __init__(inout self):

    def __init__(inout self, x: f64, y: f64, z: f64):
        self.elt[0] = x
        self.elt[1] = y
        self.elt[2] = z

    def __init__(inout self, p: Self):
        self.elt[0] = p[0]
        self.elt[1] = p[1]
        self.elt[2] = p[2]

    def __init__(inout self, k: ZeroOrOne):
        self.elt[0] = k
        self.elt[1] = k
        self.elt[2] = k

    def __init__(inout self, a: Axis):
        self.MakeUnit(a, vl_one)

    def Elts(self) -> Int:
        return 3

    def __getitem__(self, i: Int) -> f64:
        return self.elt[i]

    def __setitem__(inout self, i: Int, val: f64):
        self.elt[i] = val

    def Ref(self) -> Pointer[f64]:
        return Pointer(self.elt.data)

    def Set(inout self, x: f64, y: f64, z: f64) -> Self:
        self.elt[0] = x
        self.elt[1] = y
        self.elt[2] = z
        return self

    def __copyinit__(inout self, other: Self):
        self.elt = other.elt

    def __moveinit__(inout self, owned other: Self):
        self.elt = other.elt

    def __del__(owned self):

    def __iadd__(inout self, a: vector3) -> Self:
        self.elt[0] += a[0]
        self.elt[1] += a[1]
        self.elt[2] += a[2]
        return self

    def __isub__(inout self, a: vector3) -> Self:
        self.elt[0] -= a[0]
        self.elt[1] -= a[1]
        self.elt[2] -= a[2]
        return self

    def __imul__(inout self, s: f64) -> Self:
        self.elt[0] *= s
        self.elt[1] *= s
        self.elt[2] *= s
        return self

    def __itruediv__(inout self, s: f64) -> Self:
        self.elt[0] /= s
        self.elt[1] /= s
        self.elt[2] /= s
        return self

    def __eq__(self, a: Self) -> Bool:
        return self.elt[0] == a[0] and self.elt[1] == a[1] and self.elt[2] == a[2]

    def __ne__(self, a: Self) -> Bool:
        return self.elt[0] != a[0] or self.elt[1] != a[1] or self.elt[2] != a[2]

    def __lt__(self, a: Self) -> Bool:
        return ((self.elt[0] < a[0]) or ((self.elt[0] == a[0]) and (self.elt[1] < a[1])) or ((self.elt[0] == a[0]) and (self.elt[1] == a[1]) and (self.elt[2] < a[2])))

    def __ge__(self, a: Self) -> Bool:
        return self.elt[0] >= a[0] and self.elt[1] >= a[1] and self.elt[2] >= a[2]

    def __add__(self, a: vector3) -> Self:
        var result: Self
        result[0] = self.elt[0] + a[0]
        result[1] = self.elt[1] + a[1]
        result[2] = self.elt[2] + a[2]
        return result

    def __sub__(self, a: vector3) -> Self:
        var result: Self
        result[0] = self.elt[0] - a[0]
        result[1] = self.elt[1] - a[1]
        result[2] = self.elt[2] - a[2]
        return result

    def __sub__(self, a: Self) -> vector3:
        var result: vector3
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

    def __mul__(self, s: f64) -> Self:
        var result: Self
        result[0] = self.elt[0] * s
        result[1] = self.elt[1] * s
        result[2] = self.elt[2] * s
        return result

    def __truediv__(self, s: f64) -> Self:
        var result: Self
        result[0] = self.elt[0] / s
        result[1] = self.elt[1] / s
        result[2] = self.elt[2] / s
        return result

    def MakeZero(inout self) -> Self:
        self.elt[0] = vl_zero
        self.elt[1] = vl_zero
        self.elt[2] = vl_zero
        return self

    def MakeUnit(inout self, n: Int, k: f64 = vl_one) -> Self:
        if n == 0:
            self.elt[0] = k
            self.elt[1] = vl_zero
            self.elt[2] = vl_zero
        elif n == 1:
            self.elt[0] = vl_zero
            self.elt[1] = k
            self.elt[2] = vl_zero
        elif n == 2:
            self.elt[0] = vl_zero
            self.elt[1] = vl_zero
            self.elt[2] = k
        else:
            self.elt[0] = 0
            self.elt[1] = 0
            self.elt[2] = 0
        return self

    def MakeBlock(inout self, k: f64 = vl_one) -> Self:
        self.elt[0] = k
        self.elt[1] = k
        self.elt[2] = k
        return self

    def __assign__(inout self, k: ZeroOrOne) -> Self:
        self.elt[0] = k
        self.elt[1] = k
        self.elt[2] = k
        return self

    def __assign__(inout self, a: vector3) -> Self:
        self.elt[0] = a[0]
        self.elt[1] = a[1]
        self.elt[2] = a[2]
        return self

    def __assign__(inout self, a: Self) -> Self:
        self.elt[0] = a[0]
        self.elt[1] = a[1]
        self.elt[2] = a[2]
        return self

def __mul__(s: f64, p: point3) -> point3:
    return p * s

def sqrdist(a: point3, b: point3) -> f64:
    return ((b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1]) + (b[2] - a[2]) * (b[2] - a[2]))

def dist(a: point3, b: point3) -> f64:
    return sqrt(sqrdist(a, b))

def __str__(p: point3) -> String:
    var w: Int = 0
    var s: String = "["
    s += str(p[0]) + " "
    s += str(p[1]) + " "
    s += str(p[2]) + "]"
    return s

def __repr__(p: point3) -> String:
    return __str__(p)

def __lshift__(s: String, p: point3) -> String:
    var w: Int = 0
    var result: String = s
    result += "["
    result += str(p[0]) + " "
    result += str(p[1]) + " "
    result += str(p[2]) + "]"
    return result

def __rshift__(s: String, p: point3) -> String:
    var result: point3
    var c: UInt8
    var osstream: String
    # skip through spaces
    var idx: Int = 0
    while idx < len(s):
        c = s[idx]
        if not isspace(c):
            break
        idx += 1
    if idx >= len(s):
        return s
    if c != ord('['):
        # putback not supported, return fail
        return s
    idx += 1
    # parse numbers
    var num_str: String = ""
    var num_idx: Int = 0
    var nums: List[f64] = List[f64]()
    while idx < len(s) and len(nums) < 3:
        c = s[idx]
        if isspace(c) or c == ord(']'):
            if len(num_str) > 0:
                nums.append(atol(num_str))
                num_str = ""
            if c == ord(']'):
                break
        else:
            num_str += chr(c)
        idx += 1
    if len(nums) < 3:
        return s
    result[0] = nums[0]
    result[1] = nums[1]
    result[2] = nums[2]
    # skip to ]
    while idx < len(s):
        c = s[idx]
        if c == ord(']'):
            break
        idx += 1
    if idx >= len(s):
        return s
    p = result
    return s