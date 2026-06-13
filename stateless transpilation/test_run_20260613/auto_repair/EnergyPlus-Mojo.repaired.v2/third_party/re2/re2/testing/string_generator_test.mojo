from util.test.mojo import *
from util.utf.mojo import *
from re2.testing.string_generator.mojo import *
from re2.testing.regexp_generator.mojo import *

def IntegerPower(i: Int, e: Int) -> Int64:
    var p: Int64 = 1
    while e > 0:
        p *= i
        e -= 1
    return p

def RunTest(len: Int, alphabet: String, donull: Bool):
    var g = StringGenerator(len, Explode(alphabet))
    var n: Int = 0
    var last_l: Int = -1
    var last_s: String = ""
    if donull:
        g.GenerateNULL()
        EXPECT_TRUE(g.HasNext())
        var sp = g.Next()
        EXPECT_EQ(sp.data(), None)
        EXPECT_EQ(sp.size(), 0)
    while g.HasNext():
        var s = String(g.Next())
        n += 1
        var p: Pointer[UInt8] = s.c_str()
        while p[0] != 0:
            var r: Rune
            var bytes = chartorune(Pointer[Rune].address_of(r), p)
            p += bytes
            EXPECT_TRUE(utfrune(alphabet.c_str(), r) != None)
        var l = utflen(s.c_str())
        EXPECT_LE(l, len)
        if last_l < l:
            last_l = l
        else:
            EXPECT_EQ(last_l, l)
            EXPECT_LT(last_s, s)
        last_s = s
    var m: Int64 = 0
    var alpha = utflen(alphabet.c_str())
    if alpha == 0:
        len = 0
    for i in range(0, len + 1):
        m += IntegerPower(alpha, i)
    EXPECT_EQ(n, m)

def StringGenerator_NoLength():
    RunTest(0, "abc", False)

def StringGenerator_NoLengthNoAlphabet():
    RunTest(0, "", False)

def StringGenerator_NoAlphabet():
    RunTest(5, "", False)

def StringGenerator_Simple():
    RunTest(3, "abc", False)

def StringGenerator_UTF8():
    RunTest(4, "abc\xE2\x98\xBA", False)

def StringGenerator_GenNULL():
    RunTest(0, "abc", True)
    RunTest(0, "", True)
    RunTest(5, "", True)
    RunTest(3, "abc", True)
    RunTest(4, "abc\xE2\x98\xBA", True)