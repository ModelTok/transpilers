from testing import *
from ObjexxFCL.floops import floops
from ObjexxFCL.unit import *
from memory import sizeof

@value
struct floopsTest:

def test_floops1():
	var i: Int
	var b: Int = -3
	var e: Int = 3
	var s: Int = 2
	expect_equal[Int](4, floops(i, b, e, s))
	expect_equal[Int](b, i)

def test_floops2():
	var i: Int
	var b: Int = -3
	var e: Int = 3
	var s: Int = -2
	expect_equal[Int](0, floops(i, b, e, s))
	expect_equal[Int](b, i)

def test_floops3():
	var i: Int
	var b: Int = -3
	var e: Int = 3
	expect_equal[Int](7, floops(i, b, e))
	expect_equal[Int](b, i)

def test_floops4():
	var i: Int
	var b: Int = 3
	var e: Int = -3
	var s: Int = -2
	expect_equal[Int](4, floops(i, b, e, s))
	expect_equal[Int](b, i)

def test_floops5():
	var i: Float64
	var b: Float64 = 2.5
	var e: Float64 = -2.5
	var s: Float64 = -1.0
	expect_equal[Int](6, floops(i, b, e, s))
	expect_equal[Float64](b, i)