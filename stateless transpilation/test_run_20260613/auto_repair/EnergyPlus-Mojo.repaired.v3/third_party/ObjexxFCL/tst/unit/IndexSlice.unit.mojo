from testing import *
from ObjexxFCL.IndexSlice import IndexSlice
from ObjexxFCL.Index import Index
from ObjexxFCL.unit import *

def test_ConstructionConstantRange():
    var r = IndexSlice(-3, 3, 2)
    assert_equal(IndexSlice(-3, 3, 2), r)
    assert_not_equal(IndexSlice(-3, 3, 1), r)
    assert_equal(-3, r.l())
    assert_equal(3, r.u())
    assert_equal(2, r.s())
    assert_equal(4, r.size())
    assert_equal(3, r.last())

def test_ConstructionCopy():
    var r = IndexSlice(-3, 3)
    var s = IndexSlice(r)
    assert_equal(r, s)
    assert_equal(3, r.last())

def test_ConstructionList():
    var r = IndexSlice{-5, 5, 2}
    assert_equal(IndexSlice(-5, 5, 2), r)
    assert_equal(5, r.last())

def test_ConstructionOmit():
    var r = IndexSlice(-3, _, 3)
    assert_equal(IndexSlice(-3, _, 3), r)
    assert_equal(-3, r.l())
    assert_true(not r.u_initialized())
    assert_equal(0, r.size())

def test_Assignment():
    var r = IndexSlice(-3, 3)
    var s = IndexSlice()
    s = r
    assert_equal(r, s)

def test_Lifetime():
    var rp = IndexSlice(-3, 5)
    var r = rp
    assert_equal(IndexSlice(-3, 5), r)

def test_Swap():
    var l = -3
    var u = 9
    var s = 3
    var r = IndexSlice(2*l, u, s)
    var q = IndexSlice(l, u+3, s+1)
    assert_equal(-6, r.l())
    assert_equal(9, r.u())
    assert_equal(3, r.s())
    assert_equal(9, r.last())
    assert_equal(-3, q.l())
    assert_equal(12, q.u())
    assert_equal(4, q.s())
    assert_equal(9, q.last())
    r.swap(q)
    assert_equal(-6, q.l())
    assert_equal(9, q.u())
    assert_equal(3, q.s())
    assert_equal(-3, r.l())
    assert_equal(12, r.u())
    assert_equal(4, r.s())
    swap(q, r)
    assert_equal(-6, r.l())
    assert_equal(9, r.u())
    assert_equal(3, r.s())
    assert_equal(-3, q.l())
    assert_equal(12, q.u())
    assert_equal(4, q.s())

def test_InitializerListConstructionDefault():
    var s = IndexSlice{}
    assert_false(s.l_initialized())
    assert_false(s.u_initialized())
    assert_equal(1, s.s())
    assert_equal(0, s.size())

def test_InitializerListConstructionInt1():
    var s = IndexSlice{9}
    assert_true(s.l_initialized())
    assert_false(s.u_initialized())
    assert_equal(9, s.l())
    assert_equal(1, s.s())
    assert_equal(0, s.size())

def test_InitializerListConstructionInt2():
    var s = IndexSlice{9, 19}
    assert_true(s.l_initialized())
    assert_true(s.u_initialized())
    assert_equal(9, s.l())
    assert_equal(19, s.u())
    assert_equal(1, s.s())
    assert_equal(11, s.size())

def test_InitializerListConstructionIndex2():
    var s = IndexSlice{9, _}
    assert_true(s.l_initialized())
    assert_false(s.u_initialized())
    assert_equal(9, s.l())
    assert_equal(1, s.s())
    assert_equal(0, s.size())

def test_InitializerListConstructionIndexExplicit2():
    var s = IndexSlice{Index(9), _}
    assert_true(s.l_initialized())
    assert_false(s.u_initialized())
    assert_equal(9, s.l())
    assert_equal(1, s.s())
    assert_equal(0, s.size())

def test_SliceInitializerList():
    var r = IndexSlice(-3, 3)
    var s = IndexSlice(33)
    assert_equal(33, s.l())
    assert_equal(33, s.u())
    assert_equal(1, s.s())
    assert_equal(1, s.size())
    assert_true(s.scalar())
    var l = List[IndexSlice](r, 33)
    assert_equal(2, len(l))
    var i = l.begin()
    assert_equal(r, i[])
    i = i.__iadd__(1)
    assert_equal(s, i[])