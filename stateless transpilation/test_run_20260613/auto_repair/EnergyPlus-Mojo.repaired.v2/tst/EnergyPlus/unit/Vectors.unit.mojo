from gtest import Test, EXPECT_EQ, EXPECT_DOUBLE_EQ
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Vectors import Vector, AreaPolygon, VecNormalize, VecRound, PointsInPlane
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from math import sqrt
from memory import Array1D
from utils import Real64

@register_passable("trivial")
struct VectorsTest_AreaPolygon(Test[EnergyPlusFixture]):
    def __call__(self):
        var a = Array1D[Vector](4) # 3 x 7 rectangle
        a[0].x = a[0].y = a[0].z = 0.0
        a[1].x = 3.0
        a[1].y = a[1].z = 0.0
        a[2].x = 3.0
        a[2].y = 7.0
        a[2].z = 0.0
        a[3].x = 0.0
        a[3].y = 7.0
        a[3].z = 0.0
        EXPECT_EQ(21.0, AreaPolygon(4, a))

@register_passable("trivial")
struct VectorsTest_VecNormalize(Test[EnergyPlusFixture]):
    def __call__(self):
        {
            var v = Vector(3.0, 3.0, 3.0)
            var n = VecNormalize(v)
            var h: Real64 = 3.0 / sqrt(27.0)
            EXPECT_DOUBLE_EQ(h, n.x)
            EXPECT_DOUBLE_EQ(h, n.y)
            EXPECT_DOUBLE_EQ(h, n.z)
        }
        {
            var v = Vector(1.0, 3.0, 5.0)
            var n = VecNormalize(v)
            var f: Real64 = 1.0 / sqrt(35.0)
            EXPECT_DOUBLE_EQ(f * v.x, n.x)
            EXPECT_DOUBLE_EQ(f * v.y, n.y)
            EXPECT_DOUBLE_EQ(f * v.z, n.z)
        }

@register_passable("trivial")
struct VectorsTest_VecRound(Test[EnergyPlusFixture]):
    def __call__(self):
        var v = Vector(11.567, -33.602, 55.981)
        VecRound(v, 2.0)
        EXPECT_DOUBLE_EQ(11.5, v.x)
        EXPECT_DOUBLE_EQ(-33.5, v.y)
        EXPECT_DOUBLE_EQ(56.0, v.z)

@register_passable("trivial")
struct VectorsTest_CoplnarPoints(Test[EnergyPlusFixture]):
    def __call__(self):
        {
            var base = Array1D[Vector](4)
            base[0] = Vector(0, 0, 0)
            base[1] = Vector(1, 0, 0)
            base[2] = Vector(1, 1, 0)
            base[3] = Vector(0, 1, 0)
            var coplanarPoints = List[Int]()
            var ErrorsFound: Bool
            var query = Array1D[Vector](4)
            query[0] = Vector(0, 0, 0)
            query[1] = Vector(1, 1, 1)
            query[2] = Vector(2, 0, 0)
            query[3] = Vector(0, 0, -1)
            coplanarPoints = PointsInPlane(base, base.size, query, query.size, ErrorsFound)
            EXPECT_EQ(coplanarPoints[0], 1)      # 1st point in query is coplanar with base
            EXPECT_EQ(coplanarPoints[1], 3)      # 3rd point in query is coplanar with base
            EXPECT_EQ(coplanarPoints.size, 2)    # Only 2 points in query are coplanar with base
        }