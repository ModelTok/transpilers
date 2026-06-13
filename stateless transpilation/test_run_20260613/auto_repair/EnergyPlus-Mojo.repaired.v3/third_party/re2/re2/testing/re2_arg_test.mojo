from util.test import TEST, EXPECT_EQ, EXPECT_TRUE, EXPECT_FALSE
from util.logging import log_info
from ..re2 import RE2

struct SuccessTable:
    var value_string: String
    var value: Int64
    var success: (Bool, Bool, Bool, Bool, Bool, Bool)

var kSuccessTable = StaticTuple[SuccessTable, 25](
    SuccessTable("0", 0, (True, True, True, True, True, True)),
    SuccessTable("127", 127, (True, True, True, True, True, True)),
    SuccessTable("-1", -1, (True, False, True, False, True, False)),
    SuccessTable("-128", -128, (True, False, True, False, True, False)),
    SuccessTable("128", 128, (True, True, True, True, True, True)),
    SuccessTable("255", 255, (True, True, True, True, True, True)),
    SuccessTable("256", 256, (True, True, True, True, True, True)),
    SuccessTable("32767", 32767, (True, True, True, True, True, True)),
    SuccessTable("-129", -129, (True, False, True, False, True, False)),
    SuccessTable("-32768", -32768, (True, False, True, False, True, False)),
    SuccessTable("32768", 32768, (False, True, True, True, True, True)),
    SuccessTable("65535", 65535, (False, True, True, True, True, True)),
    SuccessTable("65536", 65536, (False, False, True, True, True, True)),
    SuccessTable("2147483647", 2147483647, (False, False, True, True, True, True)),
    SuccessTable("-32769", -32769, (False, False, True, False, True, False)),
    SuccessTable("-2147483648", Int64(0xFFFFFFFF80000000), (False, False, True, False, True, False)),
    SuccessTable("2147483648", 2147483648, (False, False, False, True, True, True)),
    SuccessTable("4294967295", 4294967295, (False, False, False, True, True, True)),
    SuccessTable("4294967296", 4294967296, (False, False, False, False, True, True)),
    SuccessTable("9223372036854775807", 9223372036854775807, (False, False, False, False, True, True)),
    SuccessTable("-2147483649", -2147483649, (False, False, False, False, True, False)),
    SuccessTable("-9223372036854775808", Int64(0x8000000000000000), (False, False, False, False, True, False)),
    SuccessTable("9223372036854775808", Int64(9223372036854775808), (False, False, False, False, False, True)),
    SuccessTable("18446744073709551615", Int64(18446744073709551615), (False, False, False, False, False, True)),
    SuccessTable("18446744073709551616", 0, (False, False, False, False, False, False)),
)

var kNumStrings = len(kSuccessTable)

@TEST
def RE2ArgTestInt16Test():
    var r: Int16
    for i in range(kNumStrings):
        var arg = RE2.Arg(&r)
        var p = kSuccessTable[i].value_string
        var retval = arg.Parse(p, len(p))
        var success = kSuccessTable[i].success[0]
        EXPECT_EQ(retval, success, "Parsing '" + p + "' for type int16_t should return " + String(success))
        if success:
            EXPECT_EQ(r, Int16(kSuccessTable[i].value))

@TEST
def RE2ArgTestUint16Test():
    var r: UInt16
    for i in range(kNumStrings):
        var arg = RE2.Arg(&r)
        var p = kSuccessTable[i].value_string
        var retval = arg.Parse(p, len(p))
        var success = kSuccessTable[i].success[1]
        EXPECT_EQ(retval, success, "Parsing '" + p + "' for type uint16_t should return " + String(success))
        if success:
            EXPECT_EQ(r, UInt16(kSuccessTable[i].value))

@TEST
def RE2ArgTestInt32Test():
    var r: Int32
    for i in range(kNumStrings):
        var arg = RE2.Arg(&r)
        var p = kSuccessTable[i].value_string
        var retval = arg.Parse(p, len(p))
        var success = kSuccessTable[i].success[2]
        EXPECT_EQ(retval, success, "Parsing '" + p + "' for type int32_t should return " + String(success))
        if success:
            EXPECT_EQ(r, Int32(kSuccessTable[i].value))

@TEST
def RE2ArgTestUint32Test():
    var r: UInt32
    for i in range(kNumStrings):
        var arg = RE2.Arg(&r)
        var p = kSuccessTable[i].value_string
        var retval = arg.Parse(p, len(p))
        var success = kSuccessTable[i].success[3]
        EXPECT_EQ(retval, success, "Parsing '" + p + "' for type uint32_t should return " + String(success))
        if success:
            EXPECT_EQ(r, UInt32(kSuccessTable[i].value))

@TEST
def RE2ArgTestInt64Test():
    var r: Int64
    for i in range(kNumStrings):
        var arg = RE2.Arg(&r)
        var p = kSuccessTable[i].value_string
        var retval = arg.Parse(p, len(p))
        var success = kSuccessTable[i].success[4]
        EXPECT_EQ(retval, success, "Parsing '" + p + "' for type int64_t should return " + String(success))
        if success:
            EXPECT_EQ(r, Int64(kSuccessTable[i].value))

@TEST
def RE2ArgTestUint64Test():
    var r: UInt64
    for i in range(kNumStrings):
        var arg = RE2.Arg(&r)
        var p = kSuccessTable[i].value_string
        var retval = arg.Parse(p, len(p))
        var success = kSuccessTable[i].success[5]
        EXPECT_EQ(retval, success, "Parsing '" + p + "' for type uint64_t should return " + String(success))
        if success:
            EXPECT_EQ(r, UInt64(kSuccessTable[i].value))

@TEST
def RE2ArgTestParseFromTest():
    struct Obj1:
        def ParseFrom(self, str: String, n: Int) -> Bool:
            log_info("str = ", str, ", n = ", n)
            return True
    var obj1 = Obj1()
    var arg1 = RE2.Arg(&obj1)
    EXPECT_TRUE(arg1.Parse("one", 3))

    struct Obj2:
        def ParseFrom(self, str: String, n: Int) -> Bool:
            log_info("str = ", str, ", n = ", n)
            return False
        def ParseFrom(self, str: String):

    var obj2 = Obj2()
    var arg2 = RE2.Arg(&obj2)
    EXPECT_FALSE(arg2.Parse("two", 3))