from math import sqrt, max as math_max, abs as math_abs
from math import fabs

alias Real = Float64

struct Vector3:
    var x: Real
    var y: Real
    var z: Real

    fn __init__(inout self, x: Real = 0.0, y: Real = 0.0, z: Real = 0.0):
        self.x = x
        self.y = y
        self.z = z

    fn __sub__(self, other: Vector3) -> Vector3:
        return Vector3(self.x - other.x, self.y - other.y, self.z - other.z)

    fn __add__(self, other: Vector3) -> Vector3:
        return Vector3(self.x + other.x, self.y + other.y, self.z + other.z)

    fn __mul__(self, scalar: Real) -> Vector3:
        return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __rmul__(self, scalar: Real) -> Vector3:
        return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)

    fn mag_squared(self) -> Real:
        return self.x * self.x + self.y * self.y + self.z * self.z

    fn min(inout self, other: Vector3) -> None:
        if other.x < self.x:
            self.x = other.x
        if other.y < self.y:
            self.y = other.y
        if other.z < self.z:
            self.z = other.z

    fn max(inout self, other: Vector3) -> None:
        if other.x > self.x:
            self.x = other.x
        if other.y > self.y:
            self.y = other.y
        if other.z > self.z:
            self.z = other.z

trait Surface:
    fn get_vertex_count(self) -> Int:
        ...
    fn get_vertex(self, idx: Int) -> Vector3:
        ...
    fn is_transparent(self) -> Bool:
        ...

trait PredicateFn:
    fn call(self, surface: Surface) -> Bool:
        ...

trait ProcessFn:
    fn call(self, surface: Surface) -> None:
        ...

trait EnergyPlusState:
    pass

fn distance_squared(a: Vector3, b: Vector3) -> Real:
    var diff = b - a
    return diff.mag_squared()

fn mid(a: Vector3, b: Vector3) -> Vector3:
    return Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, (a.z + b.z) * 0.5)

fn cen(l: Vector3, u: Vector3) -> Vector3:
    return Vector3((l.x + u.x) * 0.5, (l.y + u.y) * 0.5, (l.z + u.z) * 0.5)

fn magnitude_squared(v: Vector3) -> Real:
    return v.mag_squared()

fn square(x: Real) -> Real:
    return x * x

struct SurfaceOctreeCube:
    var d_: UInt8
    var n_: UInt8
    var l_: Vector3
    var u_: Vector3
    var c_: Vector3
    var w_: Real
    var r_: Real
    var cubes_: InlineArray[DTypePointer[DType.uint8], 8]
    var surfaces_: DynamicVector[Int]

    alias max_depth: UInt8 = 255
    alias max_surfaces: Int = 10

    fn __init__(inout self):
        self.d_ = 0
        self.n_ = 0
        self.l_ = Vector3(0.0, 0.0, 0.0)
        self.u_ = Vector3(0.0, 0.0, 0.0)
        self.c_ = Vector3(0.0, 0.0, 0.0)
        self.w_ = 0.0
        self.r_ = 0.0
        self.cubes_ = InlineArray[DTypePointer[DType.uint8], 8](fill=None)
        self.surfaces_ = DynamicVector[Int]()

    fn __init__(inout self, d: UInt8, l: Vector3, u: Vector3, w: Real):
        self.d_ = d
        self.n_ = 0
        self.l_ = l
        self.u_ = u
        self.c_ = cen(l, u)
        self.w_ = w
        self.r_ = 0.75 * (w * w)
        self.cubes_ = InlineArray[DTypePointer[DType.uint8], 8](fill=None)
        self.surfaces_ = DynamicVector[Int]()

    fn depth(self) -> UInt8:
        return self.d_

    fn n_children(self) -> UInt8:
        return self.n_

    fn n_sub_cube(self) -> UInt8:
        return self.n_

    fn lower(self) -> Vector3:
        return self.l_

    fn upper(self) -> Vector3:
        return self.u_

    fn center(self) -> Vector3:
        return self.c_

    fn width(self) -> Real:
        return self.w_

    fn surfaces_size(self) -> Int:
        return len(self.surfaces_)

    fn contains_vertex(self, v: Vector3) -> Bool:
        return (self.l_.x <= v.x) and (v.x <= self.u_.x) and (self.l_.y <= v.y) and (v.y <= self.u_.y) and (self.l_.z <= v.z) and (v.z <= self.u_.z)

    fn contains_surface(self, surface: Surface) -> Bool:
        for i in range(surface.get_vertex_count()):
            var v = surface.get_vertex(i)
            if not self.contains_vertex(v):
                return False
        return True

    fn segment_intersects_sphere(self, a: Vector3, b: Vector3) -> Bool:
        var ab = b - a
        var ab_mag_squared = ab.mag_squared()
        if ab_mag_squared == 0.0:
            return distance_squared(a, self.c_) <= self.r_
        var ac = self.c_ - a
        var projection_fac = ((ac.x * ab.x) + (ac.y * ab.y) + (ac.z * ab.z)) / ab_mag_squared
        if (0.0 <= projection_fac) and (projection_fac <= 1.0):
            return distance_squared(ac, projection_fac * ab) <= self.r_
        return (distance_squared(a, self.c_) <= self.r_) or (distance_squared(b, self.c_) <= self.r_)

    fn ray_intersects_sphere(self, a: Vector3, dir: Vector3) -> Bool:
        var ac = self.c_ - a
        var projection_fac = (ac.x * dir.x) + (ac.y * dir.y) + (ac.z * dir.z)
        if 0.0 <= projection_fac:
            return distance_squared(ac, projection_fac * dir) <= self.r_
        return distance_squared(a, self.c_) <= self.r_

    fn line_intersects_sphere(self, a: Vector3, dir: Vector3) -> Bool:
        var ac = self.c_ - a
        return ac.mag_squared() - square((ac.x * dir.x) + (ac.y * dir.y) + (ac.z * dir.z)) <= self.r_

    fn segment_intersects_cube(self, a: Vector3, b: Vector3) -> Bool:
        if self.contains_vertex(a) or self.contains_vertex(b):
            return True
        var m = mid(a, b) - self.c_
        var mb = (b - self.c_) - m
        var e = Vector3(fabs(mb.x), fabs(mb.y), fabs(mb.z))
        var h = 0.5 * self.w_
        if fabs(m.x) > h + e.x:
            return False
        if fabs(m.y) > h + e.y:
            return False
        if fabs(m.z) > h + e.z:
            return False
        if fabs(m.y * mb.z - m.z * mb.y) > h * (e.z + e.y):
            return False
        if fabs(m.x * mb.z - m.z * mb.x) > h * (e.z + e.x):
            return False
        if fabs(m.x * mb.y - m.y * mb.x) > h * (e.y + e.x):
            return False
        return True

    fn safe_inverse(v: Vector3) -> Vector3:
        return Vector3(1.0 / v.x if v.x != 0.0 else 0.0, 1.0 / v.y if v.y != 0.0 else 0.0, 1.0 / v.z if v.z != 0.0 else 0.0)

    fn ray_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Vector3) -> Bool:
        if self.contains_vertex(a):
            return True

        var tx: Real
        if dir.x > 0.0:
            tx = (self.l_.x - a.x) * dir_inv.x
        elif dir.x < 0.0:
            tx = (self.u_.x - a.x) * dir_inv.x
        else:
            tx = (-1.7976931348623157e+308)

        var ty: Real
        if dir.y > 0.0:
            ty = (self.l_.y - a.y) * dir_inv.y
        elif dir.y < 0.0:
            ty = (self.u_.y - a.y) * dir_inv.y
        else:
            ty = (-1.7976931348623157e+308)

        var tz: Real
        if dir.z > 0.0:
            tz = (self.l_.z - a.z) * dir_inv.z
        elif dir.z < 0.0:
            tz = (self.u_.z - a.z) * dir_inv.z
        else:
            tz = (-1.7976931348623157e+308)

        var tmax = math_max(math_max(tx, ty), tz)
        if tmax >= 0.0:
            if tx == tmax:
                var y = a.y + (tmax * dir.y)
                if (y < self.l_.y) or (y > self.u_.y):
                    return False
                var z = a.z + (tmax * dir.z)
                if (z < self.l_.z) or (z > self.u_.z):
                    return False
            elif ty == tmax:
                var x = a.x + (tmax * dir.x)
                if (x < self.l_.x) or (x > self.u_.x):
                    return False
                var z = a.z + (tmax * dir.z)
                if (z < self.l_.z) or (z > self.u_.z):
                    return False
            else:
                var x = a.x + (tmax * dir.x)
                if (x < self.l_.x) or (x > self.u_.x):
                    return False
                var y = a.y + (tmax * dir.y)
                if (y < self.l_.y) or (y > self.u_.y):
                    return False
            return True
        return False

    fn ray_intersects_cube(self, a: Vector3, dir: Vector3) -> Bool:
        return self.ray_intersects_cube(a, dir, self.safe_inverse(dir))

    fn line_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Vector3) -> Bool:
        var txl: Real
        var txu: Real
        if dir.x > 0.0:
            txl = (self.l_.x - a.x) * dir_inv.x
            txu = (self.u_.x - a.x) * dir_inv.x
        elif dir.x < 0.0:
            txl = (self.u_.x - a.x) * dir_inv.x
            txu = (self.l_.x - a.x) * dir_inv.x
        else:
            if (self.l_.x - a.x <= 0.0) and (self.u_.x - a.x >= 0.0):
                txl = (-1.7976931348623157e+308)
                txu = 1.7976931348623157e+308
            else:
                return False

        var tyl: Real
        var tyu: Real
        if dir.y > 0.0:
            tyl = (self.l_.y - a.y) * dir_inv.y
            tyu = (self.u_.y - a.y) * dir_inv.y
        elif dir.y < 0.0:
            tyl = (self.u_.y - a.y) * dir_inv.y
            tyu = (self.l_.y - a.y) * dir_inv.y
        else:
            if (self.l_.y - a.y <= 0.0) and (self.u_.y - a.y >= 0.0):
                tyl = (-1.7976931348623157e+308)
                tyu = 1.7976931348623157e+308
            else:
                return False

        if (txl > tyu) or (tyl > txu):
            return False

        var tzl: Real
        var tzu: Real
        if dir.z > 0.0:
            tzl = (self.l_.z - a.z) * dir_inv.z
            tzu = (self.u_.z - a.z) * dir_inv.z
        elif dir.z < 0.0:
            tzl = (self.u_.z - a.z) * dir_inv.z
            tzu = (self.l_.z - a.z) * dir_inv.z
        else:
            if (self.l_.z - a.z <= 0.0) and (self.u_.z - a.z >= 0.0):
                tzl = (-1.7976931348623157e+308)
                tzu = 1.7976931348623157e+308
            else:
                return False

        return ((txl <= tzu) and (tzl <= txu) and (tyl <= tzu) and (tzl <= tyu))

    fn line_intersects_cube(self, a: Vector3, dir: Vector3) -> Bool:
        return self.line_intersects_cube(a, dir, self.safe_inverse(dir))

    fn _add(inout self, surface: Int):
        self.surfaces_.push_back(surface)

    fn _contains_vertex(l: Vector3, u: Vector3, v: Vector3) -> Bool:
        return (l.x <= v.x) and (v.x <= u.x) and (l.y <= v.y) and (v.y <= u.y) and (l.z <= v.z) and (v.z <= u.z)

    fn _contains_surface(l: Vector3, u: Vector3, surface: Surface) -> Bool:
        for i in range(surface.get_vertex_count()):
            var v = surface.get_vertex(i)
            if not SurfaceOctreeCube._contains_vertex(l, u, v):
                return False
        return True
