from memory import *
from gtest import *
from WCECommon import *

class MMapTest(Test):
    def SetUp(self):

@fixture
def MMapTest_TestDouble():
    SCOPED_TRACE("Begin Test: Multimap with doubles.")
    @value
    enum a:
        a1
        a2
        a3
    @value
    enum b:
        b1
        b2
        b3
    var aMap = mmap[Float64, a, b]()
    aMap(a.a1, b.b1) = 1
    aMap(a.a2, b.b2) = 2
    EXPECT_EQ(1, aMap.at(a.a1, b.b1))
    EXPECT_EQ(2, aMap.at(a.a2, b.b2))

@fixture
def MMapTest_TestString():
    SCOPED_TRACE("Begin Test: Multimap with strings.")
    @value
    enum A:
        a1
        a2
        a3
    @value
    enum B:
        b1
        b2
        b3
    var aMap = mmap[String, A, B]()
    aMap(A.a1, B.b1) = "Value1"
    aMap(A.a2, B.b2) = "Value2"
    EXPECT_EQ("Value1", aMap.at(A.a1, B.b1))
    EXPECT_EQ("Value2", aMap.at(A.a2, B.b2))