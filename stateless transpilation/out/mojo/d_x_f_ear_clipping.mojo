from math import sqrt, acos, cos, sin, pi, fabs
from math import atan2

alias RadToDeg = 180.0 / pi
alias TwoPi = 2.0 * pi
alias Pi = pi

struct Vector:
    var x: Float64
    var y: Float64
    var z: Float64

    fn __init__() -> Self:
        return Self{x: 0.0, y: 0.0, z: 0.0}

    fn __init__(x: Float64, y: Float64, z: Float64) -> Self:
        return Self{x: x, y: y, z: z}

struct Vector_2d:
    var x: Float64
    var y: Float64

    fn __init__() -> Self:
        return Self{x: 0.0, y: 0.0}

    fn __init__(x: Float64, y: Float64) -> Self:
        return Self{x: x, y: y}

struct dTriangle:
    var vv0: Int32
    var vv1: Int32
    var vv2: Int32

    fn __init__() -> Self:
        return Self{vv0: 0, vv1: 0, vv2: 0}

    fn __init__(vv0: Int32, vv1: Int32, vv2: Int32) -> Self:
        return Self{vv0: vv0, vv1: vv1, vv2: vv2}

fn sign(a: Float64, b: Float64) -> Float64:
    if b >= 0.0:
        return fabs(a)
    else:
        return -fabs(a)

fn any_gt(arr: DynamicVector[Int32], val: Int32) -> Bool:
    for i in range(len(arr)):
        if arr[i] > val:
            return True
    return False

fn InPolygon(point: Vector, poly: DynamicVector[Vector], nsides: Int32) -> Bool:
    alias epsilon = 0.0000001
    var anglesum: Float64 = 0.0

    for vert in range(nsides - 1):
        var p1 = Vector(
            poly[vert].x - point.x,
            poly[vert].y - point.y,
            poly[vert].z - point.z
        )
        var p2 = Vector(
            poly[vert + 1].x - point.x,
            poly[vert + 1].y - point.y,
            poly[vert + 1].z - point.z
        )

        var m1 = Modulus(p1)
        var m2 = Modulus(p2)

        if m1 * m2 <= epsilon:
            return True

        var costheta = (p1.x * p2.x + p1.y * p2.y + p1.z * p2.z) / (m1 * m2)
        var acosval = acos(costheta)
        anglesum += acosval

    if fabs(anglesum - TwoPi) <= epsilon:
        return True

    return False

fn Modulus(point: Vector) -> Float64:
    return sqrt(point.x * point.x + point.y * point.y + point.z * point.z)

fn Triangulate(state: EnergyPlusDataStub, nsides: Int32, polygon: DynamicVector[Vector],
               surfazimuth: Float64, surftilt: Float64, surfname: String, surfclass: Int32) -> Tuple[Int32, DynamicVector[dTriangle]]:
    alias point_tolerance = 0.00001

    var ears = DynamicVector[Int32]()
    var r_angles = DynamicVector[Int32]()
    var rangles = DynamicVector[Float64]()
    var c_vertices = DynamicVector[Int32]()
    var earvert = DynamicVector[InlineArray[Int32, 3]]()
    var removed = DynamicVector[Bool]()
    var earverts = InlineArray[Int32, 3](0, 0, 0)
    var xvt = DynamicVector[Float64]()
    var yvt = DynamicVector[Float64]()
    var zvt = DynamicVector[Float64]()

    for i in range(nsides):
        ears.push_back(0)
        r_angles.push_back(0)
        rangles.push_back(0.0)
        c_vertices.push_back(0)
        removed.push_back(False)
        xvt.push_back(0.0)
        yvt.push_back(0.0)
        zvt.push_back(0.0)
        earvert.push_back(InlineArray[Int32, 3](0, 0, 0))

    var vertex = DynamicVector[Vector_2d]()
    for i in range(nsides):
        vertex.push_back(Vector_2d())

    alias SurfaceClass_Floor = 1
    alias SurfaceClass_Roof = 2
    alias SurfaceClass_Overhang = 3

    if surfclass == SurfaceClass_Floor or surfclass == SurfaceClass_Roof or surfclass == SurfaceClass_Overhang:
        CalcRfFlrCoordinateTransformation(nsides, polygon, surfazimuth, surftilt, xvt, yvt, zvt)
        for svert in range(nsides):
            for mvert in range(svert + 1, nsides):
                if fabs(xvt[svert] - xvt[mvert]) <= point_tolerance:
                    xvt[svert] = xvt[mvert]
                if fabs(zvt[svert] - zvt[mvert]) <= point_tolerance:
                    zvt[svert] = zvt[mvert]
        for svert in range(nsides):
            vertex[svert].x = xvt[svert]
            vertex[svert].y = zvt[svert]
    else:
        CalcWallCoordinateTransformation(nsides, polygon, surfazimuth, surftilt, xvt, yvt, zvt)
        for svert in range(nsides):
            for mvert in range(svert + 1, nsides):
                if fabs(xvt[svert] - xvt[mvert]) <= point_tolerance:
                    xvt[svert] = xvt[mvert]
                if fabs(zvt[svert] - zvt[mvert]) <= point_tolerance:
                    zvt[svert] = zvt[mvert]
        for svert in range(nsides):
            vertex[svert].x = xvt[svert]
            vertex[svert].y = zvt[svert]

    var nvertcur = nsides
    var ncount = 0
    var svert: Int32 = 0
    var mvert: Int32 = 1
    var evert: Int32 = 2

    while nvertcur > 3:
        var nears: Int32 = 0
        var nrangles: Int32 = 0
        var ncverts: Int32 = 0

        generate_ears(state, nsides, vertex, ears, nears, r_angles, nrangles, c_vertices, ncverts, removed, earverts, rangles)

        if not any_gt(ears, 0):
            ShowWarningError(state, String("DXFOut: Could not triangulate surface=\"") + surfname + String("\", type=\"") + String(surfclass) + String("\", check surface vertex order(entry)"))
            state.inc_errcount()
            if state.get_errcount() == 1 and not state.get_display_extra_warnings():
                ShowContinueError(state, "...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual surfaces.")
            if state.get_display_extra_warnings():
                ShowMessage(state, String(" surface=") + surfname + String(" class=") + String(surfclass))
                for j in range(nsides):
                    ShowMessage(state, String(" side=") + String(j + 1) + String(" (") + String(polygon[j].x) + String(",") + String(polygon[j].y) + String(",") + String(polygon[j].z) + String(")"))
                ShowMessage(state, String(" number of triangles found=") + String(ncount))
                for j in range(nrangles):
                    ShowMessage(state, String(" r angle=") + String(j + 1) + String(" vert=") + String(r_angles[j]) + String(" deg=") + String(rangles[j] * RadToDeg))

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
            var j: Int32 = 0
            ncount += 1
            for i in range(nsides):
                if not removed[i]:
                    earvert[ncount - 1][j] = i
                    j += 1

    var ntri = ncount
    var outtriangles = DynamicVector[dTriangle]()
    for i in range(ntri):
        outtriangles.push_back(dTriangle(earvert[i][0], earvert[i][1], earvert[i][2]))

    return Tuple[Int32, DynamicVector[dTriangle]](ntri, outtriangles)

fn angle_2dvector(xa: Float64, ya: Float64, xb: Float64, yb: Float64, xc: Float64, yc: Float64) -> Float64:
    alias epsilon = 0.0000001

    var x1 = xa - xb
    var y1 = ya - yb
    var x2 = xc - xb
    var y2 = yc - yb

    var t = sqrt((x1 * x1 + y1 * y1) * (x2 * x2 + y2 * y2))
    if t == 0.0:
        t = 1.0

    t = (x1 * x2 + y1 * y2) / t

    if (1.0 - epsilon) < fabs(t):
        t = sign(1.0, t)

    var angle = acos(t)

    if x2 * y1 - y2 * x1 < 0.0:
        angle = 2.0 * Pi - angle

    return angle

fn polygon_contains_point_2d(nsides: Int32, polygon: DynamicVector[Vector_2d], point: Vector_2d) -> Bool:
    var inside: Bool = False

    for i in range(nsides):
        var ip1: Int32 = i + 1 if i < nsides - 1 else 0

        if ((polygon[i].y < point.y and point.y <= polygon[ip1].y) or
            (point.y <= polygon[i].y and polygon[ip1].y < point.y)):
            if ((point.x - polygon[i].x) - (point.y - polygon[i].y) *
                (polygon[ip1].x - polygon[i].x) / (polygon[ip1].y - polygon[i].y) < 0):
                inside = not inside

    return inside

fn generate_ears(state: EnergyPlusDataStub, nvert: Int32, vertex: DynamicVector[Vector_2d],
                 inout ears: DynamicVector[Int32], inout nears: Int32, inout r_vertices: DynamicVector[Int32],
                 inout nrverts: Int32, inout c_vertices: DynamicVector[Int32], inout ncverts: Int32,
                 inout removed: DynamicVector[Bool], inout earvert: InlineArray[Int32, 3], inout rangles: DynamicVector[Float64]):
    for i in range(len(ears)):
        ears[i] = 0
    for i in range(len(r_vertices)):
        r_vertices[i] = 0
    for i in range(len(rangles)):
        rangles[i] = 0.0
    for i in range(len(c_vertices)):
        c_vertices[i] = 0

    nears = 0
    nrverts = 0
    ncverts = 0

    var testtri = DynamicVector[Vector_2d]()
    testtri.push_back(Vector_2d())
    testtri.push_back(Vector_2d())
    testtri.push_back(Vector_2d())

    for svert in range(nvert):
        if removed[svert]:
            continue

        var mvert: Int32 = svert + 1
        for j in range(nvert):
            if mvert >= nvert:
                mvert = 0
            if removed[mvert]:
                mvert += 1
                if mvert >= nvert:
                    mvert = 0
            else:
                break

        var evert: Int32 = mvert + 1
        for j in range(nvert):
            if evert >= nvert:
                evert = 0
            if removed[evert]:
                evert += 1
                if evert >= nvert:
                    evert = 0
            else:
                break

        var ang = angle_2dvector(vertex[svert].x, vertex[svert].y, vertex[mvert].x,
                                vertex[mvert].y, vertex[evert].x, vertex[evert].y)

        if ang > Pi:
            nrverts += 1
            r_vertices[nrverts - 1] = mvert
            rangles[nrverts - 1] = ang
            continue

        ncverts += 1
        c_vertices[ncverts - 1] = mvert

        testtri[0] = vertex[svert]
        testtri[1] = vertex[mvert]
        testtri[2] = vertex[evert]

        var tvert: Int32 = evert
        var inpoly: Bool = False
        for j in range(4, nvert + 1):
            tvert += 1
            if tvert >= nvert:
                tvert = 0
            if removed[tvert]:
                continue
            var point = vertex[tvert]
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
            if state.get_trackit():
                DebugPrint(state, String("ear=") + String(nears) + String(" triangle=") + String(svert) + String(mvert) + String(evert))

fn CalcWallCoordinateTransformation(nsides: Int32, polygon: DynamicVector[Vector],
                                     surfazimuth: Float64, surftilt: Float64,
                                     inout xvt: DynamicVector[Float64], inout yvt: DynamicVector[Float64], inout zvt: DynamicVector[Float64]):
    var alpha = surfazimuth
    var alpha180 = 180.0 - alpha
    var alphrad = alpha180 / RadToDeg
    var cos_alphrad = cos(alphrad)
    var sin_alphrad = sin(alphrad)

    for i in range(nsides):
        xvt[i] = cos_alphrad * polygon[i].x + sin_alphrad * polygon[i].y
        yvt[i] = -sin_alphrad * polygon[i].x + cos_alphrad * polygon[i].y
        zvt[i] = polygon[i].z

fn CalcRfFlrCoordinateTransformation(nsides: Int32, polygon: DynamicVector[Vector],
                                      surfazimuth: Float64, surftilt: Float64,
                                      inout xvt: DynamicVector[Float64], inout yvt: DynamicVector[Float64], inout zvt: DynamicVector[Float64]):
    var alpha = -surftilt
    var alphrad = alpha / RadToDeg
    var cos_alphrad = cos(alphrad)
    var sin_alphrad = sin(alphrad)

    for i in range(nsides):
        xvt[i] = polygon[i].x
        yvt[i] = cos_alphrad * polygon[i].x + sin_alphrad * polygon[i].y
        zvt[i] = -sin_alphrad * polygon[i].x + cos_alphrad * polygon[i].y

struct DXFEarClippingData:
    var trackit: Bool
    var errcount: Int32

    fn __init__() -> Self:
        return Self{trackit: False, errcount: 0}

    fn init_constant_state(self, inout state: EnergyPlusDataStub):
        pass

    fn init_state(self, inout state: EnergyPlusDataStub):
        pass

    fn clear_state(inout self):
        self.trackit = False
        self.errcount = 0

struct EnergyPlusDataStub:
    var trackit: Bool
    var errcount: Int32
    var display_extra_warnings: Bool

    fn __init__() -> Self:
        return Self{trackit: False, errcount: 0, display_extra_warnings: False}

    fn get_trackit(self) -> Bool:
        return self.trackit

    fn set_trackit(inout self, val: Bool):
        self.trackit = val

    fn get_errcount(self) -> Int32:
        return self.errcount

    fn inc_errcount(inout self):
        self.errcount += 1

    fn get_display_extra_warnings(self) -> Bool:
        return self.display_extra_warnings

fn ShowWarningError(state: EnergyPlusDataStub, msg: String):
    pass

fn ShowContinueError(state: EnergyPlusDataStub, msg: String):
    pass

fn ShowMessage(state: EnergyPlusDataStub, msg: String):
    pass

fn DebugPrint(state: EnergyPlusDataStub, msg: String):
    pass
