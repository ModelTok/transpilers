from math import sqrt, atan2, acos
import math

# EXTERNAL DEPS (to wire in glue):
# - Vector, PlaneEq, Polyhedron: from DataVectorTypes
# - EnergyPlusData: from Data.EnergyPlusData (state.dataVectors.p0)
# - Constant.DegToRad, Constant.OneThousandth, Constant.OneMillionth, Constant.SmallDistance

struct Vector:
    var x: Float64
    var y: Float64
    var z: Float64

    fn __init__() -> Self:
        return Self{x: 0.0, y: 0.0, z: 0.0}

    fn __init__(x: Float64, y: Float64, z: Float64) -> Self:
        return Self{x: x, y: y, z: z}

    fn __add__(self, other: Vector) -> Vector:
        return Vector(self.x + other.x, self.y + other.y, self.z + other.z)

    fn __sub__(self, other: Vector) -> Vector:
        return Vector(self.x - other.x, self.y - other.y, self.z - other.z)

    fn __mul__(self, scalar: Float64) -> Vector:
        return Vector(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __rmul__(scalar: Float64, self: Vector) -> Vector:
        return Vector(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __truediv__(self, scalar: Float64) -> Vector:
        return Vector(self.x / scalar, self.y / scalar, self.z / scalar)

    fn __iadd__(inout self, other: Vector):
        self.x += other.x
        self.y += other.y
        self.z += other.z

    fn __iadd__(inout self, scalar: Float64):
        self.x = scalar
        self.y = scalar
        self.z = scalar

    fn __itruediv__(inout self, scalar: Float64):
        self.x /= scalar
        self.y /= scalar
        self.z /= scalar

fn cross(v1: Vector, v2: Vector) -> Vector:
    return Vector(
        v1.y * v2.z - v1.z * v2.y,
        v1.z * v2.x - v1.x * v2.z,
        v1.x * v2.y - v1.y * v2.x
    )

fn dot(v1: Vector, v2: Vector) -> Float64:
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

struct PlaneEq:
    var x: Float64
    var y: Float64
    var z: Float64
    var w: Float64

    fn __init__() -> Self:
        return Self{x: 0.0, y: 0.0, z: 0.0, w: 0.0}

    fn __init__(x: Float64, y: Float64, z: Float64, w: Float64) -> Self:
        return Self{x: x, y: y, z: z, w: w}

struct SurfaceFace:
    var FacePoints: List[Vector]
    var NewellAreaVector: Vector

    fn __init__() -> Self:
        return Self{FacePoints: List[Vector](), NewellAreaVector: Vector()}

struct Polyhedron:
    var NumSurfaceFaces: Int
    var SurfaceFace: List[SurfaceFace]

    fn __init__() -> Self:
        return Self{NumSurfaceFaces: 0, SurfaceFace: List[SurfaceFace]()}

struct VectorsData:
    var p0: Vector

    fn __init__() -> Self:
        return Self{p0: Vector(0.0, 0.0, 0.0)}

    fn init_constant_state(inout self, state):
        pass

    fn init_state(inout self, state):
        pass

    fn clear_state(inout self):
        self.p0 = Vector(0.0, 0.0, 0.0)

alias XUnit = Vector(1.0, 0.0, 0.0)
alias YUnit = Vector(0.0, 1.0, 0.0)
alias ZUnit = Vector(0.0, 0.0, 1.0)

fn nint64(x: Float64) -> Int:
    if x >= 0.0:
        return int(x + 0.5)
    else:
        return int(x - 0.5)

fn mod(a: Float64, b: Float64) -> Float64:
    return a - b * int(a / b)

struct Constant:
    alias DegToRad: Float64 = 0.0174532925199432957692
    alias OneThousandth: Float64 = 0.001
    alias OneMillionth: Float64 = 0.000001
    alias SmallDistance: Float64 = 1e-10

fn AreaPolygon(n: Int, p: List[Vector]) -> Float64:
    var edge0 = p[1] - p[0]
    var edge1 = p[2] - p[0]

    var edgex = cross(edge0, edge1)
    var nor = VecNormalize(edgex)

    var csum = Vector(0.0, 0.0, 0.0)

    for i in range(n - 1):
        csum += cross(p[i], p[i + 1])
    csum += cross(p[n - 1], p[0])

    var areap = 0.5 * abs(dot(nor, csum))

    return areap

fn VecSquaredLength(vec: Vector) -> Float64:
    return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z

fn VecLength(vec: Vector) -> Float64:
    return sqrt(VecSquaredLength(vec))

fn VecNegate(vec: Vector) -> Vector:
    return Vector(-vec.x, -vec.y, -vec.z)

fn VecNormalize(vec: Vector) -> Vector:
    var veclen = VecLength(vec)
    if veclen != 0.0:
        return Vector(vec.x / veclen, vec.y / veclen, vec.z / veclen)
    else:
        return Vector(0.0, 0.0, 0.0)

fn VecRound(inout vec: Vector, roundto: Float64):
    vec.x = nint64(vec.x * roundto) / roundto
    vec.y = nint64(vec.y * roundto) / roundto
    vec.z = nint64(vec.z * roundto) / roundto

fn DetermineAzimuthAndTilt(Surf: List[Vector], inout Azimuth: Float64, inout Tilt: Float64, inout lcsx: Vector, inout lcsy: Vector, inout lcsz: Vector, NewellSurfaceNormalVector: Vector):
    lcsx = VecNormalize(Surf[2] - Surf[1])
    lcsz = NewellSurfaceNormalVector
    lcsy = cross(lcsz, lcsx)

    var costheta = dot(lcsz, ZUnit)

    var epsilon: Float64 = 1.12e-16
    var rotang_0: Float64 = 0.0
    if abs(costheta) < 1.0 - epsilon:
        var x2 = cross(ZUnit, lcsz)
        rotang_0 = atan2(dot(x2, YUnit), dot(x2, XUnit))
    else:
        rotang_0 = atan2(dot(lcsx, YUnit), dot(lcsx, XUnit))

    var tlt = acos(NewellSurfaceNormalVector.z)
    tlt /= Constant.DegToRad

    var az = rotang_0

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

    Azimuth = az
    Tilt = tlt

fn PlaneEquation(verts: List[Vector], nverts: Int, inout plane: PlaneEq, inout error: Bool):
    var normal = Vector(0.0, 0.0, 0.0)
    var refpt = Vector(0.0, 0.0, 0.0)
    for i in range(nverts):
        var u = verts[i]
        var v = verts[i + 1] if i < nverts - 1 else verts[0]
        normal.x += (u.y - v.y) * (u.z + v.z)
        normal.y += (u.z - v.z) * (u.x + v.x)
        normal.z += (u.x - v.x) * (u.y + v.y)
        refpt += u

    var lenvec = VecLength(normal)
    error = False
    if lenvec != 0.0:
        plane.x = normal.x / lenvec
        plane.y = normal.y / lenvec
        plane.z = normal.z / lenvec
        lenvec *= nverts
        plane.w = -dot(refpt, normal) / lenvec
    else:
        error = True

fn Pt2Plane(pt: Vector, pleq: PlaneEq) -> Float64:
    return pleq.x * pt.x + pleq.y * pt.y + pleq.z * pt.z + pleq.w

fn CreateNewellAreaVector(VList: List[Vector], NSides: Int, inout OutNewellAreaVector: Vector):
    OutNewellAreaVector = Vector(0.0, 0.0, 0.0)

    var V1 = VList[1] - VList[0]
    for Vert in range(2, NSides):
        var V2 = VList[Vert] - VList[0]
        OutNewellAreaVector += cross(V1, V2)
        V1 = V2

    OutNewellAreaVector /= 2.0

fn CreateNewellSurfaceNormalVector(VList: List[Vector], NSides: Int, inout OutNewellSurfaceNormalVector: Vector):
    OutNewellSurfaceNormalVector = Vector(0.0, 0.0, 0.0)
    var xvalue: Float64 = 0.0
    var yvalue: Float64 = 0.0
    var zvalue: Float64 = 0.0

    for Side in range(1, NSides + 1):
        var curVert = Side - 1
        var nextVert = Side if Side < NSides else 0
        xvalue += (VList[curVert].y - VList[nextVert].y) * (VList[curVert].z + VList[nextVert].z)
        yvalue += (VList[curVert].z - VList[nextVert].z) * (VList[curVert].x + VList[nextVert].x)
        zvalue += (VList[curVert].x - VList[nextVert].x) * (VList[curVert].y + VList[nextVert].y)

    OutNewellSurfaceNormalVector.x = xvalue
    OutNewellSurfaceNormalVector.y = yvalue
    OutNewellSurfaceNormalVector.z = zvalue
    OutNewellSurfaceNormalVector = VecNormalize(OutNewellSurfaceNormalVector)

fn CompareTwoVectors(vector1: Vector, vector2: Vector, inout areSame: Bool, tolerance: Float64):
    areSame = True
    if abs(vector1.x - vector2.x) > tolerance:
        areSame = False
    if abs(vector1.y - vector2.y) > tolerance:
        areSame = False
    if abs(vector1.z - vector2.z) > tolerance:
        areSame = False

fn CalcCoPlanarNess(Surf: List[Vector], NSides: Int, inout IsCoPlanar: Bool, inout MaxDist: Float64, inout ErrorVertex: Int):
    IsCoPlanar = True
    MaxDist = 0.0
    ErrorVertex = 0

    var NewellPlane = PlaneEq()
    var plerror = False

    PlaneEquation(Surf, NSides, NewellPlane, plerror)

    for vert in range(NSides):
        var dist = Pt2Plane(Surf[vert], NewellPlane)
        if abs(dist) > MaxDist:
            MaxDist = abs(dist)
            ErrorVertex = vert + 1

    if abs(MaxDist) > Constant.SmallDistance:
        IsCoPlanar = False

fn PointsInPlane(BaseSurf: List[Vector], BaseSides: Int, QuerySurf: List[Vector], QuerySides: Int, inout ErrorFound: Bool) -> List[Int]:
    var pointIndices = List[Int]()

    var NewellPlane = PlaneEq()
    PlaneEquation(BaseSurf, BaseSides, NewellPlane, ErrorFound)

    for vert in range(QuerySides):
        var dist = Pt2Plane(QuerySurf[vert], NewellPlane)
        if abs(dist) < Constant.SmallDistance:
            pointIndices.append(vert + 1)

    return pointIndices

fn CalcPolyhedronVolume(state, Poly: Polyhedron) -> Float64:
    var Volume: Float64 = 0.0

    for NFace in range(1, Poly.NumSurfaceFaces + 1):
        var p3FaceOrigin = Poly.SurfaceFace[NFace - 1].FacePoints[1]
        var PyramidVolume = dot(Poly.SurfaceFace[NFace - 1].NewellAreaVector, (p3FaceOrigin - state.dataVectors.p0))
        Volume += PyramidVolume / 3.0

    return Volume
