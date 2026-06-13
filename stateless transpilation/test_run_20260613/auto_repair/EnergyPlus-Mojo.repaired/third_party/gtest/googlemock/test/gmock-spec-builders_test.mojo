from gmock.gmock-spec-builders import *
from memory import *
from io import *
from sstream import *
from string import *
from gmock.gmock import *
from gmock.internal.gmock-port import *
from gtest.gtest import *
from gtest.gtest-spi import *
from gtest.internal.gtest-port import *

namespace testing:
    namespace internal:
        class ExpectationTester:
            def SetCallCount(self, n: Int, exp: ExpectationBase):
                exp.call_count_ = n

namespace:
    using testing._
    using testing.AnyNumber
    using testing.AtLeast
    using testing.AtMost
    using testing.Between
    using testing.Cardinality
    using testing.CardinalityInterface
    using testing.Const
    using testing.ContainsRegex
    using testing.DoAll
    using testing.DoDefault
    using testing.Eq
    using testing.Expectation
    using testing.ExpectationSet
    using testing.GMOCK_FLAG(verbose)
    using testing.Gt
    using testing.IgnoreResult
    using testing.InSequence
    using testing.Invoke
    using testing.InvokeWithoutArgs
    using testing.IsNotSubstring
    using testing.IsSubstring
    using testing.Lt
    using testing.Message
    using testing.Mock
    using testing.NaggyMock
    using testing.Ne
    using testing.Return
    using testing.SaveArg
    using testing.Sequence
    using testing.SetArgPointee
    using testing.internal.ExpectationTester
    using testing.internal.FormatFileLocation
    using testing.internal.kAllow
    using testing.internal.kErrorVerbosity
    using testing.internal.kFail
    using testing.internal.kInfoVerbosity
    using testing.internal.kWarn
    using testing.internal.kWarningVerbosity
    #if GTEST_HAS_STREAM_REDIRECTION
    using testing.HasSubstr
    using testing.internal.CaptureStdout
    using testing.internal.GetCapturedStdout
    #endif

    class Incomplete:

    class MockIncomplete:
        def __init__(self):

        def ByRefFunc(self, x: Incomplete&):

    def PrintTo(x: Incomplete&, os: ::ostream*):

    @testing.Test
    def MockMethodTest_CanInstantiateWithIncompleteArgType():
        var incomplete = MockIncomplete()
        EXPECT_CALL(incomplete, ByRefFunc(_)).Times(AnyNumber())

    def PrintTo(x: Incomplete&, os: ::ostream*):
        *os << "incomplete"

    class Result:

    class NonDefaultConstructible:
        def __init__(self, dummy: Int):

    class MockA:
        def __init__(self):

        def DoA(self, n: Int):

        def ReturnResult(self, n: Int) -> Result:

        def ReturnNonDefaultConstructible(self) -> NonDefaultConstructible:

        def Binary(self, x: Int, y: Int) -> Bool:

        def ReturnInt(self, x: Int, y: Int) -> Int:

    class MockB:
        def __init__(self):

        def DoB(self) -> Int:

        def DoB(self, n: Int) -> Int:

    class ReferenceHoldingMock:
        def __init__(self):

        def AcceptReference(self, ptr: shared_ptr<MockA>*):

    #define Method MethodW
    class CC:
        def __del__(self):

        def Method(self) -> Int:

    class MockCC(CC):
        def __init__(self):

        def Method(self) -> Int:

    @testing.Test
    def OnCallSyntaxTest_CompilesWithMethodNameExpandedFromMacro():
        var cc = MockCC()
        ON_CALL(cc, Method())

    @testing.Test
    def OnCallSyntaxTest_WorksWithMethodNameExpandedFromMacro():
        var cc = MockCC()
        ON_CALL(cc, Method()).WillByDefault(Return(42))
        EXPECT_EQ(42, cc.Method())

    @testing.Test
    def ExpectCallSyntaxTest_CompilesWithMethodNameExpandedFromMacro():
        var cc = MockCC()
        EXPECT_CALL(cc, Method())
        cc.Method()

    @testing.Test
    def ExpectCallSyntaxTest_WorksWithMethodNameExpandedFromMacro():
        var cc = MockCC()
        EXPECT_CALL(cc, Method()).WillOnce(Return(42))
        EXPECT_EQ(42, cc.Method())

    #undef Method

    @testing.Test
    def OnCallSyntaxTest_EvaluatesFirstArgumentOnce():
        var a = MockA()
        var pa: MockA* = &a
        ON_CALL(*pa++, DoA(_))
        EXPECT_EQ(&a + 1, pa)

    @testing.Test
    def OnCallSyntaxTest_EvaluatesSecondArgumentOnce():
        var a = MockA()
        var n: Int = 0
        ON_CALL(a, DoA(n++))
        EXPECT_EQ(1, n)

    @testing.Test
    def OnCallSyntaxTest_WithIsOptional():
        var a = MockA()
        ON_CALL(a, DoA(5)).WillByDefault(Return())
        ON_CALL(a, DoA(_)).With(_).WillByDefault(Return())

    @testing.Test
    def OnCallSyntaxTest_WithCanAppearAtMostOnce():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            ON_CALL(a, ReturnResult(_)).With(_).With(_).WillByDefault(Return(Result()))
        }, ".With() cannot appear more than once in an ON_CALL()")

    @testing.Test
    def OnCallSyntaxTest_WillByDefaultIsMandatory():
        var a = MockA()
        EXPECT_DEATH_IF_SUPPORTED({
            ON_CALL(a, DoA(5))
            a.DoA(5)
        }, "")

    @testing.Test
    def OnCallSyntaxTest_WillByDefaultCanAppearAtMostOnce():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            ON_CALL(a, DoA(5)).WillByDefault(Return()).WillByDefault(Return())
        }, ".WillByDefault() must appear exactly once in an ON_CALL()")

    @testing.Test
    def ExpectCallSyntaxTest_EvaluatesFirstArgumentOnce():
        var a = MockA()
        var pa: MockA* = &a
        EXPECT_CALL(*pa++, DoA(_))
        a.DoA(0)
        EXPECT_EQ(&a + 1, pa)

    @testing.Test
    def ExpectCallSyntaxTest_EvaluatesSecondArgumentOnce():
        var a = MockA()
        var n: Int = 0
        EXPECT_CALL(a, DoA(n++))
        a.DoA(0)
        EXPECT_EQ(1, n)

    @testing.Test
    def ExpectCallSyntaxTest_WithIsOptional():
        var a = MockA()
        EXPECT_CALL(a, DoA(5)).Times(0)
        EXPECT_CALL(a, DoA(6)).With(_).Times(0)

    @testing.Test
    def ExpectCallSyntaxTest_WithCanAppearAtMostOnce():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(6)).With(_).With(_)
        }, ".With() cannot appear more than once in an EXPECT_CALL()")
        a.DoA(6)

    @testing.Test
    def ExpectCallSyntaxTest_WithMustBeFirstClause():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).Times(1).With(_)
        }, ".With() must be the first clause in an EXPECT_CALL()")
        a.DoA(1)
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(2)).WillOnce(Return()).With(_)
        }, ".With() must be the first clause in an EXPECT_CALL()")
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_TimesCanBeInferred():
        var a = MockA()
        EXPECT_CALL(a, DoA(1)).WillOnce(Return())
        EXPECT_CALL(a, DoA(2)).WillOnce(Return()).WillRepeatedly(Return())
        a.DoA(1)
        a.DoA(2)
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_TimesCanAppearAtMostOnce():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).Times(1).Times(2)
        }, ".Times() cannot appear more than once in an EXPECT_CALL()")
        a.DoA(1)
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_TimesMustBeBeforeInSequence():
        var a = MockA()
        var s = Sequence()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).InSequence(s).Times(1)
        }, ".Times() cannot appear after ")
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_InSequenceIsOptional():
        var a = MockA()
        var s = Sequence()
        EXPECT_CALL(a, DoA(1))
        EXPECT_CALL(a, DoA(2)).InSequence(s)
        a.DoA(1)
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_InSequenceCanAppearMultipleTimes():
        var a = MockA()
        var s1 = Sequence()
        var s2 = Sequence()
        EXPECT_CALL(a, DoA(1)).InSequence(s1, s2).InSequence(s1)
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_InSequenceMustBeBeforeAfter():
        var a = MockA()
        var s = Sequence()
        var e: Expectation = EXPECT_CALL(a, DoA(1)).Times(AnyNumber())
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(2)).After(e).InSequence(s)
        }, ".InSequence() cannot appear after ")
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_InSequenceMustBeBeforeWillOnce():
        var a = MockA()
        var s = Sequence()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).WillOnce(Return()).InSequence(s)
        }, ".InSequence() cannot appear after ")
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_AfterMustBeBeforeWillOnce():
        var a = MockA()
        var e: Expectation = EXPECT_CALL(a, DoA(1))
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(2)).WillOnce(Return()).After(e)
        }, ".After() cannot appear after ")
        a.DoA(1)
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_WillIsOptional():
        var a = MockA()
        EXPECT_CALL(a, DoA(1))
        EXPECT_CALL(a, DoA(2)).WillOnce(Return())
        a.DoA(1)
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_WillCanAppearMultipleTimes():
        var a = MockA()
        EXPECT_CALL(a, DoA(1)).Times(AnyNumber()).WillOnce(Return()).WillOnce(Return()).WillOnce(Return())

    @testing.Test
    def ExpectCallSyntaxTest_WillMustBeBeforeWillRepeatedly():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).WillRepeatedly(Return()).WillOnce(Return())
        }, ".WillOnce() cannot appear after ")
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_WillRepeatedlyIsOptional():
        var a = MockA()
        EXPECT_CALL(a, DoA(1)).WillOnce(Return())
        EXPECT_CALL(a, DoA(2)).WillOnce(Return()).WillRepeatedly(Return())
        a.DoA(1)
        a.DoA(2)
        a.DoA(2)

    @testing.Test
    def ExpectCallSyntaxTest_WillRepeatedlyCannotAppearMultipleTimes():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).WillRepeatedly(Return()).WillRepeatedly(Return())
        }, ".WillRepeatedly() cannot appear more than once in an EXPECT_CALL()")

    @testing.Test
    def ExpectCallSyntaxTest_WillRepeatedlyMustBeBeforeRetiresOnSaturation():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).RetiresOnSaturation().WillRepeatedly(Return())
        }, ".WillRepeatedly() cannot appear after ")

    @testing.Test
    def ExpectCallSyntaxTest_RetiresOnSaturationIsOptional():
        var a = MockA()
        EXPECT_CALL(a, DoA(1))
        EXPECT_CALL(a, DoA(1)).RetiresOnSaturation()
        a.DoA(1)
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_RetiresOnSaturationCannotAppearMultipleTimes():
        var a = MockA()
        EXPECT_NONFATAL_FAILURE({
            EXPECT_CALL(a, DoA(1)).RetiresOnSaturation().RetiresOnSaturation()
        }, ".RetiresOnSaturation() cannot appear more than once")
        a.DoA(1)

    @testing.Test
    def ExpectCallSyntaxTest_DefaultCardinalityIsOnce():
        {
            var a = MockA()
            EXPECT_CALL(a, DoA(1))
            a.DoA(1)
        }
        EXPECT_NONFATAL_FAILURE({
            var a = MockA()
            EXPECT_CALL(a, DoA(1))
        }, "to be called once")
        EXPECT_NONFATAL_FAILURE({
            var a = MockA()
            EXPECT_CALL(a, DoA(1))
            a.DoA(1)
            a.DoA(1)
        }, "to be called once")

    #if GTEST_HAS_STREAM_REDIRECTION
    @testing.Test
    def ExpectCallSyntaxTest_DoesNotWarnOnAdequateActionCount():
        CaptureStdout()
        {
            var b = MockB()
            EXPECT_CALL(b, DoB()).Times(0)
            EXPECT_CALL(b, DoB(1)).Times(AtMost(1))
            EXPECT_CALL(b, DoB(2)).Times(1).WillRepeatedly(Return(1))
            EXPECT_CALL(b, DoB(3)).Times(Between(1, 2)).WillOnce(Return(1)).WillOnce(Return(2))
            EXPECT_CALL(b, DoB(4)).Times(AtMost(3)).WillOnce(Return(1)).WillRepeatedly(Return(2))
            b.DoB(2)
            b.DoB(3)
        }
        EXPECT_STREQ("", GetCapturedStdout().c_str())

    @testing.Test
    def ExpectCallSyntaxTest_WarnsOnTooManyActions():
        CaptureStdout()
        {
            var b = MockB()
            EXPECT_CALL(b, DoB()).Times(0).WillOnce(Return(1))
            EXPECT_CALL(b, DoB()).Times(AtMost(1)).WillOnce(Return(1)).WillOnce(Return(2))
            EXPECT_CALL(b, DoB(1)).Times(1).WillOnce(Return(1)).WillOnce(Return(2)).RetiresOnSaturation()
            EXPECT_CALL(b, DoB()).Times(0).WillRepeatedly(Return(1))
            EXPECT_CALL(b, DoB(2)).Times(1).WillOnce(Return(1)).WillRepeatedly(Return(2))
            b.DoB(1)
            b.DoB(2)
        }
        var output: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "Too many actions specified in EXPECT_CALL(b, DoB())...\nExpected to be never called, but has 1 WillOnce().", output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Too many actions specified in EXPECT_CALL(b, DoB())...\nExpected to be called at most once, but has 2 WillOnce()s.", output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Too many actions specified in EXPECT_CALL(b, DoB(1))...\nExpected to be called once, but has 2 WillOnce()s.", output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Too many actions specified in EXPECT_CALL(b, DoB())...\nExpected to be never called, but has 0 WillOnce()s and a WillRepeatedly().", output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Too many actions specified in EXPECT_CALL(b, DoB(2))...\nExpected to be called once, but has 1 WillOnce() and a WillRepeatedly().", output)

    @testing.Test
    def ExpectCallSyntaxTest_WarnsOnTooFewActions():
        var b = MockB()
        EXPECT_CALL(b, DoB()).Times(Between(2, 3)).WillOnce(Return(1))
        CaptureStdout()
        b.DoB()
        var output: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "Too few actions specified in EXPECT_CALL(b, DoB())...\nExpected to be called between 2 and 3 times, but has only 1 WillOnce().", output)
        b.DoB()

    @testing.Test
    def ExpectCallSyntaxTest_WarningIsErrorWithFlag():
        var original_behavior: Int = testing.GMOCK_FLAG(default_mock_behavior)
        testing.GMOCK_FLAG(default_mock_behavior) = kAllow
        CaptureStdout()
        {
            var a = MockA()
            a.DoA(0)
        }
        var output: std.string = GetCapturedStdout()
        EXPECT_TRUE(output.empty()) if output else True
        testing.GMOCK_FLAG(default_mock_behavior) = kWarn
        CaptureStdout()
        {
            var a = MockA()
            a.DoA(0)
        }
        var warning_output: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "GMOCK WARNING", warning_output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Uninteresting mock function call", warning_output)
        testing.GMOCK_FLAG(default_mock_behavior) = kFail
        EXPECT_NONFATAL_FAILURE({
            var a = MockA()
            a.DoA(0)
        }, "Uninteresting mock function call")
        testing.GMOCK_FLAG(default_mock_behavior) = -1
        CaptureStdout()
        {
            var a = MockA()
            a.DoA(0)
        }
        warning_output = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "GMOCK WARNING", warning_output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Uninteresting mock function call", warning_output)
        testing.GMOCK_FLAG(default_mock_behavior) = 3
        CaptureStdout()
        {
            var a = MockA()
            a.DoA(0)
        }
        warning_output = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "GMOCK WARNING", warning_output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Uninteresting mock function call", warning_output)
        testing.GMOCK_FLAG(default_mock_behavior) = original_behavior
    #endif

    @testing.Test
    def OnCallTest_TakesBuiltInDefaultActionWhenNoOnCall():
        var b = MockB()
        EXPECT_CALL(b, DoB())
        EXPECT_EQ(0, b.DoB())

    @testing.Test
    def OnCallTest_TakesBuiltInDefaultActionWhenNoOnCallMatches():
        var b = MockB()
        ON_CALL(b, DoB(1)).WillByDefault(Return(1))
        EXPECT_CALL(b, DoB(_))
        EXPECT_EQ(0, b.DoB(2))

    @testing.Test
    def OnCallTest_PicksLastMatchingOnCall():
        var b = MockB()
        ON_CALL(b, DoB(_)).WillByDefault(Return(3))
        ON_CALL(b, DoB(2)).WillByDefault(Return(2))
        ON_CALL(b, DoB(1)).WillByDefault(Return(1))
        EXPECT_CALL(b, DoB(_))
        EXPECT_EQ(2, b.DoB(2))

    @testing.Test
    def ExpectCallTest_AllowsAnyCallWhenNoSpec():
        var b = MockB()
        EXPECT_CALL(b, DoB())
        b.DoB()
        b.DoB(1)
        b.DoB(2)

    @testing.Test
    def ExpectCallTest_PicksLastMatchingExpectCall():
        var b = MockB()
        EXPECT_CALL(b, DoB(_)).WillRepeatedly(Return(2))
        EXPECT_CALL(b, DoB(1)).WillRepeatedly(Return(1))
        EXPECT_EQ(1, b.DoB(1))

    @testing.Test
    def ExpectCallTest_CatchesTooFewCalls():
        EXPECT_NONFATAL_FAILURE({
            var b = MockB()
            EXPECT_CALL(b, DoB(5)).Times(AtLeast(2))
            b.DoB(5)
        }, "Actual function call count doesn't match EXPECT_CALL(b, DoB(5))...\n         Expected: to be called at least twice\n           Actual: called once - unsatisfied and active")

    @testing.Test
    def ExpectCallTest_InfersCardinalityWhenThereIsNoWillRepeatedly():
        {
            var b = MockB()
            EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillOnce(Return(2))
            EXPECT_EQ(1, b.DoB())
            EXPECT_EQ(2, b.DoB())
        }
        EXPECT_NONFATAL_FAILURE({
            var b = MockB()
            EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillOnce(Return(2))
            EXPECT_EQ(1, b.DoB())
        }, "to be called twice")
        {
            var b = MockB()
            EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillOnce(Return(2))
            EXPECT_EQ(1, b.DoB())
            EXPECT_EQ(2, b.DoB())
            EXPECT_NONFATAL_FAILURE(b.DoB(), "to be called twice")
        }

    @testing.Test
    def ExpectCallTest_InfersCardinality1WhenThereIsWillRepeatedly():
        {
            var b = MockB()
            EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillRepeatedly(Return(2))
            EXPECT_EQ(1, b.DoB())
        }
        {
            var b = MockB()
            EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillRepeatedly(Return(2))
            EXPECT_EQ(1, b.DoB())
            EXPECT_EQ(2, b.DoB())
            EXPECT_EQ(2, b.DoB())
        }
        EXPECT_NONFATAL_FAILURE({
            var b = MockB()
            EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillRepeatedly(Return(2))
        }, "to be called at least once")

    @testing.Test
    def ExpectCallTest_NthMatchTakesNthAction():
        var b = MockB()
        EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillOnce(Return(2)).WillOnce(Return(3))
        EXPECT_EQ(1, b.DoB())
        EXPECT_EQ(2, b.DoB())
        EXPECT_EQ(3, b.DoB())

    @testing.Test
    def ExpectCallTest_TakesRepeatedActionWhenWillListIsExhausted():
        var b = MockB()
        EXPECT_CALL(b, DoB()).WillOnce(Return(1)).WillRepeatedly(Return(2))
        EXPECT_EQ(1, b.DoB())
        EXPECT_EQ(2, b.DoB())
        EXPECT_EQ(2, b.DoB())

    #if GTEST_HAS_STREAM_REDIRECTION
    @testing.Test
    def ExpectCallTest_TakesDefaultActionWhenWillListIsExhausted():
        var b = MockB()
        EXPECT_CALL(b, DoB(_)).Times(1)
        EXPECT_CALL(b, DoB()).Times(AnyNumber()).WillOnce(Return(1)).WillOnce(Return(2))
        CaptureStdout()
        EXPECT_EQ(0, b.DoB(1))
        EXPECT_EQ(1, b.DoB())
        EXPECT_EQ(2, b.DoB())
        var output1: std.string = GetCapturedStdout()
        EXPECT_STREQ("", output1.c_str())
        CaptureStdout()
        EXPECT_EQ(0, b.DoB())
        EXPECT_EQ(0, b.DoB())
        var output2: std.string = GetCapturedStdout()
        EXPECT_THAT(output2.c_str(), HasSubstr("Actions ran out in EXPECT_CALL(b, DoB())...\nCalled 3 times, but only 2 WillOnce()s are specified - returning default value."))
        EXPECT_THAT(output2.c_str(), HasSubstr("Actions ran out in EXPECT_CALL(b, DoB())...\nCalled 4 times, but only 2 WillOnce()s are specified - returning default value."))

    @testing.Test
    def FunctionMockerMessageTest_ReportsExpectCallLocationForExhausedActions():
        var b = MockB()
        var expect_call_location: std.string = FormatFileLocation(__FILE__, __LINE__ + 1)
        EXPECT_CALL(b, DoB()).Times(AnyNumber()).WillOnce(Return(1))
        EXPECT_EQ(1, b.DoB())
        CaptureStdout()
        EXPECT_EQ(0, b.DoB())
        var output: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, expect_call_location, output)

    @testing.Test
    def FunctionMockerMessageTest_ReportsDefaultActionLocationOfUninterestingCallsForNaggyMock():
        var on_call_location: std.string
        CaptureStdout()
        {
            var b = NaggyMock[MockB]()
            on_call_location = FormatFileLocation(__FILE__, __LINE__ + 1)
            ON_CALL(b, DoB(_)).WillByDefault(Return(0))
            b.DoB(0)
        }
        EXPECT_PRED_FORMAT2(IsSubstring, on_call_location, GetCapturedStdout())
    #endif

    @testing.Test
    def UninterestingCallTest_DoesDefaultAction():
        var a = MockA()
        ON_CALL(a, Binary(_, _)).WillByDefault(Return(true))
        EXPECT_TRUE(a.Binary(1, 2))
        var b = MockB()
        EXPECT_EQ(0, b.DoB())

    @testing.Test
    def UnexpectedCallTest_DoesDefaultAction():
        var a = MockA()
        ON_CALL(a, Binary(_, _)).WillByDefault(Return(true))
        EXPECT_CALL(a, Binary(0, 0))
        a.Binary(0, 0)
        var result: Bool = false
        EXPECT_NONFATAL_FAILURE(result = a.Binary(1, 2), "Unexpected mock function call")
        EXPECT_TRUE(result)
        var b = MockB()
        EXPECT_CALL(b, DoB(0)).Times(0)
        var n: Int = -1
        EXPECT_NONFATAL_FAILURE(n = b.DoB(1), "Unexpected mock function call")
        EXPECT_EQ(0, n)

    @testing.Test
    def UnexpectedCallTest_GeneratesFailureForVoidFunction():
        var a1 = MockA()
        EXPECT_CALL(a1, DoA(1))
        a1.DoA(1)
        EXPECT_NONFATAL_FAILURE(a1.DoA(9), "Unexpected mock function call - returning directly.\n    Function call: DoA(9)\nGoogle Mock tried the following 1 expectation, but it didn't match:")
        EXPECT_NONFATAL_FAILURE(a1.DoA(9), "  Expected arg #0: is equal to 1\n           Actual: 9\n         Expected: to be called once\n           Actual: called once - saturated and active")
        var a2 = MockA()
        EXPECT_CALL(a2, DoA(1))
        EXPECT_CALL(a2, DoA(3))
        a2.DoA(1)
        EXPECT_NONFATAL_FAILURE(a2.DoA(2), "Unexpected mock function call - returning directly.\n    Function call: DoA(2)\nGoogle Mock tried the following 2 expectations, but none matched:")
        EXPECT_NONFATAL_FAILURE(a2.DoA(2), "tried expectation #0: EXPECT_CALL(a2, DoA(1))...\n  Expected arg #0: is equal to 1\n           Actual: 2\n         Expected: to be called once\n           Actual: called once - saturated and active")
        EXPECT_NONFATAL_FAILURE(a2.DoA(2), "tried expectation #1: EXPECT_CALL(a2, DoA(3))...\n  Expected arg #0: is equal to 3\n           Actual: 2\n         Expected: to be called once\n           Actual: never called - unsatisfied and active")
        a2.DoA(3)

    @testing.Test
    def UnexpectedCallTest_GeneartesFailureForNonVoidFunction():
        var b1 = MockB()
        EXPECT_CALL(b1, DoB(1))
        b1.DoB(1)
        EXPECT_NONFATAL_FAILURE(b1.DoB(2), "Unexpected mock function call - returning default value.\n    Function call: DoB(2)\n          Returns: 0\nGoogle Mock tried the following 1 expectation, but it didn't match:")
        EXPECT_NONFATAL_FAILURE(b1.DoB(2), "  Expected arg #0: is equal to 1\n           Actual: 2\n         Expected: to be called once\n           Actual: called once - saturated and active")

    @testing.Test
    def UnexpectedCallTest_RetiredExpectation():
        var b = MockB()
        EXPECT_CALL(b, DoB(1)).RetiresOnSaturation()
        b.DoB(1)
        EXPECT_NONFATAL_FAILURE(b.DoB(1), "         Expected: the expectation is active\n           Actual: it is retired")

    @testing.Test
    def UnexpectedCallTest_UnmatchedArguments():
        var b = MockB()
        EXPECT_CALL(b, DoB(1))
        EXPECT_NONFATAL_FAILURE(b.DoB(2), "  Expected arg #0: is equal to 1\n           Actual: 2\n")
        b.DoB(1)

    @testing.Test
    def UnexpectedCallTest_UnsatisifiedPrerequisites():
        var s1 = Sequence()
        var s2 = Sequence()
        var b = MockB()
        EXPECT_CALL(b, DoB(1)).InSequence(s1)
        EXPECT_CALL(b, DoB(2)).Times(AnyNumber()).InSequence(s1)
        EXPECT_CALL(b, DoB(3)).InSequence(s2)
        EXPECT_CALL(b, DoB(4)).InSequence(s1, s2)
        var failures = ::testing.TestPartResultArray()
        {
            var reporter = ::testing.ScopedFakeTestPartResultReporter(&failures)
            b.DoB(4)
        }
        ASSERT_EQ(1, failures.size())
        var r: ::testing.TestPartResult = failures.GetTestPartResult(0)
        EXPECT_EQ(::testing.TestPartResult.kNonFatalFailure, r.type())
        #if GTEST_USES_PCRE
        EXPECT_THAT(r.message(), ContainsRegex("(?s)the following immediate pre-requisites are not satisfied:\n.*: pre-requisite #0\n.*: pre-requisite #1"))
        #elif GTEST_USES_POSIX_RE
        EXPECT_THAT(r.message(), ContainsRegex("the following immediate pre-requisites are not satisfied:\n(.|\n)*: pre-requisite #0\n(.|\n)*: pre-requisite #1"))
        #else
        EXPECT_THAT(r.message(), ContainsRegex("the following immediate pre-requisites are not satisfied:"))
        EXPECT_THAT(r.message(), ContainsRegex(": pre-requisite #0"))
        EXPECT_THAT(r.message(), ContainsRegex(": pre-requisite #1"))
        #endif
        b.DoB(1)
        b.DoB(3)
        b.DoB(4)

    @testing.Test
    def UndefinedReturnValueTest_ReturnValueIsMandatoryWhenNotDefaultConstructible():
        var a = MockA()
        #if GTEST_HAS_EXCEPTIONS
        EXPECT_ANY_THROW(a.ReturnNonDefaultConstructible())
        #else
        EXPECT_DEATH_IF_SUPPORTED(a.ReturnNonDefaultConstructible(), "")
        #endif

    @testing.Test
    def ExcessiveCallTest_DoesDefaultAction():
        var a = MockA()
        ON_CALL(a, Binary(_, _)).WillByDefault(Return(true))
        EXPECT_CALL(a, Binary(0, 0))
        a.Binary(0, 0)
        var result: Bool = false
        EXPECT_NONFATAL_FAILURE(result = a.Binary(0, 0), "Mock function called more times than expected")
        EXPECT_TRUE(result)
        var b = MockB()
        EXPECT_CALL(b, DoB(0)).Times(0)
        var n: Int = -1
        EXPECT_NONFATAL_FAILURE(n = b.DoB(0), "Mock function called more times than expected")
        EXPECT_EQ(0, n)

    @testing.Test
    def ExcessiveCallTest_GeneratesFailureForVoidFunction():
        var a = MockA()
        EXPECT_CALL(a, DoA(_)).Times(0)
        EXPECT_NONFATAL_FAILURE(a.DoA(9), "Mock function called more times than expected - returning directly.\n    Function call: DoA(9)\n         Expected: to be never called\n           Actual: called once - over-saturated and active")

    @testing.Test
    def ExcessiveCallTest_GeneratesFailureForNonVoidFunction():
        var b = MockB()
        EXPECT_CALL(b, DoB(_))
        b.DoB(1)
        EXPECT_NONFATAL_FAILURE(b.DoB(2), "Mock function called more times than expected - returning default value.\n    Function call: DoB(2)\n          Returns: 0\n         Expected: to be called once\n           Actual: called twice - over-saturated and active")

    @testing.Test
    def InSequenceTest_AllExpectationInScopeAreInSequence():
        var a = MockA()
        {
            var dummy = InSequence()
            EXPECT_CALL(a, DoA(1))
            EXPECT_CALL(a, DoA(2))
        }
        EXPECT_NONFATAL_FAILURE({
            a.DoA(2)
        }, "Unexpected mock function call")
        a.DoA(1)
        a.DoA(2)

    @testing.Test
    def InSequenceTest_NestedInSequence():
        var a = MockA()
        {
            var dummy = InSequence()
            EXPECT_CALL(a, DoA(1))
            {
                var dummy2 = InSequence()
                EXPECT_CALL(a, DoA(2))
                EXPECT_CALL(a, DoA(3))
            }
        }
        EXPECT_NONFATAL_FAILURE({
            a.DoA(1)
            a.DoA(3)
        }, "Unexpected mock function call")
        a.DoA(2)
        a.DoA(3)

    @testing.Test
    def InSequenceTest_ExpectationsOutOfScopeAreNotAffected():
        var a = MockA()
        {
            var dummy = InSequence()
            EXPECT_CALL(a, DoA(1))
            EXPECT_CALL(a, DoA(2))
        }
        EXPECT_CALL(a, DoA(3))
        EXPECT_NONFATAL_FAILURE({
            a.DoA(2)
        }, "Unexpected mock function call")
        a.DoA(3)
        a.DoA(1)
        a.DoA(2)

    @testing.Test
    def SequenceTest_AnyOrderIsOkByDefault():
        {
            var a = MockA()
            var b = MockB()
            EXPECT_CALL(a, DoA(1))
            EXPECT_CALL(b, DoB()).Times(AnyNumber())
            a.DoA(1)
            b.DoB()
        }
        {
            var a = MockA()
            var b = MockB()
            EXPECT_CALL(a, DoA(1))
            EXPECT_CALL(b, DoB()).Times(AnyNumber())
            b.DoB()
            a.DoA(1)
        }

    @testing.Test
    def SequenceTest_CallsMustBeInStrictOrderWhenSaidSo1():
        var a = MockA()
        ON_CALL(a, ReturnResult(_)).WillByDefault(Return(Result()))
        var s = Sequence()
        EXPECT_CALL(a, ReturnResult(1)).InSequence(s)
        EXPECT_CALL(a, ReturnResult(2)).InSequence(s)
        EXPECT_CALL(a, ReturnResult(3)).InSequence(s)
        a.ReturnResult(1)
        EXPECT_NONFATAL_FAILURE(a.ReturnResult(3), "Unexpected mock function call")
        a.ReturnResult(2)
        a.ReturnResult(3)

    @testing.Test
    def SequenceTest_CallsMustBeInStrictOrderWhenSaidSo2():
        var a = MockA()
        ON_CALL(a, ReturnResult(_)).WillByDefault(Return(Result()))
        var s = Sequence()
        EXPECT_CALL(a, ReturnResult(1)).InSequence(s)
        EXPECT_CALL(a, ReturnResult(2)).InSequence(s)
        EXPECT_NONFATAL_FAILURE(a.ReturnResult(2), "Unexpected mock function call")
        a.ReturnResult(1)
        a.ReturnResult(2)

    class PartialOrderTest(testing.Test):
        def __init__(self):
            ON_CALL(self.a_, ReturnResult(_)).WillByDefault(Return(Result()))
            var x = Sequence()
            var y = Sequence()
            EXPECT_CALL(self.a_, ReturnResult(1)).InSequence(x)
            EXPECT_CALL(self.b_, DoB()).Times(2).InSequence(y)
            EXPECT_CALL(self.a_, ReturnResult(2)).Times(AnyNumber()).InSequence(x, y)
            EXPECT_CALL(self.a_, ReturnResult(3)).InSequence(x)
        var a_: MockA
        var b_: MockB

    @testing.Test
    def PartialOrderTest_CallsMustConformToSpecifiedDag1():
        var self = PartialOrderTest()
        self.a_.ReturnResult(1)
        self.b_.DoB()
        EXPECT_NONFATAL_FAILURE(self.a_.ReturnResult(2), "Unexpected mock function call")
        self.b_.DoB()
        self.a_.ReturnResult(3)

    @testing.Test
    def PartialOrderTest_CallsMustConformToSpecifiedDag2():
        var self = PartialOrderTest()
        EXPECT_NONFATAL_FAILURE(self.a_.ReturnResult(2), "Unexpected mock function call")
        self.a_.ReturnResult(1)
        self.b_.DoB()
        self.b_.DoB()
        self.a_.ReturnResult(3)

    @testing.Test
    def PartialOrderTest_CallsMustConformToSpecifiedDag3():
        var self = PartialOrderTest()
        EXPECT_NONFATAL_FAILURE(self.a_.ReturnResult(3), "Unexpected mock function call")
        self.a_.ReturnResult(1)
        self.b_.DoB()
        self.b_.DoB()
        self.a_.ReturnResult(3)

    @testing.Test
    def PartialOrderTest_CallsMustConformToSpecifiedDag4():
        var self = PartialOrderTest()
        self.a_.ReturnResult(1)
        self.b_.DoB()
        self.b_.DoB()
        self.a_.ReturnResult(3)
        EXPECT_NONFATAL_FAILURE(self.a_.ReturnResult(2), "Unexpected mock function call")

    @testing.Test
    def SequenceTest_Retirement():
        var a = MockA()
        var s = Sequence()
        EXPECT_CALL(a, DoA(1)).InSequence(s)
        EXPECT_CALL(a, DoA(_)).InSequence(s).RetiresOnSaturation()
        EXPECT_CALL(a, DoA(1)).InSequence(s)
        a.DoA(1)
        a.DoA(2)
        a.DoA(1)

    @testing.Test
    def ExpectationTest_ConstrutorsWork():
        var a = MockA()
        var e1: Expectation
        var e2: Expectation = EXPECT_CALL(a, DoA(2))
        var e3: Expectation = EXPECT_CALL(a, DoA(3)).With(_)
        {
            var s = Sequence()
            var e4: Expectation = EXPECT_CALL(a, DoA(4)).Times(1)
            var e5: Expectation = EXPECT_CALL(a, DoA(5)).InSequence(s)
        }
        var e6: Expectation = EXPECT_CALL(a, DoA(6)).After(e2)
        var e7: Expectation = EXPECT_CALL(a, DoA(7)).WillOnce(Return())
        var e8: Expectation = EXPECT_CALL(a, DoA(8)).WillRepeatedly(Return())
        var e9: Expectation = EXPECT_CALL(a, DoA(9)).RetiresOnSaturation()
        var e10: Expectation = e2
        EXPECT_THAT(e1, Ne(e2))
        EXPECT_THAT(e2, Eq(e10))
        a.DoA(2)
        a.DoA(3)
        a.DoA(4)
        a.DoA(5)
        a.DoA(6)
        a.DoA(7)
        a.DoA(8)
        a.DoA(9)

    @testing.Test
    def ExpectationTest_AssignmentWorks():
        var a = MockA()
        var e1: Expectation
        var e2: Expectation = EXPECT_CALL(a, DoA(1))
        EXPECT_THAT(e1, Ne(e2))
        e1 = e2
        EXPECT_THAT(e1, Eq(e2))
        a.DoA(1)

    @testing.Test
    def ExpectationSetTest_MemberTypesAreCorrect():
        ::testing.StaticAssertTypeEq[Expectation, ExpectationSet.value_type]()

    @testing.Test
    def ExpectationSetTest_ConstructorsWork():
        var a = MockA()
        var e1: Expectation
        var e2: Expectation
        var es1: ExpectationSet
        var es2: ExpectationSet = EXPECT_CALL(a, DoA(1))
        var es3: ExpectationSet = e1
        var es4: ExpectationSet = ExpectationSet(e1)
        var es5: ExpectationSet = e2
        var es6: ExpectationSet = ExpectationSet(e2)
        var es7: ExpectationSet = es2
        EXPECT_EQ(0, es1.size())
        EXPECT_EQ(1, es2.size())
        EXPECT_EQ(1, es3.size())
        EXPECT_EQ(1, es4.size())
        EXPECT_EQ(1, es5.size())
        EXPECT_EQ(1, es6.size())
        EXPECT_EQ(1, es7.size())
        EXPECT_THAT(es3, Ne(es2))
        EXPECT_THAT(es4, Eq(es3))
        EXPECT_THAT(es5, Eq(es4))
        EXPECT_THAT(es6, Eq(es5))
        EXPECT_THAT(es7, Eq(es2))
        a.DoA(1)

    @testing.Test
    def ExpectationSetTest_AssignmentWorks():
        var es1: ExpectationSet
        var es2: ExpectationSet = Expectation()
        es1 = es2
        EXPECT_EQ(1, es1.size())
        EXPECT_THAT(*(es1.begin()), Eq(Expectation()))
        EXPECT_THAT(es1, Eq(es2))

    @testing.Test
    def ExpectationSetTest_InsertionWorks():
        var es1: ExpectationSet
        var e1: Expectation
        es1 += e1
        EXPECT_EQ(1, es1.size())
        EXPECT_THAT(*(es1.begin()), Eq(e1))
        var a = MockA()
        var e2: Expectation = EXPECT_CALL(a, DoA(1))
        es1 += e2
        EXPECT_EQ(2, es1.size())
        var it1: ExpectationSet.const_iterator = es1.begin()
        var it2: ExpectationSet.const_iterator = it1
        ++it2
        EXPECT_TRUE(*it1 == e1 or *it2 == e1)
        EXPECT_TRUE(*it1 == e2 or *it2 == e2)
        a.DoA(1)

    @testing.Test
    def ExpectationSetTest_SizeWorks():
        var es: ExpectationSet
        EXPECT_EQ(0, es.size())
        es += Expectation()
        EXPECT_EQ(1, es.size())
        var a = MockA()
        es += EXPECT_CALL(a, DoA(1))
        EXPECT_EQ(2, es.size())
        a.DoA(1)

    @testing.Test
    def ExpectationSetTest_IsEnumerable():
        var es: ExpectationSet
        EXPECT_TRUE(es.begin() == es.end())
        es += Expectation()
        var it: ExpectationSet.const_iterator = es.begin()
        EXPECT_TRUE(it != es.end())
        EXPECT_THAT(*it, Eq(Expectation()))
        ++it
        EXPECT_TRUE(it == es.end())

    @testing.Test
    def AfterTest_SucceedsWhenPartialOrderIsSatisfied():
        var a = MockA()
        var es: ExpectationSet
        es += EXPECT_CALL(a, DoA(1))
        es += EXPECT_CALL(a, DoA(2))
        EXPECT_CALL(a, DoA(3)).After(es)
        a.DoA(1)
        a.DoA(2)
        a.DoA(3)

    @testing.Test
    def AfterTest_SucceedsWhenTotalOrderIsSatisfied():
        var a = MockA()
        var b = MockB()
        var e1: Expectation = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(b, DoB()).Times(2).After(e1)
        EXPECT_CALL(a, DoA(2)).After(e2)
        a.DoA(1)
        b.DoB()
        b.DoB()
        a.DoA(2)

    @testing.Test
    def AfterTest_CallsMustBeInStrictOrderWhenSpecifiedSo1():
        var a = MockA()
        var b = MockB()
        var e1: Expectation = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(b, DoB()).After(e1)
        EXPECT_CALL(a, DoA(2)).After(e2)
        a.DoA(1)
        EXPECT_NONFATAL_FAILURE(a.DoA(2), "Unexpected mock function call")
        b.DoB()
        a.DoA(2)

    @testing.Test
    def AfterTest_CallsMustBeInStrictOrderWhenSpecifiedSo2():
        var a = MockA()
        var b = MockB()
        var e1: Expectation = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(b, DoB()).Times(2).After(e1)
        EXPECT_CALL(a, DoA(2)).After(e2)
        a.DoA(1)
        b.DoB()
        EXPECT_NONFATAL_FAILURE(a.DoA(2), "Unexpected mock function call")
        b.DoB()
        a.DoA(2)

    @testing.Test
    def AfterTest_CallsMustSatisfyPartialOrderWhenSpecifiedSo():
        var a = MockA()
        ON_CALL(a, ReturnResult(_)).WillByDefault(Return(Result()))
        var e: Expectation = EXPECT_CALL(a, DoA(1))
        var es: ExpectationSet = EXPECT_CALL(a, DoA(2))
        EXPECT_CALL(a, ReturnResult(3)).After(e, es)
        EXPECT_NONFATAL_FAILURE(a.ReturnResult(3), "Unexpected mock function call")
        a.DoA(2)
        a.DoA(1)
        a.ReturnResult(3)

    @testing.Test
    def AfterTest_CallsMustSatisfyPartialOrderWhenSpecifiedSo2():
        var a = MockA()
        var e: Expectation = EXPECT_CALL(a, DoA(1))
        var es: ExpectationSet = EXPECT_CALL(a, DoA(2))
        EXPECT_CALL(a, DoA(3)).After(e, es)
        a.DoA(2)
        EXPECT_NONFATAL_FAILURE(a.DoA(3), "Unexpected mock function call")
        a.DoA(1)
        a.DoA(3)

    @testing.Test
    def AfterTest_CanBeUsedWithInSequence():
        var a = MockA()
        var s = Sequence()
        var e: Expectation = EXPECT_CALL(a, DoA(1))
        EXPECT_CALL(a, DoA(2)).InSequence(s)
        EXPECT_CALL(a, DoA(3)).InSequence(s).After(e)
        a.DoA(1)
        EXPECT_NONFATAL_FAILURE(a.DoA(3), "Unexpected mock function call")
        a.DoA(2)
        a.DoA(3)

    @testing.Test
    def AfterTest_CanBeCalledManyTimes():
        var a = MockA()
        var e1: Expectation = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(a, DoA(2))
        var e3: Expectation = EXPECT_CALL(a, DoA(3))
        EXPECT_CALL(a, DoA(4)).After(e1).After(e2).After(e3)
        a.DoA(3)
        a.DoA(1)
        a.DoA(2)
        a.DoA(4)

    @testing.Test
    def AfterTest_AcceptsUpToFiveArguments():
        var a = MockA()
        var e1: Expectation = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(a, DoA(2))
        var e3: Expectation = EXPECT_CALL(a, DoA(3))
        var es1: ExpectationSet = EXPECT_CALL(a, DoA(4))
        var es2: ExpectationSet = EXPECT_CALL(a, DoA(5))
        EXPECT_CALL(a, DoA(6)).After(e1, e2, e3, es1, es2)
        a.DoA(5)
        a.DoA(2)
        a.DoA(4)
        a.DoA(1)
        a.DoA(3)
        a.DoA(6)

    @testing.Test
    def AfterTest_AcceptsDuplicatedInput():
        var a = MockA()
        ON_CALL(a, ReturnResult(_)).WillByDefault(Return(Result()))
        var e1: Expectation = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(a, DoA(2))
        var es: ExpectationSet
        es += e1
        es += e2
        EXPECT_CALL(a, ReturnResult(3)).After(e1, e2, es, e1)
        a.DoA(1)
        EXPECT_NONFATAL_FAILURE(a.ReturnResult(3), "Unexpected mock function call")
        a.DoA(2)
        a.ReturnResult(3)

    @testing.Test
    def AfterTest_ChangesToExpectationSetHaveNoEffectAfterwards():
        var a = MockA()
        var es1: ExpectationSet = EXPECT_CALL(a, DoA(1))
        var e2: Expectation = EXPECT_CALL(a, DoA(2))
        EXPECT_CALL(a, DoA(3)).After(es1)
        es1 += e2
        a.DoA(1)
        a.DoA(3)
        a.DoA(2)

    @testing.Test
    def DeletingMockEarlyTest_Success1():
        var b1: MockB* = new MockB()
        var a: MockA* = new MockA()
        var b2: MockB* = new MockB()
        {
            var dummy = InSequence()
            EXPECT_CALL(*b1, DoB(_)).WillOnce(Return(1))
            EXPECT_CALL(*a, Binary(_, _)).Times(AnyNumber()).WillRepeatedly(Return(true))
            EXPECT_CALL(*b2, DoB(_)).Times(AnyNumber()).WillRepeatedly(Return(2))
        }
        EXPECT_EQ(1, b1->DoB(1))
        delete b1
        EXPECT_TRUE(a->Binary(0, 1))
        delete b2
        EXPECT_TRUE(a->Binary(1, 2))
        delete a

    @testing.Test
    def DeletingMockEarlyTest_Success2():
        var b1: MockB* = new MockB()
        var a: MockA* = new MockA()
        var b2: MockB* = new MockB()
        {
            var dummy = InSequence()
            EXPECT_CALL(*b1, DoB(_)).WillOnce(Return(1))
            EXPECT_CALL(*a, Binary(_, _)).Times(AnyNumber())
            EXPECT_CALL(*b2, DoB(_)).Times(AnyNumber()).WillRepeatedly(Return(2))
        }
        delete a
        EXPECT_EQ(1, b1->DoB(1))
        EXPECT_EQ(2, b2->DoB(2))
        delete b1
        delete b2

    #ifdef _MSC_VER
    # pragma warning(push)
    # pragma warning(disable:4100)
    #endif
    # ACTION_P(Delete, ptr) { delete ptr; }
    #ifdef _MSC_VER
    # pragma warning(pop)
    #endif

    @testing.Test
    def DeletingMockEarlyTest_CanDeleteSelfInActionReturningVoid():
        var a: MockA* = new MockA()
        EXPECT_CALL(*a, DoA(_)).WillOnce(Delete(a))
        a->DoA(42)

    @testing.Test
    def DeletingMockEarlyTest_CanDeleteSelfInActionReturningValue():
        var a: MockA* = new MockA()
        EXPECT_CALL(*a, ReturnResult(_)).WillOnce(DoAll(Delete(a), Return(Result())))
        a->ReturnResult(42)

    @testing.Test
    def DeletingMockEarlyTest_Failure1():
        var b1: MockB* = new MockB()
        var a: MockA* = new MockA()
        var b2: MockB* = new MockB()
        {
            var dummy = InSequence()
            EXPECT_CALL(*b1, DoB(_)).WillOnce(Return(1))
            EXPECT_CALL(*a, Binary(_, _)).Times(AnyNumber())
            EXPECT_CALL(*b2, DoB(_)).Times(AnyNumber()).WillRepeatedly(Return(2))
        }
        delete a
        EXPECT_NONFATAL_FAILURE({
            b2->DoB(2)
        }, "Unexpected mock function call")
        EXPECT_EQ(1, b1->DoB(1))
        delete b1
        delete b2

    @testing.Test
    def DeletingMockEarlyTest_Failure2():
        var b1: MockB* = new MockB()
        var a: MockA* = new MockA()
        var b2: MockB* = new MockB()
        {
            var dummy = InSequence()
            EXPECT_CALL(*b1, DoB(_))
            EXPECT_CALL(*a, Binary(_, _)).Times(AnyNumber())
            EXPECT_CALL(*b2, DoB(_)).Times(AnyNumber())
        }
        EXPECT_NONFATAL_FAILURE(delete b1, "Actual: never called")
        EXPECT_NONFATAL_FAILURE(a->Binary(0, 1), "Unexpected mock function call")
        EXPECT_NONFATAL_FAILURE(b2->DoB(1), "Unexpected mock function call")
        delete a
        delete b2

    class EvenNumberCardinality(CardinalityInterface):
        def IsSatisfiedByCallCount(self, call_count: Int) -> Bool:
            return call_count % 2 == 0
        def IsSaturatedByCallCount(self, call_count: Int) -> Bool:
            return false
        def DescribeTo(self, os: ::ostream*) -> None:
            *os << "called even number of times"

    def EvenNumber() -> Cardinality:
        return Cardinality(EvenNumberCardinality())

    @testing.Test
    def ExpectationBaseTest_AllPrerequisitesAreSatisfiedWorksForNonMonotonicCardinality():
        var a: MockA* = new MockA()
        var s = Sequence()
        EXPECT_CALL(*a, DoA(1)).Times(EvenNumber()).InSequence(s)
        EXPECT_CALL(*a, DoA(2)).Times(AnyNumber()).InSequence(s)
        EXPECT_CALL(*a, DoA(3)).Times(AnyNumber())
        a->DoA(3)
        a->DoA(1)
        EXPECT_NONFATAL_FAILURE(a->DoA(2), "Unexpected mock function call")
        EXPECT_NONFATAL_FAILURE(delete a, "to be called even number of times")

    struct Printable:

    def operator<<(os: ::ostream&, x: Printable&):
        os << "Printable"

    struct Unprintable:
        def __init__(self):
            self.value = 0
        var value: Int

    class MockC:
        def __init__(self):

        def VoidMethod(self, cond: Bool, n: Int, s: std.string, p: void*, x: Printable&, y: Unprintable):

        def NonVoidMethod(self) -> Int:

    class VerboseFlagPreservingFixture(testing.Test):
        def __init__(self):
            self.saved_verbose_flag_ = GMOCK_FLAG(verbose)
        def __del__(self):
            GMOCK_FLAG(verbose) = self.saved_verbose_flag_
        var saved_verbose_flag_: std.string

    #if GTEST_HAS_STREAM_REDIRECTION
    @testing.Test
    def FunctionCallMessageTest_UninterestingCallOnNaggyMockGeneratesNoStackTraceWhenVerboseWarning():
        GMOCK_FLAG(verbose) = kWarningVerbosity
        var c = NaggyMock[MockC]()
        CaptureStdout()
        c.VoidMethod(false, 5, "Hi", None, Printable(), Unprintable())
        var output: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "GMOCK WARNING", output)
        EXPECT_PRED_FORMAT2(IsNotSubstring, "Stack trace:", output)

    @testing.Test
    def FunctionCallMessageTest_UninterestingCallOnNaggyMockGeneratesFyiWithStackTraceWhenVerboseInfo():
        GMOCK_FLAG(verbose) = kInfoVerbosity
        var c = NaggyMock[MockC]()
        CaptureStdout()
        c.VoidMethod(false, 5, "Hi", None, Printable(), Unprintable())
        var output: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "GMOCK WARNING", output)
        EXPECT_PRED_FORMAT2(IsSubstring, "Stack trace:", output)
        #ifndef NDEBUG
        EXPECT_PRED_FORMAT2(IsSubstring, "VoidMethod(", output)
        CaptureStdout()
        c.NonVoidMethod()
        var output2: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "NonVoidMethod(", output2)
        #endif

    @testing.Test
    def FunctionCallMessageTest_UninterestingCallOnNaggyMockPrintsArgumentsAndReturnValue():
        var b = NaggyMock[MockB]()
        CaptureStdout()
        b.DoB()
        var output1: std.string = GetCapturedStdout()
        EXPECT_PRED_FORMAT2(IsSubstring, "Uninteresting mock function call - returning default value.\n    Function call: DoB()\n          Returns: 0\n", output1.c_str())
        var c = NaggyMock[MockC]()
        CaptureStdout()
        c.VoidMethod(false, 5, "Hi", None, Printable(), Unprintable())
        var output2: std.string = GetCapturedStdout()
        EXPECT_THAT(output2.c_str(), ContainsRegex("Uninteresting mock function call - returning directly\\.\n    Function call: VoidMethod\\(false, 5, \"Hi\", NULL, @.+ Printable, 4-byte object <00-00 00-00>\\)"))

    class GMockVerboseFlagTest(VerboseFlagPreservingFixture):
        def VerifyOutput(self, output: std.string&, should_print: Bool, expected_substring: std.string&, function_name: std.string&):
            if should_print:
                EXPECT_THAT(output.c_str(), HasSubstr(expected_substring))
                #ifndef NDEBUG
                EXPECT_THAT(output.c_str(), HasSubstr(function_name))
                #else
                _ = function_name
                #endif
            else:
                EXPECT_STREQ("", output.c_str())
        def TestExpectedCall(self, should_print: Bool):
            var a = MockA()
            EXPECT_CALL(a, DoA(5))
            EXPECT_CALL(a, Binary(_, 1)).WillOnce(Return(true))
            CaptureStdout()
            a.DoA(5)
            VerifyOutput(GetCapturedStdout(), should_print, "Mock function call matches EXPECT_CALL(a, DoA(5))...\n    Function call: DoA(5)\nStack trace:\n", "DoA")
            CaptureStdout()
            a.Binary(2, 1)
            VerifyOutput(GetCapturedStdout(), should_print, "Mock function call matches EXPECT_CALL(a, Binary(_, 1))...\n    Function call: Binary(2, 1)\n          Returns: true\nStack trace:\n", "Binary")
        def TestUninterestingCallOnNaggyMock(self, should_print: Bool):
            var a = NaggyMock[MockA]()
            var note: std.string = "NOTE: You can safely ignore the above warning unless this call should not happen.  Do not suppress it by blindly adding an EXPECT_CALL() if you don't mean to enforce the call.  See https://github.com/google/googletest/blob/master/docs/gmock_cook_book.md#knowing-when-to-expect for details."
            CaptureStdout()
            a.DoA(5)
            VerifyOutput(GetCapturedStdout(), should_print, "\nGMOCK WARNING:\nUninteresting mock function call - returning directly.\n    Function call: DoA(5)\n" + note, "DoA")
            CaptureStdout()
            a.Binary(2, 1)
            VerifyOutput(GetCapturedStdout(), should_print, "\nGMOCK WARNING:\nUninteresting mock function call - returning default value.\n    Function call: Binary(2, 1)\n          Returns: false\n" + note, "Binary")

    @testing.Test
    def GMockVerboseFlagTest_Info():
        var self = GMockVerboseFlagTest()
        GMOCK_FLAG(verbose) = kInfoVerbosity
        self.TestExpectedCall(true)
        self.TestUninterestingCallOnNaggyMock(true)

    @testing.Test
    def GMockVerboseFlagTest_Warning():
        var self = GMockVerboseFlagTest()
        GMOCK_FLAG(verbose) = kWarningVerbosity
        self.TestExpectedCall(false)
        self.TestUninterestingCallOnNaggyMock(true)

    @testing.Test
    def GMockVerboseFlagTest_Error():
        var self = GMockVerboseFlagTest()
        GMOCK_FLAG(verbose) = kErrorVerbosity
        self.TestExpectedCall(false)
        self.TestUninterestingCallOnNaggyMock(false)

    @testing.Test
    def GMockVerboseFlagTest_InvalidFlagIsTreatedAsWarning():
        var self = GMockVerboseFlagTest()
        GMOCK_FLAG(verbose) = "invalid"
        self.TestExpectedCall(false)
        self.TestUninterestingCallOnNaggyMock(true)
    #endif

    class PrintMeNot:

    def PrintTo(dummy: PrintMeNot&, os: ::ostream*):
        ADD_FAILURE() << "Google Mock is printing a value that shouldn't be printed even to an internal buffer."

    class LogTestHelper:
        def __init__(self):

        def Foo(self, x: PrintMeNot) -> PrintMeNot:

    class GMockLogTest(VerboseFlagPreservingFixture):
        var helper_: LogTestHelper

    @testing.Test
    def GMockLogTest_DoesNotPrintGoodCallInternallyIfVerbosityIsWarning():
        var self = GMockLogTest()
        GMOCK_FLAG(verbose) = kWarningVerbosity
        EXPECT_CALL(self.helper_, Foo(_)).WillOnce(Return(PrintMeNot()))
        self.helper_.Foo(PrintMeNot())

    @testing.Test
    def GMockLogTest_DoesNotPrintGoodCallInternallyIfVerbosityIsError():
        var self = GMockLogTest()
        GMOCK_FLAG(verbose) = kErrorVerbosity
        EXPECT_CALL(self.helper_, Foo(_)).WillOnce(Return(PrintMeNot()))
        self.helper_.Foo(PrintMeNot())

    @testing.Test
    def GMockLogTest_DoesNotPrintWarningInternallyIfVerbosityIsError():
        var self = GMockLogTest()
        GMOCK_FLAG(verbose) = kErrorVerbosity
        ON_CALL(self.helper_, Foo(_)).WillByDefault(Return(PrintMeNot()))
        self.helper_.Foo(PrintMeNot())

    @testing.Test
    def AllowLeakTest_AllowsLeakingUnusedMockObject():
        var a: MockA* = new MockA()
        Mock.AllowLeak(a)

    @testing.Test
    def AllowLeakTest_CanBeCalledBeforeOnCall():
        var a: MockA* = new MockA()
        Mock.AllowLeak(a)
        ON_CALL(*a, DoA(_)).WillByDefault(Return())
        a->DoA(0)

    @testing.Test
    def AllowLeakTest_CanBeCalledAfterOnCall():
        var a: MockA* = new MockA()
        ON_CALL(*a, DoA(_)).WillByDefault(Return())
        Mock.AllowLeak(a)

    @testing.Test
    def AllowLeakTest_CanBeCalledBeforeExpectCall():
        var a: MockA* = new MockA()
        Mock.AllowLeak(a)
        EXPECT_CALL(*a, DoA(_))
        a->DoA(0)

    @testing.Test
    def AllowLeakTest_CanBeCalledAfterExpectCall():
        var a: MockA* = new MockA()
        EXPECT_CALL(*a, DoA(_)).Times(AnyNumber())
        Mock.AllowLeak(a)

    @testing.Test
    def AllowLeakTest_WorksWhenBothOnCallAndExpectCallArePresent():
        var a: MockA* = new MockA()
        ON_CALL(*a, DoA(_)).WillByDefault(Return())
        EXPECT_CALL(*a, DoA(_)).Times(AnyNumber())
        Mock.AllowLeak(a)

    @testing.Test
    def VerifyAndClearExpectationsTest_NoMethodHasExpectations():
        var b = MockB()
        ASSERT_TRUE(Mock.VerifyAndClearExpectations(&b))
        EXPECT_EQ(0, b.DoB())
        EXPECT_EQ(0, b.DoB(1))

    @testing.Test
    def VerifyAndClearExpectationsTest_SomeMethodsHaveExpectationsAndSucceed():
        var b = MockB()
        EXPECT_CALL(b, DoB()).WillOnce(Return(1))
        b.DoB()
        ASSERT_TRUE(Mock.VerifyAndClearExpectations(&b))
        EXPECT_EQ(0, b.DoB())
        EXPECT_EQ(0, b.DoB(1))

    @testing.Test
    def VerifyAndClearExpectationsTest_SomeMethodsHaveExpectationsAndFail():
        var b = MockB()
        EXPECT_CALL(b, DoB()).WillOnce(Return(1))
        var result: Bool = true
        EXPECT_NONFATAL_FAILURE(result = Mock.VerifyAndClearExpectations(&b), "Actual: never called")
        ASSERT_FALSE(result)
        EXPECT_EQ(0, b.DoB())
        EXPECT_EQ(0, b.DoB(1))

    @testing.Test
    def VerifyAndClearExpectationsTest_AllMethodsHaveExpectations():
        var b = MockB()
        EXPECT_CALL(b, DoB()).WillOnce(Return(1))
        EXPECT_CALL(b, DoB(_)).WillOnce(Return(2))
        b.DoB()
        b.DoB(1)
        ASSERT_TRUE(Mock.VerifyAndClearExpectations(&b))
        EXPECT_EQ(0, b.DoB())
        EXPECT_EQ(0, b.DoB(1))

    @testing.Test
    def VerifyAndClearExpectationsTest_AMethodHasManyExpectations():
        var b = MockB()
        EXPECT_CALL(b, DoB(0)).WillOnce(Return(1))
        EXPECT_CALL(b, DoB(_)).WillOnce(Return(2))
        b.DoB(1)
        var result: Bool = true
        EXPECT_NONFATAL_FAILURE(result = Mock.VerifyAndClearExpectations(&b), "Actual: never called")
        ASSERT_FALSE(result)
        EXPECT_EQ(0, b.DoB())
        EXPECT_EQ(0, b.DoB(1))

    @testing.Test
    def VerifyAndClearExpectationsTest_CanCallManyTimes():
        var b = MockB()
        EXPECT_CALL(b, DoB())
        b.DoB()
        Mock.VerifyAndClearExpectations(&b)
        EXPECT_CALL(b, DoB(_)).WillOnce(Return(1))
        b.DoB(1