from DElightManagerC import *
from BGL import *
from math import *
from memory import *
from sys import *
from io import *
from string import *
from utils import *

# C++ includes translated to Mojo imports
# #include <iostream>
# #include <sstream>
# #include <iomanip>
# #include <vector>
# using namespace std;
# #ifndef INFINITY
# extern double INFINITY;
# #endif
# extern double NaN_QUIET;
# #include "DElightManagerC.h"
# #include "BGL.h"

# Note: INFINITY and NaN_QUIET are expected to be defined in the imported modules

@value
struct RHCoordSys3:
    var cs3: List[vector3]

    def __init__(inout self):
        self.cs3 = List[vector3](3)
        self.cs3[0] = vl_x  # x
        self.cs3[1] = vl_y  # y
        self.cs3[2] = vl_z  # z

    def __init__(inout self, cs0: RHCoordSys3):  # copy
        self.cs3 = List[vector3](3)
        self.cs3[0] = cs0[0]
        self.cs3[1] = cs0[1]
        self.cs3[2] = cs0[2]

    def __init__(inout self, z: vector3, p0: point3, p1: point3):
        self.cs3 = List[vector3](3)
        var v1: vector3 = vector3(p1 - p0)
        var v2: vector3 = cross(z, v1)
        if len(z) == 0 or len(v1) == 0 or len(v2) == 0:
            self.cs3[0] = vector3(NaN_QUIET, NaN_QUIET, NaN_QUIET)  # x
            self.cs3[1] = vector3(NaN_QUIET, NaN_QUIET, NaN_QUIET)  # y
            self.cs3[2] = vector3(NaN_QUIET, NaN_QUIET, NaN_QUIET)  # z
        else:
            self.cs3[2] = norm(z)  # z
            self.cs3[1] = norm(v2)  # y
            self.cs3[0] = cross(self.cs3[1], self.cs3[2])  # x

    def __init__(inout self, p0: point3, p1: point3, p2: point3):
        self.cs3 = List[vector3](3)
        var v0: vector3 = vector3(p1 - p0)
        var v1: vector3 = vector3(p2 - p0)
        var v2: vector3 = cross(v0, v1)
        if not len(v0) and not len(v1) and not len(v2):
            self.cs3[0] = vector3(NaN_QUIET, NaN_QUIET, NaN_QUIET)  # x
            self.cs3[1] = vector3(NaN_QUIET, NaN_QUIET, NaN_QUIET)  # y
            self.cs3[2] = vector3(NaN_QUIET, NaN_QUIET, NaN_QUIET)  # z
        else:
            self.cs3[2] = norm(v2)  # z
            self.cs3[0] = norm(v0)  # x
            self.cs3[1] = cross(self.cs3[2], self.cs3[0])  # y

    def __init__(inout self, phi: Double, theta: Double, zeta: Double):
        self.cs3 = List[vector3](3)
        var csTemp: RHCoordSys3 = RHCoordSys3()  # cs = [[1 0 0][0 1 0][0 0 1]]
        csTemp = csTemp.Rotate3a(phi, theta, zeta)
        self.cs3[0] = csTemp[0]
        self.cs3[1] = csTemp[1]
        self.cs3[2] = csTemp[2]

    def __init__(inout self, x: vector3, y: vector3, z: vector3):
        self.cs3 = List[vector3](3)
        self.cs3[0] = x
        self.cs3[1] = y
        self.cs3[2] = z

    def __del__(owned self):

    def __getitem__(self, i: Int) -> vector3:
        return self.cs3[i]

    def __setitem__(inout self, i: Int, val: vector3):
        self.cs3[i] = val

    def Rotate1(self, axis: vector3, angle: Double) -> RHCoordSys3:
        var csTemp: RHCoordSys3 = RHCoordSys3()
        var R1: matrix3 = Rot3(axis, angle)
        csTemp[0] = R1 * self.cs3[0]
        csTemp[1] = R1 * self.cs3[1]
        csTemp[2] = R1 * self.cs3[2]
        return csTemp

    def Rotate3(self, Azimuth: Double, Tilt: Double, AxialRot: Double) -> RHCoordSys3:
        var x1: vector3
        var z2: vector3
        var R1: matrix3
        var R2: matrix3
        var R3: matrix3
        var Rtot: matrix3
        if Azimuth:
            R1 = Rot3(self.cs3[2], Azimuth)  # rotation is around ICS_z
            x1 = R1 * self.cs3[0]
        else:
            R1 = vl_I
            x1 = self.cs3[0]
        if Tilt:
            R2 = Rot3(x1, Tilt)  # rotation is around x1
            z2 = R2 * self.cs3[2]  # z2 = R2*z1; z1 = ICS_z;
        else:
            R2 = vl_I
            z2 = self.cs3[2]
        if AxialRot:
            R3 = Rot3(z2, AxialRot)  # rotation is around z2 (= surface normal)
        else:
            R3 = vl_I
        Rtot = R3 * R2 * R1  # order is important
        return RHCoordSys3(Rtot * self.cs3[0], Rtot * self.cs3[1], Rtot * self.cs3[2])

    def Rotate3a(self, Azimuth: Double, Tilt: Double, AxialRot: Double) -> RHCoordSys3:
        var xx: vector3 = self.cs3[0]
        var zz: vector3 = self.cs3[2]
        if Azimuth:
            xx = Rot3(zz, Azimuth) * xx  # rotation is around ICS_z
        if Tilt:
            zz = Rot3(xx, Tilt) * zz  # rotation is around x1
        if AxialRot:
            xx = Rot3(zz, AxialRot) * xx  # rotation is around z2 (= surface normal)
        return RHCoordSys3(xx, cross(zz, xx), zz)

    def RotateY(self) -> RHCoordSys3:
        return RHCoordSys3(-self.cs3[0], self.cs3[1], -self.cs3[2])

    def RotAngles(self, Ref_CS: RHCoordSys3 = RHCoordSys3()) -> List[Double]:
        var RotAng: List[Double] = List[Double](3)
        var z3: vector3 = self.cs3[2]
        var costheta: Double = dot(z3, Ref_CS[2])
        if fabs(costheta) < 1.0:  # normal cases
            RotAng[1] = acos(costheta)
            var x2: vector3 = cross(Ref_CS[2], z3)  # order is important; x2 = x1
            RotAng[0] = atan2(dot(x2, Ref_CS[1]), dot(x2, Ref_CS[0]))
            var y2: vector3 = cross(z3, x2)  # order is important; z3 = z2
            var x3: vector3 = self.cs3[0]
            RotAng[2] = atan2(dot(x3, y2), dot(x3, x2))
        else:  # special cases: tilt angle theta = 0, PI
            if costheta >= 1.0:
                RotAng[1] = 0.0
            else:
                RotAng[1] = PI  # i.e., if (costheta <= -1.)
            RotAng[0] = atan2(dot(self.cs3[0], Ref_CS[1]), dot(self.cs3[0], Ref_CS[0]))
            RotAng[2] = 0.0
        return RotAng

def dirWCStoLCS(vDir1: vector3, LCS: RHCoordSys3) -> vector3:
    normalize(vDir1)
    return vector3(dot(vDir1, LCS[0]), dot(vDir1, LCS[1]), dot(vDir1, LCS[2]))

def dirLCStoWCS(vDir1: vector3, LCS: RHCoordSys3) -> vector3:
    normalize(vDir1)
    return vDir1[0] * LCS[0] + vDir1[1] * LCS[1] + vDir1[2] * LCS[2]

def dirCS1toCS2(vDir1: vector3, CS1: RHCoordSys3, CS2: RHCoordSys3) -> vector3:
    return dirWCStoLCS(dirLCStoWCS(vDir1, CS1), CS2)

# end namespace BldgGeomLib

# using namespace BldgGeomLib;

def operator_ostream(s: OStream, cs: RHCoordSys3) -> OStream:
    var w: Int = s.width()
    s << '[' << cs[0] << setw(w) << cs[1] << setw(w) << cs[2] << ']'
    return s

def operator_istream(s: IStream, cs: inout RHCoordSys3) -> IStream:
    var result: RHCoordSys3 = RHCoordSys3()
    var c: Char
    var osstream: OStringStream = OStringStream()
    while s >> c and isspace(c):  # ignore leading white space

    if c == '[':
        s >> result[0] >> result[1] >> result[2]
        if not s:
            osstream << "Expected number while reading RHCoordSys3\n"
            writewndo(osstream.str(), "e")
            return s
        while s >> c and isspace(c):

        if c != ']':
            s.clear(ios.failbit)
            osstream << "Expected ']' while reading RHCoordSys3\n"
            writewndo(osstream.str(), "e")
            return s
    else:
        s.clear(ios.failbit)
        osstream << "Expected '[' while reading RHCoordSys3\n"
        writewndo(osstream.str(), "e")
        return s
    cs = result
    return s