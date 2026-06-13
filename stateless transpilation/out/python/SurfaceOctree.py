from dataclasses import dataclass, field
from typing import List, Optional, Callable, TypeVar, Protocol
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object, used in processSomeSurfaceRayIntersectsCube)
# - DataSurfaces.SurfaceData (Surface with Vertex: List[Vertex], IsTransparent: bool)

@dataclass
class Vector3:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

    def __sub__(self, other: 'Vector3') -> 'Vector3':
        return Vector3(self.x - other.x, self.y - other.y, self.z - other.z)

    def __add__(self, other: 'Vector3') -> 'Vector3':
        return Vector3(self.x + other.x, self.y + other.y, self.z + other.z)

    def __mul__(self, scalar: float) -> 'Vector3':
        return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)

    def __rmul__(self, scalar: float) -> 'Vector3':
        return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)

    def mag_squared(self) -> float:
        return self.x * self.x + self.y * self.y + self.z * self.z

    def min(self, other: 'Vector3') -> None:
        self.x = min(self.x, other.x)
        self.y = min(self.y, other.y)
        self.z = min(self.z, other.z)

    def max(self, other: 'Vector3') -> None:
        self.x = max(self.x, other.x)
        self.y = max(self.y, other.y)
        self.z = max(self.z, other.z)

class Surface(Protocol):
    Vertex: List[Vector3]
    IsTransparent: bool

def distance_squared(a: Vector3, b: Vector3) -> float:
    diff = b - a
    return diff.mag_squared()

def mid(a: Vector3, b: Vector3) -> Vector3:
    return Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, (a.z + b.z) * 0.5)

def cen(l: Vector3, u: Vector3) -> Vector3:
    return Vector3((l.x + u.x) * 0.5, (l.y + u.y) * 0.5, (l.z + u.z) * 0.5)

def magnitude_squared(v: Vector3) -> float:
    return v.mag_squared()

def square(x: float) -> float:
    return x * x

class SurfaceOctreeCube:
    max_depth: int = 255
    max_surfaces: int = 10

    def __init__(self, depth: int = 0, lower: Optional[Vector3] = None, upper: Optional[Vector3] = None, width: Optional[float] = None):
        self.d_: int = depth
        self.n_: int = 0
        self.l_: Vector3 = lower if lower is not None else Vector3(0.0, 0.0, 0.0)
        self.u_: Vector3 = upper if upper is not None else Vector3(0.0, 0.0, 0.0)
        self.c_: Vector3 = cen(self.l_, self.u_) if width is not None else Vector3(0.0, 0.0, 0.0)
        self.w_: float = width if width is not None else 0.0
        self.r_: float = 0.75 * (width * width) if width is not None else 0.0
        self.cubes_: List[Optional['SurfaceOctreeCube']] = [None] * 8
        self.surfaces_: List[Surface] = []

        if width is not None:
            assert self.valid()

    @classmethod
    def from_surfaces(cls, surfaces: List[Surface]) -> 'SurfaceOctreeCube':
        obj = cls(0, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), None)
        obj.init(surfaces)
        return obj

    def depth(self) -> int:
        return self.d_

    def n_children(self) -> int:
        return self.n_

    def n_sub_cube(self) -> int:
        return self.n_

    def lower(self) -> Vector3:
        return self.l_

    def upper(self) -> Vector3:
        return self.u_

    def center(self) -> Vector3:
        return self.c_

    def width(self) -> float:
        return self.w_

    def surfaces(self) -> List[Surface]:
        return self.surfaces_

    def surfaces_size(self) -> int:
        return len(self.surfaces_)

    def contains_vertex(self, v: Vector3) -> bool:
        return (self.l_.x <= v.x) and (v.x <= self.u_.x) and (self.l_.y <= v.y) and (v.y <= self.u_.y) and (self.l_.z <= v.z) and (v.z <= self.u_.z)

    def contains_surface(self, surface: Surface) -> bool:
        for v in surface.Vertex:
            if not self.contains_vertex(v):
                return False
        return True

    def segment_intersects_sphere(self, a: Vector3, b: Vector3) -> bool:
        ab = b - a
        ab_mag_squared = ab.mag_squared()
        if ab_mag_squared == 0.0:
            return distance_squared(a, self.c_) <= self.r_
        ac = self.c_ - a
        projection_fac = ((ac.x * ab.x) + (ac.y * ab.y) + (ac.z * ab.z)) / ab_mag_squared
        if (0.0 <= projection_fac) and (projection_fac <= 1.0):
            return distance_squared(ac, projection_fac * ab) <= self.r_
        return (distance_squared(a, self.c_) <= self.r_) or (distance_squared(b, self.c_) <= self.r_)

    def ray_intersects_sphere(self, a: Vector3, dir: Vector3) -> bool:
        assert abs(dir.mag_squared() - 1.0) < 4 * 2.220446049250313e-16
        ac = self.c_ - a
        projection_fac = (ac.x * dir.x) + (ac.y * dir.y) + (ac.z * dir.z)
        if 0.0 <= projection_fac:
            return distance_squared(ac, projection_fac * dir) <= self.r_
        return distance_squared(a, self.c_) <= self.r_

    def line_intersects_sphere(self, a: Vector3, dir: Vector3) -> bool:
        assert abs(dir.mag_squared() - 1.0) < 4 * 2.220446049250313e-16
        ac = self.c_ - a
        return ac.mag_squared() - square((ac.x * dir.x) + (ac.y * dir.y) + (ac.z * dir.z)) <= self.r_

    def segment_intersects_cube(self, a: Vector3, b: Vector3) -> bool:
        if self.contains_vertex(a) or self.contains_vertex(b):
            return True
        m = mid(a, b) - self.c_
        mb = (b - self.c_) - m
        e = Vector3(abs(mb.x), abs(mb.y), abs(mb.z))
        h = 0.5 * self.w_
        if abs(m.x) > h + e.x:
            return False
        if abs(m.y) > h + e.y:
            return False
        if abs(m.z) > h + e.z:
            return False
        if abs(m.y * mb.z - m.z * mb.y) > h * (e.z + e.y):
            return False
        if abs(m.x * mb.z - m.z * mb.x) > h * (e.z + e.x):
            return False
        if abs(m.x * mb.y - m.y * mb.x) > h * (e.y + e.x):
            return False
        return True

    @staticmethod
    def safe_inverse(v: Vector3) -> Vector3:
        return Vector3(1.0 / v.x if v.x != 0.0 else 0.0, 1.0 / v.y if v.y != 0.0 else 0.0, 1.0 / v.z if v.z != 0.0 else 0.0)

    def ray_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None) -> bool:
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        assert abs(dir.mag_squared() - 1.0) < 4 * 2.220446049250313e-16
        assert (dir.x == 0.0) or (abs(dir_inv.x - (1.0 / dir.x)) < 2 * 2.220446049250313e-16 * abs(dir_inv.x))
        assert (dir.y == 0.0) or (abs(dir_inv.y - (1.0 / dir.y)) < 2 * 2.220446049250313e-16 * abs(dir_inv.y))
        assert (dir.z == 0.0) or (abs(dir_inv.z - (1.0 / dir.z)) < 2 * 2.220446049250313e-16 * abs(dir_inv.z))

        if self.contains_vertex(a):
            return True

        if dir.x > 0.0:
            tx = (self.l_.x - a.x) * dir_inv.x
        elif dir.x < 0.0:
            tx = (self.u_.x - a.x) * dir_inv.x
        else:
            tx = float('-inf')

        if dir.y > 0.0:
            ty = (self.l_.y - a.y) * dir_inv.y
        elif dir.y < 0.0:
            ty = (self.u_.y - a.y) * dir_inv.y
        else:
            ty = float('-inf')

        if dir.z > 0.0:
            tz = (self.l_.z - a.z) * dir_inv.z
        elif dir.z < 0.0:
            tz = (self.u_.z - a.z) * dir_inv.z
        else:
            tz = float('-inf')

        tmax = max(tx, ty, tz)
        if tmax >= 0.0:
            if tx == tmax:
                y = a.y + (tmax * dir.y)
                if (y < self.l_.y) or (y > self.u_.y):
                    return False
                z = a.z + (tmax * dir.z)
                if (z < self.l_.z) or (z > self.u_.z):
                    return False
            elif ty == tmax:
                x = a.x + (tmax * dir.x)
                if (x < self.l_.x) or (x > self.u_.x):
                    return False
                z = a.z + (tmax * dir.z)
                if (z < self.l_.z) or (z > self.u_.z):
                    return False
            else:
                x = a.x + (tmax * dir.x)
                if (x < self.l_.x) or (x > self.u_.x):
                    return False
                y = a.y + (tmax * dir.y)
                if (y < self.l_.y) or (y > self.u_.y):
                    return False
            return True
        return False

    def line_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None) -> bool:
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        assert abs(dir.mag_squared() - 1.0) < 4 * 2.220446049250313e-16
        assert (dir.x == 0.0) or (abs(dir_inv.x - (1.0 / dir.x)) < 2 * 2.220446049250313e-16 * abs(dir_inv.x))
        assert (dir.y == 0.0) or (abs(dir_inv.y - (1.0 / dir.y)) < 2 * 2.220446049250313e-16 * abs(dir_inv.y))
        assert (dir.z == 0.0) or (abs(dir_inv.z - (1.0 / dir.z)) < 2 * 2.220446049250313e-16 * abs(dir_inv.z))

        if dir.x > 0.0:
            txl = (self.l_.x - a.x) * dir_inv.x
            txu = (self.u_.x - a.x) * dir_inv.x
        elif dir.x < 0.0:
            txl = (self.u_.x - a.x) * dir_inv.x
            txu = (self.l_.x - a.x) * dir_inv.x
        else:
            if (self.l_.x - a.x <= 0.0) and (self.u_.x - a.x >= 0.0):
                txl = float('-inf')
                txu = float('inf')
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
                tyl = float('-inf')
                tyu = float('inf')
            else:
                return False

        if (txl > tyu) or (tyl > txu):
            return False

        if dir.z > 0.0:
            tzl = (self.l_.z - a.z) * dir_inv.z
            tzu = (self.u_.z - a.z) * dir_inv.z
        elif dir.z < 0.0:
            tzl = (self.u_.z - a.z) * dir_inv.z
            tzu = (self.l_.z - a.z) * dir_inv.z
        else:
            if (self.l_.z - a.z <= 0.0) and (self.u_.z - a.z >= 0.0):
                tzl = float('-inf')
                tzu = float('inf')
            else:
                return False

        return ((txl <= tzu) and (tzl <= txu) and (tyl <= tzu) and (tzl <= tyu))

    def surfaces_segment_intersects_sphere(self, a: Vector3, b: Vector3, surfaces: List[Surface]) -> None:
        if self.segment_intersects_sphere(a, b):
            if self.surfaces_:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                self.cubes_[i].surfaces_segment_intersects_sphere(a, b, surfaces)

    def surfaces_ray_intersects_sphere(self, a: Vector3, dir: Vector3, surfaces: List[Surface]) -> None:
        if self.ray_intersects_sphere(a, dir):
            if self.surfaces_:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                self.cubes_[i].surfaces_ray_intersects_sphere(a, dir, surfaces)

    def surfaces_line_intersects_sphere(self, a: Vector3, dir: Vector3, surfaces: List[Surface]) -> None:
        if self.line_intersects_sphere(a, dir):
            if self.surfaces_:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                self.cubes_[i].surfaces_line_intersects_sphere(a, dir, surfaces)

    def surfaces_segment_intersects_cube(self, a: Vector3, b: Vector3, surfaces: List[Surface]) -> None:
        if self.segment_intersects_cube(a, b):
            if self.surfaces_:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                self.cubes_[i].surfaces_segment_intersects_cube(a, b, surfaces)

    def surfaces_ray_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None, surfaces: Optional[List[Surface]] = None) -> None:
        if surfaces is None:
            surfaces = []
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        if self.ray_intersects_cube(a, dir, dir_inv):
            if self.surfaces_:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                self.cubes_[i].surfaces_ray_intersects_cube(a, dir, dir_inv, surfaces)

    def surfaces_line_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None, surfaces: Optional[List[Surface]] = None) -> None:
        if surfaces is None:
            surfaces = []
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        if self.line_intersects_cube(a, dir, dir_inv):
            if self.surfaces_:
                surfaces.extend(self.surfaces_)
            for i in range(self.n_):
                self.cubes_[i].surfaces_line_intersects_cube(a, dir, dir_inv, surfaces)

    def has_surface_segment_intersects_cube(self, a: Vector3, b: Vector3, predicate: Callable[[Surface], bool]) -> bool:
        if self.segment_intersects_cube(a, b):
            for surface in self.surfaces_:
                if predicate(surface):
                    return True
            for i in range(self.n_):
                if self.cubes_[i].has_surface_segment_intersects_cube(a, b, predicate):
                    return True
        return False

    def has_surface_ray_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None, predicate: Optional[Callable[[Surface], bool]] = None) -> bool:
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        if self.ray_intersects_cube(a, dir, dir_inv):
            for surface in self.surfaces_:
                if predicate(surface):
                    return True
            for i in range(self.n_):
                if self.cubes_[i].has_surface_ray_intersects_cube(a, dir, dir_inv, predicate):
                    return True
        return False

    def process_surface_ray_intersects_cube(self, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None, function: Optional[Callable[[Surface], None]] = None) -> None:
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        if self.ray_intersects_cube(a, dir, dir_inv):
            for surface in self.surfaces_:
                function(surface)
            for i in range(self.n_):
                self.cubes_[i].process_surface_ray_intersects_cube(a, dir, dir_inv, function)

    def process_some_surface_ray_intersects_cube(self, state, a: Vector3, dir: Vector3, dir_inv: Optional[Vector3] = None, predicate: Optional[Callable[[Surface], bool]] = None) -> bool:
        if dir_inv is None:
            dir_inv = self.safe_inverse(dir)
        if self.ray_intersects_cube(a, dir, dir_inv):
            for surface in self.surfaces_:
                if predicate(surface):
                    return True
            for i in range(self.n_):
                if self.cubes_[i].process_some_surface_ray_intersects_cube(state, a, dir, dir_inv, predicate):
                    return True
        return False

    def init(self, surfaces: List[Surface]) -> None:
        assert self.d_ == 0
        assert self.n_ == 0
        self.surfaces_ = []
        for surface in surfaces:
            if (len(surface.Vertex) >= 3) and (not surface.IsTransparent):
                self.surfaces_.append(surface)

        if not self.surfaces_:
            self.l_ = Vector3(0.0, 0.0, 0.0)
            self.u_ = Vector3(0.0, 0.0, 0.0)
            self.c_ = Vector3(0.0, 0.0, 0.0)
            self.w_ = 0.0
            self.r_ = 0.0
            return

        surface_0 = self.surfaces_[0]
        self.l_ = Vector3(surface_0.Vertex[0].x, surface_0.Vertex[0].y, surface_0.Vertex[0].z)
        self.u_ = Vector3(surface_0.Vertex[0].x, surface_0.Vertex[0].y, surface_0.Vertex[0].z)

        for surface in self.surfaces_:
            for vertex in surface.Vertex:
                self.l_.min(vertex)
                self.u_.max(vertex)

        self.c_ = cen(self.l_, self.u_)

        diagonal = self.u_ - self.l_
        self.w_ = max(diagonal.x, diagonal.y, diagonal.z)
        self.r_ = 0.75 * (self.w_ * self.w_)
        h = 0.5 * self.w_
        self.l_ = self.c_ - h
        self.u_ = self.c_ + h

        assert self.valid()

        self._branch()

    def valid(self) -> bool:
        if not (((self.l_.x <= self.c_.x) and (self.l_.y <= self.c_.y) and (self.l_.z <= self.c_.z)) and ((self.c_.x <= self.u_.x) and (self.c_.y <= self.u_.y) and (self.c_.z <= self.u_.z))):
            return False
        tol2 = max(max(magnitude_squared(self.l_), magnitude_squared(self.u_)) * (4 * 2.220446049250313e-16), 2 * 2.225073858507201e-308)
        if distance_squared(self.c_, cen(self.l_, self.u_)) > tol2:
            return False
        tol = max(math.sqrt(max(magnitude_squared(self.l_), magnitude_squared(self.u_))) * (4 * 2.220446049250313e-16), 2 * 2.225073858507201e-308)
        d = self.u_ - self.l_
        return (abs(d.x - self.w_) <= tol) and (abs(d.x - d.y) <= tol) and (abs(d.x - d.z) <= tol)

    def _add(self, surface: Surface) -> None:
        self.surfaces_.append(surface)

    def _branch(self) -> None:
        if (len(self.surfaces_) > self.max_surfaces) and (self.d_ < self.max_depth):
            surfaces_all = self.surfaces_
            self.surfaces_ = []
            for surface in surfaces_all:
                self._surface_branch(surface)

            self.n_ = 0
            for i in range(8):
                if self.cubes_[i] is not None:
                    if self.n_ < i:
                        self.cubes_[self.n_] = self.cubes_[i]
                        self.cubes_[i] = None
                    self.n_ += 1

            for i in range(self.n_):
                self.cubes_[i]._branch()

    def _surface_branch(self, surface: Surface) -> None:
        h = 0.5 * self.w_
        sl = Vector3(surface.Vertex[0].x, surface.Vertex[0].y, surface.Vertex[0].z)
        su = Vector3(surface.Vertex[0].x, surface.Vertex[0].y, surface.Vertex[0].z)
        for vertex in surface.Vertex:
            sl.min(vertex)
            su.max(vertex)
        ctr = cen(sl, su)
        i = 0 if ctr.x <= self.c_.x else 1
        j = 0 if ctr.y <= self.c_.y else 1
        k = 0 if ctr.z <= self.c_.z else 1
        cube_idx = (i << 2) + (j << 1) + k
        cube = self.cubes_[cube_idx]

        if cube is not None:
            if (((cube.l_.x <= sl.x) and (cube.l_.y <= sl.y) and (cube.l_.z <= sl.z)) and ((su.x <= cube.u_.x) and (su.y <= cube.u_.y) and (su.z <= cube.u_.z))):
                cube._add(surface)
            else:
                self.surfaces_.append(surface)
        else:
            x = i * h
            y = j * h
            z = k * h
            l = Vector3(self.l_.x + x, self.l_.y + y, self.l_.z + z)
            u = Vector3(self.c_.x + x, self.c_.y + y, self.c_.z + z)
            if (((l.x <= sl.x) and (l.y <= sl.y) and (l.z <= sl.z)) and ((su.x <= u.x) and (su.y <= u.y) and (su.z <= u.z))):
                self.cubes_[cube_idx] = SurfaceOctreeCube(self.d_ + 1, l, u, h)
                self.cubes_[cube_idx]._add(surface)
            else:
                self.surfaces_.append(surface)

    @staticmethod
    def _contains_vertex(l: Vector3, u: Vector3, v: Vector3) -> bool:
        return (l.x <= v.x) and (v.x <= u.x) and (l.y <= v.y) and (v.y <= u.y) and (l.z <= v.z) and (v.z <= u.z)

    @staticmethod
    def _contains_surface(l: Vector3, u: Vector3, surface: Surface) -> bool:
        for v in surface.Vertex:
            if not SurfaceOctreeCube._contains_vertex(l, u, v):
                return False
        return True

    def __del__(self):
        for i in range(self.n_):
            if self.cubes_[i] is not None:
                del self.cubes_[i]
