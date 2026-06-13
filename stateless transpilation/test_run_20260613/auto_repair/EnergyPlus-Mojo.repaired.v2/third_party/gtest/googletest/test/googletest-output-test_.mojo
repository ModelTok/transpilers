from gtest.gtest-spi import *
from gtest.gtest import *
from src.gtest-internal-inl import *
from stdlib import *
#if _MSC_VER
GTEST_DISABLE_MSC_WARNINGS_PUSH_(4127 /* conditional expression is constant */)
#endif  //  _MSC_VER
#if GTEST_IS_THREADSAFE
using testing::ScopedFakeTestPartResultReporter
using testing::TestPartResultArray
using testing::internal::Notification
using testing::internal::ThreadWithParam
#endif
namespace posix = ::testing::internal::posix
def TestEq1(x: Int32):
  ASSERT_EQ(1, x)

def TryTestSubroutine():
  TestEq1(2)
  if testing::Test::HasFatalFailure(): return
  FAIL() << "This should never be reached."

@testing::TEST
struct PassingTest:
  @testing::TEST
  def PassingTest1(): pass

  @testing::TEST
  def PassingTest2(): pass

class FailingParamTest(testing::TestWithParam[Int32]): pass

@testing::TEST_P(FailingParamTest)
def Fails(self):
  EXPECT_EQ(1, self.GetParam())

INSTANTIATE_TEST_SUITE_P(PrintingFailingParams,
                         FailingParamTest,
                         testing::Values(2))

class EmptyBasenameParamInst(testing::TestWithParam[Int32]): pass

@testing::TEST_P(EmptyBasenameParamInst)
def Passes(self): EXPECT_EQ(1, self.GetParam())

INSTANTIATE_TEST_SUITE_P(, EmptyBasenameParamInst, testing::Values(1))

static var kGoldenString: StaticArray[Int8, 12] = "\"Line\0 1\"\nLine 2"

@testing::TEST
struct NonfatalFailureTest:
  @testing::TEST
  def EscapesStringOperands():
    var actual: String = "actual \"string\""
    EXPECT_EQ(kGoldenString, actual)
    var golden: Pointer[Int8] = kGoldenString
    EXPECT_EQ(golden, actual)

  @testing::TEST
  def DiffForLongStrings():
    var golden_str: String = String(kGoldenString, sizeof(kGoldenString) - 1)
    EXPECT_EQ(golden_str, "Line 2")

@testing::TEST
struct FatalFailureTest:
  @testing::TEST
  def FatalFailureInSubroutine():
    printf("(expecting a failure that x should be 1)\n")
    TryTestSubroutine()

  @testing::TEST
  def FatalFailureInNestedSubroutine():
    printf("(expecting a failure that x should be 1)\n")
    TryTestSubroutine()
    if HasFatalFailure(): return
    FAIL() << "This should never be reached."

  @testing::TEST
  def NonfatalFailureInSubroutine():
    printf("(expecting a failure on false)\n")
    EXPECT_TRUE(false)  // Generates a nonfatal failure
    ASSERT_FALSE(HasFatalFailure())  // This should succeed.

@testing::TEST
struct LoggingTest:
  @testing::TEST
  def InterleavingLoggingAndAssertions():
    static var a: StaticArray[Int32, 4] = [3, 9, 2, 6]
    printf("(expecting 2 failures on (3) >= (a[i]))\n")
    for i in range(0, static_cast[Int32](sizeof(a)/sizeof(*a))):
      printf("i == %d\n", i)
      EXPECT_GE(3, a[i])

def SubWithoutTrace(n: Int32):
  EXPECT_EQ(1, n)
  ASSERT_EQ(2, n)

def SubWithTrace(n: Int32):
  SCOPED_TRACE(testing::Message() << "n = " << n)
  SubWithoutTrace(n)

@testing::TEST
struct SCOPED_TRACETest:
  @testing::TEST
  def AcceptedValues():
    SCOPED_TRACE("literal string")
    SCOPED_TRACE(String("string"))
    SCOPED_TRACE(1337)  // streamable type
    var null_value: Pointer[Int8] = None
    SCOPED_TRACE(null_value)
    ADD_FAILURE() << "Just checking that all these values work fine."

  @testing::TEST
  def ObeysScopes():
    printf("(expected to fail)\n")
    ADD_FAILURE() << "This failure is expected, and shouldn't have a trace."
    {
      SCOPED_TRACE("Expected trace")
      ADD_FAILURE() << "This failure is expected, and should have a trace."
    }
    ADD_FAILURE() << "This failure is expected, and shouldn't have a trace."

  @testing::TEST
  def WorksInLoop():
    printf("(expected to fail)\n")
    for i in range(1, 3):
      SCOPED_TRACE(testing::Message() << "i = " << i)
      SubWithoutTrace(i)

  @testing::TEST
  def WorksInSubroutine():
    printf("(expected to fail)\n")
    SubWithTrace(1)
    SubWithTrace(2)

  @testing::TEST
  def CanBeNested():
    printf("(expected to fail)\n")
    SCOPED_TRACE("")  // A trace without a message.
    SubWithTrace(2)

  @testing::TEST
  def CanBeRepeated():
    printf("(expected to fail)\n")
    SCOPED_TRACE("A")
    ADD_FAILURE() << "This failure is expected, and should contain trace point A."
    SCOPED_TRACE("B")
    ADD_FAILURE() << "This failure is expected, and should contain trace point A and B."
    {
      SCOPED_TRACE("C")
      ADD_FAILURE() << "This failure is expected, and should " << "contain trace point A, B, and C."
    }
    SCOPED_TRACE("D")
    ADD_FAILURE() << "This failure is expected, and should " << "contain trace point A, B, and D."

#if GTEST_IS_THREADSAFE
struct CheckPoints:
  var n1: Notification
  var n2: Notification
  var n3: Notification

static def ThreadWithScopedTrace(check_points: Pointer[CheckPoints]):
  {
    SCOPED_TRACE("Trace B")
    ADD_FAILURE() << "Expected failure #1 (in thread B, only trace B alive)."
    check_points[].n1.Notify()
    check_points[].n2.WaitForNotification()
    ADD_FAILURE() << "Expected failure #3 (in thread B, trace A & B both alive)."
  }  // Trace B dies here.
  ADD_FAILURE() << "Expected failure #4 (in thread B, only trace A alive)."
  check_points[].n3.Notify()

@testing::TEST
def WorksConcurrently():
  printf("(expecting 6 failures)\n")
  var check_points: CheckPoints
  var thread: ThreadWithParam[Pointer[CheckPoints]](&ThreadWithScopedTrace, &check_points, None)
  check_points.n1.WaitForNotification()
  {
    SCOPED_TRACE("Trace A")
    ADD_FAILURE() << "Expected failure #2 (in thread A, trace A & B both alive)."
    check_points.n2.Notify()
    check_points.n3.WaitForNotification()
    ADD_FAILURE() << "Expected failure #5 (in thread A, only trace A alive)."
  }  // Trace A dies here.
  ADD_FAILURE() << "Expected failure #6 (in thread A, no trace alive)."
  thread.Join()
#endif  // GTEST_IS_THREADSAFE

@testing::TEST
struct ScopedTraceTest:
  @testing::TEST
  def WithExplicitFileAndLine():
    testing::ScopedTrace trace("explicit_file.cc", 123, "expected trace message")
    ADD_FAILURE() << "Check that the trace is attached to a particular location."

@testing::TEST
struct DisabledTestsWarningTest:
  @testing::TEST
  def DISABLED_AlsoRunDisabledTestsFlagSuppressesWarning(): pass

def AdHocTest():
  printf("The non-test part of the code is expected to have 2 failures.\n\n")
  EXPECT_TRUE(false)
  EXPECT_EQ(2, 3)

def RunAllTests() -> Int32:
  AdHocTest()
  return RUN_ALL_TESTS()

class NonFatalFailureInFixtureConstructorTest(testing::Test):
  protected:
  def __init__(self):
    printf("(expecting 5 failures)\n")
    ADD_FAILURE() << "Expected failure #1, in the test fixture c'tor."

  def __del__(self):
    ADD_FAILURE() << "Expected failure #5, in the test fixture d'tor."

  def SetUp(self):
    ADD_FAILURE() << "Expected failure #2, in SetUp()."

  def TearDown(self):
    ADD_FAILURE() << "Expected failure #4, in TearDown."

@testing::TEST_F(NonFatalFailureInFixtureConstructorTest)
def FailureInConstructor(self):
  ADD_FAILURE() << "Expected failure #3, in the test body."

class FatalFailureInFixtureConstructorTest(testing::Test):
  protected:
  def __init__(self):
    printf("(expecting 2 failures)\n")
    self.Init()

  def __del__(self):
    ADD_FAILURE() << "Expected failure #2, in the test fixture d'tor."

  def SetUp(self):
    ADD_FAILURE() << "UNEXPECTED failure in SetUp().  " << "We should never get here, as the test fixture c'tor " << "had a fatal failure."

  def TearDown(self):
    ADD_FAILURE() << "UNEXPECTED failure in TearDown().  " << "We should never get here, as the test fixture c'tor " << "had a fatal failure."

  private:
  def Init(self):
    FAIL() << "Expected failure #1, in the test fixture c'tor."

@testing::TEST_F(FatalFailureInFixtureConstructorTest)
def FailureInConstructor(self):
  ADD_FAILURE() << "UNEXPECTED failure in the test body.  " << "We should never get here, as the test fixture c'tor " << "had a fatal failure."

class NonFatalFailureInSetUpTest(testing::Test):
  protected:
  def __del__(self):
    self.Deinit()

  def SetUp(self):
    printf("(expecting 4 failures)\n")
    ADD_FAILURE() << "Expected failure #1, in SetUp()."

  def TearDown(self):
    FAIL() << "Expected failure #3, in TearDown()."

  private:
  def Deinit(self):
    FAIL() << "Expected failure #4, in the test fixture d'tor."

@testing::TEST_F(NonFatalFailureInSetUpTest)
def FailureInSetUp(self):
  FAIL() << "Expected failure #2, in the test function."

class FatalFailureInSetUpTest(testing::Test):
  protected:
  def __del__(self):
    self.Deinit()

  def SetUp(self):
    printf("(expecting 3 failures)\n")
    FAIL() << "Expected failure #1, in SetUp()."

  def TearDown(self):
    FAIL() << "Expected failure #2, in TearDown()."

  private:
  def Deinit(self):
    FAIL() << "Expected failure #3, in the test fixture d'tor."

@testing::TEST_F(FatalFailureInSetUpTest)
def FailureInSetUp(self):
  FAIL() << "UNEXPECTED failure in the test function.  " << "We should never get here, as SetUp() failed."

@testing::TEST
struct AddFailureAtTest:
  @testing::TEST
  def MessageContainsSpecifiedFileAndLineNumber():
    ADD_FAILURE_AT("foo.cc", 42) << "Expected nonfatal failure in foo.cc"

@testing::TEST
struct GtestFailAtTest:
  @testing::TEST
  def MessageContainsSpecifiedFileAndLineNumber():
    GTEST_FAIL_AT("foo.cc", 42) << "Expected fatal failure in foo.cc"

namespace foo:
  class MixedUpTestSuiteTest(testing::Test): pass

  @testing::TEST_F(MixedUpTestSuiteTest)
  def FirstTestFromNamespaceFoo(): pass

  @testing::TEST_F(MixedUpTestSuiteTest)
  def SecondTestFromNamespaceFoo(): pass

  class MixedUpTestSuiteWithSameTestNameTest(testing::Test): pass

  @testing::TEST_F(MixedUpTestSuiteWithSameTestNameTest)
  def TheSecondTestWithThisNameShouldFail(): pass

namespace bar:
  class MixedUpTestSuiteTest(testing::Test): pass

  @testing::TEST_F(MixedUpTestSuiteTest)
  def ThisShouldFail(): pass

  @testing::TEST_F(MixedUpTestSuiteTest)
  def ThisShouldFailToo(): pass

  class MixedUpTestSuiteWithSameTestNameTest(testing::Test): pass

  @testing::TEST_F(MixedUpTestSuiteWithSameTestNameTest)
  def TheSecondTestWithThisNameShouldFail(): pass

class TEST_F_before_TEST_in_same_test_case(testing::Test): pass

@testing::TEST_F(TEST_F_before_TEST_in_same_test_case)
def DefinedUsingTEST_F(): pass

@testing::TEST
def DefinedUsingTESTAndShouldFail(): pass

class TEST_before_TEST_F_in_same_test_case(testing::Test): pass

@testing::TEST
def DefinedUsingTEST(): pass

@testing::TEST_F(TEST_before_TEST_F_in_same_test_case)
def DefinedUsingTEST_FAndShouldFail(): pass

var global_integer: Int32 = 0

@testing::TEST
struct ExpectNonfatalFailureTest:
  @testing::TEST
  def CanReferenceGlobalVariables():
    global_integer = 0
    EXPECT_NONFATAL_FAILURE({
      EXPECT_EQ(1, global_integer) << "Expected non-fatal failure."
    }, "Expected non-fatal failure.")

  @testing::TEST
  def CanReferenceLocalVariables():
    var m: Int32 = 0
    static var n: Int32
    n = 1
    EXPECT_NONFATAL_FAILURE({
      EXPECT_EQ(m, n) << "Expected non-fatal failure."
    }, "Expected non-fatal failure.")

  @testing::TEST
  def SucceedsWhenThereIsOneNonfatalFailure():
    EXPECT_NONFATAL_FAILURE({
      ADD_FAILURE() << "Expected non-fatal failure."
    }, "Expected non-fatal failure.")

  @testing::TEST
  def FailsWhenThereIsNoNonfatalFailure():
    printf("(expecting a failure)\n")
    EXPECT_NONFATAL_FAILURE({
    }, "")

  @testing::TEST
  def FailsWhenThereAreTwoNonfatalFailures():
    printf("(expecting a failure)\n")
    EXPECT_NONFATAL_FAILURE({
      ADD_FAILURE() << "Expected non-fatal failure 1."
      ADD_FAILURE() << "Expected non-fatal failure 2."
    }, "")

  @testing::TEST
  def FailsWhenThereIsOneFatalFailure():
    printf("(expecting a failure)\n")
    EXPECT_NONFATAL_FAILURE({
      FAIL() << "Expected fatal failure."
    }, "")

  @testing::TEST
  def FailsWhenStatementReturns():
    printf("(expecting a failure)\n")
    EXPECT_NONFATAL_FAILURE({
      return
    }, "")

#if GTEST_HAS_EXCEPTIONS
  @testing::TEST
  def FailsWhenStatementThrows():
    printf("(expecting a failure)\n")
    try:
      EXPECT_NONFATAL_FAILURE({
        throw 0
      }, "")
    except Int32:  # NOLINT

#endif  // GTEST_HAS_EXCEPTIONS

@testing::TEST
struct ExpectFatalFailureTest:
  @testing::TEST
  def CanReferenceGlobalVariables():
    global_integer = 0
    EXPECT_FATAL_FAILURE({
      ASSERT_EQ(1, global_integer) << "Expected fatal failure."
    }, "Expected fatal failure.")

  @testing::TEST
  def CanReferenceLocalStaticVariables():
    static var n: Int32
    n = 1
    EXPECT_FATAL_FAILURE({
      ASSERT_EQ(0, n) << "Expected fatal failure."
    }, "Expected fatal failure.")

  @testing::TEST
  def SucceedsWhenThereIsOneFatalFailure():
    EXPECT_FATAL_FAILURE({
      FAIL() << "Expected fatal failure."
    }, "Expected fatal failure.")

  @testing::TEST
  def FailsWhenThereIsNoFatalFailure():
    printf("(expecting a failure)\n")
    EXPECT_FATAL_FAILURE({
    }, "")

  def FatalFailure():
    FAIL() << "Expected fatal failure."

  @testing::TEST
  def FailsWhenThereAreTwoFatalFailures():
    printf("(expecting a failure)\n")
    EXPECT_FATAL_FAILURE({
      FatalFailure()
      FatalFailure()
    }, "")

  @testing::TEST
  def FailsWhenThereIsOneNonfatalFailure():
    printf("(expecting a failure)\n")
    EXPECT_FATAL_FAILURE({
      ADD_FAILURE() << "Expected non-fatal failure."
    }, "")

  @testing::TEST
  def FailsWhenStatementReturns():
    printf("(expecting a failure)\n")
    EXPECT_FATAL_FAILURE({
      return
    }, "")

#if GTEST_HAS_EXCEPTIONS
  @testing::TEST
  def FailsWhenStatementThrows():
    printf("(expecting a failure)\n")
    try:
      EXPECT_FATAL_FAILURE({
        throw 0
      }, "")
    except Int32:  # NOLINT

#endif  // GTEST_HAS_EXCEPTIONS

def ParamNameFunc(info: testing::TestParamInfo[String]) -> String:
  return info.param

class ParamTest(testing::TestWithParam[String]): pass

@testing::TEST_P(ParamTest)
def Success(self):
  EXPECT_EQ("a", self.GetParam())

@testing::TEST_P(ParamTest)
def Failure(self):
  EXPECT_EQ("b", self.GetParam()) << "Expected failure"

INSTANTIATE_TEST_SUITE_P(PrintingStrings,
                         ParamTest,
                         testing::Values(String("a")),
                         ParamNameFunc)

using NoTests = ParamTest
INSTANTIATE_TEST_SUITE_P(ThisIsOdd, NoTests, ::testing::Values("Hello"))

class DetectNotInstantiatedTest(testing::TestWithParam[Int32]): pass

@testing::TEST_P(DetectNotInstantiatedTest)
def Used(self): pass

@testing::TYPED_TEST_SUITE
struct TypedTest[T: AnyType]:
  @testing::TYPED_TEST
  def Success(self):
    EXPECT_EQ(0, TypeParam())

  @testing::TYPED_TEST
  def Failure(self):
    EXPECT_EQ(1, TypeParam()) << "Expected failure"

TYPED_TEST_SUITE(TypedTest, testing::Types[Int32])

typedef testing::Types[Int8, Int32] TypesForTestWithNames

@testing::TYPED_TEST_SUITE
struct TypedTestWithNames[T: AnyType]: pass

class TypedTestNames:
  @staticmethod
  def GetName[T: AnyType](i: Int32) -> String:
    if __type_is[T, Int8]:
      return String("char") + ::testing::PrintToString(i)
    if __type_is[T, Int32]:
      return String("int") + ::testing::PrintToString(i)

TYPED_TEST_SUITE(TypedTestWithNames, TypesForTestWithNames, TypedTestNames)

@testing::TYPED_TEST(TypedTestWithNames)
def Success(self): pass

@testing::TYPED_TEST(TypedTestWithNames)
def Failure(self): FAIL()

@testing::TYPED_TEST_SUITE_P
struct TypedTestP[T: AnyType]: pass

@testing::TYPED_TEST_P(TypedTestP)
def Success(self):
  EXPECT_EQ(0U, TypeParam())

@testing::TYPED_TEST_P(TypedTestP)
def Failure(self):
  EXPECT_EQ(1U, TypeParam()) << "Expected failure"

REGISTER_TYPED_TEST_SUITE_P(TypedTestP, Success, Failure)

typedef testing::Types[UInt8, UInt32] UnsignedTypes
INSTANTIATE_TYPED_TEST_SUITE_P(Unsigned, TypedTestP, UnsignedTypes)

class TypedTestPNames:
  @staticmethod
  def GetName[T: AnyType](i: Int32) -> String:
    if __type_is[T, UInt8]:
      return String("unsignedChar") + ::testing::PrintToString(i)
    if __type_is[T, UInt32]:
      return String("unsignedInt") + ::testing::PrintToString(i)

INSTANTIATE_TYPED_TEST_SUITE_P(UnsignedCustomName, TypedTestP, UnsignedTypes,
                              TypedTestPNames)

@testing::TYPED_TEST_SUITE_P
struct DetectNotInstantiatedTypesTest[T: AnyType]: pass

@testing::TYPED_TEST_P(DetectNotInstantiatedTypesTest)
def Used(self):
  var instantiate: TypeParam
  (void)instantiate

REGISTER_TYPED_TEST_SUITE_P(DetectNotInstantiatedTypesTest, Used)

#if GTEST_HAS_DEATH_TEST
@testing::TEST
struct ADeathTest:
  @testing::TEST
  def ShouldRunFirst(): pass

@testing::TYPED_TEST_SUITE
struct ATypedDeathTest[T: AnyType]: pass

typedef testing::Types[Int32, Float64] NumericTypes
TYPED_TEST_SUITE(ATypedDeathTest, NumericTypes)

@testing::TYPED_TEST(ATypedDeathTest)
def ShouldRunFirst(self): pass

@testing::TYPED_TEST_SUITE_P
struct ATypeParamDeathTest[T: AnyType]: pass

@testing::TYPED_TEST_P(ATypeParamDeathTest)
def ShouldRunFirst(self): pass

REGISTER_TYPED_TEST_SUITE_P(ATypeParamDeathTest, ShouldRunFirst)
INSTANTIATE_TYPED_TEST_SUITE_P(My, ATypeParamDeathTest, NumericTypes)
#endif  // GTEST_HAS_DEATH_TEST

class ExpectFailureTest(testing::Test):
  public:  // Must be public and not protected due to a bug in g++ 3.4.2.
  enum FailureMode:
    FATAL_FAILURE
    NONFATAL_FAILURE

  @staticmethod
  def AddFailure(failure: FailureMode):
    if failure == FailureMode.FATAL_FAILURE:
      FAIL() << "Expected fatal failure."
    else:
      ADD_FAILURE() << "Expected non-fatal failure."

@testing::TEST_F(ExpectFailureTest)
def ExpectFatalFailure(self):
  printf("(expecting 1 failure)\n")
  EXPECT_FATAL_FAILURE(SUCCEED(), "Expected fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_FATAL_FAILURE(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.NONFATAL_FAILURE), "Expected non-fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_FATAL_FAILURE(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.FATAL_FAILURE), "Some other fatal failure expected.")

@testing::TEST_F(ExpectFailureTest)
def ExpectNonFatalFailure(self):
  printf("(expecting 1 failure)\n")
  EXPECT_NONFATAL_FAILURE(SUCCEED(), "Expected non-fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_NONFATAL_FAILURE(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.FATAL_FAILURE), "Expected fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_NONFATAL_FAILURE(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.NONFATAL_FAILURE), "Some other non-fatal failure.")

#if GTEST_IS_THREADSAFE
class ExpectFailureWithThreadsTest(ExpectFailureTest):
  protected:
  @staticmethod
  def AddFailureInOtherThread(failure: FailureMode):
    var thread: ThreadWithParam[FailureMode](&ExpectFailureTest.AddFailure, failure, None)
    thread.Join()

@testing::TEST_F(ExpectFailureWithThreadsTest)
def ExpectFatalFailure(self):
  printf("(expecting 2 failures)\n")
  EXPECT_FATAL_FAILURE(ExpectFailureWithThreadsTest.AddFailureInOtherThread(ExpectFailureTest.FailureMode.FATAL_FAILURE),
                       "Expected fatal failure.")

@testing::TEST_F(ExpectFailureWithThreadsTest)
def ExpectNonFatalFailure(self):
  printf("(expecting 2 failures)\n")
  EXPECT_NONFATAL_FAILURE(ExpectFailureWithThreadsTest.AddFailureInOtherThread(ExpectFailureTest.FailureMode.NONFATAL_FAILURE),
                          "Expected non-fatal failure.")

typedef ExpectFailureWithThreadsTest ScopedFakeTestPartResultReporterTest

@testing::TEST_F(ScopedFakeTestPartResultReporterTest)
def InterceptOnlyCurrentThread(self):
  printf("(expecting 2 failures)\n")
  var results: TestPartResultArray
  {
    var reporter: ScopedFakeTestPartResultReporter(
        ScopedFakeTestPartResultReporter.INTERCEPT_ONLY_CURRENT_THREAD,
        &results)
    ExpectFailureWithThreadsTest.AddFailureInOtherThread(ExpectFailureTest.FailureMode.FATAL_FAILURE)
    ExpectFailureWithThreadsTest.AddFailureInOtherThread(ExpectFailureTest.FailureMode.NONFATAL_FAILURE)
  }
  EXPECT_EQ(0, results.size()) << "This shouldn't fail."
#endif  // GTEST_IS_THREADSAFE

@testing::TEST_F(ExpectFailureTest)
def ExpectFatalFailureOnAllThreads(self):
  printf("(expecting 1 failure)\n")
  EXPECT_FATAL_FAILURE_ON_ALL_THREADS(SUCCEED(), "Expected fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_FATAL_FAILURE_ON_ALL_THREADS(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.NONFATAL_FAILURE),
                                      "Expected non-fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_FATAL_FAILURE_ON_ALL_THREADS(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.FATAL_FAILURE),
                                      "Some other fatal failure expected.")

@testing::TEST_F(ExpectFailureTest)
def ExpectNonFatalFailureOnAllThreads(self):
  printf("(expecting 1 failure)\n")
  EXPECT_NONFATAL_FAILURE_ON_ALL_THREADS(SUCCEED(), "Expected non-fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_NONFATAL_FAILURE_ON_ALL_THREADS(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.FATAL_FAILURE),
                                         "Expected fatal failure.")
  printf("(expecting 1 failure)\n")
  EXPECT_NONFATAL_FAILURE_ON_ALL_THREADS(ExpectFailureTest.AddFailure(ExpectFailureTest.FailureMode.NONFATAL_FAILURE),
                                         "Some other non-fatal failure.")

class DynamicFixture(testing::Test):
  protected:
  def __init__(self):
    printf("DynamicFixture()\n")

  def __del__(self):
    printf("~DynamicFixture()\n")

  def SetUp(self):
    printf("DynamicFixture::SetUp\n")

  def TearDown(self):
    printf("DynamicFixture::TearDown\n")

  @staticmethod
  def SetUpTestSuite():
    printf("DynamicFixture::SetUpTestSuite\n")

  @staticmethod
  def TearDownTestSuite():
    printf("DynamicFixture::TearDownTestSuite\n")

@testing::TYPED_TEST_SUITE
struct DynamicTest[Pass: Bool](DynamicFixture):
  def TestBody(self):
    EXPECT_TRUE(Pass)

var dynamic_test = (
    testing::RegisterTest(
        "DynamicFixture", "DynamicTestPass", None, None, __FILE__,
        __LINE__, lambda: DynamicTest[True]()),
    testing::RegisterTest(
        "DynamicFixture", "DynamicTestFail", None, None, __FILE__,
        __LINE__, lambda: DynamicTest[False]()),
    testing::RegisterTest(
        "DynamicFixtureAnotherName", "DynamicTestPass", None, None,
        __FILE__, __LINE__,
        lambda: DynamicTest[True]()),
    testing::RegisterTest(
        "BadDynamicFixture1", "FixtureBase", None, None, __FILE__,
        __LINE__, lambda: DynamicTest[True]()),
    testing::RegisterTest(
        "BadDynamicFixture1", "TestBase", None, None, __FILE__, __LINE__,
        lambda: DynamicTest[True]()),
    testing::RegisterTest(
        "BadDynamicFixture2", "FixtureBase", None, None, __FILE__,
        __LINE__, lambda: DynamicTest[True]()),
    testing::RegisterTest("BadDynamicFixture2", "Derived", None, None,
                          __FILE__, __LINE__,
                          lambda: DynamicTest[True]()))

class FooEnvironment(testing::Environment):
  def SetUp(self):
    printf("%s", "FooEnvironment::SetUp() called.\n")

  def TearDown(self):
    printf("%s", "FooEnvironment::TearDown() called.\n")
    FAIL() << "Expected fatal failure."

class BarEnvironment(testing::Environment):
  def SetUp(self):
    printf("%s", "BarEnvironment::SetUp() called.\n")

  def TearDown(self):
    printf("%s", "BarEnvironment::TearDown() called.\n")
    ADD_FAILURE() << "Expected non-fatal failure."

def main(argc: Int32, argv: Pointer[Pointer[Int8]]) -> Int32:
  testing::GTEST_FLAG(print_time) = false
  testing::InitGoogleTest(&argc, argv)
  var internal_skip_environment_and_ad_hoc_tests: Bool = count(argv, argv + argc, String("internal_skip_environment_and_ad_hoc_tests")) > 0
#if GTEST_HAS_DEATH_TEST
  if testing::internal::GTEST_FLAG(internal_run_death_test) != "":
# if GTEST_OS_WINDOWS
    posix::FReopen("nul:", "w", stdout)
# else
    posix::FReopen("/dev/null", "w", stdout)
# endif  // GTEST_OS_WINDOWS
    return RUN_ALL_TESTS()
#endif  // GTEST_HAS_DEATH_TEST
  if internal_skip_environment_and_ad_hoc_tests:
    return RUN_ALL_TESTS()
  testing::AddGlobalTestEnvironment(FooEnvironment())
  testing::AddGlobalTestEnvironment(BarEnvironment())
#if _MSC_VER
GTEST_DISABLE_MSC_WARNINGS_POP_()  //  4127
#endif  //  _MSC_VER
  return RunAllTests()