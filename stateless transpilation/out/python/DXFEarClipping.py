from dataclasses import dataclass
from typing import Protocol
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state.dataDXFEarClipping (trackit: bool, errcount: int), state.dataGlobal.DisplayExtraWarnings, state.files.debug
# - DataSurfaces: SurfaceClass enum (Floor, Roof, Overhang), cSurfaceClass(SurfaceClass) -> str
# - Vector (x, y, z), Vector_2d (x, y), dTriangle (vv0, vv1, vv2)
# - Constants: TwoPi, Pi, RadToDeg
# - ShowWarningError, ShowContinueError, ShowMessage, print (to state.files.debug)

class SurfaceClass:
    Floor = 1
    Roof = 2
    Overhang = 3

@dataclass
class Vector:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

@dataclass
class Vector_2d:
    x: float = 0.0
    y: float = 0.0

@dataclass
class dTriangle:
    vv0: int = 0
    vv1: int = 0
    vv2: int = 0

class Constants:
    TwoPi = 2.0 * math.pi
    Pi = math.pi
    RadToDeg = 180.0 / math.pi

class EnergyPlusDataStub(Protocol):
    def get_trackit(self) -> bool: ...
    def set_trackit(self, val: bool): ...
    def get_errcount(self) -> int: ...
    def inc_errcount(self): ...
    def get_display_extra_warnings(self) -> bool: ...

def sign(a: float, b: float) -> float:
    return abs(a) * (1.0 if b >= 0.0 else -1.0)

def any_gt(arr, val):
    return any(x > val for x in arr[:len(arr)])

def InPolygon(point: Vector, poly: list, nsides: int) -> bool:
    epsilon = 0.0000001
    anglesum = 0.0

    for vert in range(nsides - 1):
        p1 = Vector(
            poly[vert].x - point.x,
            poly[vert].y - point.y,
            poly[vert].z - point.z
        )
        p2 = Vector(
            poly[vert + 1].x - point.x,
            poly[vert + 1].y - point.y,
            poly[vert + 1].z - point.z
        )

        m1 = Modulus(p1)
        m2 = Modulus(p2)

        if m1 * m2 <= epsilon:
            return True

        costheta = (p1.x * p2.x + p1.y * p2.y + p1.z * p2.z) / (m1 * m2)
        acosval = math.acos(costheta)
        anglesum += acosval

    if abs(anglesum - Constants.TwoPi) <= epsilon:
        return True

    return False

def Modulus(point: Vector) -> float:
    return math.sqrt(point.x * point.x + point.y * point.y + point.z * point.z)

def Triangulate(state, nsides: int, polygon: list, surfazimuth: float, surftilt: float, 
                surfname: str, surfclass: int) -> tuple:
    point_tolerance = 0.00001

    ears = [0] * nsides
    r_angles = [0] * nsides
    rangles = [0.0] * nsides
    c_vertices = [0] * nsides
    earvert = [[0, 0, 0] for _ in range(nsides)]
    removed = [False] * nsides
    earverts = [0, 0, 0]
    xvt = [0.0] * nsides
    yvt = [0.0] * nsides
    zvt = [0.0] * nsides

    vertex = [Vector_2d() for _ in range(nsides)]

    if surfclass == SurfaceClass.Floor or surfclass == SurfaceClass.Roof or surfclass == SurfaceClass.Overhang:
        CalcRfFlrCoordinateTransformation(nsides, polygon, surfazimuth, surftilt, xvt, yvt, zvt)
        for svert in range(nsides):
            for mvert in range(svert + 1, nsides):
                if abs(xvt[svert] - xvt[mvert]) <= point_tolerance:
                    xvt[svert] = xvt[mvert]
                if abs(zvt[svert] - zvt[mvert]) <= point_tolerance:
                    zvt[svert] = zvt[mvert]
        for svert in range(nsides):
            vertex[svert].x = xvt[svert]
            vertex[svert].y = zvt[svert]
    else:
        CalcWallCoordinateTransformation(nsides, polygon, surfazimuth, surftilt, xvt, yvt, zvt)
        for svert in range(nsides):
            for mvert in range(svert + 1, nsides):
                if abs(xvt[svert] - xvt[mvert]) <= point_tolerance:
                    xvt[svert] = xvt[mvert]
                if abs(zvt[svert] - zvt[mvert]) <= point_tolerance:
                    zvt[svert] = zvt[mvert]
        for svert in range(nsides):
            vertex[svert].x = xvt[svert]
            vertex[svert].y = zvt[svert]

    nvertcur = nsides
    ncount = 0
    svert = 0
    mvert = 1
    evert = 2

    while nvertcur > 3:
        nears, nrangles, ncverts, ears, r_angles, rangles, c_vertices, earverts = generate_ears(
            state, nsides, vertex, ears, r_angles, rangles, c_vertices, removed, earverts
        )

        if not any_gt(ears, 0):
            ShowWarningError(state, f"DXFOut: Could not triangulate surface=\"{surfname}\", type=\"{surfclass}\", check surface vertex order(entry)")
            state.dataDXFEarClipping.errcount += 1
            if state.dataDXFEarClipping.errcount == 1 and not state.dataGlobal.DisplayExtraWarnings:
                ShowContinueError(state, "...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual surfaces.")
            if state.dataGlobal.DisplayExtraWarnings:
                ShowMessage(state, f" surface={surfname} class={surfclass}")
                for j in range(nsides):
                    ShowMessage(state, f" side={j+1} ({polygon[j].x:.1f},{polygon[j].y:.1f},{polygon[j].z:.1f})")
                ShowMessage(state, f" number of triangles found={ncount:12}")
                for j in range(nrangles):
                    ShowMessage(state, f" r angle={j+1} vert={r_angles[j]} deg={rangles[j] * Constants.RadToDeg:.1f}")
            break

        if nears > 0:
            svert = earverts[0]
            mvert = earverts[1]
            evert = earverts[2]
            ncount += 1
            removed[mvert] = True
            earvert[ncount - 1][0] = svert
            earvert[ncount - 1][1] = mvert
            earvert[ncount - 1][2] = evert
            nvertcur -= 1

        if nvertcur == 3:
            j = 0
            ncount += 1
            for i in range(nsides):
                if not removed[i]:
                    earvert[ncount - 1][j] = i
                    j += 1

    ntri = ncount
    outtriangles = []
    for i in range(ntri):
        tri = dTriangle(earvert[i][0], earvert[i][1], earvert[i][2])
        outtriangles.append(tri)

    return ntri, outtriangles

def angle_2dvector(xa: float, ya: float, xb: float, yb: float, xc: float, yc: float) -> float:
    epsilon = 0.0000001

    x1 = xa - xb
    y1 = ya - yb
    x2 = xc - xb
    y2 = yc - yb

    t = math.sqrt((x1 * x1 + y1 * y1) * (x2 * x2 + y2 * y2))
    if t == 0.0:
        t = 1.0

    t = (x1 * x2 + y1 * y2) / t

    if (1.0 - epsilon) < abs(t):
        t = sign(1.0, t)

    angle = math.acos(t)

    if x2 * y1 - y2 * x1 < 0.0:
        angle = 2.0 * Constants.Pi - angle

    return angle

def polygon_contains_point_2d(nsides: int, polygon: list, point: Vector_2d) -> bool:
    inside = False

    for i in range(nsides):
        ip1 = i + 1 if i < nsides - 1 else 0

        if ((polygon[i].y < point.y and point.y <= polygon[ip1].y) or 
            (point.y <= polygon[i].y and polygon[ip1].y < point.y)):
            if ((point.x - polygon[i].x) - (point.y - polygon[i].y) * 
                (polygon[ip1].x - polygon[i].x) / (polygon[ip1].y - polygon[i].y) < 0):
                inside = not inside

    return inside

def generate_ears(state, nvert: int, vertex: list, ears: list, r_vertices: list, rangles: list,
                  c_vertices: list, removed: list, earvert: list) -> tuple:
    ears = [0] * nvert
    r_vertices = [0] * nvert
    rangles = [0.0] * nvert
    c_vertices = [0] * nvert
    nears = 0
    nrverts = 0
    ncverts = 0
    testtri = [Vector_2d(), Vector_2d(), Vector_2d()]

    for svert in range(nvert):
        if removed[svert]:
            continue

        mvert = svert + 1
        for j in range(nvert):
            if mvert >= nvert:
                mvert = 0
            if removed[mvert]:
                mvert += 1
                if mvert >= nvert:
                    mvert = 0
            else:
                break

        evert = mvert + 1
        for j in range(nvert):
            if evert >= nvert:
                evert = 0
            if removed[evert]:
                evert += 1
                if evert >= nvert:
                    evert = 0
            else:
                break

        ang = angle_2dvector(vertex[svert].x, vertex[svert].y, vertex[mvert].x, 
                            vertex[mvert].y, vertex[evert].x, vertex[evert].y)

        if ang > Constants.Pi:
            nrverts += 1
            r_vertices[nrverts - 1] = mvert
            rangles[nrverts - 1] = ang
            continue

        ncverts += 1
        c_vertices[ncverts - 1] = mvert

        testtri[0] = vertex[svert]
        testtri[1] = vertex[mvert]
        testtri[2] = vertex[evert]

        tvert = evert
        inpoly = False
        for j in range(4, nvert + 1):
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
            ears[nears - 1] = mvert
            if nears == 1:
                earvert[0] = svert
                earvert[1] = mvert
                earvert[2] = evert
            if state.dataDXFEarClipping.trackit:
                print(f"ear={nears} triangle={svert:12}{mvert:12}{evert:12}", file=state.files.debug)

    return nears, nrverts, ncverts, ears, r_vertices, rangles, c_vertices, earvert

def CalcWallCoordinateTransformation(nsides: int, polygon: list, surfazimuth: float, 
                                     surftilt: float, xvt: list, yvt: list, zvt: list):
    alpha = surfazimuth
    alpha180 = 180.0 - alpha
    alphrad = alpha180 / Constants.RadToDeg
    cos_alphrad = math.cos(alphrad)
    sin_alphrad = math.sin(alphrad)

    for i in range(nsides):
        xvt[i] = cos_alphrad * polygon[i].x + sin_alphrad * polygon[i].y
        yvt[i] = -sin_alphrad * polygon[i].x + cos_alphrad * polygon[i].y
        zvt[i] = polygon[i].z

def CalcRfFlrCoordinateTransformation(nsides: int, polygon: list, surfazimuth: float,
                                      surftilt: float, xvt: list, yvt: list, zvt: list):
    alpha = -surftilt
    alphrad = alpha / Constants.RadToDeg
    cos_alphrad = math.cos(alphrad)
    sin_alphrad = math.sin(alphrad)

    for i in range(nsides):
        xvt[i] = polygon[i].x
        yvt[i] = cos_alphrad * polygon[i].x + sin_alphrad * polygon[i].y
        zvt[i] = -sin_alphrad * polygon[i].x + cos_alphrad * polygon[i].y

@dataclass
class DXFEarClippingData:
    trackit: bool = False
    errcount: int = 0

    def init_constant_state(self, state): pass
    def init_state(self, state): pass
    def clear_state(self):
        self.trackit = False
        self.errcount = 0
