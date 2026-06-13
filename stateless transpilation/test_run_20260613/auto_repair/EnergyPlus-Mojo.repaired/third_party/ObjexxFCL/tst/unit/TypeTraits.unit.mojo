from testing import *
from ObjexxFCL.TypeTraits import *
from ObjexxFCL.unit import *

class B:
    def __del__(owned self):

class D(B):
    def __del__(owned self):

def test_TypeTests():
    var d = D()
    var b = B()
    var b2 = B()
    assert_true(same_type_as(b, b))
    assert_true(same_type_as(b, b2))
    assert_true(same_type_as(b2, b))
    assert_false(same_type_as(b, d))
    assert_false(same_type_as(d, b))
    assert_true(is_a[B](d))
    assert_true(is_a[D](d))
    assert_true(is_a[B](b))
    assert_false(is_a[D](b))