from ObjexxFCL.Optional import Optional_int_const, Optional_int, Optional_string_const, Optional_string, _
from ObjexxFCL.string.functions import *
from ObjexxFCL.unit import *

def OptionalTest_ConstructionDefault():
    var o = Optional_int_const()
    assert(Optional_int_const() == o)
    assert(Optional_int_const(2) != o)
    assert(Optional_int_const(_) == o)
    assert(not o.present())

def OptionalTest_ConstructionOmit():
    var o = Optional_int_const(_)
    assert(Optional_int_const() == o)
    assert(Optional_int_const(2) != o)
    assert(Optional_int_const(_) == o)
    assert(not o.present())

def OptionalTest_ConstructionValue():
    var o = Optional_int_const(33)
    assert(33 == o())
    assert(33 == Int(o))  # Conversion operator
    assert(33 == o)  # Conversion operator

def OptionalTest_ConstructionExpression():
    var o = Optional_int_const(33 * 2)
    assert(66 == o())
    assert(66 == Int(o))  # Conversion operator
    assert(66 == o)  # Conversion operator

def OptionalTest_ConstructionCopy():
    var o = Optional_int(33)
    var c = Optional_int(o)
    assert(33 == c())
    assert(33 == Int(c))  # Conversion operator
    assert(33 == c)  # Conversion operator

def OptionalTest_ConstructionCopyConst():
    var o = Optional_int_const(33)
    var c = Optional_int_const(o)
    assert(33 == c())
    assert(33 == Int(c))  # Conversion operator
    assert(33 == c)  # Conversion operator

def OptionalTest_AssignmentValue():
    var i = -3
    var o = Optional_int(i)
    o = 42
    assert(42 == o)
    assert(42 == i)

def OptionalTest_AssignmentOmit():
    var i = -3
    var o = Optional_int(i)
    o = _
    assert(Optional_int(_) == o)
    assert(not o.present())
    assert(-3 != o)

def OptionalTest_StringFromLiteral():
    var o = Optional_string_const("A literal string")
    assert(String("A literal string") == o)
    assert("A literal string" == o())  # Need the () on o() when types don't match exactly
    assert(o.present())
    assert(String("Some other string") != o)

def OptionalTest_StringAssignment():
    var s = String("A literal string")
    var o = Optional_string(s)
    assert(String("A literal string") == o)
    assert("A literal string" == o())  # Need the () on o() when types don't match exactly
    assert(o.present())
    assert(String("Some other string") != o)
    o = "New string"
    assert("New string" == o())  # Need the () on o() when types don't match exactly
    assert("New string" == s)

def OptionalTest_StringConversion():
    var s = String("Dog")
    var o = Optional_string_const(s)
    assert(String("Dog Run") == o + " Run")
    assert(String("Fast Dog") == "Fast " + o)

def OptionalTest_ConstReference():
    var i = 42
    var j = i  # borrowed reference (const)
    var o = Optional_int_const(j)
    assert(42 == o())
    i = 56
    assert(56 == o())

def OptionalTest_ConstOptionalFromNonPresentNonConstOptional():
    var o = Optional_int()  # Not "present"
    var c = Optional_int_const(o)
    assert(not c.present())

def OptionalTest_ConstOptionalFromConst():
    var i = 42
    var c = Optional_int_const(i)
    assert(42 == c())
    i = 56
    assert(56 == c())  # Proves that c is not holding a local copy
    assert(not c.own())  # So does this

def OptionalTest_ConstOptionalFromConstRef():
    var i = 42
    var r = i  # const reference
    var c = Optional_int_const(r)
    assert(42 == c())
    i = 56
    assert(56 == c())  # Proves that c is not holding a local copy
    assert(not c.own())  # So does this

def OptionalTest_ConstOptionalFromNonConstOptional():
    var i = 42
    var o = Optional_int(i)
    var c = Optional_int_const(o)
    assert(42 == c())
    i = 56
    assert(56 == c())  # Proves that c is not holding a local copy
    assert(not c.own())  # So does this
    o = 123
    assert(123 == c())