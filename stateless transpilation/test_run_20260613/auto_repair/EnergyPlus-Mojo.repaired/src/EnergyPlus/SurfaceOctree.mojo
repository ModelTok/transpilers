from std import *
from math import *
from memory import Pointer

# Forward declarations
struct Vector3:
    var x: Float64
    var y: Float64
    var z: Float64

    def __init__(inout self, x: Float64 = 0.0, y: Float64 = 0.0, z: Float64 = 0.0):
        self.x = x
        self.y = y
        self.z = z

    def mag_squared(self) -> Float64:
        return self.x * self.x + self.y * self.y + self.z * self.z

    def min(inout self, v: Vector3):
        if v.x < self.x: self.x = v.x
        if v.y < self.y: self.y = v.y
        if v.z < self.z: self.z = v.z

    def max(inout self, v: Vector3):
        if v.x > self.x: self.x = v.x
        if v.y > self.y: self.y = v.y
        if v.z > self.z: self.z = v.z

    def __sub__(self, other: Vector3) -> Vector3:
        return Vector3(self.x - other.x, self.y - other.y, self.z - other.z)

    def __add__(self, other: Vector3) -> Vector3:
        return Vector3(self.x + other.x, self.y + other.y, self.z + other.z)

    def __mul__(self, scalar: Float64) -> Vector3:
        return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)

    def __neg__(self) -> Vector3:
        return Vector3(-self.x, -self.y, -self.z)

    def __eq__(self, other: Vector3) -> Bool:
        return self.x == other.x and self.y == other.y and self.z == other.z

# Equivalent of ObjexxFCL utility functions
def cen(l: Vector3, u: Vector3) -> Vector3:
    return Vector3((l.x + u.x) / 2.0, (l.y + u.y) / 2.0, (l.z + u.z) / 2.0)

def distance_squared(a: Vector3, b: Vector3) -> Float64:
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z)

def square(x: Float64) -> Float64:
    return x * x

def magnitude_squared(v: Vector3) -> Float64:
    return v.x * v.x + v.y * v.y + v.z * v.z

def mid(a: Vector3, b: Vector3) -> Vector3:
    return Vector3((a.x + b.x) / 2.0, (a.y + b.y) / 2.0, (a.z + b.z) / 2.0)

def max3(a: Float64, b: Float64, c: Float64) -> Float64:
    if a >= b and a >= c:
        return a
    elif b >= a and b >= c:
        return b
    else:
        return c

def max_f(a: Float64, b: Float64) -> Float64:
    return a if a >= b else b

# Alias for Real
alias Real = Float64

# Import SurfaceData from DataSurfaces (fictional module)
# In practice, this file would be placed relative to DataSurfaces.mojo
from DataSurfaces import SurfaceData as SurfaceData

# Equivalent of SurfaceOctreeCube
@value
struct SurfaceOctreeCube:
    # Public types
    alias Surface = SurfaceData
    alias Vertex = Vector3
    alias Surfaces = List[Surface]
    alias size_type = UInt

    # Private static constants (as methods)
    def maxDepth_() -> UInt8:
        return 255

    def maxSurfaces_() -> size_type:
        return 10

    # Data members
    var d_: UInt8
    var n_: UInt8
    var l_: Vertex
    var u_: Vertex
    var c_: Vertex
    var w_: Real
    var r_: Real
    var cubes_: List[SurfaceOctreeCube?]
    var surfaces_: Surfaces

    # Constructor: default
    def __init__(inout self):
        self.d_ = 0
        self.n_ = 0
        self.l_ = Vertex(0.0)
        self.u_ = Vertex(0.0)
        self.c_ = Vertex(0.0)
        self.w_ = 0.0
        self.r_ = 0.0
        self.cubes_ = List[SurfaceOctreeCube?]()
        for i in range(8):
            self.cubes_.append(None)
        self.surfaces_ = List[Surface]()

    # Constructor with EPVector (List) of surfaces
    def __init__(inout self, surfaces: List[Surface]):
        self.d_ = 0
        self.n_ = 0
        self.l_ = Vertex(0.0)
        self.u_ = Vertex(0.0)
        self.c_ = Vertex(0.0)
        self.w_ = 0.0
        self.r_ = 0.0
        self.cubes_ = List[SurfaceOctreeCube?]()
        for i in range(8):
            self.cubes_.append(None)
        self.surfaces_ = List[Surface]()
        self.init(surfaces)

    # Constructor with depth, lower, upper, width
    def __init__(inout self, d: UInt8, l: Vertex, u: Vertex, w: Real):
        self.d_ = d
        self.n_ = 0
        self.l_ = l
        self.u_ = u
        self.c_ = cen(l, u)
        self.w_ = w
        self.r_ = 0.75 * (w * w)
        self.cubes_ = List[SurfaceOctreeCube?]()
        for i in range(8):
            self.cubes_.append(None)
        self.surfaces_ = List[Surface]()
        assert(self.valid())

    # Destructor not needed in Mojo (garbage collected)

    # Properties
    def d(self) -> UInt8: return self.d_
    def depth(self) -> UInt8: return self.d_
    def nChildren(self) -> UInt8: return self.n_
    def nSubCube(self) -> UInt8: return self.n_
    def l(self) -> Vertex: return self.l_
    def u(self) -> Vertex: return self.u_
    def c(self) -> Vertex: return self.c_
    def center(self) -> Vertex: return self.c_
    def w(self) -> Real: return self.w_
    def width(self) -> Real: return self.w_
    def surfaces(self) -> Surfaces: return self.surfaces_
    def surfaces_size(self) -> size_type: return len(self.surfaces_)
    # Iterators: in Mojo we can iterate directly over the list
    # No need for begin/end

    # Methods
    def contains(self, v: Vertex) -> Bool:
        return (self.l_.x <= v.x) and (v.x <= self.u_.x) and (self.l_.y <= v.y) and (v.y <= self.u_.y) and (self.l_.z <= v.z) and (v.z <= self.u_.z)

    def contains(self, surface: Surface) -> Bool:
        for v in surface.Vertex:
            if not self.contains(v):
                return False
        return True

    def segmentIntersectsSphere(self, a: Vertex, b: Vertex) -> Bool:
        ab = b - a
        ab_mag_squared = ab.mag_squared()
        if ab_mag_squared == 0.0:
            return distance_squared(a, self.c_) <= self.r_
        ac = self.c_ - a
        projection_fac = ((ac.x * ab.x) + (ac.y * ab.y) + (ac.z * ab.z)) / ab_mag_squared
        if (0.0 <= projection_fac) and (projection_fac <= 1.0):
            return distance_squared(ac, projection_fac * ab) <= self.r_
        return (distance_squared(a, self.c_) <= self.r_) or (distance_squared(b, self.c_) <= self.r_)

    def rayIntersectsSphere(self, a: Vertex, dir: Vertex) -> Bool:
        assert(abs(dir.mag_squared() - 1.0) < 4 * std.numeric_limits[Float64].epsilon())
        ac = self.c_ - a
        projection_fac = (ac.x * dir.x) + (ac.y * dir.y) + (ac.z * dir.z)
        if 0.0 <= projection_fac:
            return distance_squared(ac, projection_fac * dir) <= self.r_
        return distance_squared(a, self.c_) <= self.r_

    def lineIntersectsSphere(self, a: Vertex, dir: Vertex) -> Bool:
        assert(abs(dir.mag_squared() - 1.0) < 4 * std.numeric_limits[Float64].epsilon())
        ac = self.c_ - a
        return ac.mag_squared() - square((ac.x * dir.x) + (ac.y * dir.y) + (ac.z * dir.z)) <= self.r_

    def segmentIntersectsCube(self, a: Vertex, b: Vertex) -> Bool:
        if self.contains(a) or self.contains(b):
            return True
        m = mid(a, b) - self.c_
        mb = b - self.c_ - m
        e = Vertex(abs(mb.x), abs(mb.y), abs(mb.z))
        h = 0.5 * self.w_
        if abs(m.x) > h + e.x: return False
        if abs(m.y) > h + e.y: return False
        if abs(m.z) > h + e.z: return False
        if abs(m.y * mb.z - m.z * mb.y) > h * (e.z + e.y): return False
        if abs(m.x * mb.z - m.z * mb.x) > h * (e.z + e.x): return False
        if abs(m.x * mb.y - m.y * mb.x) > h * (e.y + e.x): return False
        return True

    def rayIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex) -> Bool:
        assert(abs(dir.mag_squared() - 1.0) < 4 * std.numeric_limits[Float64].epsilon())
        assert((dir.x == 0.0) or (abs(dir_inv.x - (1.0 / dir.x)) < 2 * std.numeric_limits[Float64].epsilon() * abs(dir_inv.x)))
        assert((dir.y == 0.0) or (abs(dir_inv.y - (1.0 / dir.y)) < 2 * std.numeric_limits[Float64].epsilon() * abs(dir_inv.y)))
        assert((dir.z == 0.0) or (abs(dir_inv.z - (1.0 / dir.z)) < 2 * std.numeric_limits[Float64].epsilon() * abs(dir_inv.z)))
        if self.contains(a):
            return True
        if dir.x > 0.0:
            tx = (self.l_.x - a.x) * dir_inv.x
        elif dir.x < 0.0:
            tx = (self.u_.x - a.x) * dir_inv.x
        else:
            tx = std.numeric_limits[Float64].lowest()
        if dir.y > 0.0:
            ty = (self.l_.y - a.y) * dir_inv.y
        elif dir.y < 0.0:
            ty = (self.u_.y - a.y) * dir_inv.y
        else:
            ty = std.numeric_limits[Float64].lowest()
        if dir.z > 0.0:
            tz = (self.l_.z - a.z) * dir_inv.z
        elif dir.z < 0.0:
            tz = (self.u_.z - a.z) * dir_inv.z
        else:
            tz = std.numeric_limits[Float64].lowest()
        tmax = max3(tx, ty, tz)
        if tmax >= 0.0:
            if tx == tmax:
                y = a.y + (tmax * dir.y)
                if (y < self.l_.y) or (y > self.u_.y): return False
                z = a.z + (tmax * dir.z)
                if (z < self.l_.z) or (z > self.u_.z): return False
            elif ty == tmax:
                x = a.x + (tmax * dir.x)
                if (x < self.l_.x) or (x > self.u_.x): return False
                z = a.z + (tmax * dir.z)
                if (z < self.l_.z) or (z > self.u_.z): return False
            else:
                x = a.x + (tmax * dir.x)
                if (x < self.l_.x) or (x > self.u_.x): return False
                y = a.y + (tmax * dir.y)
                if (y < self.l_.y) or (y > self.u_.y): return False
            return True
        return False

    def rayIntersectsCube(self, a: Vertex, dir: Vertex) -> Bool:
        return self.rayIntersectsCube(a, dir, self.safe_inverse(dir))

    def lineIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex) -> Bool:
        assert(abs(dir.mag_squared() - 1.0) < 4 * std.numeric_limits[Float64].epsilon())
        assert((dir.x == 0.0) or (abs(dir_inv.x - (1.0 / dir.x)) < 2 * std.numeric_limits[Float64].epsilon() * abs(dir_inv.x)))
        assert((dir.y == 0.0) or (abs(dir_inv.y - (1.0 / dir.y)) < 2 * std.numeric_limits[Float64].epsilon() * abs(dir_inv.y)))
        assert((dir.z == 0.0) or (abs(dir_inv.z - (1.0 / dir.z)) < 2 * std.numeric_limits[Float64].epsilon() * abs(dir_inv.z)))
        if dir.x > 0.0:
            txl = (self.l_.x - a.x) * dir_inv.x
            txu = (self.u_.x - a.x) * dir_inv.x
        elif dir.x < 0.0:
            txl = (self.u_.x - a.x) * dir_inv.x
            txu = (self.l_.x - a.x) * dir_inv.x
        else:
            if (self.l_.x - a.x <= 0.0) and (self.u_.x - a.x >= 0.0):
                txl = std.numeric_limits[Float64].lowest()
                txu = std.numeric_limits[Float64].max()
            else:
                return False
        if dir.y > 0.0:
            tyl = (self.l_.y - a.y) * dir_inv.y
            tyu = (self.u_.y - a.y) * dir_inv.y
        elif dir.y < 0.0:
            tyl = (self.u_.y - a.y) * dir_inv.y
            tyu = (self.l_.y - a.y) * dir_inv.y
        else:
            if (self.l_.y - a.y <= 0.0) and (self.u_.y - a.y >= 0.0):
                tyl = std.numeric_limits[Float64].lowest()
                tyu = std.numeric_limits[Float64].max()
            else:
                return False
        if (txl > tyu) or (tyl > txu): return False
        if dir.z > 0.0:
            tzl = (self.l_.z - a.z) * dir_inv.z
            tzu = (self.u_.z - a.z) * dir_inv.z
        elif dir.z < 0.0:
            tzl = (self.u_.z - a.z) * dir_inv.z
            tzu = (self.l_.z - a.z) * dir_inv.z
        else:
            if (self.l_.z - a.z <= 0.0) and (self.u_.z - a.z >= 0.0):
                tzl = std.numeric_limits[Float64].lowest()
                tzu = std.numeric_limits[Float64].max()
            else:
                return False
        return ((txl <= tzu) and (tzl <= txu) and (tyl <= tzu) and (tzl <= tyu))

    def lineIntersectsCube(self, a: Vertex, dir: Vertex) -> Bool:
        return self.lineIntersectsCube(a, dir, self.safe_inverse(dir))

    def init(inout self, surfaces: List[Surface]):
        assert(self.d_ == 0)
        assert(self.n_ == 0)
        self.surfaces_ = List[Surface]()
        self.surfaces_.reserve(len(surfaces))
        for surface in surfaces:
            if (len(surface.Vertex) >= 3) and (not surface.IsTransparent):
                self.surfaces_.append(surface)
        if len(self.surfaces_) == 0:
            self.l_ = Vertex(0.0)
            self.u_ = Vertex(0.0)
            self.c_ = Vertex(0.0)
            self.w_ = 0.0
            self.r_ = 0.0
            return
        surface_0 = self.surfaces_[0]
        assert(len(surface_0.Vertex) > 0)
        self.l_ = surface_0.Vertex[0]
        self.u_ = surface_0.Vertex[0]
        for surface_p in self.surfaces_:
            vertices = surface_p.Vertex
            for vertex in vertices:
                self.l_.min(vertex)
                self.u_.max(vertex)
        self.c_ = cen(self.l_, self.u_)
        diagonal = self.u_ - self.l_
        self.w_ = max3(diagonal.x, diagonal.y, diagonal.z)
        self.r_ = 0.75 * (self.w_ * self.w_)
        h = 0.5 * self.w_
        self.l_ = self.c_ - h
        self.u_ = self.c_ + h
        assert(self.valid())
        self.branch()

    def valid(self) -> Bool:
        if ((self.l_.x <= self.c_.x) and (self.l_.y <= self.c_.y) and (self.l_.z <= self.c_.z)) and ((self.c_.x <= self.u_.x) and (self.c_.y <= self.u_.y) and (self.c_.z <= self.u_.z)):
            tol2 = max_f(max_f(magnitude_squared(self.l_), magnitude_squared(self.u_)) * (4 * std.numeric_limits[Float64].epsilon()), 2 * std.numeric_limits[Float64].min())
            if distance_squared(self.c_, cen(self.l_, self.u_)) <= tol2:
                tol = max_f(max_f(sqrt(max_f(magnitude_squared(self.l_), magnitude_squared(self.u_))) * (4 * std.numeric_limits[Float64].epsilon()), 2 * std.numeric_limits[Float64].min()))
                d = self.u_ - self.l_
                return (abs(d.x - self.w_) <= tol) and (abs(d.x - d.y) <= tol) and (abs(d.x - d.z) <= tol)
        return False

    def branch(inout self):
        if (len(self.surfaces_) > self.maxSurfaces_()) and (self.d_ < self.maxDepth_()):
            surfaces_all = self.surfaces_
            self.surfaces_ = List[Surface]()  # clear
            for surface_p in surfaces_all:
                self.surfaceBranch(surface_p)
            self.n_ = 0
            for i in range(8):
                cube = self.cubes_[i]
                if cube is not None:
                    if self.n_ < i:
                        self.cubes_[self.n_] = cube
                        self.cubes_[i] = None
                    self.n_ += 1
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i].branch()

    def surfaceBranch(inout self, surface: Surface):
        h = 0.5 * self.w_
        sl = surface.Vertex[0]
        su = surface.Vertex[0]
        vertices = surface.Vertex
        for vertex in vertices:
            sl.min(vertex)
            su.max(vertex)
        ctr = cen(sl, su)
        i = 0 if ctr.x <= self.c_.x else 1
        j = 0 if ctr.y <= self.c_.y else 1
        k = 0 if ctr.z <= self.c_.z else 1
        idx = (i << 2) + (j << 1) + k
        cube = self.cubes_[idx]
        if cube is not None:
            if ((cube.l_.x <= sl.x) and (cube.l_.y <= sl.y) and (cube.l_.z <= sl.z)) and ((su.x <= cube.u_.x) and (su.y <= cube.u_.y) and (su.z <= cube.u_.z)):
                cube.add(surface)
            else:
                self.surfaces_.append(surface)
        else:
            x = Float64(i) * h
            y = Float64(j) * h
            z = Float64(k) * h
            l = Vertex(self.l_.x + x, self.l_.y + y, self.l_.z + z)
            u = Vertex(self.c_.x + x, self.c_.y + y, self.c_.z + z)
            if ((l.x <= sl.x) and (l.y <= sl.y) and (l.z <= sl.z)) and ((su.x <= u.x) and (su.y <= u.y) and (su.z <= u.z)):
                self.cubes_[idx] = SurfaceOctreeCube(self.d_ + 1, l, u, h)
                self.cubes_[idx].add(surface)
            else:
                self.surfaces_.append(surface)

    # Private helper
    def add(inout self, surface: Surface):
        self.surfaces_.append(surface)

    # Public recursive query methods
    def surfacesSegmentIntersectsSphere(self, a: Vertex, b: Vertex) -> Surfaces:
        result = List[Surface]()
        self._surfacesSegmentIntersectsSphere(a, b, result)
        return result

    def _surfacesSegmentIntersectsSphere(self, a: Vertex, b: Vertex, inout surfaces: Surfaces):
        if self.segmentIntersectsSphere(a, b):
            if len(self.surfaces_) > 0:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i]._surfacesSegmentIntersectsSphere(a, b, surfaces)

    def surfacesRayIntersectsSphere(self, a: Vertex, dir: Vertex) -> Surfaces:
        result = List[Surface]()
        self._surfacesRayIntersectsSphere(a, dir, result)
        return result

    def _surfacesRayIntersectsSphere(self, a: Vertex, dir: Vertex, inout surfaces: Surfaces):
        if self.rayIntersectsSphere(a, dir):
            if len(self.surfaces_) > 0:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i]._surfacesRayIntersectsSphere(a, dir, surfaces)

    def surfacesLineIntersectsSphere(self, a: Vertex, dir: Vertex) -> Surfaces:
        result = List[Surface]()
        self._surfacesLineIntersectsSphere(a, dir, result)
        return result

    def _surfacesLineIntersectsSphere(self, a: Vertex, dir: Vertex, inout surfaces: Surfaces):
        if self.lineIntersectsSphere(a, dir):
            if len(self.surfaces_) > 0:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i]._surfacesLineIntersectsSphere(a, dir, surfaces)

    def surfacesSegmentIntersectsCube(self, a: Vertex, b: Vertex) -> Surfaces:
        result = List[Surface]()
        self._surfacesSegmentIntersectsCube(a, b, result)
        return result

    def _surfacesSegmentIntersectsCube(self, a: Vertex, b: Vertex, inout surfaces: Surfaces):
        if self.segmentIntersectsCube(a, b):
            if len(self.surfaces_) > 0:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i]._surfacesSegmentIntersectsCube(a, b, surfaces)

    def surfacesRayIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex) -> Surfaces:
        result = List[Surface]()
        self._surfacesRayIntersectsCube(a, dir, dir_inv, result)
        return result

    def _surfacesRayIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex, inout surfaces: Surfaces):
        if self.rayIntersectsCube(a, dir, dir_inv):
            if len(self.surfaces_) > 0:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i]._surfacesRayIntersectsCube(a, dir, dir_inv, surfaces)

    def surfacesRayIntersectsCube(self, a: Vertex, dir: Vertex) -> Surfaces:
        return self.surfacesRayIntersectsCube(a, dir, self.safe_inverse(dir))

    def surfacesLineIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex) -> Surfaces:
        result = List[Surface]()
        self._surfacesLineIntersectsCube(a, dir, dir_inv, result)
        return result

    def _surfacesLineIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex, inout surfaces: Surfaces):
        if self.lineIntersectsCube(a, dir, dir_inv):
            if len(self.surfaces_) > 0:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i]._surfacesLineIntersectsCube(a, dir, dir_inv, surfaces)

    def surfacesLineIntersectsCube(self, a: Vertex, dir: Vertex) -> Surfaces:
        return self.surfacesLineIntersectsCube(a, dir, self.safe_inverse(dir))

    def hasSurfaceSegmentIntersectsCube(self, a: Vertex, b: Vertex, predicate: fn(Surface) -> Bool) -> Bool:
        if self.segmentIntersectsCube(a, b):
            for surface_p in self.surfaces_:
                if predicate(surface_p):
                    return True
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    if self.cubes_[i].hasSurfaceSegmentIntersectsCube(a, b, predicate):
                        return True
        return False

    def hasSurfaceRayIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex, predicate: fn(Surface) -> Bool) -> Bool:
        if self.rayIntersectsCube(a, dir, dir_inv):
            for surface_p in self.surfaces_:
                if predicate(surface_p):
                    return True
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    if self.cubes_[i].hasSurfaceRayIntersectsCube(a, dir, dir_inv, predicate):
                        return True
        return False

    def hasSurfaceRayIntersectsCube(self, a: Vertex, dir: Vertex, predicate: fn(Surface) -> Bool) -> Bool:
        return self.hasSurfaceRayIntersectsCube(a, dir, self.safe_inverse(dir), predicate)

    def processSurfaceRayIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex, function: fn(Surface)):
        if self.rayIntersectsCube(a, dir, dir_inv):
            for surface_p in self.surfaces_:
                function(surface_p)
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    self.cubes_[i].processSurfaceRayIntersectsCube(a, dir, dir_inv, function)

    def processSurfaceRayIntersectsCube(self, a: Vertex, dir: Vertex, function: fn(Surface)):
        self.processSurfaceRayIntersectsCube(a, dir, self.safe_inverse(dir), function)

    def processSomeSurfaceRayIntersectsCube(self, a: Vertex, dir: Vertex, dir_inv: Vertex, predicate: fn(Surface) -> Bool) -> Bool:
        if self.rayIntersectsCube(a, dir, dir_inv):
            for surface_p in self.surfaces_:
                if predicate(surface_p):
                    return True
            for i in range(self.n_):
                if self.cubes_[i] is not None:
                    if self.cubes_[i].processSomeSurfaceRayIntersectsCube(a, dir, dir_inv, predicate):
                        return True
        return False

    def processSomeSurfaceRayIntersectsCube(self, a: Vertex, dir: Vertex, predicate: fn(Surface) -> Bool) -> Bool:
        return self.processSomeSurfaceRayIntersectsCube(a, dir, self.safe_inverse(dir), predicate)

    # Static method
    def safe_inverse(v: Vertex) -> Vertex:
        return Vertex((1.0 / v.x if v.x != 0.0 else 0.0), (1.0 / v.y if v.y != 0.0 else 0.0), (1.0 / v.z if v.z != 0.0 else 0.0))

    # Private static contains
    def _contains(l: Vertex, u: Vertex, v: Vertex) -> Bool:
        return (l.x <= v.x) and (v.x <= u.x) and (l.y <= v.y) and (v.y <= u.y) and (l.z <= v.z) and (v.z <= u.z)

    def _contains(l: Vertex, u: Vertex, surface: Surface) -> Bool:
        for v in surface.Vertex:
            if not SurfaceOctreeCube._contains(l, u, v):
                return False
        return True