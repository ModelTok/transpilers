from testing import expect_equal
from ObjexxFCL.DimensionSlice import DimensionSlice
from ObjexxFCL.IndexRange import IndexRange
from ObjexxFCL.IndexSlice import IndexSlice
from ObjexxFCL.unit import *

def test_ConstructionIndexSlice():
    var s = IndexSlice(-3, 3, 2)
    var d = DimensionSlice(s)
    expect_equal(s.s(), d.m())
    expect_equal(2, d.m())
    expect_equal(s.l() - s.s(), d.k())
    expect_equal(-5, d.k())
    expect_equal(int(s.size()), d.u())
    expect_equal(4, d.u())

def test_ConstructionIndexSliceMultiplier():
    var s = IndexSlice(-3, 3, 2)
    var d = DimensionSlice(s, 3)
    expect_equal(s.s() * 3, d.m())
    expect_equal(6, d.m())
    expect_equal((s.l() - s.s()) * 3, d.k())
    expect_equal(-15, d.k())
    expect_equal(int(s.size()), d.u())
    expect_equal(4, d.u())
    var dc = DimensionSlice(d)  # Copy construction
    expect_equal(6, dc.m())
    expect_equal(-15, dc.k())
    expect_equal(4, dc.u())
    expect_equal(d.m(), dc.m())
    expect_equal(d.k(), dc.k())
    expect_equal(d.u(), dc.u())

def test_ConstructionIndexRangeSliceMultiplier():
    var r = IndexRange(-5, 5)
    var s = IndexSlice(-3, 3, 2)
    var d = DimensionSlice(r, s, 3)
    expect_equal(s.s() * 3, d.m())
    expect_equal(6, d.m())
    expect_equal((s.l() - s.s()) * 3, d.k())
    expect_equal(-15, d.k())
    expect_equal(int(s.size()), d.u())
    expect_equal(4, d.u())

def test_ConstructionIndexRangeSliceOmitMultiplier():
    var r = IndexRange(-5, 3)
    var s = IndexSlice(-3, _, 2)
    var d = DimensionSlice(r, s, 3)
    expect_equal(s.s() * 3, d.m())
    expect_equal(6, d.m())
    expect_equal((s.l() - s.s()) * 3, d.k())
    expect_equal(-15, d.k())
    expect_equal(4, d.u())