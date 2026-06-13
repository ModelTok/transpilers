// Mojo translation of Vectors.cc (faithful 1:1, no refactoring)
// Module name: EnergyPlus.Vectors (implicit via file path structure)

from DataVectorTypes import Vector, PlaneEq, Polyhedron, cross, dot
from DataGlobals import Constant, nint64
from .Data.EnergyPlusData import EnergyPlusData
from Data.BaseData import BaseGlobalStruct  # for VectorsData (if needed)
from math import sqrt, abs, atan2, acos, fmod as mod_  # mod_ to avoid name clash; use 'mod' later

# Global constants (as in Vectors.cc)
let XUnit: Vector = Vector(1.0, 0.0, 0.0)
let YUnit: Vector = Vector(0.0, 1.0, 0.0)
let ZUnit: Vector = Vector(0.0, 0.0, 1.0)

def area_polygon(n: Int, inout p: List[Vector]) -> Real64:
    # EP_SIZE_CHECK(p, n)
    let edge0: Vector = p[1] - p[0]
    let edge1: Vector = p[2] - p[0]
    let edgex: Vector = cross(edge0, edge1)
    let nor: Vector = vec_normalize(edgex)
    var csum: Vector
    csum = Vector(0.0, 0.0, 0.0)
    for i in range(0, n - 1):  # i 0 to n-2 inclusive
        csum += cross(p[i], p[i + 1])
    csum += cross(p[n - 1], p[0])
    let areap: Real64 = 0.5 * abs(dot(nor, csum))
    return areap

def vec_squared_length(vec: Vector) -> Real64:
    let vecsqlen: Real64 = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    return vecsqlen

def vec_length(vec: Vector) -> Real64:
    let veclen: Real64 = sqrt(vec_squared_length(vec))
    return veclen

def vec_negate(vec: Vector) -> Vector:
    var vec_negate: Vector
    vec_negate.x = -vec.x
    vec_negate.y = -vec.y
    vec_negate.z = -vec.z
    return vec_negate

def vec_normalize(vec: Vector) -> Vector:
    var vec_normalize: Vector
    let veclen: Real64 = vec_length(vec)
    if veclen != 0.0:
        vec_normalize.x = vec.x / veclen
        vec_normalize.y = vec.y / veclen
        vec_normalize.z = vec.z / veclen
    else:
        vec_normalize.x = 0.0
        vec_normalize.y = 0.0
        vec_normalize.z = 0.0
    return vec_normalize

def vec_round(inout vec: Vector, roundto: Real64):
    vec.x = nint64(vec.x * roundto) / roundto
    vec.y = nint64(vec.y * roundto) / roundto
    vec.z = nint64(vec.z * roundto) / roundto

def determine_azimuth_and_tilt(
    Surf: List[Vector],  # Surface Definition (1‑based indexing in original)
    inout Azimuth: Real64,
    inout Tilt: Real64,
    inout lcsx: Vector,
    inout lcsy: Vector,
    inout lcsz: Vector,
    NewellSurfaceNormalVector: Vector
):
    lcsx = vec_normalize(Surf[2] - Surf[1])  # Sur(3)-Sur(2) -> 0‑based: indices 2 and 1
    lcsz = NewellSurfaceNormalVector
    lcsy = cross(lcsz, lcsx)
    let costheta: Real64 = dot(lcsz, ZUnit)
    let epsilon: Real64 = 1.12e-16
    var rotang_0: Real64 = 0.0
    if abs(costheta) < 1.0 - epsilon:
        let x2: Vector = cross(ZUnit, lcsz)
        rotang_0 = atan2(dot(x2, YUnit), dot(x2, XUnit))
    else:
        rotang_0 = atan2(dot(lcsx, YUnit), dot(lcsx, XUnit))
    var tlt: Real64 = acos(NewellSurfaceNormalVector.z)
    tlt /= Constant.DegToRad
    var az: Real64 = rotang_0
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

def plane_equation(
    inout verts: List[Vector],
    nverts: Int,
    inout plane: PlaneEq,
    inout error: Bool
):
    # EP_SIZE_CHECK(verts, nverts)
    var normal: Vector = Vector(0.0, 0.0, 0.0)
    var refpt: Vector = Vector(0.0, 0.0, 0.0)
    for i in range(0, nverts):
        let u: Vector = verts[i]
        let v: Vector = verts[i + 1] if i < nverts - 1 else verts[0]
        normal.x += (u.y - v.y) * (u.z + v.z)
        normal.y += (u.z - v.z) * (u.x + v.x)
        normal.z += (u.x - v.x) * (u.y + v.y)
        refpt += u
    let lenvec: Real64 = vec_length(normal)
    error = False
    if lenvec != 0.0:
        plane.x = normal.x / lenvec
        plane.y = normal.y / lenvec
        plane.z = normal.z / lenvec
        let lenvec_mul: Real64 = lenvec * nverts
        plane.w = -dot(refpt, normal) / lenvec_mul
    else:
        error = True

def pt2_plane(pt: Vector, pleq: PlaneEq) -> Real64:
    let PtDist: Real64 = (pleq.x * pt.x) + (pleq.y * pt.y) + (pleq.z * pt.z) + pleq.w
    return PtDist

def create_newell_area_vector(
    VList: List[Vector],
    NSides: Int,
    inout OutNewellAreaVector: Vector
):
    OutNewellAreaVector = Vector(0.0, 0.0, 0.0)
    let V1_init: Vector = VList[1] - VList[0]  # VList(2)-VList(1) -> 0‑based: indices 1 and 0
    var V1: Vector = V1_init
    for Vert in range(2, NSides):  # Vert 3..NSides (1‑based) -> 0‑based: 2..NSides-1
        let V2: Vector = VList[Vert] - VList[0]
        OutNewellAreaVector += cross(V1, V2)
        V1 = V2
    OutNewellAreaVector /= 2.0

def create_newell_surface_normal_vector(
    VList: List[Vector],
    NSides: Int,
    inout OutNewellSurfaceNormalVector: Vector
):
    OutNewellSurfaceNormalVector = Vector(0.0, 0.0, 0.0)
    var xvalue: Real64 = 0.0
    var yvalue: Real64 = 0.0
    var zvalue: Real64 = 0.0
    for Side in range(1, NSides + 1):  # Side 1..NSides (1‑based)
        let curVert: Int = Side
        let nextVert: Int = Side + 1
        let nextVert_adj: Int = 1 if nextVert > NSides else nextVert  # handle wrap
        # use 0‑based indices: curVert-1, nextVert_adj-1
        xvalue += (VList[curVert - 1].y - VList[nextVert_adj - 1].y) * (VList[curVert - 1].z + VList[nextVert_adj - 1].z)
        yvalue += (VList[curVert - 1].z - VList[nextVert_adj - 1].z) * (VList[curVert - 1].x + VList[nextVert_adj - 1].x)
        zvalue += (VList[curVert - 1].x - VList[nextVert_adj - 1].x) * (VList[curVert - 1].y + VList[nextVert_adj - 1].y)
    OutNewellSurfaceNormalVector.x = xvalue
    OutNewellSurfaceNormalVector.y = yvalue
    OutNewellSurfaceNormalVector.z = zvalue
    OutNewellSurfaceNormalVector = vec_normalize(OutNewellSurfaceNormalVector)

def compare_two_vectors(
    vector1: Vector,
    vector2: Vector,
    inout areSame: Bool,
    tolerance: Real64
):
    areSame = True
    if abs(vector1.x - vector2.x) > tolerance:
        areSame = False
    if abs(vector1.y - vector2.y) > tolerance:
        areSame = False
    if abs(vector1.z - vector2.z) > tolerance:
        areSame = False

def calc_co_planar_ness(
    inout Surf: List[Vector],
    NSides: Int,
    inout IsCoPlanar: Bool,
    inout MaxDist: Real64,
    inout ErrorVertex: Int
):
    # EP_SIZE_CHECK(Surf, NSides)
    var plerror: Bool = False
    var NewellPlane: PlaneEq
    IsCoPlanar = True
    MaxDist = 0.0
    ErrorVertex = 0
    plane_equation(Surf, NSides, NewellPlane, plerror)
    for vert in range(1, NSides + 1):  # vert 1..NSides (1‑based)
        let dist: Real64 = pt2_plane(Surf[vert - 1], NewellPlane)
        if abs(dist) > MaxDist:
            MaxDist = abs(dist)
            ErrorVertex = vert
    if abs(MaxDist) > Constant.SmallDistance:
        IsCoPlanar = False

def points_in_plane(
    inout BaseSurf: List[Vector],
    BaseSides: Int,
    QuerySurf: List[Vector],
    QuerySides: Int,
    inout ErrorFound: Bool
) -> List[Int]:
    var pointIndices: List[Int] = List[Int]()
    var NewellPlane: PlaneEq
    plane_equation(BaseSurf, BaseSides, NewellPlane, ErrorFound)
    for vert in range(1, QuerySides + 1):  # vert 1..QuerySides (1‑based)
        let dist: Real64 = pt2_plane(QuerySurf[vert - 1], NewellPlane)
        if abs(dist) < Constant.SmallDistance:
            pointIndices.append(vert)
    return pointIndices

def calc_polyhedron_volume(state: EnergyPlusData, Poly: Polyhedron) -> Real64:
    var p3FaceOrigin: Vector
    var Volume: Real64 = 0.0
    for NFace in range(1, Poly.NumSurfaceFaces + 1):  # NFace 1..NumSurfaceFaces (1‑based)
        p3FaceOrigin = Poly.SurfaceFace(NFace - 1).FacePoints[1]  # FacePoints(2) -> 0‑based index 1
        let PyramidVolume: Real64 = dot(
            Poly.SurfaceFace(NFace - 1).NewellAreaVector,
            (p3FaceOrigin - state.dataVectors.p0)
        )
        Volume += PyramidVolume / 3.0
    return Volume

# Helper for 'mod' as used in determine_azimuth_and_tilt
def mod(a: Real64, b: Real64) -> Real64:
    return mod_(a, b)

# The following struct is defined in Vectors.hh; included for completeness but not part of .cc.
# Since the .cc file does not contain it, we leave it commented unless needed.
# struct VectorsData:
#     var p0: Vector = Vector(0.0, 0.0, 0.0)
#     def init_constant_state(inout self, state: EnergyPlusData):
#         pass
#     def init_state(inout self, state: EnergyPlusData):
#         pass
#     def clear_state(inout self):
#         self.p0 = Vector(0.0, 0.0, 0.0)