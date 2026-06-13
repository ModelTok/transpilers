from math import sqrt, cos, sin, acos, fabs
from sys import stdout
from typing import List, Tuple, Optional
struct Constant:
    static Pi: Float64 = 3.14159265358979323846
    static TwoPi: Float64 = 2.0 * Pi
    static RadToDeg: Float64 = 180.0 / Pi
@value
struct Vector:
    x: Float64 = 0.0
    y: Float64 = 0.0
    z: Float64 = 0.0
@value
struct Vector_2d:
    x: Float64 = 0.0
    y: Float64 = 0.0
@value
struct dTriangle:
    vv0: Int32 = 0
    vv1: Int32 = 0
    vv2: Int32 = 0
struct DataSurfaces:
    @value
    struct SurfaceClass:
        static Floor: Int32 = 0
        static Roof: Int32 = 1
        static Overhang: Int32 = 2
        @staticmethod
        def cSurfaceClass(sclass: Int32) -> String:
            if sclass == 0: return "Floor"
            elif sclass == 1: return "Roof"
            elif sclass == 2: return "Overhang"
            else: return "Unknown"
struct EnergyPlusData:
    dataDXFEarClipping: DXFECDataPointer
    dataGlobal: GlobalDataPointer
    files: FilesStruct
struct DXFECDataPointer:
    trackit: Bool = False
    errcount: Int32 = 0
struct GlobalDataPointer:
    DisplayExtraWarnings: Bool = False
struct FilesStruct:
    debug: FileHandle
struct FileHandle:

def EP_SIZE_CHECK(arr: List, n: Int32):

def sign(val: Float64, sgn: Float64) -> Float64:
    if sgn >= 0.0:
        return fabs(val)
    else:
        return -fabs(val)
def any_gt(arr: List[Int32], val: Int32) -> Bool:
    for v in arr:
        if v > val:
            return True
    return False
def ShowWarningError(state: EnergyPlusData, message: String):
    print("WARNING:", message)
def ShowContinueError(state: EnergyPlusData, message: String):
    print("CONTINUE:", message)
def ShowMessage(state: EnergyPlusData, message: String):
    print("MESSAGE:", message)
def InPolygon(point: Vector, poly: List[Vector], nsides: Int32) -> Bool:
    var epsilon: Float64 = 0.0000001
    var costheta: Float64
    var m1: Float64
    var m2: Float64
    var acosval: Float64
    var p1: Vector
    var p2: Vector
    var InPolygon: Bool = False
    var anglesum: Float64 = 0.0
    for vert in range(0, nsides - 1):
        p1.x = poly[vert].x - point.x
        p1.y = poly[vert].y - point.y
        p1.z = poly[vert].z - point.z
        p2.x = poly[vert + 1].x - point.x  # note: 0-based
        p2.y = poly[vert + 1].y - point.y
        p2.z = poly[vert + 1].z - point.z
        m1 = Modulus(p1)
        m2 = Modulus(p2)
        if m1 * m2 <= epsilon:
            InPolygon = True
            break
        costheta = (p1.x * p2.x + p1.y * p2.y + p1.z * p2.z) / (m1 * m2)
        acosval = acos(costheta)
        anglesum += acosval
    if fabs(anglesum - Constant.TwoPi) <= epsilon:
        InPolygon = True
    return InPolygon
def Modulus(point: Vector) -> Float64:
    var rModulus: Float64
    rModulus = sqrt(point.x * point.x + point.y * point.y + point.z * point.z)
    return rModulus
def Triangulate(state: EnergyPlusData, nsides: Int32, polygon: List[Vector], outtriangles: List[dTriangle],
               surfazimuth: Float64, surftilt: Float64, surfname: String,
               surfclass: Int32) -> Int32:
    var point_tolerance: Float64 = 0.00001
    var ears: List[Int32] = [0] * nsides
    var r_angles: List[Int32] = [0] * nsides
    var rangles: List[Float64] = [0.0] * nsides
    var c_vertices: List[Int32] = [0] * nsides
    var earvert: List[List[Int32]] = [[0,0,0] for _ in range(nsides)]
    var removed: List[Bool] = [False] * nsides
    var earverts: List[Int32] = [0,0,0]
    var xvt: List[Float64] = [0.0] * nsides
    var yvt: List[Float64] = [0.0] * nsides
    var zvt: List[Float64] = [0.0] * nsides
    var nears: Int32 = 0
    var nrangles: Int32 = 0
    var ncverts: Int32 = 0
    var vertex: List[Vector_2d] = [Vector_2d() for _ in range(nsides)]
    var Triangle: List[dTriangle] = [dTriangle() for _ in range(nsides)]
    if surfclass == DataSurfaces.SurfaceClass.Floor or surfclass == DataSurfaces.SurfaceClass.Roof or surfclass == DataSurfaces.SurfaceClass.Overhang:
        CalcRfFlrCoordinateTransformation(nsides, polygon, surfazimuth, surftilt, xvt, yvt, zvt)
        for svert in range(0, nsides):
            for mvert in range(svert + 1, nsides):
                if fabs(xvt[svert] - xvt[mvert]) <= point_tolerance:
                    xvt[svert] = xvt[mvert]
                if fabs(zvt[svert] - zvt[mvert]) <= point_tolerance:
                    zvt[svert] = zvt[mvert]
        for svert in range(0, nsides):
            vertex[svert].x = xvt[svert]
            vertex[svert].y = zvt[svert]
    else:
        CalcWallCoordinateTransformation(nsides, polygon, surfazimuth, surftilt, xvt, yvt, zvt)
        for svert in range(0, nsides):
            for mvert in range(svert + 1, nsides):
                if fabs(xvt[svert] - xvt[mvert]) <= point_tolerance:
                    xvt[svert] = xvt[mvert]
                if fabs(zvt[svert] - zvt[mvert]) <= point_tolerance:
                    zvt[svert] = zvt[mvert]
        for svert in range(0, nsides):
            vertex[svert].x = xvt[svert]
            vertex[svert].y = zvt[svert]
    var nvertcur: Int32 = nsides
    var ncount: Int32 = 0
    var svert: Int32 = 1  # keep as 1-based index for logic, but arrays are 0-based
    var mvert: Int32 = 2
    var evert: Int32 = 3
    while nvertcur > 3:
        generate_ears(state, nsides, vertex, ears, nears, r_angles, nrangles, c_vertices, ncverts, removed, earverts, rangles)
        if not any_gt(ears, 0):
            ShowWarningError(state, "DXFOut: Could not triangulate surface=\"{}\", type=\"{}\", check surface vertex order(entry)".format(surfname,
                             DataSurfaces.SurfaceClass.cSurfaceClass(surfclass)))
            state.dataDXFEarClipping.errcount += 1
            if state.dataDXFEarClipping.errcount == 1 and not state.dataGlobal.DisplayExtraWarnings:
                ShowContinueError(state, "...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual surfaces.")
            if state.dataGlobal.DisplayExtraWarnings:
                ShowMessage(state, " surface={} class={}".format(surfname, DataSurfaces.SurfaceClass.cSurfaceClass(surfclass)))
                for j in range(0, nsides):
                    ShowMessage(state, " side={} ({:.1f},{:.1f},{:.1f})".format(j+1, polygon[j].x, polygon[j].y, polygon[j].z))
                ShowMessage(state, " number of triangles found={:12}".format(ncount))
                for j in range(0, nrangles):
                    ShowMessage(state, " r angle={} vert={} deg={:.1f}".format(j+1, r_angles[j], rangles[j] * Constant.RadToDeg))
            break
        if nears > 0:
            svert = earverts[0]
            mvert = earverts[1]
            evert = earverts[2]
            ncount += 1
            removed[mvert-1] = True
            earvert[ncount-1][0] = svert
            earvert[ncount-1][1] = mvert
            earvert[ncount-1][2] = evert
            nvertcur -= 1
        if nvertcur == 3:
            var j: Int32 = 1
            ncount += 1
            for i in range(0, nsides):
                if removed[i]:
                    continue
                earvert[ncount-1][j-1] = i+1
                j += 1
    var ntri: Int32 = ncount
    for i in range(0, ntri):
        Triangle[i].vv0 = earvert[i][0]
        Triangle[i].vv1 = earvert[i][1]
        Triangle[i].vv2 = earvert[i][2]
    outtriangles.clear()
    for i in range(0, ntri):
        outtriangles.append(Triangle[i])
    return ntri
def angle_2dvector(xa: Float64, ya: Float64, xb: Float64, yb: Float64, xc: Float64, yc: Float64) -> Float64:
    var epsilon: Float64 = 0.0000001
    var x1: Float64 = xa - xb
    var y1: Float64 = ya - yb
    var x2: Float64 = xc - xb
    var y2: Float64 = yc - yb
    var t: Float64 = sqrt((x1 * x1 + y1 * y1) * (x2 * x2 + y2 * y2))
    if t == 0.0E+00:
        t = 1.0E+00
    t = (x1 * x2 + y1 * y2) / t
    if (1.0E+00 - epsilon) < fabs(t):
        t = sign(1.0E+00, t)
    var angle: Float64 = acos(t)
    if x2 * y1 - y2 * x1 < 0.0E+00:
        angle = 2.0E+00 * Constant.Pi - angle
    return angle
def polygon_contains_point_2d(nsides: Int32, polygon: List[Vector_2d], point: Vector_2d) -> Bool:
    var ip1: Int32
    var inside: Bool = False
    for i in range(0, nsides):
        if i < nsides - 1:
            ip1 = i + 1
        else:
            ip1 = 0
        if (polygon[i].y < point.y and point.y <= polygon[ip1].y) or (point.y <= polygon[i].y and polygon[ip1].y < point.y):
            if (point.x - polygon[i].x) - (point.y - polygon[i].y) * (polygon[ip1].x - polygon[i].x) / (polygon[ip1].y - polygon[i].y) < 0:
                inside = not inside
    return inside
def generate_ears(state: EnergyPlusData, nvert: Int32, vertex: List[Vector_2d], ears: List[Int32],
                 nears: Int32, r_vertices: List[Int32], nrverts: Int32, c_vertices: List[Int32],
                 ncverts: Int32, removed: List[Bool], earvert: List[Int32], rangles: List[Float64]):
    var inpoly: Bool
    var point: Vector_2d
    var testtri: List[Vector_2d] = [Vector_2d() for _ in range(3)]
    for i in range(0, nvert):
        ears[i] = 0
        r_vertices[i] = 0
        rangles[i] = 0.0
    nears = 0
    nrverts = 0
    for i in range(0, nvert):
        c_vertices[i] = 0
    ncverts = 0
    for svert in range(0, nvert):
        if removed[svert]:
            continue
        var mvert: Int32 = svert + 1
        for j in range(0, nvert):
            if mvert >= nvert:
                mvert = 0
            if removed[mvert]:
                mvert += 1
                if mvert >= nvert:
                    mvert = 0
            else:
                break
        var evert: Int32 = mvert + 1
        for j in range(0, nvert):
            if evert >= nvert:
                evert = 0
            if removed[evert]:
                evert += 1
                if evert >= nvert:
                    evert = 0
            else:
                break
        var ang: Float64 = angle_2dvector(vertex[svert].x, vertex[svert].y, vertex[mvert].x, vertex[mvert].y, vertex[evert].x, vertex[evert].y)
        if ang > Constant.Pi:
            nrverts += 1
            r_vertices[nrverts-1] = mvert + 1  # store 1-based index
            rangles[nrverts-1] = ang
            continue
        ncverts += 1
        c_vertices[ncverts-1] = mvert + 1
        testtri[0] = vertex[svert]
        testtri[1] = vertex[mvert]
        testtri[2] = vertex[evert]
        var tvert: Int32 = evert
        for j in range(4, nvert+1):
            tvert += 1
            if tvert >= nvert:
                tvert = 0
            if removed[tvert]:
                continue
            point = vertex[tvert]
            inpoly = polygon_contains_point_2d(3, testtri, point)
            if not inpoly:
                continue
            break
        if not inpoly:
            nears += 1
            ears[nears-1] = mvert + 1
            if nears == 1:
                earvert[0] = svert + 1
                earvert[1] = mvert + 1
                earvert[2] = evert + 1
            if state.dataDXFEarClipping.trackit:
                print("ear={} triangle={:12}{:12}{:12}\n".format(nears, svert+1, mvert+1, evert+1))
def CalcWallCoordinateTransformation(nsides: Int32, polygon: List[Vector], surfazimuth: Float64,
                                    surftilt: Float64, xvt: List[Float64], yvt: List[Float64], zvt: List[Float64]):
    var alpha: Float64 = surfazimuth
    var alpha180: Float64 = 180.0 - alpha
    var alphrad: Float64 = alpha180 / Constant.RadToDeg
    var cos_alphrad: Float64 = cos(alphrad)
    var sin_alphrad: Float64 = sin(alphrad)
    for i in range(0, nsides):
        xvt[i] = cos_alphrad * polygon[i].x + sin_alphrad * polygon[i].y
        yvt[i] = -sin_alphrad * polygon[i].x + cos_alphrad * polygon[i].y
        zvt[i] = polygon[i].z
def CalcRfFlrCoordinateTransformation(nsides: Int32, polygon: List[Vector], surfazimuth: Float64,
                                     surftilt: Float64, xvt: List[Float64], yvt: List[Float64], zvt: List[Float64]):
    var alpha: Float64 = -surftilt
    var alphrad: Float64 = alpha / Constant.RadToDeg
    var cos_alphrad: Float64 = cos(alphrad)
    var sin_alphrad: Float64 = sin(alphrad)
    for i in range(0, nsides):
        xvt[i] = polygon[i].x
        yvt[i] = cos_alphrad * polygon[i].x + sin_alphrad * polygon[i].y
        zvt[i] = -sin_alphrad * polygon[i].x + cos_alphrad * polygon[i].y
struct DXFEarClippingData:
    var trackit: Bool = False
    var errcount: Int32 = 0
    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(self):
        self.trackit = False
        self.errcount = 0