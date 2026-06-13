from testing import *
from ObjexxFCL.Index import Index
from ObjexxFCL.ObjexxFCL.unit import *
from ObjexxFCL.gtest import *

def Test_IndexTest_ConstructionConstantRange():
    var r = Index(3)
    assert_equal(Index(3), r)
    assert_not_equal(Index(2), r)
    assert_not_equal(Index(_), r)
    assert_equal(3, r.i())
    assert_equal(3, int(r))  # Conversion operator
    assert_equal(3, r)  # Conversion operator

def Test_IndexTest_ConstructionCopy():
    var r = Index(-3)
    var s = Index(r)
    assert_equal(r, s)

def Test_IndexTest_ConstructionOmit():
    var r = Index(_)
    assert_equal(Index(_), r)
    assert_false(r.initialized())

def Test_IndexTest_Assignment():
    var r = Index(-3)
    var s = Index()
    s = r
    assert_equal(r, s)

def Test_IndexTest_Swap():
    var l = -3
    var r = Index(2 * l)
    var q = Index(l)
    assert_equal(-6, r.i())
    assert_equal(-3, q.i())
    r.swap(q)
    assert_equal(-6, q.i())
    assert_equal(-3, r.i())
    swap(q, r)
    assert_equal(-6, r.i())
    assert_equal(-3, q.i())