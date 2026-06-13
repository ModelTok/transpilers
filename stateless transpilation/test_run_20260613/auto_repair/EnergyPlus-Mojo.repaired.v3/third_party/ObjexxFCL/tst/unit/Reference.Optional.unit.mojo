from testing import assert_equal
from ......ObjexxFCL.Reference import Reference_int, Reference_int_const
from ......ObjexxFCL.Optional import Optional_int, Optional_int_const

@value
struct ReferenceOptionalTest:
    @staticmethod
    def ConstReferenceConstOptional() raises:
        var i: Int = 42
        let j: &Int = i
        var o: Optional_int_const = Optional_int_const(j)
        var r: Reference_int_const = Reference_int_const(o)
        assert_equal(42, o())
        assert_equal(42, r())
        i = 56
        assert_equal(56, o())
        assert_equal(56, r())

    @staticmethod
    def ConstReferenceConstOptionalValue() raises:
        var i: Int = 42
        let j: &Int = i
        var o: Optional_int_const = Optional_int_const(j)
        var r: Reference_int_const = Reference_int_const(o())
        assert_equal(42, o())
        assert_equal(42, r())
        i = 56
        assert_equal(56, o())
        assert_equal(56, r())

    @staticmethod
    def ReferenceConstOptional() raises:
        var i: Int = 42
        let j: &Int = i
        var o: Optional_int_const = Optional_int_const(j)
        var r: Reference_int = Reference_int(o)
        assert_equal(42, o())
        assert_equal(42, r())
        i = 56
        assert_equal(56, o())
        assert_equal(56, r())

    @staticmethod
    def ReferenceConstOptionalValue() raises:
        var i: Int = 42
        let j: &Int = i
        var o: Optional_int_const = Optional_int_const(j)
        var r: Reference_int = Reference_int(o())
        assert_equal(42, o())
        assert_equal(42, r())
        i = 56
        assert_equal(56, o())
        assert_equal(56, r())

    @staticmethod
    def ReferenceAttachConstOptional() raises:
        var i: Int = 42
        var o: Optional_int_const = Optional_int_const(i)
        var r: Reference_int
        r >>= o
        assert_equal(42, o())
        assert_equal(42, r())
        i = 56
        assert_equal(56, o())
        assert_equal(56, r())

def main() raises:
    ReferenceOptionalTest.ConstReferenceConstOptional()
    ReferenceOptionalTest.ConstReferenceConstOptionalValue()
    ReferenceOptionalTest.ReferenceConstOptional()
    ReferenceOptionalTest.ReferenceConstOptionalValue()
    ReferenceOptionalTest.ReferenceAttachConstOptional()