from gtest import *
from EnergyPlus.EPVector import EPVector
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

@parameter
def EPVectorTest_Basic[EnergyPlusFixture]():
    var v = EPVector[Int]()
    v.allocate(4)
    assert_true(v.allocated())
    v[0] = 1
    v[1] = 2
    v[2] = 3
    v[3] = 4
    assert_equal(1, v(1))
    assert_equal(2, v(2))
    assert_equal(3, v(3))
    assert_equal(4, v(4))
    #if not NDEBUG:
    #    assert_throws(v[4] = 5, out_of_range)
    #    assert_throws(v(5) = 5, out_of_range)
    #endif // !NDEBUG
    v.resize(2)
    assert_equal(2, v.size())
    assert_equal(1, v(1))
    assert_equal(2, v(2))
    v.resize(4)
    assert_equal(1, v(1))
    assert_equal(2, v(2))
    assert_equal(0, v(3))
    assert_equal(0, v(4))
    v.clear()
    assert_false(v.allocated())
    assert_true(v.empty())
    v.resize(4)
    assert_equal(0, v(1))
    assert_equal(0, v(2))
    assert_equal(0, v(3))
    assert_equal(0, v(4))
    v.clear()
    v.resize(4, true)
    assert_equal(1, v(1))
    assert_equal(1, v(2))
    assert_equal(1, v(3))
    assert_equal(1, v(4))
    v.deallocate()
    assert_false(v.allocated())
    assert_true(v.empty())
    v.resize(3, 2)
    assert_equal(2, v(1))
    assert_equal(2, v(2))
    assert_equal(2, v(3))
    assert_true(v.allocated())

@parameter
def EPVectorTest_Bools[EnergyPlusFixture]():
    var v = EPVector[Bool]()
    v.allocate(4)
    assert_true(v.allocated())
    v[0] = true
    v[1] = false
    v[2] = false
    v[3] = true
    assert_true(v(1))
    assert_false(v(2))
    assert_false(v(3))
    assert_true(v(4))
    #if not NDEBUG:
    #    assert_throws(v[4] = true, out_of_range)
    #    assert_throws(v(5) = false, out_of_range)
    #endif // !NDEBUG
    v.resize(2)
    assert_equal(2, v.size())
    assert_true(v(1))
    assert_false(v(2))
    v.resize(4)
    assert_true(v(1))
    assert_false(v(2))
    assert_false(v(3))
    assert_false(v(4))
    v.clear()
    assert_false(v.allocated())
    assert_true(v.empty())
    v.resize(4)
    assert_false(v(1))
    assert_false(v(2))
    assert_false(v(3))
    assert_false(v(4))
    v.clear()
    v.resize(4, true)
    assert_true(v(1))
    assert_true(v(2))
    assert_true(v(3))
    assert_true(v(4))
    v.deallocate()
    assert_false(v.allocated())
    assert_true(v.empty())
    v.resize(3, true)
    assert_true(v(1))
    assert_true(v(2))
    assert_true(v(3))
    assert_true(v.allocated())