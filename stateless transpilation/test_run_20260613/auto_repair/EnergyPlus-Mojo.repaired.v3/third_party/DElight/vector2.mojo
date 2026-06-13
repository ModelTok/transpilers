from DEF import *
from CONST import *
from vector2 import *
from point2 import *
from DElightManagerC import *
from memory import memset
from math import sqrt
from sys import info

@value
struct vector2:
    var elt: StaticTuple[Double, 2]
    
    def __init__(inout self):

    def __init__(inout self, x: Double, y: Double):
        self.elt[0] = x
        self.elt[1] = y
    
    def __init__(inout self, v: Self):
        self.elt[0] = v[0]
        self.elt[1] = v[1]
    
    def __init__(inout self, a: point2, b: point2):
        self.elt[0] = b[0] - a[0]
        self.elt[1] = b[1] - a[1]
    
    def __init__(inout self, k: ZeroOrOne):
        self.elt[0] = k
        self.elt[1] = k
    
    def __init__(inout self, k: Axis):
        self.MakeUnit(k.value, vl_one)
    
    def __getitem__(self, i: Int) -> Double:
        return self.elt[i]
    
    def __setitem__(inout self, i: Int, val: Double):
        self.elt[i] = val
    
    def Elts(self) -> Int:
        return 2
    
    def Ref(self) -> Pointer[Double]:
        return Pointer[Double](self.elt.data)
    
    def __copyinit__(inout self, existing: Self):
        self.elt[0] = existing[0]
        self.elt[1] = existing[1]
    
    def __moveinit__(inout self, owned existing: Self):
        self.elt[0] = existing[0]
        self.elt[1] = existing[1]
    
    def __del__(owned self):

    def __iadd__(inout self, a: Self) -> Self:
        self.elt[0] += a[0]
        self.elt[1] += a[1]
        return self
    
    def __isub__(inout self, a: Self) -> Self:
        self.elt[0] -= a[0]
        self.elt[1] -= a[1]
        return self
    
    def __imul__(inout self, a: Self) -> Self:
        self.elt[0] *= a[0]
        self.elt[1] *= a[1]
        return self
    
    def __imul__(inout self, s: Double) -> Self:
        self.elt[0] *= s
        self.elt[1] *= s
        return self
    
    def __itruediv__(inout self, a: Self) -> Self:
        self.elt[0] /= a[0]
        self.elt[1] /= a[1]
        return self
    
    def __itruediv__(inout self, s: Double) -> Self:
        self.elt[0] /= s
        self.elt[1] /= s
        return self
    
    def __lt__(self, a: Self) -> Bool:
        return (self.elt[0] < a[0]) or ((self.elt[0] == a[0]) and (self.elt[1] < a[1]))
    
    def __eq__(self, a: Self) -> Bool:
        return self.elt[0] == a[0] and self.elt[1] == a[1]
    
    def __ne__(self, a: Self) -> Bool:
        return self.elt[0] != a[0] or self.elt[1] != a[1]
    
    def __add__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] + a[0]
        result[1] = self.elt[1] + a[1]
        return result
    
    def __sub__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] - a[0]
        result[1] = self.elt[1] - a[1]
        return result
    
    def __neg__(self) -> Self:
        var result: Self
        result[0] = -self.elt[0]
        result[1] = -self.elt[1]
        return result
    
    def __mul__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] * a[0]
        result[1] = self.elt[1] * a[1]
        return result
    
    def __mul__(self, s: Double) -> Self:
        var result: Self
        result[0] = self.elt[0] * s
        result[1] = self.elt[1] * s
        return result
    
    def __truediv__(self, a: Self) -> Self:
        var result: Self
        result[0] = self.elt[0] / a[0]
        result[1] = self.elt[1] / a[1]
        return result
    
    def __truediv__(self, s: Double) -> Self:
        var result: Self
        result[0] = self.elt[0] / s
        result[1] = self.elt[1] / s
        return result
    
    def MakeZero(inout self) -> Self:
        self.elt[0] = vl_zero
        self.elt[1] = vl_zero
        return self
    
    def MakeUnit(inout self, i: Int, k: Double = vl_one) -> Self:
        if i == 0:
            self.elt[0] = k; self.elt[1] = vl_zero
        elif i == 1:
            self.elt[0] = vl_zero; self.elt[1] = k
        else:
            self.elt[0] = 0; self.elt[1] = 0
        return self
    
    def MakeBlock(inout self, k: Double = vl_one) -> Self:
        self.elt[0] = k; self.elt[1] = k
        return self
    
    def __assign__(inout self, v: Self) -> Self:
        self.elt[0] = v[0]
        self.elt[1] = v[1]
        return self
    
    def __assign__(inout self, k: ZeroOrOne) -> Self:
        self.elt[0] = k
        self.elt[1] = k
        return self
    
    def __assign__(inout self, k: Axis) -> Self:
        self.MakeUnit(k.value, vl_1)
        return self

def __mul__(s: Double, v: vector2) -> vector2:
    return v * s

def dot(a: vector2, b: vector2) -> Double:
    return a[0] * b[0] + a[1] * b[1]

def len(v: vector2) -> Double:
    return sqrt(dot(v, v))

def sqrlen(v: vector2) -> Double:
    return dot(v, v)

def norm(v: vector2) -> vector2:
    if sqrlen(v) > 0.0:
        return v / len(v)
    return vector2(0, 0)

def normalize(inout v: vector2):
    if sqrlen(v) > 0.0:
        v /= len(v)

def cross(v: vector2) -> vector2:
    var result: vector2
    result[0] = v[1]
    result[1] = -v[0]
    return result