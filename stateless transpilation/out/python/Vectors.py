from dataclasses import dataclass, field
from typing import List
import math

# EXTERNAL DEPS (to wire in glue):
# - Vector, PlaneEq, Polyhedron: from DataVectorTypes
# - EnergyPlusData: from Data.EnergyPlusData (state.dataVectors.p0)
# - Constant.DegToRad, Constant.OneThousandth, Constant.OneMillionth, Constant.SmallDistance

@dataclass
class Vector:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

    def __add__(self, other):
        return Vector(self.x + other.x, self.y + other.y, self.z + other.z)

    def __sub__(self, other):
        return Vector(self.x - other.x, self.y - other.y, self.z - other.z)

    def __mul__(self, scalar):
        return Vector(self.x * scalar, self.y * scalar, self.z * scalar)

    def __rmul__(self, scalar):
        return Vector(self.x * scalar, self.y * scalar, self.z * scalar)

    def __truediv__(self, scalar):
        return Vector(self.x / scalar, self.y / scalar, self.z / scalar)

    def __iadd__(self, other):
        if isinstance(other, Vector):
            self.x += other.x
            self.y += other.y
            self.z += other.z
        else:
            self.x = float(other)
            self.y = float(other)
            self.z = float(other)
        return self

    def __itruediv__(self, scalar):
        self.x /= scalar
        self.y /= scalar
        self.z /= scalar
        return self

def cross(v1: Vector, v2: Vector) -> Vector:
    return Vector(
        v1.y * v2.z - v1.z * v2.y,
        v1.z * v2.x - v1.x * v2.z,
        v1.x * v2.y - v1.y * v2.x
    )

def dot(v1: Vector, v2: Vector) -> float:
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

@dataclass
class PlaneEq:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0
    w: float = 0.0

@dataclass
class SurfaceFace:
    FacePoints: List[Vector] = field(default_factory=list)
    NewellAreaVector: Vector = field(default_factory=lambda: Vector(0.0, 0.0, 0.0))

@dataclass
class Polyhedron:
    NumSurfaceFaces: int = 0
    SurfaceFace: List[SurfaceFace] = field(default_factory=list)

@dataclass
class VectorsData:
    p0: Vector = field(default_factory=lambda: Vector(0.0, 0.0, 0.0))

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.p0 = Vector(0.0, 0.0, 0.0)

XUnit = Vector(1.0, 0.0, 0.0)
YUnit = Vector(0.0, 1.0, 0.0)
ZUnit = Vector(0.0, 0.0, 1.0)

def nint64(x: float) -> int:
    return int(x + 0.5) if x >= 0 else int(x - 0.5)

def mod(a: float, b: float) -> float:
    return a - b * int(a / b)

class Constant:
    DegToRad = 0.0174532925199432957692
    OneThousandth = 0.001
    OneMillionth = 0.000001
    SmallDistance = 1e-10

def AreaPolygon(n: int, p: List[Vector]) -> float:
    edge0 = p[1] - p[0]
    edge1 = p[2] - p[0]

    edgex = cross(edge0, edge1)
    nor = VecNormalize(edgex)

    csum = Vector(0.0, 0.0, 0.0)

    for i in range(n - 1):
        csum += cross(p[i], p[i + 1])
    csum += cross(p[n - 1], p[0])

    areap = 0.5 * abs(dot(nor, csum))

    return areap

def VecSquaredLength(vec: Vector) -> float:
    return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z

def VecLength(vec: Vector) -> float:
    return math.sqrt(VecSquaredLength(vec))

def VecNegate(vec: Vector) -> Vector:
    return Vector(-vec.x, -vec.y, -vec.z)

def VecNormalize(vec: Vector) -> Vector:
    veclen = VecLength(vec)
    if veclen != 0.0:
        return Vector(vec.x / veclen, vec.y / veclen, vec.z / veclen)
    else:
        return Vector(0.0, 0.0, 0.0)

def VecRound(vec: Vector, roundto: float) -> None:
    vec.x = nint64(vec.x * roundto) / roundto
    vec.y = nint64(vec.y * roundto) / roundto
    vec.z = nint64(vec.z * roundto) / roundto

def DetermineAzimuthAndTilt(Surf: List[Vector], Azimuth: list, Tilt: list, lcsx: list, lcsy: list, lcsz: list, NewellSurfaceNormalVector: Vector) -> None:
    lcsx[0] = VecNormalize(Surf[2] - Surf[1])
    lcsz[0] = NewellSurfaceNormalVector
    lcsy[0] = cross(lcsz[0], lcsx[0])

    costheta = dot(lcsz[0], ZUnit)

    epsilon = 1.12e-16
    rotang_0 = 0.0
    if abs(costheta) < 1.0 - epsilon:
        x2 = cross(ZUnit, lcsz[0])
        rotang_0 = math.atan2(dot(x2, YUnit), dot(x2, XUnit))
    else:
        rotang_0 = math.atan2(dot(lcsx[0], YUnit), dot(lcsx[0], XUnit))

    tlt = math.acos(NewellSurfaceNormalVector.z)
    tlt /= Constant.DegToRad

    az = rotang_0

    az /= Constant.DegToRad
    az = mod(450.0 - az, 360.0)
    az += 90.0
    if az < 0.0:
        az += 360.0
    az = mod(az, 360.0)

    if abs(az - 360.0) < Constant.OneThousandth:
        az = 0.0
    elif abs(az - 180.0) < Constant.OneMillionth:
        az = 180.0
    if abs(tlt - 180.0) < Constant.OneMillionth:
        tlt = 180.0

    Azimuth[0] = az
    Tilt[0] = tlt

def PlaneEquation(verts: List[Vector], nverts: int, plane: list, error: list) -> None:
    normal = Vector(0.0, 0.0, 0.0)
    refpt = Vector(0.0, 0.0, 0.0)
    for i in range(nverts):
        u = verts[i]
        v = verts[i + 1] if i < nverts - 1 else verts[0]
        normal.x += (u.y - v.y) * (u.z + v.z)
        normal.y += (u.z - v.z) * (u.x + v.x)
        normal.z += (u.x - v.x) * (u.y + v.y)
        refpt += u

    lenvec = VecLength(normal)
    error[0] = False
    if lenvec != 0.0:
        plane[0].x = normal.x / lenvec
        plane[0].y = normal.y / lenvec
        plane[0].z = normal.z / lenvec
        lenvec *= nverts
        plane[0].w = -dot(refpt, normal) / lenvec
    else:
        error[0] = True

def Pt2Plane(pt: Vector, pleq: PlaneEq) -> float:
    return pleq.x * pt.x + pleq.y * pt.y + pleq.z * pt.z + pleq.w

def CreateNewellAreaVector(VList: List[Vector], NSides: int, OutNewellAreaVector: list) -> None:
    OutNewellAreaVector[0] = Vector(0.0, 0.0, 0.0)

    V1 = VList[1] - VList[0]
    for Vert in range(2, NSides):
        V2 = VList[Vert] - VList[0]
        OutNewellAreaVector[0] += cross(V1, V2)
        V1 = V2

    OutNewellAreaVector[0] /= 2.0

def CreateNewellSurfaceNormalVector(VList: List[Vector], NSides: int, OutNewellSurfaceNormalVector: list) -> None:
    OutNewellSurfaceNormalVector[0] = Vector(0.0, 0.0, 0.0)
    xvalue = 0.0
    yvalue = 0.0
    zvalue = 0.0

    for Side in range(1, NSides + 1):
        curVert = Side - 1
        nextVert = Side if Side < NSides else 0
        xvalue += (VList[curVert].y - VList[nextVert].y) * (VList[curVert].z + VList[nextVert].z)
        yvalue += (VList[curVert].z - VList[nextVert].z) * (VList[curVert].x + VList[nextVert].x)
        zvalue += (VList[curVert].x - VList[nextVert].x) * (VList[curVert].y + VList[nextVert].y)

    OutNewellSurfaceNormalVector[0].x = xvalue
    OutNewellSurfaceNormalVector[0].y = yvalue
    OutNewellSurfaceNormalVector[0].z = zvalue
    OutNewellSurfaceNormalVector[0] = VecNormalize(OutNewellSurfaceNormalVector[0])

def CompareTwoVectors(vector1: Vector, vector2: Vector, areSame: list, tolerance: float) -> None:
    areSame[0] = True
    if abs(vector1.x - vector2.x) > tolerance:
        areSame[0] = False
    if abs(vector1.y - vector2.y) > tolerance:
        areSame[0] = False
    if abs(vector1.z - vector2.z) > tolerance:
        areSame[0] = False

def CalcCoPlanarNess(Surf: List[Vector], NSides: int, IsCoPlanar: list, MaxDist: list, ErrorVertex: list) -> None:
    IsCoPlanar[0] = True
    MaxDist[0] = 0.0
    ErrorVertex[0] = 0

    NewellPlane = PlaneEq()
    plerror = [False]

    PlaneEquation(Surf, NSides, [NewellPlane], plerror)

    for vert in range(NSides):
        dist = Pt2Plane(Surf[vert], NewellPlane)
        if abs(dist) > MaxDist[0]:
            MaxDist[0] = abs(dist)
            ErrorVertex[0] = vert + 1

    if abs(MaxDist[0]) > Constant.SmallDistance:
        IsCoPlanar[0] = False

def PointsInPlane(BaseSurf: List[Vector], BaseSides: int, QuerySurf: List[Vector], QuerySides: int, ErrorFound: list) -> List[int]:
    pointIndices = []

    NewellPlane = PlaneEq()
    PlaneEquation(BaseSurf, BaseSides, [NewellPlane], ErrorFound)

    for vert in range(QuerySides):
        dist = Pt2Plane(QuerySurf[vert], NewellPlane)
        if abs(dist) < Constant.SmallDistance:
            pointIndices.append(vert + 1)

    return pointIndices

def CalcPolyhedronVolume(state, Poly: Polyhedron) -> float:
    Volume = 0.0

    for NFace in range(1, Poly.NumSurfaceFaces + 1):
        p3FaceOrigin = Poly.SurfaceFace[NFace - 1].FacePoints[1]
        PyramidVolume = dot(Poly.SurfaceFace[NFace - 1].NewellAreaVector, (p3FaceOrigin - state.dataVectors.p0))
        Volume += PyramidVolume / 3.0

    return Volume
