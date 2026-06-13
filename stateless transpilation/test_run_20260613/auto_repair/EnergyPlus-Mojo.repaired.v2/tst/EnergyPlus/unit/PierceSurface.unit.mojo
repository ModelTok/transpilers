from gtest import Test, Expect
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.PierceSurface import PierceSurface
from algorithm import sort
from math import atan, cos, sin
from EnergyPlus.DataSurfaces import SurfaceData, Surface2D, SurfaceShape, ShapeCat, Vector2D
from DataVectorTypes import Vector

using EnergyPlus = EnergyPlus
using DataSurfaces = DataSurfaces
using Vector = DataVectorTypes.Vector
using Vector2D = DataSurfaces.Surface2D.Vector2D

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_Rectangular():
    var floor = DataSurfaces.SurfaceData()
    floor.Vertex.dimension(4)
    floor.Vertex = [Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 0), Vector(0, 1, 0)]
    floor.Shape = SurfaceShape.Rectangle
    floor.set_computed_geometry()
    var floor2d = floor.surface2d
    Expect.ENUM_EQ(ShapeCat.Rectangular, floor.shapeCat)
    Expect.EQ(2, floor2d.axis)
    Expect.EQ(Vector2D(0, 0), floor2d.vl)
    Expect.EQ(Vector2D(1, 1), floor2d.vu)
    Expect.DOUBLE_EQ(1.0, floor2d.s1)
    Expect.DOUBLE_EQ(1.0, floor2d.s3)
    { # Ray straight down into center of floor
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
        hit = PierceSurface(floor, rayOri, rayDir, 1.1, hitPt) # Distance limit > 1.0 => Still hits
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
        hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, 0.9, hitPt) # Distance limit < 1.0 => Doesn't hit
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(0.0, hitPt.x)
        Expect.DOUBLE_EQ(0.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight up away from floor
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, 1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # No plane intersection so hitPt is undefined
    }
    { # Ray down steep into floor
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.25, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.75, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray down shallow to floor's plane
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(2.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # Misses surface but intersects plane
        Expect.DOUBLE_EQ(2.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_Triangular():
    var floor = DataSurfaces.SurfaceData()
    floor.Vertex.dimension(3)
    floor.Vertex = [Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 0)]
    floor.Shape = SurfaceShape.Triangle
    floor.set_computed_geometry()
    var floor2d = floor.surface2d
    Expect.ENUM_EQ(ShapeCat.Triangular, floor.shapeCat)
    Expect.EQ(2, floor2d.axis)
    Expect.EQ(Vector2D(0, 0), floor2d.vl)
    Expect.EQ(Vector2D(1, 1), floor2d.vu)
    { # Ray straight down into floor
        var rayOri = Vector(0.9, 0.1, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.9, hitPt.x)
        Expect.DOUBLE_EQ(0.1, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight up away from floor
        var rayOri = Vector(0.9, 0.1, 1.0)
        var rayDir = Vector(0.0, 0.0, 1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # No plane intersection so hitPt is undefined
    }
    { # Ray down steep into floor
        var rayOri = Vector(0.9, 0.1, 1.0)
        var rayDir = Vector(-0.25, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.65, hitPt.x)
        Expect.DOUBLE_EQ(0.1, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray down shallow to floor's plane
        var rayOri = Vector(0.9, 0.1, 1.0)
        var rayDir = Vector(2.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # Misses surface but intersects plane
        Expect.DOUBLE_EQ(2.9, hitPt.x)
        Expect.DOUBLE_EQ(0.1, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_ConvexOctagonal():
    var N: Int = 8 # Number of vertices and edges
    var TwoPi: Float64 = 8.0 * atan(1.0)
    var wedge: Float64 = TwoPi / N
    var floor = DataSurfaces.SurfaceData()
    floor.Vertex.reserve(N)
    for i in range(N):
        var angle: Float64 = i * wedge
        floor.Vertex.push_back(Vector(cos(angle), sin(angle), 0.0))
    floor.IsConvex = True
    floor.set_computed_geometry()
    var floor2d = floor.surface2d
    Expect.ENUM_EQ(ShapeCat.Convex, floor.shapeCat)
    Expect.EQ(2, floor2d.axis)
    { # Ray straight down into center of floor
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
    }
    { # Ray straight up away from floor
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(0.0, 0.0, 1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # No plane intersection so hitPt is undefined
    }
    { # Ray down steep into floor
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(0.25, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
    }
    { # Ray down shallow to floor's plane
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(2.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # Misses surface but intersects plane
    }
    { # Ray straight down into point on floor
        var rayOri = Vector(-0.05, -0.8, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_Convex8Sides():
    var floor = DataSurfaces.SurfaceData()
    floor.Vertex.dimension(8)
    floor.Vertex = [Vector(0, 0, 0),
                    Vector(0.5, -0.25, 0),
                    Vector(1, 0, 0),
                    Vector(1.25, 0.5, 0),
                    Vector(1, 1, 0),
                    Vector(0.5, 1.25, 0),
                    Vector(0, 1, 0),
                    Vector(-0.25, 0.5, 0)]
    floor.IsConvex = True
    floor.set_computed_geometry()
    var floor2d = floor.surface2d
    Expect.ENUM_EQ(ShapeCat.Convex, floor.shapeCat)
    Expect.EQ(2, floor2d.axis)
    Expect.EQ(Vector2D(-0.25, -0.25), floor2d.vl)
    Expect.EQ(Vector2D(1.25, 1.25), floor2d.vu)
    { # Ray straight down into center of floor
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight up away from floor
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, 1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # No plane intersection so hitPt is undefined
    }
    { # Ray down steep into floor
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.25, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.75, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray down shallow to floor's plane
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(2.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # Misses surface but intersects plane
        Expect.DOUBLE_EQ(2.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_ConvexNGon():
    var N: Int = 32 # Number of vertices and edges
    var TwoPi: Float64 = 8.0 * atan(1.0)
    var wedge: Float64 = TwoPi / N
    var floor = DataSurfaces.SurfaceData()
    floor.Vertex.reserve(N)
    for i in range(N):
        var angle: Float64 = i * wedge
        floor.Vertex.push_back(Vector(cos(angle), sin(angle), 0.0))
    floor.IsConvex = True
    floor.set_computed_geometry()
    var floor2d = floor.surface2d
    Expect.ENUM_EQ(ShapeCat.Convex, floor.shapeCat)
    Expect.EQ(2, floor2d.axis)
    Expect.EQ(Vector2D(-1.0, -1.0), floor2d.vl)
    Expect.EQ(Vector2D(1.0, 1.0), floor2d.vu)
    { # Ray straight down into center of floor
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.0, hitPt.x)
        Expect.DOUBLE_EQ(0.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight up away from floor
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(0.0, 0.0, 1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # No plane intersection so hitPt is undefined
    }
    { # Ray down steep into floor
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(0.25, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.25, hitPt.x)
        Expect.DOUBLE_EQ(0.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray down shallow to floor's plane
        var rayOri = Vector(0.0, 0.0, 1.0)
        var rayDir = Vector(2.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(floor, rayOri, rayDir, hitPt)
        Expect.FALSE(hit) # Misses surface but intersects plane
        Expect.DOUBLE_EQ(2.0, hitPt.x)
        Expect.DOUBLE_EQ(0.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_NonconvexBoomerang():
    var boomerang = DataSurfaces.SurfaceData()
    boomerang.Vertex.dimension(4)
    boomerang.Vertex = [Vector(0, 0, 0), Vector(1, 0, 0), Vector(0.2, 0.2, 0), Vector(0, 1, 0)] # Nonconvex "pointy boomerang"
    boomerang.IsConvex = False
    boomerang.set_computed_geometry()
    var boomerang2d = boomerang.surface2d
    Expect.ENUM_EQ(ShapeCat.Nonconvex, boomerang.shapeCat)
    Expect.EQ(2, boomerang2d.axis)
    { # Ray straight down into a "wing" of boomerang
        var rayOri = Vector(0.3, 0.1, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(boomerang, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.3, hitPt.x)
        Expect.DOUBLE_EQ(0.1, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into V notch near boomerang
        var rayOri = Vector(0.21, 0.21, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(boomerang, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(0.21, hitPt.x)
        Expect.DOUBLE_EQ(0.21, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_NonconvexUShape():
    var ushape = DataSurfaces.SurfaceData()
    ushape.Vertex.dimension(8)
    ushape.Vertex = [
        Vector(0, 0, 0), Vector(3, 0, 0), Vector(3, 2, 0), Vector(2, 2, 0), Vector(2, 1, 0), Vector(1, 1, 0), Vector(1, 2, 0), Vector(0, 2, 0)]
    ushape.IsConvex = False
    ushape.set_computed_geometry()
    var ushape2d = ushape.surface2d
    Expect.ENUM_EQ(ShapeCat.Nonconvex, ushape.shapeCat)
    Expect.EQ(2, ushape2d.axis)
    { # Ray straight down into middle of base
        var rayOri = Vector(1.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(ushape, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(1.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down below base
        var rayOri = Vector(1.5, -0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(ushape, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(1.5, hitPt.x)
        Expect.DOUBLE_EQ(-0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into left vertical
        var rayOri = Vector(0.5, 1.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(ushape, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(1.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into right vertical
        var rayOri = Vector(2.5, 1.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(ushape, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(2.5, hitPt.x)
        Expect.DOUBLE_EQ(1.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into notch area outside of ushape
        var rayOri = Vector(1.5, 1.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(ushape, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(1.5, hitPt.x)
        Expect.DOUBLE_EQ(1.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }

@register_test(EnergyPlusFixture)
def test_PierceSurfaceTest_NonconvexStar4():
    var star = DataSurfaces.SurfaceData()
    star.Vertex.dimension(8)
    star.Vertex = [Vector(0, 0, 0),
                   Vector(2, 1, 0),
                   Vector(4, 0, 0),
                   Vector(3, 2, 0),
                   Vector(4, 4, 0),
                   Vector(2, 3, 0),
                   Vector(0, 4, 0),
                   Vector(1, 2, 0)] # 4-pointed star resting on 2 vertices
    star.IsConvex = False
    star.set_computed_geometry()
    var star2d = star.surface2d
    Expect.ENUM_EQ(ShapeCat.Nonconvex, star.shapeCat)
    Expect.EQ(2, star2d.axis)
    { # Ray straight down into middle of star
        var rayOri = Vector(2.0, 2.0, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(2.0, hitPt.x)
        Expect.DOUBLE_EQ(2.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down below middle and outside star
        var rayOri = Vector(2.0, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(2.0, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down above middle and outside star
        var rayOri = Vector(2.0, 3.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(2.0, hitPt.x)
        Expect.DOUBLE_EQ(3.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down left of middle and outside star
        var rayOri = Vector(0.5, 2.0, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(2.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down right of middle and outside star
        var rayOri = Vector(3.5, 2.0, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.FALSE(hit)
        Expect.DOUBLE_EQ(3.5, hitPt.x)
        Expect.DOUBLE_EQ(2.0, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into left lower point
        var rayOri = Vector(0.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into right lower point
        var rayOri = Vector(3.5, 0.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(3.5, hitPt.x)
        Expect.DOUBLE_EQ(0.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into left upper point
        var rayOri = Vector(0.5, 3.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(0.5, hitPt.x)
        Expect.DOUBLE_EQ(3.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }
    { # Ray straight down into right upper point
        var rayOri = Vector(3.5, 3.5, 1.0)
        var rayDir = Vector(0.0, 0.0, -1.0)
        var hit = False
        var hitPt = Vector(0.0)
        hit = PierceSurface(star, rayOri, rayDir, hitPt)
        Expect.TRUE(hit)
        Expect.DOUBLE_EQ(3.5, hitPt.x)
        Expect.DOUBLE_EQ(3.5, hitPt.y)
        Expect.DOUBLE_EQ(0.0, hitPt.z)
    }