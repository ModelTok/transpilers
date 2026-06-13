from DElightManagerC import writewndo
from DEF import Int, Char, Bool, Void, ZeroOrOne, Block
from CONST import vl_one, vl_zero
from vector3 import vector3, dot, cross
from point3 import point3
from point2 import point2
from vector2 import vector2
from math import sin, cos, isspace

alias Double = Float64

module BldgGeomLib:

    struct matrix3:
        var row: StaticArray[vector3, 3]

        def __init__(inout self):

        def __init__(inout self, a: Double, b: Double, c: Double,
                          d: Double, e: Double, f: Double,
                          g: Double, h: Double, i: Double):
            self.row[0][0] = a;  self.row[0][1] = b;  self.row[0][2] = c
            self.row[1][0] = d;  self.row[1][1] = e;  self.row[1][2] = f
            self.row[2][0] = g;  self.row[2][1] = h;  self.row[2][2] = i

        def __init__(inout self, other: Self):
            self.row[0] = other.row[0]
            self.row[1] = other.row[1]
            self.row[2] = other.row[2]

        def __init__(inout self, k: ZeroOrOne):
            self.MakeDiag(k)

        def __init__(inout self, k: Block):
            self.MakeBlock(k)

        def Rows(self) -> Int:
            return 3

        def Cols(self) -> Int:
            return 3

        def __getitem__(self, i: Int) -> vector3:
            return self.row[i]

        def __setitem__(self, i: Int, value: vector3):
            self.row[i] = value

        def Ref(self) -> Pointer[Double]:
            return self.row.ptr.__ptr_unsafe__(Pointer[Double])

        def __copyinit__(inout self, other: Self):
            self = other

        def __moveinit__(inout self, owned other: Self):
            self.row = other.row

        def __del__(owned self):

        def __iadd__(inout self, m: Self) -> Self:
            self.row[0] += m.row[0]
            self.row[1] += m.row[1]
            self.row[2] += m.row[2]
            return self

        def __isub__(inout self, m: Self) -> Self:
            self.row[0] -= m.row[0]
            self.row[1] -= m.row[1]
            self.row[2] -= m.row[2]
            return self

        def __imul__(inout self, m: Self) -> Self:
            self = self * m
            return self

        def __imul__(inout self, s: Double) -> Self:
            self.row[0] *= s
            self.row[1] *= s
            self.row[2] *= s
            return self

        def __itruediv__(inout self, s: Double) -> Self:
            self.row[0] /= s
            self.row[1] /= s
            self.row[2] /= s
            return self

        def __lt__(self, m: Self) -> Bool:
            return ( (self.row[0] < m.row[0]) or ((self.row[0] == m.row[0]) and (self.row[1] < m.row[1])) or ((self.row[0] == m.row[0]) and (self.row[1] == m.row[1]) and (self.row[2] < m.row[2])) )

        def __eq__(self, m: Self) -> Bool:
            return (self.row[0] == m.row[0]) and (self.row[1] == m.row[1]) and (self.row[2] == m.row[2])

        def __ne__(self, m: Self) -> Bool:
            return (self.row[0] != m.row[0]) or (self.row[1] != m.row[1]) or (self.row[2] != m.row[2])

        def __add__(self, m: Self) -> Self:
            var result: Self
            result.row[0] = self.row[0] + m.row[0]
            result.row[1] = self.row[1] + m.row[1]
            result.row[2] = self.row[2] + m.row[2]
            return result

        def __sub__(self, m: Self) -> Self:
            var result: Self
            result.row[0] = self.row[0] - m.row[0]
            result.row[1] = self.row[1] - m.row[1]
            result.row[2] = self.row[2] - m.row[2]
            return result

        def __neg__(self) -> Self:
            var result: Self
            result.row[0] = -self.row[0]
            result.row[1] = -self.row[1]
            result.row[2] = -self.row[2]
            return result

        def __mul__(self, m: Self) -> Self:
            alias N = self.row
            alias M = m.row
            var result: Self
            result.row[0][0] = N[0][0] * M[0][0] + N[0][1] * M[1][0] + N[0][2] * M[2][0]
            result.row[0][1] = N[0][0] * M[0][1] + N[0][1] * M[1][1] + N[0][2] * M[2][1]
            result.row[0][2] = N[0][0] * M[0][2] + N[0][1] * M[1][2] + N[0][2] * M[2][2]
            result.row[1][0] = N[1][0] * M[0][0] + N[1][1] * M[1][0] + N[1][2] * M[2][0]
            result.row[1][1] = N[1][0] * M[0][1] + N[1][1] * M[1][1] + N[1][2] * M[2][1]
            result.row[1][2] = N[1][0] * M[0][2] + N[1][1] * M[1][2] + N[1][2] * M[2][2]
            result.row[2][0] = N[2][0] * M[0][0] + N[2][1] * M[1][0] + N[2][2] * M[2][0]
            result.row[2][1] = N[2][0] * M[0][1] + N[2][1] * M[1][1] + N[2][2] * M[2][1]
            result.row[2][2] = N[2][0] * M[0][2] + N[2][1] * M[1][2] + N[2][2] * M[2][2]
            return result

        def __mul__(self, s: Double) -> Self:
            var result: Self
            result.row[0] = self.row[0] * s
            result.row[1] = self.row[1] * s
            result.row[2] = self.row[2] * s
            return result

        def __truediv__(self, s: Double) -> Self:
            var result: Self
            result.row[0] = self.row[0] / s
            result.row[1] = self.row[1] / s
            result.row[2] = self.row[2] / s
            return result

        def MakeZero(inout self):
            for i in range(9):
                (Pointer[Double](self.row.ptr.__ptr_unsafe__()))[i] = vl_zero

        def MakeDiag(inout self, k: Double = vl_one):
            for i in range(3):
                for j in range(3):
                    if i == j:
                        self.row[i][j] = k
                    else:
                        self.row[i][j] = vl_zero

        def MakeBlock(inout self, k: Double = vl_one):
            for i in range(9):
                (Pointer[Double](self.row.ptr.__ptr_unsafe__()))[i] = k

        def MakeRot(inout self, axis: vector3, theta: Double) -> Self:
            var s: Double
            var q: StaticArray[Double, 4]
            theta /= 2.0
            s = sin(theta)
            q[0] = s * axis[0]
            q[1] = s * axis[1]
            q[2] = s * axis[2]
            q[3] = cos(theta)
            var i2: Double = 2 * q[0]
            var j2: Double = 2 * q[1]
            var k2: Double = 2 * q[2]
            var ij: Double = i2 * q[1]
            var ik: Double = i2 * q[2]
            var jk: Double = j2 * q[2]
            var ri: Double = i2 * q[3]
            var rj: Double = j2 * q[3]
            var rk: Double = k2 * q[3]
            i2 *= q[0]
            j2 *= q[1]
            k2 *= q[2]
            self.row[0][0] = 1.0 - j2 - k2;  self.row[0][1] = ij - rk;       self.row[0][2] = ik + rj
            self.row[1][0] = ij + rk;       self.row[1][1] = 1.0 - i2 - k2;  self.row[1][2] = jk - ri
            self.row[2][0] = ik - rj;       self.row[2][1] = jk + ri;       self.row[2][2] = 1.0 - i2 - j2
            return self

    # Inline free functions within namespace (from header)

    def operator*(inout p: point3, m: matrix3) -> point3:
        var result: point3
        result[0] = p[0] * m[0][0] + p[1] * m[1][0] + p[2] * m[2][0]
        result[1] = p[0] * m[0][1] + p[1] * m[1][1] + p[2] * m[2][1]
        result[2] = p[0] * m[0][2] + p[1] * m[1][2] + p[2] * m[2][2]
        return result

    def operator*(m: matrix3, p: point3) -> point3:
        var result: point3
        result[0] = p[0] * m[0][0] + p[1] * m[0][1] + p[2] * m[0][2]
        result[1] = p[0] * m[1][0] + p[1] * m[1][1] + p[2] * m[1][2]
        result[2] = p[0] * m[2][0] + p[1] * m[2][1] + p[2] * m[2][2]
        return result

    def operator*=(inout p: point3, m: matrix3) -> point3:
        var t0: Double
        var t1: Double
        t0   = p[0] * m[0][0] + p[1] * m[1][0] + p[2] * m[2][0]
        t1   = p[0] * m[0][1] + p[1] * m[1][1] + p[2] * m[2][1]
        p[2] = p[0] * m[0][2] + p[1] * m[1][2] + p[2] * m[2][2]
        p[0] = t0
        p[1] = t1
        return p

    def operator*(m: matrix3, v: vector3) -> vector3:
        var result: vector3
        result[0] = v[0] * m[0][0] + v[1] * m[0][1] + v[2] * m[0][2]
        result[1] = v[0] * m[1][0] + v[1] * m[1][1] + v[2] * m[1][2]
        result[2] = v[0] * m[2][0] + v[1] * m[2][1] + v[2] * m[2][2]
        return result

    def operator*(v: vector3, m: matrix3) -> vector3:
        var result: vector3
        result[0] = v[0] * m[0][0] + v[1] * m[1][0] + v[2] * m[2][0]
        result[1] = v[0] * m[0][1] + v[1] * m[1][1] + v[2] * m[2][1]
        result[2] = v[0] * m[0][2] + v[1] * m[1][2] + v[2] * m[2][2]
        return result

    def operator*=(inout v: vector3, m: matrix3) -> vector3:
        var t0: Double
        var t1: Double
        t0   = v[0] * m[0][0] + v[1] * m[1][0] + v[2] * m[2][0]
        t1   = v[0] * m[0][1] + v[1] * m[1][1] + v[2] * m[2][1]
        v[2] = v[0] * m[0][2] + v[1] * m[1][2] + v[2] * m[2][2]
        v[0] = t0
        v[1] = t1
        return v

    def operator*(s: Double, m: matrix3) -> matrix3:
        return m * s

    def trans(m: matrix3) -> matrix3:
        var result: matrix3
        result[0][0] = m[0][0]; result[0][1] = m[1][0]; result[0][2] = m[2][0]
        result[1][0] = m[0][1]; result[1][1] = m[1][1]; result[1][2] = m[2][1]
        result[2][0] = m[0][2]; result[2][1] = m[1][2]; result[2][2] = m[2][2]
        return result

    def trace(m: matrix3) -> Double:
        return m[0][0] + m[1][1] + m[2][2]

    def adj(m: matrix3) -> matrix3:
        var result: matrix3
        result[0] = cross(m[1], m[2])
        result[1] = cross(m[2], m[0])
        result[2] = cross(m[0], m[1])
        return result

    def det(m: matrix3) -> Double:
        return dot(m[0], cross(m[1], m[2]))

    def inv(m: matrix3) -> matrix3:
        var mDet: Double
        var adjoint: matrix3
        var result: matrix3
        adjoint = adj(m)
        mDet = dot(adjoint[0], m[0])
        if mDet != 0.0:
            result = trans(adjoint)
            result /= mDet
        else:
            result.MakeZero()
        return result

    def oprod(a: vector3, b: vector3) -> matrix3:
        var result: matrix3
        result[0] = a[0] * b
        result[1] = a[1] * b
        result[2] = a[2] * b
        return result

    def Rot3(axis: vector3, theta: Double) -> matrix3:
        var result: matrix3
        result.MakeRot(axis, theta)
        return result


# Outside namespace

def operator<<(inout s: String, m: BldgGeomLib.matrix3) -> String:
    var w: Int = s.len()  # approximate width, not exactly same as s.width()
    s += '['
    s += str(m[0])
    s += '\n'
    # setw not directly supported, add spaces based on w
    for _ in range(w):
        s += ' '
    s += str(m[1])
    s += '\n'
    for _ in range(w):
        s += ' '
    s += str(m[2])
    s += ']'
    s += '\n'
    return s

def operator>>(inout s: String, inout m: BldgGeomLib.matrix3) -> String:
    var result: BldgGeomLib.matrix3
    var c: String
    var osstream: String = ""
    # skip spaces
    while len(s) > 0:
        c = s[0]
        if not c.isspace():
            break
        s = s[1:]
    if len(s) == 0:
        return s
    # check for fail bit not really simulated
    if s[0] != '[':
        s = '[' + s  # putback (simplified)
        # set fail could be simulated with error
        # just return for simplicity
        return s
    s = s[1:]  # eat '['
    # parse three vector3 (assume space separated)
    # We'll read line by line; simplified: use Python-like split
    # This is a rough approximation
    var parts: List[String] = s.split()
    if len(parts) < 9:
        osstream = "matrix3:ReadError2: Expected number\n"
        writewndo(osstream, "e")
        return s
    # parse into result
    var idx: Int = 0
    for i in range(3):
        for j in range(3):
            result[i][j] = parts[idx].to_float64()
            idx += 1
    # skip remaining until ']'
    while len(s) > 0 and s[0] != ']':
        s = s[1:]
    if len(s) == 0 or s[0] != ']':
        osstream = "matrix3:ReadError3: Expected ']'\n"
        writewndo(osstream, "e")
        return s
    s = s[1:]  # eat ']'
    m = result
    return s