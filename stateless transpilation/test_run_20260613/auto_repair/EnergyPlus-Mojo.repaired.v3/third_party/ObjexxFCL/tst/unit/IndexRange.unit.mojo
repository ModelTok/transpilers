from gtest import Test, EXPECT_EQ
from ObjexxFCL.IndexRange import IndexRange
from ObjexxFCL.unit import *

@value
struct IndexRangeTest:
    def ConstructionConstantRange():
        var r = IndexRange(-3, 3)
        EXPECT_EQ(IndexRange(-3, 3), r)
        EXPECT_EQ(-3, r.l())
        EXPECT_EQ(3, r.u())
        EXPECT_EQ(7, r.size())

    def ConstructionCopy():
        var r = IndexRange(-3, 3)
        var s = IndexRange(r)
        EXPECT_EQ(r, s)

    def Assignment():
        var r = IndexRange(-3, 3)
        var s = IndexRange()
        s = r
        EXPECT_EQ(r, s)

    def Lifetime():
        var rp = IndexRange(-3, 5)
        var r = rp
        EXPECT_EQ(IndexRange(-3, 5), r)

    def Swap():
        let l: Int = -3
        let u: Int = 9
        var r = IndexRange(2*l, u)
        var s = IndexRange(l, u+3)
        EXPECT_EQ(-6, r.l())
        EXPECT_EQ(9, r.u())
        EXPECT_EQ(-3, s.l())
        EXPECT_EQ(12, s.u())
        r.swap(s)
        EXPECT_EQ(-6, s.l())
        EXPECT_EQ(9, s.u())
        EXPECT_EQ(-3, r.l())
        EXPECT_EQ(12, r.u())
        swap(s, r)
        EXPECT_EQ(-6, r.l())
        EXPECT_EQ(9, r.u())
        EXPECT_EQ(-3, s.l())
        EXPECT_EQ(12, s.u())