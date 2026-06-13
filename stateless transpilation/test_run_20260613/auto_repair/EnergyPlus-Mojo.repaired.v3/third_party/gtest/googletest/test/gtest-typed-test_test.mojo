// Header content from gtest-typed-test_test.h
from gtest import Test
from gtest import TYPED_TEST_SUITE_P, TYPED_TEST_P, REGISTER_TYPED_TEST_SUITE_P

@value
class ContainerTest[T](Test):

TYPED_TEST_SUITE_P(ContainerTest)

TYPED_TEST_P(ContainerTest, CanBeDefaultConstructed) {
    var container: TypeParam
}

TYPED_TEST_P(ContainerTest, InitialSizeIsZero) {
    var container: TypeParam
    EXPECT_EQ(0U, container.size())
}

REGISTER_TYPED_TEST_SUITE_P(ContainerTest,
                            CanBeDefaultConstructed, InitialSizeIsZero)

// End of header content

from gtest import Test
from gtest import TYPED_TEST_SUITE, TYPED_TEST
from gtest import Types, TypedTestSuitePState
from gtest import EXPECT_EQ, EXPECT_STREQ, EXPECT_DEATH_IF_SUPPORTED, ASSERT_TRUE, EXPECT_LT
from gtest import UnitTest

from std.vector import Vector
from std.set import Set
from std.type_traits import is_same

#if _MSC_VER
# GTEST_DISABLE_MSC_WARNINGS_PUSH_(4127 /* conditional expression is constant */)
#endif  //  _MSC_VER

@value
class CommonTest[T](Test):
    shared_: T* = None

    @staticmethod
    def SetUpTestSuite():
        shared_ = new T(5)

    @staticmethod
    def TearDownTestSuite():
        delete shared_
        shared_ = None

    protected:
        alias Vector = Vector[T]
        alias IntSet = Set[Int]

    def __init__(inout self):
        self.value_ = 1

    def __del__(self):
        EXPECT_EQ(3, self.value_)

    def SetUp(inout self):
        EXPECT_EQ(1, self.value_)
        self.value_ += 1

    def TearDown(inout self):
        EXPECT_EQ(2, self.value_)
        self.value_ += 1

    var value_: T
    static var shared_: T* = None

type TwoTypes = Types[char, int]

TYPED_TEST_SUITE(CommonTest, TwoTypes)

TYPED_TEST(CommonTest, ValuesAreCorrect) {
    EXPECT_EQ(5, *TestFixture.shared_)
    var empty: TestFixture.Vector = Vector[T]()
    EXPECT_EQ(0U, empty.size())
    var empty2: TestFixture.IntSet = Set[Int]()
    EXPECT_EQ(0U, empty2.size())
    EXPECT_EQ(2, this.value_)
}

TYPED_TEST(CommonTest, ValuesAreStillCorrect) {
    ASSERT_TRUE(this.shared_ != None)
    EXPECT_EQ(5, *this.shared_)
    EXPECT_EQ(static_cast[TypeParam](2), this.value_)
}

@value
class TypedTest1[T](Test):

TYPED_TEST_SUITE(TypedTest1, int)

TYPED_TEST(TypedTest1, A) {}

@value
class TypedTest2[T](Test):

TYPED_TEST_SUITE(TypedTest2, Types[int])

TYPED_TEST(TypedTest2, A) {}

namespace library1:
    @value
    class NumericTest[T](Test):

    type NumericTypes = Types[int, long]

    TYPED_TEST_SUITE(NumericTest, NumericTypes)

    TYPED_TEST(NumericTest, DefaultIsZero) {
        EXPECT_EQ(0, TypeParam())
    }

@value
class TypedTestWithNames[T](Test):

class TypedTestNames:
    @staticmethod
    def GetName[T](i: Int) -> String:
        if is_same[T, char]().value:
            return String("char") + PrintToString(i)
        if is_same[T, int]().value:
            return String("int") + PrintToString(i)
        return ""

TYPED_TEST_SUITE(TypedTestWithNames, TwoTypes, TypedTestNames)

TYPED_TEST(TypedTestWithNames, TestSuiteName) {
    if is_same[TypeParam, char]().value:
        EXPECT_STREQ(UnitTest.GetInstance()
                         .current_test_info()
                         .test_suite_name(),
                     "TypedTestWithNames/char0")
    if is_same[TypeParam, int]().value:
        EXPECT_STREQ(UnitTest.GetInstance()
                         .current_test_info()
                         .test_suite_name(),
                     "TypedTestWithNames/int1")
}

class TypedTestSuitePStateTest(Test):
    protected:
        var state_: TypedTestSuitePState

    def SetUp(inout self):
        self.state_.AddTestName("foo.cc", 0, "FooTest", "A")
        self.state_.AddTestName("foo.cc", 0, "FooTest", "B")
        self.state_.AddTestName("foo.cc", 0, "FooTest", "C")

TEST_F(TypedTestSuitePStateTest, SucceedsForMatchingList) {
    var tests: String = "A, B, C"
    EXPECT_EQ(tests,
              self.state_.VerifyRegisteredTestNames("Suite", "foo.cc", 1, tests))
}

TEST_F(TypedTestSuitePStateTest, IgnoresOrderAndSpaces) {
    var tests: String = "A,C,   B"
    EXPECT_EQ(tests,
              self.state_.VerifyRegisteredTestNames("Suite", "foo.cc", 1, tests))
}

type TypedTestSuitePStateDeathTest = TypedTestSuitePStateTest

TEST_F(TypedTestSuitePStateDeathTest, DetectsDuplicates) {
    EXPECT_DEATH_IF_SUPPORTED(
        self.state_.VerifyRegisteredTestNames("Suite", "foo.cc", 1, "A, B, A, C"),
        "foo\\.cc.1.?: Test A is listed more than once\\.")
}

TEST_F(TypedTestSuitePStateDeathTest, DetectsExtraTest) {
    EXPECT_DEATH_IF_SUPPORTED(
        self.state_.VerifyRegisteredTestNames("Suite", "foo.cc", 1, "A, B, C, D"),
        "foo\\.cc.1.?: No test named D can be found in this test suite\\.")
}

TEST_F(TypedTestSuitePStateDeathTest, DetectsMissedTest) {
    EXPECT_DEATH_IF_SUPPORTED(
        self.state_.VerifyRegisteredTestNames("Suite", "foo.cc", 1, "A, C"),
        "foo\\.cc.1.?: You forgot to list test B\\.")
}

TEST_F(TypedTestSuitePStateDeathTest, DetectsTestAfterRegistration) {
    self.state_.VerifyRegisteredTestNames("Suite", "foo.cc", 1, "A, B, C")
    EXPECT_DEATH_IF_SUPPORTED(
        self.state_.AddTestName("foo.cc", 2, "FooTest", "D"),
        "foo\\.cc.2.?: Test D must be defined before REGISTER_TYPED_TEST_SUITE_P"
        "\\(FooTest, \\.\\.\\.\\)\\.")
}

@value
class DerivedTest[T](CommonTest[T]):

TYPED_TEST_SUITE_P(DerivedTest)

TYPED_TEST_P(DerivedTest, ValuesAreCorrect) {
    EXPECT_EQ(5, *TestFixture.shared_)
    EXPECT_EQ(2, this.value_)
}

TYPED_TEST_P(DerivedTest, ValuesAreStillCorrect) {
    ASSERT_TRUE(this.shared_ != None)
    EXPECT_EQ(5, *this.shared_)
    EXPECT_EQ(2, this.value_)
}

REGISTER_TYPED_TEST_SUITE_P(DerivedTest,
                           ValuesAreCorrect, ValuesAreStillCorrect)

type MyTwoTypes = Types[short, long]
INSTANTIATE_TYPED_TEST_SUITE_P(My, DerivedTest, MyTwoTypes)

@value
class TypeParametrizedTestWithNames[T](Test):

TYPED_TEST_SUITE_P(TypeParametrizedTestWithNames)

TYPED_TEST_P(TypeParametrizedTestWithNames, TestSuiteName) {
    if is_same[TypeParam, char]().value:
        EXPECT_STREQ(UnitTest.GetInstance()
                         .current_test_info()
                         .test_suite_name(),
                     "CustomName/TypeParametrizedTestWithNames/parChar0")
    if is_same[TypeParam, int]().value:
        EXPECT_STREQ(UnitTest.GetInstance()
                         .current_test_info()
                         .test_suite_name(),
                     "CustomName/TypeParametrizedTestWithNames/parInt1")
}

REGISTER_TYPED_TEST_SUITE_P(TypeParametrizedTestWithNames, TestSuiteName)

class TypeParametrizedTestNames:
    @staticmethod
    def GetName[T](i: Int) -> String:
        if is_same[T, char]().value:
            return String("parChar") + PrintToString(i)
        if is_same[T, int]().value:
            return String("parInt") + PrintToString(i)
        return ""

INSTANTIATE_TYPED_TEST_SUITE_P(CustomName, TypeParametrizedTestWithNames,
                              TwoTypes, TypeParametrizedTestNames)

@value
class TypedTestP1[T](Test):

TYPED_TEST_SUITE_P(TypedTestP1)

var IntAfterTypedTestSuiteP: type = int

TYPED_TEST_P(TypedTestP1, A) {}
TYPED_TEST_P(TypedTestP1, B) {}

var IntBeforeRegisterTypedTestSuiteP: type = int

REGISTER_TYPED_TEST_SUITE_P(TypedTestP1, A, B)

@value
class TypedTestP2[T](Test):

TYPED_TEST_SUITE_P(TypedTestP2)

TYPED_TEST_P(TypedTestP2, A) {}

REGISTER_TYPED_TEST_SUITE_P(TypedTestP2, A)

var after: IntAfterTypedTestSuiteP = 0
var before: IntBeforeRegisterTypedTestSuiteP = 0

INSTANTIATE_TYPED_TEST_SUITE_P(Int, TypedTestP1, int)
INSTANTIATE_TYPED_TEST_SUITE_P(Int, TypedTestP2, Types[int])
INSTANTIATE_TYPED_TEST_SUITE_P(Double, TypedTestP2, Types[double])

type MyContainers = Types[Vector[double], Set[char]]

INSTANTIATE_TYPED_TEST_SUITE_P(My, ContainerTest, MyContainers)

namespace library2:
    @value
    class NumericTest[T](Test):

    TYPED_TEST_SUITE_P(NumericTest)

    TYPED_TEST_P(NumericTest, DefaultIsZero) {
        EXPECT_EQ(0, TypeParam())
    }

    TYPED_TEST_P(NumericTest, ZeroIsLessThanOne) {
        EXPECT_LT(TypeParam(0), TypeParam(1))
    }

    REGISTER_TYPED_TEST_SUITE_P(NumericTest,
                               DefaultIsZero, ZeroIsLessThanOne)

    type NumericTypes = Types[int, double]
    INSTANTIATE_TYPED_TEST_SUITE_P(My, NumericTest, NumericTypes)

    static def GetTestName() -> String:
        return UnitTest.GetInstance().current_test_info().name()

    @value
    class TrimmedTest[T](Test):

    TYPED_TEST_SUITE_P(TrimmedTest)

    TYPED_TEST_P(TrimmedTest, Test1) { EXPECT_STREQ("Test1", GetTestName()) }
    TYPED_TEST_P(TrimmedTest, Test2) { EXPECT_STREQ("Test2", GetTestName()) }
    TYPED_TEST_P(TrimmedTest, Test3) { EXPECT_STREQ("Test3", GetTestName()) }
    TYPED_TEST_P(TrimmedTest, Test4) { EXPECT_STREQ("Test4", GetTestName()) }
    TYPED_TEST_P(TrimmedTest, Test5) { EXPECT_STREQ("Test5", GetTestName()) }

    REGISTER_TYPED_TEST_SUITE_P(
        TrimmedTest,
        Test1, Test2, Test3 , Test4 , Test5 )  // NOLINT

    struct MyPair[T1, T2]:

    type TrimTypes = Types[int, double, MyPair[int, int]]
    INSTANTIATE_TYPED_TEST_SUITE_P(My, TrimmedTest, TrimTypes)