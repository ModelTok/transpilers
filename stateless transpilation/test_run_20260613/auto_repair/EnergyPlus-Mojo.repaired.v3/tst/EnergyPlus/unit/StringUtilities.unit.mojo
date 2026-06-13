from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.StringUtilities import readItem, readList
from testing import expect

@test
def readItem():
    var i: Int = 0
    expect(readItem("12", i)).is_true()
    expect(i).is_equal(12)
    expect(readItem("1234fgq", i)).is_false()
    expect(readItem("abc123", i)).is_false()
    expect(i).is_equal(0)

@test
def readList():
    var i: Int = 0
    var f: Float32 = 0.0
    var c: String = ""
    var s: String = ""
    expect(readList("1,3.4,a,hello", i, f, c, s)).is_true()
    expect(i).is_equal(1)
    expect(f).is_approx_equal(3.4)
    expect(c).is_equal("a")
    expect(s).is_equal("hello")
    expect(readList("bob q 1.5 10", s, c, f, i)).is_true()
    expect(i).is_equal(10)
    expect(f).is_approx_equal(1.5)
    expect(c).is_equal("q")
    expect(s).is_equal("bob")
    expect(readList("bob;q;1.5;10", s, c, f, i)).is_false()
    expect(readList("1;3.4,a,hello", i, f, c, s)).is_false()
    expect(readList("a,hello", i, f, c, s)).is_false()