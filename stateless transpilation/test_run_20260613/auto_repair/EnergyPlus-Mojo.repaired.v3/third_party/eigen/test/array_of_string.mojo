from main import *
from Eigen import Array, Dynamic
from Eigen import std_string as string
from Eigen import std_stringstream as stringstream

def test_array_of_string():
    typedef Array[string, 1, Dynamic] ArrayXs
    var a1 = ArrayXs(3)
    var a2 = ArrayXs(3)
    var a3 = ArrayXs(3)
    var a3ref = ArrayXs(3)
    a1 << "one", "two", "three"
    a2 << "1", "2", "3"
    a3ref << "one (1)", "two (2)", "three (3)"
    var s1 = stringstream()
    s1 << a1
    VERIFY_IS_EQUAL(s1.str(), string("  one    two  three"))
    a3 = a1 + string(" (") + a2 + string(")")
    VERIFY((a3 == a3ref).all())
    a3 = a1
    a3 += string(" (") + a2 + string(")")
    VERIFY((a3 == a3ref).all())
    a1.swap(a3)
    VERIFY((a1 == a3ref).all())
    VERIFY((a3 != a3ref).all())