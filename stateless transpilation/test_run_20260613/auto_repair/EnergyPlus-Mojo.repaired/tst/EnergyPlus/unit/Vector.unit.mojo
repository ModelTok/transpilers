from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.DataVectorTypes import Vector, magnitude, magnitude_squared, distance, distance_squared, dot, cross
from EnergyPlus.UtilityRoutines import ShowMessage

def Test_Basic():
    ShowMessage(*state, "Begin Test: VectorTest, Basic")
    # {
        var v = Vector(0.0, 0.0, 0.0)
        assert equal(0.0, v.x)
        assert equal(0.0, v.y)
        assert equal(0.0, v.z)
        assert equal(0.0, v.length())
        assert equal(0.0, v.length_squared())
        assert equal(0.0, magnitude(v))
        assert equal(0.0, magnitude_squared(v))
        v *= 22.0
        assert equal(0.0, v.x)
        assert equal(0.0, v.y)
        assert equal(0.0, v.z)
        assert equal(0.0, v.length())
        assert equal(0.0, v.length_squared())
        assert equal(0.0, magnitude(v))
        assert equal(0.0, magnitude_squared(v))
        v += 2.0
        assert equal(2.0, v.x)
        assert equal(2.0, v.y)
        assert equal(2.0, v.z)
        assert equal(12.0, v.length_squared())
        assert equal(12.0, magnitude_squared(v))
        v /= 2.0
        assert equal(1.0, v.x)
        assert equal(1.0, v.y)
        assert equal(1.0, v.z)
        assert equal(3.0, v.length_squared())
        assert equal(3.0, magnitude_squared(v))
        v -= 1.0
        assert equal(0.0, v.x)
        assert equal(0.0, v.y)
        assert equal(0.0, v.z)
        assert equal(0.0, v.length())
        assert equal(0.0, v.length_squared())
        assert equal(0.0, magnitude(v))
        assert equal(0.0, magnitude_squared(v))
        var u = Vector(v)
        assert equal(u.x, v.x)
        assert equal(u.y, v.y)
        assert equal(u.z, v.z)
    # }
    # {
        var v = Vector(3.0)
        assert equal(3.0, v.x)
        assert equal(3.0, v.y)
        assert equal(3.0, v.z)
        assert equal(27.0, v.length_squared())
        assert equal(27.0, magnitude_squared(v))
        var u = Vector(v * 2.0)
        assert equal(6.0, u.x)
        assert equal(6.0, u.y)
        assert equal(6.0, u.z)
        var w = Vector(-u)
        assert equal(-6.0, w.x)
        assert equal(-6.0, w.y)
        assert equal(-6.0, w.z)
    # }
    # {
        var v = Vector(1.0, 2.0, 3.0)
        assert equal(1.0, v.x)
        assert equal(2.0, v.y)
        assert equal(3.0, v.z)
        assert equal(14.0, v.length_squared())
        assert equal(14.0, magnitude_squared(v))
        var u = Vector(1.0, 2.0, 3.0)
        assert equal(0.0, distance(u, v))
        assert equal(0.0, distance_squared(u, v))
        assert equal(14.0, dot(u, v))
        var x = Vector(cross(u, v))
        assert equal(0.0, x.x)
        assert equal(0.0, x.y)
        assert equal(0.0, x.z)
    # }
    # {
        var v = Vector(1.0, 2.0, 3.0)
        assert equal(1.0, v.x)
        assert equal(2.0, v.y)
        assert equal(3.0, v.z)
        assert equal(14.0, v.length_squared())
        assert equal(14.0, magnitude_squared(v))
        var u = Vector(2.0)
        assert equal(2.0, distance_squared(u, v))
        assert equal(12.0, dot(u, v))
        var x = Vector(cross(u, v))
        assert equal(2.0, x.x)
        assert equal(-4.0, x.y)
        assert equal(2.0, x.z)
    # }

# Note: Original C++ used TEST_F(EnergyPlusFixture, VectorTest_Basic)
# We use a plain function because test framework differences are not part of 1:1 mapping.