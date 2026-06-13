// Mojo translation of gmock-internal-utils_test.cc
// Kept all names, structure, comments verbatim.
// Includes converted to imports; preprocessor conditionals translated to runtime ifs.

from gmock.internal.gmock_internal_utils import *
from stdlib import *
from cstdint import *
from map import *
from memory import *
from sstream import *
from string import *
from vector import *
from gmock.gmock import *
from gmock.internal.gmock_port import *
from gtest.gtest-spi import *
from gtest.gtest import *
# define GTEST_IMPLEMENTATION_ 1  // not needed in Mojo
from src.gtest_internal_inl import *
# undef GTEST_IMPLEMENTATION_  // not needed

# GTEST_OS_CYGWIN, etc. are defined as runtime booleans for platform detection
# For translation, define constants (assume Linux for this demonstration)
var GTEST_OS_CYGWIN = False
var GTEST_OS_LINUX = True
var GTEST_OS_MAC = False

# namespace proto2 {
class proto2:
    class Message:

# }  // namespace proto2

# namespace testing {
# namespace internal {
# namespace {

# Mojo test functions: original names preserved via comments
# TEST(JoinAsTupleTest, JoinsEmptyTuple)
def test_JoinAsTupleTest_JoinsEmptyTuple() -> None:
    # Equivalent to EXPECT_EQ("", JoinAsTuple(Strings()));
    expect_eq("", JoinAsTuple(Strings()))

# TEST(JoinAsTupleTest, JoinsOneTuple)
def test_JoinAsTupleTest_JoinsOneTuple() -> None:
    const fields: Pointer[String] = ["1"]
    expect_eq("1", JoinAsTuple(Strings(fields, fields + 1)))

# TEST(JoinAsTupleTest, JoinsTwoTuple)
def test_JoinAsTupleTest_JoinsTwoTuple() -> None:
    const fields: Pointer[String] = ["1", "a"]
    expect_eq("(1, a)", JoinAsTuple(Strings(fields, fields + 2)))

# TEST(JoinAsTupleTest, JoinsTenTuple)
def test_JoinAsTupleTest_JoinsTenTuple() -> None:
    const fields: Pointer[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    expect_eq("(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)",
              JoinAsTuple(Strings(fields, fields + 10)))

# TEST(ConvertIdentifierNameToWordsTest, WorksWhenNameContainsNoWord)
def test_ConvertIdentifierNameToWordsTest_WorksWhenNameContainsNoWord() -> None:
    expect_eq("", ConvertIdentifierNameToWords(""))
    expect_eq("", ConvertIdentifierNameToWords("_"))
    expect_eq("", ConvertIdentifierNameToWords("__"))

# TEST(ConvertIdentifierNameToWordsTest, WorksWhenNameContainsDigits)
def test_ConvertIdentifierNameToWordsTest_WorksWhenNameContainsDigits() -> None:
    expect_eq("1", ConvertIdentifierNameToWords("_1"))
    expect_eq("2", ConvertIdentifierNameToWords("2_"))
    expect_eq("34", ConvertIdentifierNameToWords("_34_"))
    expect_eq("34 56", ConvertIdentifierNameToWords("_34_56"))

# TEST(ConvertIdentifierNameToWordsTest, WorksWhenNameContainsCamelCaseWords)
def test_ConvertIdentifierNameToWordsTest_WorksWhenNameContainsCamelCaseWords() -> None:
    expect_eq("a big word", ConvertIdentifierNameToWords("ABigWord"))
    expect_eq("foo bar", ConvertIdentifierNameToWords("FooBar"))
    expect_eq("foo", ConvertIdentifierNameToWords("Foo_"))
    expect_eq("foo bar", ConvertIdentifierNameToWords("_Foo_Bar_"))
    expect_eq("foo and bar", ConvertIdentifierNameToWords("_Foo__And_Bar"))

# TEST(ConvertIdentifierNameToWordsTest, WorksWhenNameContains_SeparatedWords)
def test_ConvertIdentifierNameToWordsTest_WorksWhenNameContains_SeparatedWords() -> None:
    expect_eq("foo bar", ConvertIdentifierNameToWords("foo_bar"))
    expect_eq("foo", ConvertIdentifierNameToWords("_foo_"))
    expect_eq("foo bar", ConvertIdentifierNameToWords("_foo_bar_"))
    expect_eq("foo and bar", ConvertIdentifierNameToWords("_foo__and_bar"))

# TEST(ConvertIdentifierNameToWordsTest, WorksWhenNameIsMixture)
def test_ConvertIdentifierNameToWordsTest_WorksWhenNameIsMixture() -> None:
    expect_eq("foo bar 123", ConvertIdentifierNameToWords("Foo_bar123"))
    expect_eq("chapter 11 section 1",
              ConvertIdentifierNameToWords("_Chapter11Section_1_"))

# TEST(GetRawPointerTest, WorksForSmartPointers)
def test_GetRawPointerTest_WorksForSmartPointers() -> None:
    const raw_p1: Pointer[Char] = new Char('a')  # NOLINT
    const p1: UniquePointer[Char] = raw_p1
    expect_eq(unsafe_ptr(raw_p1), GetRawPointer(p1))
    var raw_p2: Pointer[Double] = new Double(2.5)  # NOLINT
    const p2: SharedPointer[Double] = raw_p2
    expect_eq(unsafe_ptr(raw_p2), GetRawPointer(p2))

# TEST(GetRawPointerTest, WorksForRawPointers)
def test_GetRawPointerTest_WorksForRawPointers() -> None:
    var p: Pointer[Int] = null
    expect_true(null == GetRawPointer(p))
    var n: Int = 1
    expect_eq(unsafe_ptr(n), GetRawPointer(&n))

class Base:

class Derived(Base):

# TEST(KindOfTest, Bool)
def test_KindOfTest_Bool() -> None:
    expect_eq(kBool, GMOCK_KIND_OF_(Bool))  # NOLINT

# TEST(KindOfTest, Integer)
def test_KindOfTest_Integer() -> None:
    expect_eq(kInteger, GMOCK_KIND_OF_(Char))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(SignedChar))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(UnsignedChar))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(Short))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(UnsignedShort))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(Int))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(UnsignedInt))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(Long))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(UnsignedLong))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(LongLong))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(UnsignedLongLong))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(WChar))  # NOLINT
    expect_eq(kInteger, GMOCK_KIND_OF_(Size))  # NOLINT
    if GTEST_OS_LINUX or GTEST_OS_MAC or GTEST_OS_CYGWIN:
        expect_eq(kInteger, GMOCK_KIND_OF_(SSize))  # NOLINT

# TEST(KindOfTest, FloatingPoint)
def test_KindOfTest_FloatingPoint() -> None:
    expect_eq(kFloatingPoint, GMOCK_KIND_OF_(Float))  # NOLINT
    expect_eq(kFloatingPoint, GMOCK_KIND_OF_(Double))  # NOLINT
    expect_eq(kFloatingPoint, GMOCK_KIND_OF_(LongDouble))  # NOLINT

# TEST(KindOfTest, Other)
def test_KindOfTest_Other() -> None:
    expect_eq(kOther, GMOCK_KIND_OF_(VoidPointer))  # NOLINT
    expect_eq(kOther, GMOCK_KIND_OF_(Pointer[Char]))  # NOLINT
    expect_eq(kOther, GMOCK_KIND_OF_(Base))  # NOLINT

# TEST(LosslessArithmeticConvertibleTest, BoolToBool)
def test_LosslessArithmeticConvertibleTest_BoolToBool() -> None:
    expect_true((LosslessArithmeticConvertible[Bool, Bool]::value))

# TEST(LosslessArithmeticConvertibleTest, BoolToInteger)
def test_LosslessArithmeticConvertibleTest_BoolToInteger() -> None:
    expect_true((LosslessArithmeticConvertible[Bool, Char]::value))
    expect_true((LosslessArithmeticConvertible[Bool, Int]::value))
    expect_true((LosslessArithmeticConvertible[Bool, UnsignedLong]::value))  # NOLINT

# TEST(LosslessArithmeticConvertibleTest, BoolToFloatingPoint)
def test_LosslessArithmeticConvertibleTest_BoolToFloatingPoint() -> None:
    expect_true((LosslessArithmeticConvertible[Bool, Float]::value))
    expect_true((LosslessArithmeticConvertible[Bool, Double]::value))

# TEST(LosslessArithmeticConvertibleTest, IntegerToBool)
def test_LosslessArithmeticConvertibleTest_IntegerToBool() -> None:
    expect_false((LosslessArithmeticConvertible[UnsignedChar, Bool]::value))
    expect_false((LosslessArithmeticConvertible[Int, Bool]::value))

# TEST(LosslessArithmeticConvertibleTest, IntegerToInteger)
def test_LosslessArithmeticConvertibleTest_IntegerToInteger() -> None:
    expect_true((LosslessArithmeticConvertible[UnsignedChar, Int]::value))
    expect_true((LosslessArithmeticConvertible[UnsignedShort, UInt64]::value))  # NOLINT
    expect_false((LosslessArithmeticConvertible[Short, UInt64]::value))  # NOLINT
    expect_false((LosslessArithmeticConvertible[SignedChar, UnsignedInt]::value))  # NOLINT
    expect_true((LosslessArithmeticConvertible[UnsignedChar, UnsignedChar]::value))
    expect_true((LosslessArithmeticConvertible[Int, Int]::value))
    expect_true((LosslessArithmeticConvertible[WChar, WChar]::value))
    expect_true((LosslessArithmeticConvertible[UnsignedLong, UnsignedLong]::value))  # NOLINT
    expect_false((LosslessArithmeticConvertible[UnsignedChar, SignedChar]::value))
    expect_false((LosslessArithmeticConvertible[Int, UnsignedInt]::value))
    expect_false((LosslessArithmeticConvertible[UInt64, Int64]::value))
    expect_false((LosslessArithmeticConvertible[Long, Char]::value))  # NOLINT
    expect_false((LosslessArithmeticConvertible[Int, SignedChar]::value))
    expect_false((LosslessArithmeticConvertible[Int64, UnsignedInt]::value))

# TEST(LosslessArithmeticConvertibleTest, IntegerToFloatingPoint)
def test_LosslessArithmeticConvertibleTest_IntegerToFloatingPoint() -> None:
    expect_false((LosslessArithmeticConvertible[Char, Float]::value))
    expect_false((LosslessArithmeticConvertible[Int, Double]::value))
    expect_false((LosslessArithmeticConvertible[Short, LongDouble]::value))  # NOLINT

# TEST(LosslessArithmeticConvertibleTest, FloatingPointToBool)
def test_LosslessArithmeticConvertibleTest_FloatingPointToBool() -> None:
    expect_false((LosslessArithmeticConvertible[Float, Bool]::value))
    expect_false((LosslessArithmeticConvertible[Double, Bool]::value))

# TEST(LosslessArithmeticConvertibleTest, FloatingPointToInteger)
def test_LosslessArithmeticConvertibleTest_FloatingPointToInteger() -> None:
    expect_false((LosslessArithmeticConvertible[Float, Long]::value))  # NOLINT
    expect_false((LosslessArithmeticConvertible[Double, Int64]::value))
    expect_false((LosslessArithmeticConvertible[LongDouble, Int]::value))

# TEST(LosslessArithmeticConvertibleTest, FloatingPointToFloatingPoint)
def test_LosslessArithmeticConvertibleTest_FloatingPointToFloatingPoint() -> None:
    expect_true((LosslessArithmeticConvertible[Float, Double]::value))
    expect_true((LosslessArithmeticConvertible[Float, LongDouble]::value))
    expect_true((LosslessArithmeticConvertible[Double, LongDouble]::value))
    expect_true((LosslessArithmeticConvertible[Float, Float]::value))
    expect_true((LosslessArithmeticConvertible[Double, Double]::value))
    expect_false((LosslessArithmeticConvertible[Double, Float]::value))
    GTEST_INTENTIONAL_CONST_COND_PUSH_()
    if sizeof(Double) == sizeof(LongDouble):  # NOLINT
    GTEST_INTENTIONAL_CONST_COND_POP_()
        expect_true((LosslessArithmeticConvertible[LongDouble, Double]::value))
    else:
        expect_false((LosslessArithmeticConvertible[LongDouble, Double]::value))

# TEST(TupleMatchesTest, WorksForSize0)
def test_TupleMatchesTest_WorksForSize0() -> None:
    var matchers: Tuple[None] = (None,)
    var values: Tuple[None] = (None,)
    expect_true(TupleMatches(matchers, values))

# TEST(TupleMatchesTest, WorksForSize1)
def test_TupleMatchesTest_WorksForSize1() -> None:
    var matchers: Tuple[Matcher[Int]] = (Eq(1),)
    var values1: Tuple[Int] = (1,), values2: Tuple[Int] = (2,)
    expect_true(TupleMatches(matchers, values1))
    expect_false(TupleMatches(matchers, values2))

# TEST(TupleMatchesTest, WorksForSize2)
def test_TupleMatchesTest_WorksForSize2() -> None:
    var matchers: Tuple[Matcher[Int], Matcher[Char]] = (Eq(1), Eq('a'))
    var values1: Tuple[Int, Char] = (1, 'a'), values2: Tuple[Int, Char] = (1, 'b'), values3: Tuple[Int, Char] = (2, 'a'), values4: Tuple[Int, Char] = (2, 'b')
    expect_true(TupleMatches(matchers, values1))
    expect_false(TupleMatches(matchers, values2))
    expect_false(TupleMatches(matchers, values3))
    expect_false(TupleMatches(matchers, values4))

# TEST(TupleMatchesTest, WorksForSize5)
def test_TupleMatchesTest_WorksForSize5() -> None:
    var matchers: Tuple[Matcher[Int], Matcher[Char], Matcher[Bool], Matcher[Long], Matcher[String]] = (
        Eq(1), Eq('a'), Eq(True), Eq(2L), Eq("hi")
    )
    var values1: Tuple[Int, Char, Bool, Long, String] = (1, 'a', True, 2L, "hi")
    var values2: Tuple[Int, Char, Bool, Long, String] = (1, 'a', True, 2L, "hello")
    var values3: Tuple[Int, Char, Bool, Long, String] = (2, 'a', True, 2L, "hi")
    expect_true(TupleMatches(matchers, values1))
    expect_false(TupleMatches(matchers, values2))
    expect_false(TupleMatches(matchers, values3))

# TEST(AssertTest, SucceedsOnTrue)
def test_AssertTest_SucceedsOnTrue() -> None:
    Assert(True, __FILE__, __LINE__, "This should succeed.")
    Assert(True, __FILE__, __LINE__)  # This should succeed too.

# TEST(AssertTest, FailsFatallyOnFalse)
def test_AssertTest_FailsFatallyOnFalse() -> None:
    expect_death_if_supported({
        Assert(False, __FILE__, __LINE__, "This should fail.")
    }, "")
    expect_death_if_supported({
        Assert(False, __FILE__, __LINE__)
    }, "")

# TEST(ExpectTest, SucceedsOnTrue)
def test_ExpectTest_SucceedsOnTrue() -> None:
    Expect(True, __FILE__, __LINE__, "This should succeed.")
    Expect(True, __FILE__, __LINE__)  # This should succeed too.

# TEST(ExpectTest, FailsNonfatallyOnFalse)
def test_ExpectTest_FailsNonfatallyOnFalse() -> None:
    expect_nonfatal_failure({  # NOLINT
        Expect(False, __FILE__, __LINE__, "This should fail.")
    }, "This should fail")
    expect_nonfatal_failure({  # NOLINT
        Expect(False, __FILE__, __LINE__)
    }, "Expectation failed")

class LogIsVisibleTest(::testing::Test):
 protected:
    def SetUp() override:
        original_verbose_ = GMOCK_FLAG(verbose)
    def TearDown() override:
        GMOCK_FLAG(verbose) = original_verbose_
    var original_verbose_: String

# TEST_F(LogIsVisibleTest, AlwaysReturnsTrueIfVerbosityIsInfo)
def test_LogIsVisibleTest_AlwaysReturnsTrueIfVerbosityIsInfo() -> None:
    GMOCK_FLAG(verbose) = kInfoVerbosity
    expect_true(LogIsVisible(kInfo))
    expect_true(LogIsVisible(kWarning))

# TEST_F(LogIsVisibleTest, AlwaysReturnsFalseIfVerbosityIsError)
def test_LogIsVisibleTest_AlwaysReturnsFalseIfVerbosityIsError() -> None:
    GMOCK_FLAG(verbose) = kErrorVerbosity
    expect_false(LogIsVisible(kInfo))
    expect_false(LogIsVisible(kWarning))

# TEST_F(LogIsVisibleTest, WorksWhenVerbosityIsWarning)
def test_LogIsVisibleTest_WorksWhenVerbosityIsWarning() -> None:
    GMOCK_FLAG(verbose) = kWarningVerbosity
    expect_false(LogIsVisible(kInfo))
    expect_true(LogIsVisible(kWarning))

# if GTEST_HAS_STREAM_REDIRECTION
var GTEST_HAS_STREAM_REDIRECTION = True

def TestLogWithSeverity(verbosity: String, severity: LogSeverity, should_print: Bool) -> None:
    const old_flag: String = GMOCK_FLAG(verbose)
    GMOCK_FLAG(verbose) = verbosity
    CaptureStdout()
    Log(severity, "Test log.\n", 0)
    if should_print:
        expect_that(GetCapturedStdout().c_str(),
                    ContainsRegex(
                        severity == kWarning ? 
                        "^\nGMOCK WARNING:\nTest log\\.\nStack trace:\n" :
                        "^\nTest log\\.\nStack trace:\n"))
    else:
        expect_streq("", GetCapturedStdout().c_str())
    GMOCK_FLAG(verbose) = old_flag

# TEST(LogTest, NoStackTraceWhenStackFramesToSkipIsNegative)
def test_LogTest_NoStackTraceWhenStackFramesToSkipIsNegative() -> None:
    const saved_flag: String = GMOCK_FLAG(verbose)
    GMOCK_FLAG(verbose) = kInfoVerbosity
    CaptureStdout()
    Log(kInfo, "Test log.\n", -1)
    expect_streq("\nTest log.\n", GetCapturedStdout().c_str())
    GMOCK_FLAG(verbose) = saved_flag

struct MockStackTraceGetter(testing::internal::OsStackTraceGetterInterface):
    def CurrentStackTrace(max_depth: Int, skip_count: Int) -> String override:
        return (testing::Message() << max_depth << "::" << skip_count << "\n").GetString()
    def UponLeavingGTest() override:

# TEST(LogTest, NoSkippingStackFrameInOptMode)
def test_LogTest_NoSkippingStackFrameInOptMode() -> None:
    var mock_os_stack_trace_getter: MockStackTraceGetter = MockStackTraceGetter()
    GetUnitTestImpl().set_os_stack_trace_getter(unsafe_ptr(mock_os_stack_trace_getter))
    CaptureStdout()
    Log(kWarning, "Test log.\n", 100)
    const log: String = GetCapturedStdout()
    var expected_trace: String = (testing::Message() << GTEST_FLAG(stack_trace_depth) << "::").GetString()
    var expected_message: String = "\nGMOCK WARNING:\n" + \
                                   "Test log.\n" + \
                                   "Stack trace:\n" + \
                                   expected_trace
    expect_that(log, HasSubstr(expected_message))
    var skip_count: Int = Int64(log.substr(expected_message.size())).to_int()  # Original: atoi(log.substr(expected_message.size()).c_str())
    if defined(NDEBUG):
        const expected_skip_count: Int = 0
    else:
        const expected_skip_count: Int = 100
    expect_that(skip_count,
                AllOf(Ge(expected_skip_count), Le(expected_skip_count + 10)))
    GetUnitTestImpl().set_os_stack_trace_getter(null)

# TEST(LogTest, AllLogsArePrintedWhenVerbosityIsInfo)
def test_LogTest_AllLogsArePrintedWhenVerbosityIsInfo() -> None:
    TestLogWithSeverity(kInfoVerbosity, kInfo, True)
    TestLogWithSeverity(kInfoVerbosity, kWarning, True)

# TEST(LogTest, OnlyWarningsArePrintedWhenVerbosityIsWarning)
def test_LogTest_OnlyWarningsArePrintedWhenVerbosityIsWarning() -> None:
    TestLogWithSeverity(kWarningVerbosity, kInfo, False)
    TestLogWithSeverity(kWarningVerbosity, kWarning, True)

# TEST(LogTest, NoLogsArePrintedWhenVerbosityIsError)
def test_LogTest_NoLogsArePrintedWhenVerbosityIsError() -> None:
    TestLogWithSeverity(kErrorVerbosity, kInfo, False)
    TestLogWithSeverity(kErrorVerbosity, kWarning, False)

# TEST(LogTest, OnlyWarningsArePrintedWhenVerbosityIsInvalid)
def test_LogTest_OnlyWarningsArePrintedWhenVerbosityIsInvalid() -> None:
    TestLogWithSeverity("invalid", kInfo, False)
    TestLogWithSeverity("invalid", kWarning, True)

def GrabOutput(logger: fn(), verbosity: String) -> String:
    const saved_flag: String = GMOCK_FLAG(verbose)
    GMOCK_FLAG(verbose) = verbosity
    CaptureStdout()
    logger()
    GMOCK_FLAG(verbose) = saved_flag
    return GetCapturedStdout()

class DummyMock:
    def TestMethod() -> None: ...
    def TestMethodArg(dummy: Int) -> None: ...

def ExpectCallLogger() -> None:
    var mock: DummyMock = DummyMock()
    expect_call(mock, TestMethod())
    mock.TestMethod()

# TEST(ExpectCallTest, LogsWhenVerbosityIsInfo)
def test_ExpectCallTest_LogsWhenVerbosityIsInfo() -> None:
    expect_that(String(GrabOutput(ExpectCallLogger, kInfoVerbosity)),
                HasSubstr("EXPECT_CALL(mock, TestMethod())"))

# TEST(ExpectCallTest, DoesNotLogWhenVerbosityIsWarning)
def test_ExpectCallTest_DoesNotLogWhenVerbosityIsWarning() -> None:
    expect_streq("", GrabOutput(ExpectCallLogger, kWarningVerbosity).c_str())

# TEST(ExpectCallTest,  DoesNotLogWhenVerbosityIsError)
def test_ExpectCallTest_DoesNotLogWhenVerbosityIsError() -> None:
    expect_streq("", GrabOutput(ExpectCallLogger, kErrorVerbosity).c_str())

def OnCallLogger() -> None:
    var mock: DummyMock = DummyMock()
    on_call(mock, TestMethod())

# TEST(OnCallTest, LogsWhenVerbosityIsInfo)
def test_OnCallTest_LogsWhenVerbosityIsInfo() -> None:
    expect_that(String(GrabOutput(OnCallLogger, kInfoVerbosity)),
                HasSubstr("ON_CALL(mock, TestMethod())"))

# TEST(OnCallTest, DoesNotLogWhenVerbosityIsWarning)
def test_OnCallTest_DoesNotLogWhenVerbosityIsWarning() -> None:
    expect_streq("", GrabOutput(OnCallLogger, kWarningVerbosity).c_str())

# TEST(OnCallTest, DoesNotLogWhenVerbosityIsError)
def test_OnCallTest_DoesNotLogWhenVerbosityIsError() -> None:
    expect_streq("", GrabOutput(OnCallLogger, kErrorVerbosity).c_str())

def OnCallAnyArgumentLogger() -> None:
    var mock: DummyMock = DummyMock()
    on_call(mock, TestMethodArg(_))

# TEST(OnCallTest, LogsAnythingArgument)
def test_OnCallTest_LogsAnythingArgument() -> None:
    expect_that(String(GrabOutput(OnCallAnyArgumentLogger, kInfoVerbosity)),
                HasSubstr("ON_CALL(mock, TestMethodArg(_)"))

# endif  // GTEST_HAS_STREAM_REDIRECTION

# TEST(StlContainerViewTest, WorksForStlContainer)
def test_StlContainerViewTest_WorksForStlContainer() -> None:
    StaticAssertTypeEq[List[Int], StlContainerView[List[Int]]::type]()
    StaticAssertTypeEq[constref List[Double], StlContainerView[List[Double]]::const_reference]()
    alias Chars = List[Char]
    var v1: Chars = Chars()
    const v2: constref Chars = StlContainerView[Chars]::ConstReference(v1)
    expect_eq(unsafe_ptr(v1), unsafe_ptr(v2))
    v1.push_back('a')
    var v3: Chars = StlContainerView[Chars]::Copy(v1)
    expect_that(v3, Eq(v3))

# TEST(StlContainerViewTest, WorksForStaticNativeArray)
def test_StlContainerViewTest_WorksForStaticNativeArray() -> None:
    StaticAssertTypeEq[NativeArray[Int], StlContainerView[Int[3]]::type]()
    StaticAssertTypeEq[NativeArray[Double], StlContainerView[const Double[4]]::type]()
    StaticAssertTypeEq[NativeArray[Char[3]], StlContainerView[const Char[2][3]]::type]()
    StaticAssertTypeEq[const NativeArray[Int], StlContainerView[Int[2]]::const_reference]()
    var a1: Int[3] = [0, 1, 2]
    var a2: NativeArray[Int] = StlContainerView[Int[3]]::ConstReference(a1)
    expect_eq(3U, a2.size())
    expect_eq(unsafe_ptr(a1), a2.begin())
    const a3: NativeArray[Int] = StlContainerView[Int[3]]::Copy(a1)
    assert_eq(3U, a3.size())
    expect_eq(0, a3.begin()[0])
    expect_eq(1, a3.begin()[1])
    expect_eq(2, a3.begin()[2])
    a1[0] = 3
    expect_eq(0, a3.begin()[0])

# TEST(StlContainerViewTest, WorksForDynamicNativeArray)
def test_StlContainerViewTest_WorksForDynamicNativeArray() -> None:
    StaticAssertTypeEq[NativeArray[Int], StlContainerView[Tuple[const IntPointer, Size]]::type]()
    StaticAssertTypeEq[NativeArray[Double], StlContainerView[Tuple[SharedPointer[Double], Int]]::type]()
    StaticAssertTypeEq[const NativeArray[Int], StlContainerView[Tuple[const IntPointer, Int]]::const_reference]()
    var a1: Int[3] = [0, 1, 2]
    const p1: const IntPointer = unsafe_ptr(a1)
    var a2: NativeArray[Int] = StlContainerView[Tuple[const IntPointer, Int]]::ConstReference(
        make_tuple(p1, 3))
    expect_eq(3U, a2.size())
    expect_eq(unsafe_ptr(a1), a2.begin())
    const a3: NativeArray[Int] = StlContainerView[Tuple[IntPointer, Size]]::Copy(
        make_tuple(unsafe_ptr[Int](a1), 3))
    assert_eq(3U, a3.size())
    expect_eq(0, a3.begin()[0])
    expect_eq(1, a3.begin()[1])
    expect_eq(2, a3.begin()[2])
    a1[0] = 3
    expect_eq(0, a3.begin()[0])

# TEST(FunctionTest, Nullary)
def test_FunctionTest_Nullary() -> None:
    alias F = Function[Int()]
    expect_eq(0u, F::ArgumentCount)
    expect_true((is_same[Int, F::Result]::value))
    expect_true((is_same[Tuple[], F::ArgumentTuple]::value))
    expect_true((is_same[Tuple[], F::ArgumentMatcherTuple]::value))
    expect_true((is_same[Void(), F::MakeResultVoid]::value))
    expect_true((is_same[IgnoredValue(), F::MakeResultIgnoredValue]::value))

# TEST(FunctionTest, Unary)
def test_FunctionTest_Unary() -> None:
    alias F = Function[Int(Bool)]
    expect_eq(1u, F::ArgumentCount)
    expect_true((is_same[Int, F::Result]::value))
    expect_true((is_same[Bool, F::Arg[0]::type]::value))
    expect_true((is_same[Tuple[Bool], F::ArgumentTuple]::value))
    expect_true((is_same[Tuple[Matcher[Bool]], F::ArgumentMatcherTuple]::value))
    expect_true((is_same[Void(Bool), F::MakeResultVoid]::value))  # NOLINT
    expect_true((is_same[IgnoredValue(Bool), F::MakeResultIgnoredValue]::value))

# TEST(FunctionTest, Binary)
def test_FunctionTest_Binary() -> None:
    alias F = Function[Int(Bool, const LongPointer&)]
    expect_eq(2u, F::ArgumentCount)
    expect_true((is_same[Int, F::Result]::value))
    expect_true((is_same[Bool, F::Arg[0]::type]::value))
    expect_true((is_same[const LongPointer&, F::Arg[1]::type]::value))  # NOLINT
    expect_true((is_same[Tuple[Bool, const LongPointer&], F::ArgumentTuple]::value))
    expect_true((is_same[Tuple[Matcher[Bool], Matcher[const LongPointer&]], F::ArgumentMatcherTuple]::value))
    expect_true((is_same[Void(Bool, const LongPointer&), F::MakeResultVoid]::value))
    expect_true((is_same[IgnoredValue(Bool, const LongPointer&), F::MakeResultIgnoredValue]::value))

# TEST(FunctionTest, LongArgumentList)
def test_FunctionTest_LongArgumentList() -> None:
    alias F = Function[Char(Bool, Int, CharPointer, Int&, const LongPointer&)]
    expect_eq(5u, F::ArgumentCount)
    expect_true((is_same[Char, F::Result]::value))
    expect_true((is_same[Bool, F::Arg[0]::type]::value))
    expect_true((is_same[Int, F::Arg[1]::type]::value))
    expect_true((is_same[CharPointer, F::Arg[2]::type]::value))
    expect_true((is_same[Int&, F::Arg[3]::type]::value))
    expect_true((is_same[const LongPointer&, F::Arg[4]::type]::value))  # NOLINT
    expect_true((is_same[Tuple[Bool, Int, CharPointer, Int&, const LongPointer&], F::ArgumentTuple]::value))
    expect_true((is_same[Tuple[Matcher[Bool], Matcher[Int], Matcher[CharPointer], Matcher[Int&], Matcher[const LongPointer&]], F::ArgumentMatcherTuple]::value))
    expect_true((is_same[Void(Bool, Int, CharPointer, Int&, const LongPointer&), F::MakeResultVoid]::value))
    expect_true((is_same[IgnoredValue(Bool, Int, CharPointer, Int&, const LongPointer&), F::MakeResultIgnoredValue]::value))

# }  // namespace
# }  // namespace internal
# }  // namespace testing