from ...gtest.gtest import *
from ...gtest.gtest-death-test import *
from ...gtest.internal.gtest-filepath import *
from ...gtest.gtest-spi import *
from ...src.gtest-internal-inl import *

from testing.internal import AlwaysFalse, AlwaysTrue
from testing.internal import DeathTest, DeathTestFactory
from testing.internal import FilePath
from testing.internal import GetLastErrnoDescription
from testing.internal import GetUnitTestImpl
from testing.internal import InDeathTestChild
from testing.internal import ParseNaturalNumber
from testing.internal import posix
from testing import ContainsRegex, Matcher, Message

# GTEST_HAS_DEATH_TEST is assumed true for this translation
# Platform: Linux (GTEST_OS_LINUX true, others false)
# NDEBUG not defined (debug mode)
# GTEST_USES_PCRE false
# GTEST_HAS_CLONE and GTEST_HAS_PTHREAD true

# ReplaceDeathTestFactory class
class ReplaceDeathTestFactory:
    def __init__(self, new_factory: DeathTestFactory):
        self.unit_test_impl_ = GetUnitTestImpl()
        self.old_factory_ = self.unit_test_impl_.death_test_factory_.release()
        self.unit_test_impl_.death_test_factory_.reset(new_factory)

    def __del__(self):
        self.unit_test_impl_.death_test_factory_.release()
        self.unit_test_impl_.death_test_factory_.reset(self.old_factory_)

# Helper functions
def DieWithMessage(message: String):
    fprintf(stderr, "%s", message.c_str())
    fflush(stderr)
    if AlwaysTrue():
        _exit(1)

def DieInside(function: String):
    DieWithMessage("death inside " + function + "().")

class TestForDeathTest(testing.Test):
    def __init__(self):
        self.original_dir_ = FilePath.GetCurrentDir()
        self.should_die_ = False

    def __del__(self):
        posix.ChDir(self.original_dir_.c_str())

    @staticmethod
    def StaticMemberFunction():
        DieInside("StaticMemberFunction")

    def MemberFunction(self):
        if self.should_die_:
            DieInside("MemberFunction")

class MayDie:
    def __init__(self, should_die: bool):
        self.should_die_ = should_die

    def MemberFunction(self):
        if self.should_die_:
            DieInside("MayDie::MemberFunction")

def GlobalFunction():
    DieInside("GlobalFunction")

def NonVoidFunction() -> int:
    DieInside("NonVoidFunction")
    return 1

def DieIf(should_die: bool):
    if should_die:
        DieInside("DieIf")

def DieIfLessThan(x: int, y: int) -> bool:
    if x < y:
        DieInside("DieIfLessThan")
    return True

def DeathTestSubroutine():
    EXPECT_DEATH(GlobalFunction(), "death.*GlobalFunction")
    ASSERT_DEATH(GlobalFunction(), "death.*GlobalFunction")

def DieInDebugElse12(sideeffect: Pointer[int]) -> int:
    if sideeffect:
        sideeffect[0] = 12
    # ifndef NDEBUG
    DieInside("DieInDebugElse12")
    # endif
    return 12

# Linux-specific: NormalExitStatus, KilledExitStatus
def NormalExitStatus(exit_code: int) -> int:
    child_pid = fork()
    if child_pid == 0:
        _exit(exit_code)
    var status: int
    waitpid(child_pid, &status, 0)
    return status

def KilledExitStatus(signum: int) -> int:
    child_pid = fork()
    if child_pid == 0:
        raise(signum)
        _exit(1)
    var status: int
    waitpid(child_pid, &status, 0)
    return status

# Test cases
def test_ExitStatusPredicateTest_ExitedWithCode():
    const status0 = NormalExitStatus(0)
    const status1 = NormalExitStatus(1)
    const status42 = NormalExitStatus(42)
    const pred0 = testing.ExitedWithCode(0)
    const pred1 = testing.ExitedWithCode(1)
    const pred42 = testing.ExitedWithCode(42)
    EXPECT_PRED1(pred0, status0)
    EXPECT_PRED1(pred1, status1)
    EXPECT_PRED1(pred42, status42)
    EXPECT_FALSE(pred0(status1))
    EXPECT_FALSE(pred42(status0))
    EXPECT_FALSE(pred1(status42))

def test_ExitStatusPredicateTest_KilledBySignal():
    const status_segv = KilledExitStatus(SIGSEGV)
    const status_kill = KilledExitStatus(SIGKILL)
    const pred_segv = testing.KilledBySignal(SIGSEGV)
    const pred_kill = testing.KilledBySignal(SIGKILL)
    EXPECT_PRED1(pred_segv, status_segv)
    EXPECT_PRED1(pred_kill, status_kill)
    EXPECT_FALSE(pred_segv(status_kill))
    EXPECT_FALSE(pred_kill(status_segv))

# TestForDeathTest methods
def TestForDeathTest_SingleStatement(self: TestForDeathTest):
    if AlwaysFalse():
        ASSERT_DEATH(return, "")
    if AlwaysTrue():
        EXPECT_DEATH(_exit(1), "")
    else:

    if AlwaysFalse():
        ASSERT_DEATH(return, "") << "did not die"
    if AlwaysFalse():

    else:
        EXPECT_DEATH(_exit(1), "") << 1 << 2 << 3

def TestForDeathTest_SwitchStatement(self: TestForDeathTest):
    # GTEST_DISABLE_MSC_WARNINGS_PUSH_(4065)
    switch 0:
        default:
            ASSERT_DEATH(_exit(1), "") << "exit in default switch handler"
    switch 0:
        case 0:
            EXPECT_DEATH(_exit(1), "") << "exit in switch case"
    # GTEST_DISABLE_MSC_WARNINGS_POP_()

def TestForDeathTest_StaticMemberFunctionFastStyle(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    ASSERT_DEATH(TestForDeathTest.StaticMemberFunction(), "death.*StaticMember")

def TestForDeathTest_MemberFunctionFastStyle(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    self.should_die_ = True
    EXPECT_DEATH(self.MemberFunction(), "inside.*MemberFunction")

def ChangeToRootDir():
    posix.ChDir("/")

def TestForDeathTest_FastDeathTestInChangedDir(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    ChangeToRootDir()
    EXPECT_EXIT(_exit(1), testing.ExitedWithCode(1), "")
    ChangeToRootDir()
    ASSERT_DEATH(_exit(1), "")

# Linux-specific: SigprofAction, SetSigprofActionAndTimer, DisableSigprofActionAndTimer
def SigprofAction(signum: int, info: Pointer[siginfo_t], context: Pointer[Void]):

def SetSigprofActionAndTimer():
    var signal_action: sigaction
    memset(&signal_action, 0, sizeof(signal_action))
    sigemptyset(&signal_action.sa_mask)
    signal_action.sa_sigaction = SigprofAction
    signal_action.sa_flags = SA_RESTART | SA_SIGINFO
    ASSERT_EQ(0, sigaction(SIGPROF, &signal_action, None))
    var timer: itimerval
    timer.it_interval.tv_sec = 0
    timer.it_interval.tv_usec = 1
    timer.it_value = timer.it_interval
    ASSERT_EQ(0, setitimer(ITIMER_PROF, &timer, None))

def DisableSigprofActionAndTimer(old_signal_action: Pointer[sigaction]):
    var timer: itimerval
    timer.it_interval.tv_sec = 0
    timer.it_interval.tv_usec = 0
    timer.it_value = timer.it_interval
    ASSERT_EQ(0, setitimer(ITIMER_PROF, &timer, None))
    var signal_action: sigaction
    memset(&signal_action, 0, sizeof(signal_action))
    sigemptyset(&signal_action.sa_mask)
    signal_action.sa_handler = SIG_IGN
    ASSERT_EQ(0, sigaction(SIGPROF, &signal_action, old_signal_action))

def TestForDeathTest_FastSigprofActionSet(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    SetSigprofActionAndTimer()
    EXPECT_DEATH(_exit(1), "")
    var old_signal_action: sigaction
    DisableSigprofActionAndTimer(&old_signal_action)
    EXPECT_TRUE(old_signal_action.sa_sigaction == SigprofAction)

def TestForDeathTest_ThreadSafeSigprofActionSet(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    SetSigprofActionAndTimer()
    EXPECT_DEATH(_exit(1), "")
    var old_signal_action: sigaction
    DisableSigprofActionAndTimer(&old_signal_action)
    EXPECT_TRUE(old_signal_action.sa_sigaction == SigprofAction)

def TestForDeathTest_StaticMemberFunctionThreadsafeStyle(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    ASSERT_DEATH(TestForDeathTest.StaticMemberFunction(), "death.*StaticMember")

def TestForDeathTest_MemberFunctionThreadsafeStyle(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    self.should_die_ = True
    EXPECT_DEATH(self.MemberFunction(), "inside.*MemberFunction")

def TestForDeathTest_ThreadsafeDeathTestInLoop(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    for i in range(3):
        EXPECT_EXIT(_exit(i), testing.ExitedWithCode(i), "") << ": i = " << i

def TestForDeathTest_ThreadsafeDeathTestInChangedDir(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    ChangeToRootDir()
    EXPECT_EXIT(_exit(1), testing.ExitedWithCode(1), "")
    ChangeToRootDir()
    ASSERT_DEATH(_exit(1), "")

def TestForDeathTest_MixedStyles(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    EXPECT_DEATH(_exit(1), "")
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_DEATH(_exit(1), "")

# GTEST_HAS_CLONE && GTEST_HAS_PTHREAD
var pthread_flag: bool = False

def SetPthreadFlag():
    pthread_flag = True

def TestForDeathTest_DoesNotExecuteAtforkHooks(self: TestForDeathTest):
    if not testing.GTEST_FLAG.death_test_use_fork:
        testing.GTEST_FLAG.death_test_style = "threadsafe"
        pthread_flag = False
        ASSERT_EQ(0, pthread_atfork(&SetPthreadFlag, None, None))
        ASSERT_DEATH(_exit(1), "")
        ASSERT_FALSE(pthread_flag)

def TestForDeathTest_MethodOfAnotherClass(self: TestForDeathTest):
    const x = MayDie(True)
    ASSERT_DEATH(x.MemberFunction(), "MayDie\\:\\:MemberFunction")

def TestForDeathTest_GlobalFunction(self: TestForDeathTest):
    EXPECT_DEATH(GlobalFunction(), "GlobalFunction")

def TestForDeathTest_AcceptsAnythingConvertibleToRE(self: TestForDeathTest):
    static const regex_c_str: String = "GlobalFunction"
    EXPECT_DEATH(GlobalFunction(), regex_c_str)
    const regex = testing.internal.RE(regex_c_str)
    EXPECT_DEATH(GlobalFunction(), regex)
    # if !GTEST_USES_PCRE
    const regex_std_str: String = regex_c_str
    EXPECT_DEATH(GlobalFunction(), regex_std_str)
    EXPECT_DEATH(GlobalFunction(), String(regex_c_str).c_str())
    # endif

def TestForDeathTest_NonVoidFunction(self: TestForDeathTest):
    ASSERT_DEATH(NonVoidFunction(), "NonVoidFunction")

def TestForDeathTest_FunctionWithParameter(self: TestForDeathTest):
    EXPECT_DEATH(DieIf(True), "DieIf\\(\\)")
    EXPECT_DEATH(DieIfLessThan(2, 3), "DieIfLessThan")

def TestForDeathTest_OutsideFixture(self: TestForDeathTest):
    DeathTestSubroutine()

def TestForDeathTest_InsideLoop(self: TestForDeathTest):
    for i in range(5):
        EXPECT_DEATH(DieIfLessThan(-1, i), "DieIfLessThan") << "where i == " << i

def TestForDeathTest_CompoundStatement(self: TestForDeathTest):
    EXPECT_DEATH({
        const x = 2
        const y = x + 1
        DieIfLessThan(x, y)
    }, "DieIfLessThan")

def TestForDeathTest_DoesNotDie(self: TestForDeathTest):
    EXPECT_NONFATAL_FAILURE(EXPECT_DEATH(DieIf(False), "DieIf"), "failed to die")

def TestForDeathTest_ErrorMessageMismatch(self: TestForDeathTest):
    EXPECT_NONFATAL_FAILURE({
        EXPECT_DEATH(DieIf(True), "DieIfLessThan") << "End of death test message."
    }, "died but not with expected error")

def ExpectDeathTestHelper(aborted: Pointer[bool]):
    aborted[0] = True
    EXPECT_DEATH(DieIf(False), "DieIf")
    aborted[0] = False

def TestForDeathTest_EXPECT_DEATH(self: TestForDeathTest):
    var aborted: bool = True
    EXPECT_NONFATAL_FAILURE(ExpectDeathTestHelper(&aborted), "failed to die")
    EXPECT_FALSE(aborted)

def TestForDeathTest_ASSERT_DEATH(self: TestForDeathTest):
    static var aborted: bool = False
    EXPECT_FATAL_FAILURE({
        aborted = True
        ASSERT_DEATH(DieIf(False), "DieIf")
        aborted = False
    }, "failed to die")
    EXPECT_TRUE(aborted)

def TestForDeathTest_SingleEvaluation(self: TestForDeathTest):
    var x: int = 3
    EXPECT_DEATH(DieIf((++x) == 4), "DieIf")
    var regex: String = "DieIf"
    const regex_save = regex
    EXPECT_DEATH(DieIfLessThan(3, 4), regex++)
    EXPECT_EQ(regex_save + 1, regex)

def TestForDeathTest_RunawayIsFailure(self: TestForDeathTest):
    EXPECT_NONFATAL_FAILURE(EXPECT_DEATH(static_cast[Void](0), "Foo"), "failed to die.")

def TestForDeathTest_ReturnIsFailure(self: TestForDeathTest):
    EXPECT_FATAL_FAILURE(ASSERT_DEATH(return, "Bar"), "illegal return in test statement.")

def TestForDeathTest_TestExpectDebugDeath(self: TestForDeathTest):
    var sideeffect: int = 0
    const regex: String = "death.*DieInDebugElse12"
    EXPECT_DEBUG_DEATH(DieInDebugElse12(&sideeffect), regex) << "Must accept a streamed message"
    # ifdef NDEBUG
    EXPECT_EQ(12, sideeffect)
    # else
    EXPECT_EQ(0, sideeffect)
    # endif

def TestForDeathTest_TestAssertDebugDeath(self: TestForDeathTest):
    var sideeffect: int = 0
    ASSERT_DEBUG_DEATH(DieInDebugElse12(&sideeffect), "death.*DieInDebugElse12") << "Must accept a streamed message"
    # ifdef NDEBUG
    EXPECT_EQ(12, sideeffect)
    # else
    EXPECT_EQ(0, sideeffect)
    # endif

# ifndef NDEBUG
def ExpectDebugDeathHelper(aborted: Pointer[bool]):
    aborted[0] = True
    EXPECT_DEBUG_DEATH(return, "") << "This is expected to fail."
    aborted[0] = False

def TestForDeathTest_ExpectDebugDeathDoesNotAbort(self: TestForDeathTest):
    var aborted: bool = True
    EXPECT_NONFATAL_FAILURE(ExpectDebugDeathHelper(&aborted), "")
    EXPECT_FALSE(aborted)

def AssertDebugDeathHelper(aborted: Pointer[bool]):
    aborted[0] = True
    GTEST_LOG_(INFO) << "Before ASSERT_DEBUG_DEATH"
    ASSERT_DEBUG_DEATH(GTEST_LOG_(INFO) << "In ASSERT_DEBUG_DEATH"; return, "") << "This is expected to fail."
    GTEST_LOG_(INFO) << "After ASSERT_DEBUG_DEATH"
    aborted[0] = False

def TestForDeathTest_AssertDebugDeathAborts(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts2(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts3(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts4(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts5(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts6(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts7(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts8(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts9(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)

def TestForDeathTest_AssertDebugDeathAborts10(self: TestForDeathTest):
    static var aborted: bool = False
    aborted = False
    EXPECT_FATAL_FAILURE(AssertDebugDeathHelper(&aborted), "")
    EXPECT_TRUE(aborted)
# endif

def TestExitMacros():
    EXPECT_EXIT(_exit(1), testing.ExitedWithCode(1), "")
    ASSERT_EXIT(_exit(42), testing.ExitedWithCode(42), "")
    # if !GTEST_OS_FUCHSIA
    EXPECT_EXIT(raise(SIGKILL), testing.KilledBySignal(SIGKILL), "") << "foo"
    ASSERT_EXIT(raise(SIGUSR2), testing.KilledBySignal(SIGUSR2), "") << "bar"
    EXPECT_FATAL_FAILURE({
        ASSERT_EXIT(_exit(0), testing.KilledBySignal(SIGSEGV), "") << "This failure is expected, too."
    }, "This failure is expected, too.")
    # endif
    EXPECT_NONFATAL_FAILURE({
        EXPECT_EXIT(raise(SIGSEGV), testing.ExitedWithCode(0), "") << "This failure is expected."
    }, "This failure is expected.")

def TestForDeathTest_ExitMacros(self: TestForDeathTest):
    TestExitMacros()

def TestForDeathTest_ExitMacrosUsingFork(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_use_fork = True
    TestExitMacros()

def TestForDeathTest_InvalidStyle(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "rococo"
    EXPECT_NONFATAL_FAILURE({
        EXPECT_DEATH(_exit(0), "") << "This failure is expected."
    }, "This failure is expected.")

def TestForDeathTest_DeathTestFailedOutput(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_NONFATAL_FAILURE(
        EXPECT_DEATH(DieWithMessage("death\n"), "expected message"),
        "Actual msg:\n[  DEATH   ] death\n")

def TestForDeathTest_DeathTestUnexpectedReturnOutput(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_NONFATAL_FAILURE(
        EXPECT_DEATH({
            fprintf(stderr, "returning\n")
            fflush(stderr)
            return
        }, ""),
        "    Result: illegal return in test statement.\n Error msg:\n[  DEATH   ] returning\n")

def TestForDeathTest_DeathTestBadExitCodeOutput(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_NONFATAL_FAILURE(
        EXPECT_EXIT(DieWithMessage("exiting with rc 1\n"), testing.ExitedWithCode(3), "expected message"),
        "    Result: died but not with expected exit code:\n            Exited with exit status 1\nActual msg:\n[  DEATH   ] exiting with rc 1\n")

def TestForDeathTest_DeathTestMultiLineMatchFail(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_NONFATAL_FAILURE(
        EXPECT_DEATH(DieWithMessage("line 1\nline 2\nline 3\n"), "line 1\nxyz\nline 3\n"),
        "Actual msg:\n[  DEATH   ] line 1\n[  DEATH   ] line 2\n[  DEATH   ] line 3\n")

def TestForDeathTest_DeathTestMultiLineMatchPass(self: TestForDeathTest):
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_DEATH(DieWithMessage("line 1\nline 2\nline 3\n"), "line 1\nline 2\nline 3\n")

# MockDeathTestFactory and MockDeathTest
class MockDeathTestFactory(DeathTestFactory):
    def __init__(self):
        self.create_ = True
        self.role_ = DeathTest.OVERSEE_TEST
        self.status_ = 0
        self.passed_ = True
        self.assume_role_calls_ = 0
        self.wait_calls_ = 0
        self.passed_args_ = List[bool]()
        self.abort_args_ = List[DeathTest.AbortReason]()
        self.test_deleted_ = False

    def Create(self, statement: String, matcher: Matcher[String], file: String, line: int, test: Pointer[DeathTest]) -> bool:
        self.test_deleted_ = False
        if self.create_:
            test[0] = MockDeathTest(self, self.role_, self.status_, self.passed_)
        else:
            test[0] = None
        return True

    def SetParameters(self, create: bool, role: DeathTest.TestRole, status: int, passed: bool):
        self.create_ = create
        self.role_ = role
        self.status_ = status
        self.passed_ = passed
        self.assume_role_calls_ = 0
        self.wait_calls_ = 0
        self.passed_args_.clear()
        self.abort_args_.clear()

    def AssumeRoleCalls(self) -> int:
        return self.assume_role_calls_

    def WaitCalls(self) -> int:
        return self.wait_calls_

    def PassedCalls(self) -> int:
        return len(self.passed_args_)

    def PassedArgument(self, n: int) -> bool:
        return self.passed_args_[n]

    def AbortCalls(self) -> int:
        return len(self.abort_args_)

    def AbortArgument(self, n: int) -> DeathTest.AbortReason:
        return self.abort_args_[n]

    def TestDeleted(self) -> bool:
        return self.test_deleted_

class MockDeathTest(DeathTest):
    def __init__(self, parent: MockDeathTestFactory, role: DeathTest.TestRole, status: int, passed: bool):
        self.parent_ = parent
        self.role_ = role
        self.status_ = status
        self.passed_ = passed

    def __del__(self):
        self.parent_.test_deleted_ = True

    def AssumeRole(self) -> DeathTest.TestRole:
        self.parent_.assume_role_calls_ += 1
        return self.role_

    def Wait(self) -> int:
        self.parent_.wait_calls_ += 1
        return self.status_

    def Passed(self, exit_status_ok: bool) -> bool:
        self.parent_.passed_args_.append(exit_status_ok)
        return self.passed_

    def Abort(self, reason: DeathTest.AbortReason):
        self.parent_.abort_args_.append(reason)

# MacroLogicDeathTest
class MacroLogicDeathTest(testing.Test):
    static var replacer_: ReplaceDeathTestFactory = None
    static var factory_: MockDeathTestFactory = None

    @staticmethod
    def SetUpTestSuite():
        factory_ = MockDeathTestFactory()
        replacer_ = ReplaceDeathTestFactory(factory_)

    @staticmethod
    def TearDownTestSuite():
        del replacer_
        replacer_ = None
        del factory_
        factory_ = None

    @staticmethod
    def RunReturningDeathTest(flag: Pointer[bool]):
        ASSERT_DEATH({
            flag[0] = True
            return
        }, "")

def MacroLogicDeathTest_NothingHappens(self: MacroLogicDeathTest):
    var flag: bool = False
    factory_.SetParameters(False, DeathTest.OVERSEE_TEST, 0, True)
    EXPECT_DEATH(flag = True, "")
    EXPECT_FALSE(flag)
    EXPECT_EQ(0, factory_.AssumeRoleCalls())
    EXPECT_EQ(0, factory_.WaitCalls())
    EXPECT_EQ(0, factory_.PassedCalls())
    EXPECT_EQ(0, factory_.AbortCalls())
    EXPECT_FALSE(factory_.TestDeleted())

def MacroLogicDeathTest_ChildExitsSuccessfully(self: MacroLogicDeathTest):
    var flag: bool = False
    factory_.SetParameters(True, DeathTest.OVERSEE_TEST, 0, True)
    EXPECT_DEATH(flag = True, "")
    EXPECT_FALSE(flag)
    EXPECT_EQ(1, factory_.AssumeRoleCalls())
    EXPECT_EQ(1, factory_.WaitCalls())
    ASSERT_EQ(1, factory_.PassedCalls())
    EXPECT_FALSE(factory_.PassedArgument(0))
    EXPECT_EQ(0, factory_.AbortCalls())
    EXPECT_TRUE(factory_.TestDeleted())

def MacroLogicDeathTest_ChildExitsUnsuccessfully(self: MacroLogicDeathTest):
    var flag: bool = False
    factory_.SetParameters(True, DeathTest.OVERSEE_TEST, 1, True)
    EXPECT_DEATH(flag = True, "")
    EXPECT_FALSE(flag)
    EXPECT_EQ(1, factory_.AssumeRoleCalls())
    EXPECT_EQ(1, factory_.WaitCalls())
    ASSERT_EQ(1, factory_.PassedCalls())
    EXPECT_TRUE(factory_.PassedArgument(0))
    EXPECT_EQ(0, factory_.AbortCalls())
    EXPECT_TRUE(factory_.TestDeleted())

def MacroLogicDeathTest_ChildPerformsReturn(self: MacroLogicDeathTest):
    var flag: bool = False
    factory_.SetParameters(True, DeathTest.EXECUTE_TEST, 0, True)
    RunReturningDeathTest(&flag)
    EXPECT_TRUE(flag)
    EXPECT_EQ(1, factory_.AssumeRoleCalls())
    EXPECT_EQ(0, factory_.WaitCalls())
    EXPECT_EQ(0, factory_.PassedCalls())
    EXPECT_EQ(1, factory_.AbortCalls())
    EXPECT_EQ(DeathTest.TEST_ENCOUNTERED_RETURN_STATEMENT, factory_.AbortArgument(0))
    EXPECT_TRUE(factory_.TestDeleted())

def MacroLogicDeathTest_ChildDoesNotDie(self: MacroLogicDeathTest):
    var flag: bool = False
    factory_.SetParameters(True, DeathTest.EXECUTE_TEST, 0, True)
    EXPECT_DEATH(flag = True, "")
    EXPECT_TRUE(flag)
    EXPECT_EQ(1, factory_.AssumeRoleCalls())
    EXPECT_EQ(0, factory_.WaitCalls())
    EXPECT_EQ(0, factory_.PassedCalls())
    ASSERT_EQ(2, factory_.AbortCalls())
    EXPECT_EQ(DeathTest.TEST_DID_NOT_DIE, factory_.AbortArgument(0))
    EXPECT_EQ(DeathTest.TEST_ENCOUNTERED_RETURN_STATEMENT, factory_.AbortArgument(1))
    EXPECT_TRUE(factory_.TestDeleted())

def test_SuccessRegistrationDeathTest_NoSuccessPart():
    EXPECT_DEATH(_exit(1), "")
    EXPECT_EQ(0, GetUnitTestImpl().current_test_result().total_part_count())

def test_StreamingAssertionsDeathTest_DeathTest():
    EXPECT_DEATH(_exit(1), "") << "unexpected failure"
    ASSERT_DEATH(_exit(1), "") << "unexpected failure"
    EXPECT_NONFATAL_FAILURE({
        EXPECT_DEATH(_exit(0), "") << "expected failure"
    }, "expected failure")
    EXPECT_FATAL_FAILURE({
        ASSERT_DEATH(_exit(0), "") << "expected failure"
    }, "expected failure")

def test_GetLastErrnoDescription_GetLastErrnoDescriptionWorks():
    errno = ENOENT
    EXPECT_STRNE("", GetLastErrnoDescription().c_str())
    errno = 0
    EXPECT_STREQ("", GetLastErrnoDescription().c_str())

# ParseNaturalNumber tests
const kBiggestParsableMax: BiggestParsable = ULLONG_MAX
const kBiggestSignedParsableMax: BiggestSignedParsable = LLONG_MAX

def test_ParseNaturalNumber_RejectsInvalidFormat():
    var result: BiggestParsable = 0
    EXPECT_FALSE(ParseNaturalNumber("non-number string", &result))
    EXPECT_FALSE(ParseNaturalNumber(" 123", &result))
    EXPECT_FALSE(ParseNaturalNumber("-123", &result))
    EXPECT_FALSE(ParseNaturalNumber("+123", &result))
    errno = 0

def test_ParseNaturalNumber_RejectsOverflownNumbers():
    var result: BiggestParsable = 0
    EXPECT_FALSE(ParseNaturalNumber("99999999999999999999999", &result))
    var char_result: signed char = 0
    EXPECT_FALSE(ParseNaturalNumber("200", &char_result))
    errno = 0

def test_ParseNaturalNumber_AcceptsValidNumbers():
    var result: BiggestParsable = 0
    result = 0
    ASSERT_TRUE(ParseNaturalNumber("123", &result))
    EXPECT_EQ(123, result)
    result = 1
    ASSERT_TRUE(ParseNaturalNumber("0", &result))
    EXPECT_EQ(0, result)
    result = 1
    ASSERT_TRUE(ParseNaturalNumber("00000", &result))
    EXPECT_EQ(0, result)

def test_ParseNaturalNumber_AcceptsTypeLimits():
    var msg: Message
    msg << kBiggestParsableMax
    var result: BiggestParsable = 0
    EXPECT_TRUE(ParseNaturalNumber(msg.GetString(), &result))
    EXPECT_EQ(kBiggestParsableMax, result)
    var msg2: Message
    msg2 << kBiggestSignedParsableMax
    var signed_result: BiggestSignedParsable = 0
    EXPECT_TRUE(ParseNaturalNumber(msg2.GetString(), &signed_result))
    EXPECT_EQ(kBiggestSignedParsableMax, signed_result)
    var msg3: Message
    msg3 << INT_MAX
    var int_result: int = 0
    EXPECT_TRUE(ParseNaturalNumber(msg3.GetString(), &int_result))
    EXPECT_EQ(INT_MAX, int_result)
    var msg4: Message
    msg4 << UINT_MAX
    var uint_result: unsigned int = 0
    EXPECT_TRUE(ParseNaturalNumber(msg4.GetString(), &uint_result))
    EXPECT_EQ(UINT_MAX, uint_result)

def test_ParseNaturalNumber_WorksForShorterIntegers():
    var short_result: short = 0
    ASSERT_TRUE(ParseNaturalNumber("123", &short_result))
    EXPECT_EQ(123, short_result)
    var char_result: signed char = 0
    ASSERT_TRUE(ParseNaturalNumber("123", &char_result))
    EXPECT_EQ(123, char_result)

def test_ConditionalDeathMacrosDeathTest_ExpectsDeathWhenDeathTestsAvailable():
    EXPECT_DEATH_IF_SUPPORTED(DieInside("CondDeathTestExpectMacro"), "death inside CondDeathTestExpectMacro")
    ASSERT_DEATH_IF_SUPPORTED(DieInside("CondDeathTestAssertMacro"), "death inside CondDeathTestAssertMacro")
    EXPECT_NONFATAL_FAILURE(EXPECT_DEATH_IF_SUPPORTED(;, ""), "")
    EXPECT_FATAL_FAILURE(ASSERT_DEATH_IF_SUPPORTED(;, ""), "")

def test_InDeathTestChildDeathTest_ReportsDeathTestCorrectlyInFastStyle():
    testing.GTEST_FLAG.death_test_style = "fast"
    EXPECT_FALSE(InDeathTestChild())
    EXPECT_DEATH({
        fprintf(stderr, InDeathTestChild() ? "Inside" : "Outside")
        fflush(stderr)
        _exit(1)
    }, "Inside")

def test_InDeathTestChildDeathTest_ReportsDeathTestCorrectlyInThreadSafeStyle():
    testing.GTEST_FLAG.death_test_style = "threadsafe"
    EXPECT_FALSE(InDeathTestChild())
    EXPECT_DEATH({
        fprintf(stderr, InDeathTestChild() ? "Inside" : "Outside")
        fflush(stderr)
        _exit(1)
    }, "Inside")

def DieWithMessage(message: String):
    fputs(message, stderr)
    fflush(stderr)
    _exit(1)

def test_MatcherDeathTest_DoesNotBreakBareRegexMatching():
    # if GTEST_USES_POSIX_RE
    EXPECT_DEATH(DieWithMessage("O, I die, Horatio."), "I d[aeiou]e")
    # else
    # EXPECT_DEATH(DieWithMessage("O, I die, Horatio."), "I di?e")
    # endif

def test_MatcherDeathTest_MonomorphicMatcherMatches():
    EXPECT_DEATH(DieWithMessage("Behind O, I am slain!"), Matcher[String](ContainsRegex("I am slain")))

def test_MatcherDeathTest_MonomorphicMatcherDoesNotMatch():
    EXPECT_NONFATAL_FAILURE(
        EXPECT_DEATH(DieWithMessage("Behind O, I am slain!"), Matcher[String](ContainsRegex("Ow, I am slain"))),
        "Expected: contains regular expression \"Ow, I am slain\"")

def test_MatcherDeathTest_PolymorphicMatcherMatches():
    EXPECT_DEATH(DieWithMessage("The rest is silence."), ContainsRegex("rest is silence"))

def test_MatcherDeathTest_PolymorphicMatcherDoesNotMatch():
    EXPECT_NONFATAL_FAILURE(
        EXPECT_DEATH(DieWithMessage("The rest is silence."), ContainsRegex("rest is science")),
        "Expected: contains regular expression \"rest is science\"")

# Common section after #endif (ConditionalDeathMacrosSyntaxDeathTest)
def test_ConditionalDeathMacrosSyntaxDeathTest_SingleStatement():
    if AlwaysFalse():
        ASSERT_DEATH_IF_SUPPORTED(return, "")
    if AlwaysTrue():
        EXPECT_DEATH_IF_SUPPORTED(_exit(1), "")
    else:

    if AlwaysFalse():
        ASSERT_DEATH_IF_SUPPORTED(return, "") << "did not die"
    if AlwaysFalse():

    else:
        EXPECT_DEATH_IF_SUPPORTED(_exit(1), "") << 1 << 2 << 3

def test_ConditionalDeathMacrosSyntaxDeathTest_SwitchStatement():
    # GTEST_DISABLE_MSC_WARNINGS_PUSH_(4065)
    switch 0:
        default:
            ASSERT_DEATH_IF_SUPPORTED(_exit(1), "") << "exit in default switch handler"
    switch 0:
        case 0:
            EXPECT_DEATH_IF_SUPPORTED(_exit(1), "") << "exit in switch case"
    # GTEST_DISABLE_MSC_WARNINGS_POP_()

def test_NotADeathTest_Test():
    SUCCEED()