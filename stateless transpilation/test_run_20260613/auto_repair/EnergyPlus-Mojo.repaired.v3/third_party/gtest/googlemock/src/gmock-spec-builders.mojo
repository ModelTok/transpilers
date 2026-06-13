from gmock.gmock-spec-builders import ExpectationBase, ExpectationSet, UntypedFunctionMockerBase, UntypedExpectations, UntypedActionResultHolderBase, CallReaction, kAllow, kWarn, kFail, kInfoVerbosity, kInfo, kWarning, kNone, kTimes
from gtest.gtest import TestInfo, UnitTest, Log, LogIsVisible, Expect, Assert
from gtest.internal.gtest-port import FormatFileLocation, MutexLock, Mutex, ThreadLocal, GMOCK_FLAG
from std.memory import Rc, owned, borrowed
from std.sync import Mutex as StdMutex
from std.io import stdout, stderr, StringWriter
from std.string import String
from std.collections import List, Dict, Set
from std.os import _exit
from std.platform import is_linux, is_mac, is_windows, is_cygwin

# if GTEST_OS_CYGWIN || GTEST_OS_LINUX || GTEST_OS_MAC
@if is_cygwin() or is_linux() or is_mac()
    from std.unistd import *  # NOLINT
# endif

# ifdef _MSC_VER
@if is_windows()
    # if _MSC_VER == 1900
    @if __MSC_VER__ == 1900
        # pragma warning(push)
        # pragma warning(disable:4800)
    # endif
# endif

module testing:
    module internal:
        # GTEST_API_ GTEST_DEFINE_STATIC_MUTEX_(g_gmock_mutex)
        var g_gmock_mutex = StdMutex()

        # GTEST_API_ void LogWithLocation(testing::internal::LogSeverity severity,
        #                                 char* file , int line,
        #                                 string& message ) {
        def LogWithLocation(severity: testing.internal.LogSeverity, file: String, line: Int, message: String):
            var s = StringWriter()
            s.write(internal.FormatFileLocation(file, line))
            s.write(" ")
            s.write(message)
            s.write("\n")
            Log(severity, s.str(), 0)

        class ExpectationBase:
            var file_: String
            var line_: Int
            var source_text_: String
            var cardinality_specified_: Bool
            var cardinality_: Cardinality
            var call_count_: Int
            var retired_: Bool
            var extra_matcher_specified_: Bool
            var repeated_action_specified_: Bool
            var retires_on_saturation_: Bool
            var last_clause_: LastClause
            var action_count_checked_: Bool
            var immediate_prerequisites_: ExpectationSet
            var untyped_actions_: List[UntypedAction]

            def __init__(self, a_file: String, a_line: Int, a_source_text: String):
                self.file_ = a_file
                self.line_ = a_line
                self.source_text_ = a_source_text
                self.cardinality_specified_ = False
                self.cardinality_ = Exactly(1)
                self.call_count_ = 0
                self.retired_ = False
                self.extra_matcher_specified_ = False
                self.repeated_action_specified_ = False
                self.retires_on_saturation_ = False
                self.last_clause_ = kNone
                self.action_count_checked_ = False

            def __del__(self):

            def SpecifyCardinality(self, a_cardinality: Cardinality):
                self.cardinality_specified_ = True
                self.cardinality_ = a_cardinality

            def RetireAllPreRequisites(self) -> None:
                # GTEST_EXCLUSIVE_LOCK_REQUIRED_(g_gmock_mutex)
                if self.is_retired():
                    return
                var expectations: List[ExpectationBase] = [self]
                while not expectations.empty():
                    var exp = expectations.pop_back()
                    for it in exp.immediate_prerequisites_.begin() to exp.immediate_prerequisites_.end():
                        var next = it.expectation_base().get()
                        if not next.is_retired():
                            next.Retire()
                            expectations.push_back(next)

            def AllPrerequisitesAreSatisfied(self) -> Bool:
                # GTEST_EXCLUSIVE_LOCK_REQUIRED_(g_gmock_mutex)
                g_gmock_mutex.AssertHeld()
                var expectations: List[ExpectationBase] = [self]
                while not expectations.empty():
                    var exp = expectations.pop_back()
                    for it in exp.immediate_prerequisites_.begin() to exp.immediate_prerequisites_.end():
                        var next = it.expectation_base().get()
                        if not next.IsSatisfied():
                            return False
                        expectations.push_back(next)
                return True

            def FindUnsatisfiedPrerequisites(self, result: ExpectationSet) -> None:
                # GTEST_EXCLUSIVE_LOCK_REQUIRED_(g_gmock_mutex)
                g_gmock_mutex.AssertHeld()
                var expectations: List[ExpectationBase] = [self]
                while not expectations.empty():
                    var exp = expectations.pop_back()
                    for it in exp.immediate_prerequisites_.begin() to exp.immediate_prerequisites_.end():
                        var next = it.expectation_base().get()
                        if next.IsSatisfied():
                            if next.call_count_ == 0:
                                expectations.push_back(next)
                        else:
                            *result += *it

            def DescribeCallCountTo(self, os: OStream) -> None:
                # GTEST_EXCLUSIVE_LOCK_REQUIRED_(g_gmock_mutex)
                g_gmock_mutex.AssertHeld()
                os.write("         Expected: to be ")
                self.cardinality().DescribeTo(os)
                os.write("\n           Actual: ")
                Cardinality.DescribeActualCallCountTo(self.call_count(), os)
                os.write(" - ")
                if self.IsOverSaturated():
                    os.write("over-saturated")
                elif self.IsSaturated():
                    os.write("saturated")
                elif self.IsSatisfied():
                    os.write("satisfied")
                else:
                    os.write("unsatisfied")
                os.write(" and ")
                if self.is_retired():
                    os.write("retired")
                else:
                    os.write("active")

            def CheckActionCountIfNotDone(self) -> None:
                # GTEST_LOCK_EXCLUDED_(mutex_)
                var should_check = False
                {
                    var l = MutexLock(&self.mutex_)
                    if not self.action_count_checked_:
                        self.action_count_checked_ = True
                        should_check = True
                }
                if should_check:
                    if not self.cardinality_specified_:
                        return
                    var action_count = self.untyped_actions_.size()
                    var upper_bound = self.cardinality().ConservativeUpperBound()
                    var lower_bound = self.cardinality().ConservativeLowerBound()
                    var too_many: Bool
                    if action_count > upper_bound or (action_count == upper_bound and self.repeated_action_specified_):
                        too_many = True
                    elif 0 < action_count and action_count < lower_bound and not self.repeated_action_specified_:
                        too_many = False
                    else:
                        return
                    var ss = StringWriter()
                    self.DescribeLocationTo(&ss)
                    ss.write("Too ")
                    if too_many:
                        ss.write("many")
                    else:
                        ss.write("few")
                    ss.write(" actions specified in ")
                    ss.write(self.source_text())
                    ss.write("...\n")
                    ss.write("Expected to be ")
                    self.cardinality().DescribeTo(&ss)
                    ss.write(", but has ")
                    if not too_many:
                        ss.write("only ")
                    ss.write(action_count)
                    ss.write(" WillOnce()")
                    if action_count != 1:
                        ss.write("s")
                    if self.repeated_action_specified_:
                        ss.write(" and a WillRepeatedly()")
                    ss.write(".")
                    Log(kWarning, ss.str(), -1)

            def UntypedTimes(self, a_cardinality: Cardinality):
                if self.last_clause_ == kTimes:
                    ExpectSpecProperty(False, ".Times() cannot appear more than once in an EXPECT_CALL().")
                else:
                    ExpectSpecProperty(self.last_clause_ < kTimes, ".Times() cannot appear after .InSequence(), .WillOnce(), .WillRepeatedly(), or .RetiresOnSaturation().")
                self.last_clause_ = kTimes
                self.SpecifyCardinality(a_cardinality)

        # GTEST_API_ ThreadLocal<Sequence*> g_gmock_implicit_sequence;
        var g_gmock_implicit_sequence = ThreadLocal[Sequence]()

        def ReportUninterestingCall(reaction: CallReaction, msg: String):
            var stack_frames_to_skip = 3 if GMOCK_FLAG(verbose) == kInfoVerbosity else -1
            if reaction == kAllow:
                Log(kInfo, msg, stack_frames_to_skip)
            elif reaction == kWarn:
                Log(kWarning, msg + "\nNOTE: You can safely ignore the above warning unless this call should not happen.  Do not suppress it by blindly adding an EXPECT_CALL() if you don't mean to enforce the call.  See https://github.com/google/googletest/blob/master/docs/gmock_cook_book.md#knowing-when-to-expect for details.\n", stack_frames_to_skip)
            else:  # FAIL
                Expect(False, None, -1, msg)

        class UntypedFunctionMockerBase:
            var mock_obj_: Pointer[Void]
            var name_: String
            var untyped_expectations_: UntypedExpectations

            def __init__(self):
                self.mock_obj_ = None
                self.name_ = ""

            def __del__(self):

            def RegisterOwner(self, mock_obj: Pointer[Void]) -> None:
                # GTEST_LOCK_EXCLUDED_(g_gmock_mutex)
                {
                    var l = MutexLock(&g_gmock_mutex)
                    self.mock_obj_ = mock_obj
                }
                Mock.Register(mock_obj, self)

            def SetOwnerAndName(self, mock_obj: Pointer[Void], name: String) -> None:
                # GTEST_LOCK_EXCLUDED_(g_gmock_mutex)
                var l = MutexLock(&g_gmock_mutex)
                self.mock_obj_ = mock_obj
                self.name_ = name

            def MockObject(self) -> Pointer[Void]:
                # GTEST_LOCK_EXCLUDED_(g_gmock_mutex)
                var mock_obj: Pointer[Void]
                {
                    var l = MutexLock(&g_gmock_mutex)
                    Assert(self.mock_obj_ != None, __FILE__, __LINE__, "MockObject() must not be called before RegisterOwner() or SetOwnerAndName() has been called.")
                    mock_obj = self.mock_obj_
                }
                return mock_obj

            def Name(self) -> String:
                # GTEST_LOCK_EXCLUDED_(g_gmock_mutex)
                var name: String
                {
                    var l = MutexLock(&g_gmock_mutex)
                    Assert(self.name_ != None, __FILE__, __LINE__, "Name() must not be called before SetOwnerAndName() has been called.")
                    name = self.name_
                }
                return name

            def UntypedInvokeWith(self, untyped_args: Pointer[Void]) -> UntypedActionResultHolderBase:
                # GTEST_LOCK_EXCLUDED_(g_gmock_mutex)
                if self.untyped_expectations_.size() == 0:
                    var reaction = Mock.GetReactionOnUninterestingCalls(self.MockObject())
                    var need_to_report_uninteresting_call = (reaction == kAllow) ? LogIsVisible(kInfo) : (reaction == kWarn) ? LogIsVisible(kWarning) : True
                    if not need_to_report_uninteresting_call:
                        return self.UntypedPerformDefaultAction(untyped_args, "Function call: " + self.Name())
                    var ss = StringWriter()
                    self.UntypedDescribeUninterestingCall(untyped_args, &ss)
                    var result = self.UntypedPerformDefaultAction(untyped_args, ss.str())
                    if result != None:
                        result.PrintAsActionResult(&ss)
                    ReportUninterestingCall(reaction, ss.str())
                    return result
                var is_excessive = False
                var ss = StringWriter()
                var why = StringWriter()
                var loc = StringWriter()
                var untyped_action: Pointer[Void] = None
                var untyped_expectation = self.UntypedFindMatchingExpectation(untyped_args, &untyped_action, &is_excessive, &ss, &why)
                var found = untyped_expectation != None
                var need_to_report_call = not found or is_excessive or LogIsVisible(kInfo)
                if not need_to_report_call:
                    if untyped_action == None:
                        return self.UntypedPerformDefaultAction(untyped_args, "")
                    else:
                        return self.UntypedPerformAction(untyped_action, untyped_args)
                ss.write("    Function call: ")
                ss.write(self.Name())
                self.UntypedPrintArgs(untyped_args, &ss)
                if found and not is_excessive:
                    untyped_expectation.DescribeLocationTo(&loc)
                var result: UntypedActionResultHolderBase = None
                var perform_action = def ():
                    if untyped_action == None:
                        return self.UntypedPerformDefaultAction(untyped_args, ss.str())
                    else:
                        return self.UntypedPerformAction(untyped_action, untyped_args)
                var handle_failures = def ():
                    ss.write("\n")
                    ss.write(why.str())
                    if not found:
                        Expect(False, None, -1, ss.str())
                    elif is_excessive:
                        Expect(False, untyped_expectation.file(), untyped_expectation.line(), ss.str())
                    else:
                        Log(kInfo, loc.str() + ss.str(), 2)
                # if GTEST_HAS_EXCEPTIONS
                @if __has_feature(cxx_exceptions)
                    try:
                        result = perform_action()
                    except:
                        handle_failures()
                        raise
                # else
                @else
                    result = perform_action()
                # endif
                if result != None:
                    result.PrintAsActionResult(&ss)
                handle_failures()
                return result

            def GetHandleOf(self, exp: ExpectationBase) -> Expectation:
                for it in self.untyped_expectations_.begin() to self.untyped_expectations_.end():
                    if it.get() == exp:
                        return Expectation(*it)
                Assert(False, __FILE__, __LINE__, "Cannot find expectation.")
                return Expectation()

            def VerifyAndClearExpectationsLocked(self) -> Bool:
                # GTEST_EXCLUSIVE_LOCK_REQUIRED_(g_gmock_mutex)
                g_gmock_mutex.AssertHeld()
                var expectations_met = True
                for it in self.untyped_expectations_.begin() to self.untyped_expectations_.end():
                    var untyped_expectation = it.get()
                    if untyped_expectation.IsOverSaturated():
                        expectations_met = False
                    elif not untyped_expectation.IsSatisfied():
                        expectations_met = False
                        var ss = StringWriter()
                        ss.write("Actual function call count doesn't match ")
                        ss.write(untyped_expectation.source_text())
                        ss.write("...\n")
                        untyped_expectation.MaybeDescribeExtraMatcherTo(&ss)
                        untyped_expectation.DescribeCallCountTo(&ss)
                        Expect(False, untyped_expectation.file(), untyped_expectation.line(), ss.str())
                var expectations_to_delete = UntypedExpectations()
                self.untyped_expectations_.swap(expectations_to_delete)
                g_gmock_mutex.Unlock()
                expectations_to_delete.clear()
                g_gmock_mutex.Lock()
                return expectations_met

        def intToCallReaction(mock_behavior: Int) -> CallReaction:
            if mock_behavior >= kAllow and mock_behavior <= kFail:
                return static_cast[CallReaction](mock_behavior)
            return kWarn

    # end module internal

    # namespace {
    type FunctionMockers = Set[internal.UntypedFunctionMockerBase]

    struct MockObjectState:
        var first_used_file: String
        var first_used_line: Int
        var first_used_test_suite: String
        var first_used_test: String
        var leakable: Bool
        var function_mockers: FunctionMockers

        def __init__(self):
            self.first_used_file = None
            self.first_used_line = -1
            self.leakable = False

    class MockObjectRegistry:
        type StateMap = Dict[Pointer[Void], MockObjectState]

        var states_: StateMap

        def __del__(self):
            if not GMOCK_FLAG(catch_leaked_mocks):
                return
            var leaked_count = 0
            for it in self.states_.begin() to self.states_.end():
                if it.second.leakable:
                    continue
                stdout.write("\n")
                var state = it.second
                stdout.write(internal.FormatFileLocation(state.first_used_file, state.first_used_line))
                stdout.write(" ERROR: this mock object")
                if state.first_used_test != "":
                    stdout.write(" (used in test ")
                    stdout.write(state.first_used_test_suite)
                    stdout.write(".")
                    stdout.write(state.first_used_test)
                    stdout.write(")")
                stdout.write(" should be deleted but never is. Its address is @")
                stdout.write(it.first)
                stdout.write(".")
                leaked_count += 1
            if leaked_count > 0:
                stdout.write("\nERROR: ")
                stdout.write(leaked_count)
                stdout.write(" leaked mock ")
                if leaked_count == 1:
                    stdout.write("object")
                else:
                    stdout.write("objects")
                stdout.write(" found at program exit. Expectations on a mock object are verified when the object is destructed. Leaking a mock means that its expectations aren't verified, which is usually a test bug. If you really intend to leak a mock, you can suppress this error using testing::Mock::AllowLeak(mock_object), or you may use a fake or stub instead of a mock.\n")
                stdout.flush()
                stderr.flush()
                _exit(1)

        def states(self) -> StateMap:
            return self.states_

    var g_mock_object_registry = MockObjectRegistry()
    var g_uninteresting_call_reaction: Dict[Pointer[Void], internal.CallReaction]

    def SetReactionOnUninterestingCalls(mock_obj: Pointer[Void], reaction: internal.CallReaction) -> None:
        # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
        var l = internal.MutexLock(&internal.g_gmock_mutex)
        g_uninteresting_call_reaction[mock_obj] = reaction

    # }  // namespace

    class Mock:
        @staticmethod
        def AllowUninterestingCalls(mock_obj: Pointer[Void]) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            SetReactionOnUninterestingCalls(mock_obj, internal.kAllow)

        @staticmethod
        def WarnUninterestingCalls(mock_obj: Pointer[Void]) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            SetReactionOnUninterestingCalls(mock_obj, internal.kWarn)

        @staticmethod
        def FailUninterestingCalls(mock_obj: Pointer[Void]) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            SetReactionOnUninterestingCalls(mock_obj, internal.kFail)

        @staticmethod
        def UnregisterCallReaction(mock_obj: Pointer[Void]) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            g_uninteresting_call_reaction.erase(mock_obj)

        @staticmethod
        def GetReactionOnUninterestingCalls(mock_obj: Pointer[Void]) -> internal.CallReaction:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            if g_uninteresting_call_reaction.count(mock_obj) == 0:
                return internal.intToCallReaction(GMOCK_FLAG(default_mock_behavior))
            else:
                return g_uninteresting_call_reaction[mock_obj]

        @staticmethod
        def AllowLeak(mock_obj: Pointer[Void]) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            g_mock_object_registry.states()[mock_obj].leakable = True

        @staticmethod
        def VerifyAndClearExpectations(mock_obj: Pointer[Void]) -> Bool:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            return Mock.VerifyAndClearExpectationsLocked(mock_obj)

        @staticmethod
        def VerifyAndClear(mock_obj: Pointer[Void]) -> Bool:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            Mock.ClearDefaultActionsLocked(mock_obj)
            return Mock.VerifyAndClearExpectationsLocked(mock_obj)

        @staticmethod
        def VerifyAndClearExpectationsLocked(mock_obj: Pointer[Void]) -> Bool:
            # GTEST_EXCLUSIVE_LOCK_REQUIRED_(internal::g_gmock_mutex)
            internal.g_gmock_mutex.AssertHeld()
            if g_mock_object_registry.states().count(mock_obj) == 0:
                return True
            var expectations_met = True
            var mockers = g_mock_object_registry.states()[mock_obj].function_mockers
            for it in mockers.begin() to mockers.end():
                if not (*it).VerifyAndClearExpectationsLocked():
                    expectations_met = False
            return expectations_met

        @staticmethod
        def IsNaggy(mock_obj: Pointer[Void]) -> Bool:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            return Mock.GetReactionOnUninterestingCalls(mock_obj) == internal.kWarn

        @staticmethod
        def IsNice(mock_obj: Pointer[Void]) -> Bool:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            return Mock.GetReactionOnUninterestingCalls(mock_obj) == internal.kAllow

        @staticmethod
        def IsStrict(mock_obj: Pointer[Void]) -> Bool:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            return Mock.GetReactionOnUninterestingCalls(mock_obj) == internal.kFail

        @staticmethod
        def Register(mock_obj: Pointer[Void], mocker: internal.UntypedFunctionMockerBase) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            g_mock_object_registry.states()[mock_obj].function_mockers.insert(mocker)

        @staticmethod
        def RegisterUseByOnCallOrExpectCall(mock_obj: Pointer[Void], file: String, line: Int) -> None:
            # GTEST_LOCK_EXCLUDED_(internal::g_gmock_mutex)
            var l = internal.MutexLock(&internal.g_gmock_mutex)
            var state = g_mock_object_registry.states()[mock_obj]
            if state.first_used_file == None:
                state.first_used_file = file
                state.first_used_line = line
                var test_info = UnitTest.GetInstance().current_test_info()
                if test_info != None:
                    state.first_used_test_suite = test_info.test_suite_name()
                    state.first_used_test = test_info.name()

        @staticmethod
        def UnregisterLocked(mocker: internal.UntypedFunctionMockerBase) -> None:
            # GTEST_EXCLUSIVE_LOCK_REQUIRED_(internal::g_gmock_mutex)
            internal.g_gmock_mutex.AssertHeld()
            for it in g_mock_object_registry.states().begin() to g_mock_object_registry.states().end():
                var mockers = it.second.function_mockers
                if mockers.erase(mocker) > 0:
                    if mockers.empty():
                        g_mock_object_registry.states().erase(it)
                    return

        @staticmethod
        def ClearDefaultActionsLocked(mock_obj: Pointer[Void]) -> None:
            # GTEST_EXCLUSIVE_LOCK_REQUIRED_(internal::g_gmock_mutex)
            internal.g_gmock_mutex.AssertHeld()
            if g_mock_object_registry.states().count(mock_obj) == 0:
                return
            var mockers = g_mock_object_registry.states()[mock_obj].function_mockers
            for it in mockers.begin() to mockers.end():
                (*it).ClearDefaultActionsLocked()

    class Expectation:
        var expectation_base_: Rc[internal.ExpectationBase]

        def __init__(self):

        def __init__(self, an_expectation_base: Rc[internal.ExpectationBase]):
            self.expectation_base_ = an_expectation_base

        def __del__(self):

    class Sequence:
        var last_expectation_: Rc[Expectation]

        def AddExpectation(self, expectation: Expectation) -> None:
            if *self.last_expectation_ != expectation:
                if self.last_expectation_.expectation_base() != None:
                    expectation.expectation_base().immediate_prerequisites_ += *self.last_expectation_
                *self.last_expectation_ = expectation

    class InSequence:
        var sequence_created_: Bool

        def __init__(self):
            if internal.g_gmock_implicit_sequence.get() == None:
                internal.g_gmock_implicit_sequence.set(Sequence())
                self.sequence_created_ = True
            else:
                self.sequence_created_ = False

        def __del__(self):
            if self.sequence_created_:
                delete internal.g_gmock_implicit_sequence.get()
                internal.g_gmock_implicit_sequence.set(None)

# end module testing

# ifdef _MSC_VER
@if is_windows()
    # if _MSC_VER == 1900
    @if __MSC_VER__ == 1900
        # pragma warning(pop)
    # endif
# endif