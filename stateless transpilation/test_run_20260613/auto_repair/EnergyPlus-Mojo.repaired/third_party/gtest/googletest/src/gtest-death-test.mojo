// This is a faithful 1:1 translation from C++ to Mojo.
// Preprocessor conditionals are preserved as comments where Mojo has no equivalent.
// System headers and platform-specific APIs are not translated; they remain as placeholders.

from gtest.gtest-death-test.h import *
from functional import *
from utility import *
from gtest.internal.gtest-port.h import *
from gtest.internal.custom.gtest.h import *

// #if GTEST_HAS_DEATH_TEST
// #if GTEST_OS_MAC
// #include <crt_externs.h>
// #endif // GTEST_OS_MAC
// #include <errno.h>
// #include <fcntl.h>
// #include <limits.h>
// #if GTEST_OS_LINUX
// #include <signal.h>
// #endif // GTEST_OS_LINUX
// #include <stdarg.h>
// #if GTEST_OS_WINDOWS
// #include <windows.h>
// #else
// #include <sys/mman.h>
// #include <sys/wait.h>
// #endif // GTEST_OS_WINDOWS
// #if GTEST_OS_QNX
// #include <spawn.h>
// #endif // GTEST_OS_QNX
// #if GTEST_OS_FUCHSIA
// #include <lib/fdio/fd.h>
// #include <lib/fdio/io.h>
// #include <lib/fdio/spawn.h>
// #include <lib/zx/channel.h>
// #include <lib/zx/port.h>
// #include <lib/zx/process.h>
// #include <lib/zx/socket.h>
// #include <zircon/processargs.h>
// #include <zircon/syscalls.h>
// #include <zircon/syscalls/policy.h>
// #include <zircon/syscalls/port.h>
// #endif // GTEST_OS_FUCHSIA
// #endif // GTEST_HAS_DEATH_TEST

from gtest.gtest-message.h import *
from gtest.internal.gtest-string.h import *
from src.gtest-internal-inl.h import *

namespace testing:

    static var kDefaultDeathTestStyle: String = GTEST_DEFAULT_DEATH_TEST_STYLE

    GTEST_DEFINE_string_(
        "death_test_style",
        internal.StringFromGTestEnv("death_test_style", kDefaultDeathTestStyle),
        "Indicates how to run a death test in a forked child process: "
        "\"threadsafe\" (child process re-executes the test binary "
        "from the beginning, running only the specific death test) or "
        "\"fast\" (child process runs the death test immediately "
        "after forking)."
    )

    GTEST_DEFINE_bool_(
        "death_test_use_fork",
        internal.BoolFromGTestEnv("death_test_use_fork", false),
        "Instructs to use fork()/_exit() instead of clone() in death tests. "
        "Ignored and always uses fork() on POSIX systems where clone() is not "
        "implemented. Useful when running under valgrind or similar tools if "
        "those do not support clone(). Valgrind 3.3.1 will just fail if "
        "it sees an unsupported combination of clone() flags. "
        "It is not recommended to use this flag w/o valgrind though it will "
        "work in 99% of the cases. Once valgrind is fixed, this flag will "
        "most likely be removed."
    )

    namespace internal:

        GTEST_DEFINE_string_(
            "internal_run_death_test", "",
            "Indicates the file, line number, temporal index of "
            "the single death test to run, and a file descriptor to "
            "which a success code may be sent, all separated by "
            "the '|' characters.  This flag is specified if and only if the "
            "current process is a sub-process launched for running a thread-safe "
            "death test.  FOR INTERNAL USE ONLY."
        )

    // namespace internal

    // #if GTEST_HAS_DEATH_TEST
    namespace internal:

        // #if !GTEST_OS_WINDOWS && !GTEST_OS_FUCHSIA
        static var g_in_fast_death_test_child: Bool = false
        // #endif

        def InDeathTestChild() -> Bool:
            // #if GTEST_OS_WINDOWS || GTEST_OS_FUCHSIA
            //   return !GTEST_FLAG(internal_run_death_test).empty();
            // #else
            if GTEST_FLAG.death_test_style == "threadsafe":
                return not GTEST_FLAG.internal_run_death_test.isEmpty()
            else:
                return g_in_fast_death_test_child
            // #endif

    // namespace internal

    struct ExitedWithCode:
        var exit_code_: Int
        def __init__(inout self, exit_code: Int):
            self.exit_code_ = exit_code
        def __call__(self, exit_status: Int) -> Bool:
            // #if GTEST_OS_WINDOWS || GTEST_OS_FUCHSIA
            //   return exit_status == exit_code_;
            // #else
            return WIFEXITED(exit_status) and WEXITSTATUS(exit_status) == self.exit_code_
            // #endif // GTEST_OS_WINDOWS || GTEST_OS_FUCHSIA

    // #if !GTEST_OS_WINDOWS && !GTEST_OS_FUCHSIA
    struct KilledBySignal:
        var signum_: Int
        def __init__(inout self, signum: Int):
            self.signum_ = signum
        def __call__(self, exit_status: Int) -> Bool:
            // #if defined(GTEST_KILLED_BY_SIGNAL_OVERRIDE_)
            //   {
            //     bool result;
            //     if (GTEST_KILLED_BY_SIGNAL_OVERRIDE_(signum_, exit_status, &result)) {
            //       return result;
            //     }
            //   }
            // #endif  // defined(GTEST_KILLED_BY_SIGNAL_OVERRIDE_)
            return WIFSIGNALED(exit_status) and WTERMSIG(exit_status) == self.signum_
    // #endif // !GTEST_OS_WINDOWS && !GTEST_OS_FUCHSIA

    namespace internal:

        def ExitSummary(exit_code: Int) -> String:
            var m = Message()
            // #if GTEST_OS_WINDOWS || GTEST_OS_FUCHSIA
            //   m << "Exited with exit status " << exit_code;
            // #else
            if WIFEXITED(exit_code):
                m << "Exited with exit status " << WEXITSTATUS(exit_code)
            else if WIFSIGNALED(exit_code):
                m << "Terminated by signal " << WTERMSIG(exit_code)
            // #ifdef WCOREDUMP
            if WCOREDUMP(exit_code):
                m << " (core dumped)"
            // #endif
            // #endif // GTEST_OS_WINDOWS || GTEST_OS_FUCHSIA
            return m.GetString()

        def ExitedUnsuccessfully(exit_status: Int) -> Bool:
            return not ExitedWithCode(0)(exit_status)

        // #if !GTEST_OS_WINDOWS && !GTEST_OS_FUCHSIA
        def DeathTestThreadWarning(thread_count: size_t) -> String:
            var msg = Message()
            msg << "Death tests use fork(), which is unsafe particularly"
                << " in a threaded context. For this test, " << GTEST_NAME_ << " "
            if thread_count == 0:
                msg << "couldn't detect the number of threads."
            else:
                msg << "detected " << thread_count << " threads."
            msg << " See "
                << "https://github.com/google/googletest/blob/master/docs/"
                   "advanced.md#death-tests-and-threads"
                << " for more explanation and suggested solutions, especially if"
                << " this is the last message you see before your test times out."
            return msg.GetString()
        // #endif // !GTEST_OS_WINDOWS && !GTEST_OS_FUCHSIA

        static var kDeathTestLived: Char = 'L'
        static var kDeathTestReturned: Char = 'R'
        static var kDeathTestThrew: Char = 'T'
        static var kDeathTestInternalError: Char = 'I'
        // #if GTEST_OS_FUCHSIA
        static var kFuchsiaReadPipeFd: Int = 3
        // #endif

        enum DeathTestOutcome:
            IN_PROGRESS
            DIED
            LIVED
            RETURNED
            THREW

        def DeathTestAbort(message: String):
            var flag = GetUnitTestImpl().internal_run_death_test_flag()
            if flag != None:
                var parent = posix.FDOpen(flag.write_fd(), "w")
                fputc(kDeathTestInternalError, parent)
                fprintf(parent, "%s", message.c_str())
                fflush(parent)
                _exit(1)
            else:
                fprintf(stderr, "%s", message.c_str())
                fflush(stderr)
                posix.Abort()

        // # define GTEST_DEATH_TEST_CHECK_(expression) \
        //   do { \
        //     if (!::testing::internal::IsTrue(expression)) { \
        //       DeathTestAbort( \
        //           ::string("CHECK failed: File ") + __FILE__ +  ", line " \
        //           + ::testing::internal::StreamableToString(__LINE__) + ": " \
        //           + #expression); \
        //     } \
        //   } while (::testing::internal::AlwaysFalse())
        def GTEST_DEATH_TEST_CHECK_(expression: Bool):
            if not ::testing.internal.IsTrue(expression):
                DeathTestAbort(
                    String("CHECK failed: File ") + __FILE__ + ", line " +
                    ::testing.internal.StreamableToString(__LINE__) + ": " +
                    "expression"
                )

        // # define GTEST_DEATH_TEST_CHECK_SYSCALL_(expression) \
        //   do { \
        //     int gtest_retval; \
        //     do { \
        //       gtest_retval = (expression); \
        //     } while (gtest_retval == -1 && errno == EINTR); \
        //     if (gtest_retval == -1) { \
        //       DeathTestAbort( \
        //           ::string("CHECK failed: File ") + __FILE__ + ", line " \
        //           + ::testing::internal::StreamableToString(__LINE__) + ": " \
        //           + #expression + " != -1"); \
        //     } \
        //   } while (::testing::internal::AlwaysFalse())
        def GTEST_DEATH_TEST_CHECK_SYSCALL_(expression: Int) -> Int:
            var gtest_retval: Int
            while True:
                gtest_retval = expression
                if gtest_retval != -1:
                    break
                // errno == EINTR (simulated)
                // we'll assume loop continues
            if gtest_retval == -1:
                DeathTestAbort(
                    String("CHECK failed: File ") + __FILE__ + ", line " +
                    ::testing.internal.StreamableToString(__LINE__) + ": " +
                    "expression != -1"
                )
            return gtest_retval

        def GetLastErrnoDescription() -> String:
            return "" if errno == 0 else posix.StrError(errno)

        def FailFromInternalError(fd: Int):
            var error = Message()
            var buffer: array[Int8, 256] = 0
            var num_read: Int
            while True:
                num_read = posix.Read(fd, buffer, 255)
                if num_read <= 0:
                    break
                buffer[num_read] = 0
                error << String(buffer)
            if num_read == 0:
                GTEST_LOG_(FATAL) << error.GetString()
            else:
                var last_error = errno
                GTEST_LOG_(FATAL) << "Error while reading death test internal: " << GetLastErrnoDescription() << " [" << last_error << "]"

        struct DeathTest:
            // abstract base class; we simulate with methods
            @staticmethod
            def __init__(inout self):
                var info = GetUnitTestImpl().current_test_info()
                if info == None:
                    DeathTestAbort("Cannot run a death test outside of a TEST or "
                                   "TEST_F construct")

            @staticmethod
            def Create(statement: String, matcher: Matcher[String], file: String, line: Int, test: Pointer[DeathTest]) -> Bool:
                return GetUnitTestImpl().death_test_factory().Create(statement, matcher, file, line, test)

            @staticmethod
            def LastMessage() -> String:
                return last_death_test_message_.c_str()

            @staticmethod
            def set_last_death_test_message(message: String):
                last_death_test_message_ = message

            static var last_death_test_message_: String = String()

        struct DeathTestImpl(DeathTest):
            // protected:
            var statement_: String
            var matcher_: Matcher[String]
            var spawned_: Bool
            var status_: Int
            var outcome_: DeathTestOutcome
            var read_fd_: Int
            var write_fd_: Int

            def __init__(inout self, a_statement: String, matcher: Matcher[String]):
                self.statement_ = a_statement
                self.matcher_ = matcher
                self.spawned_ = False
                self.status_ = -1
                self.outcome_ = DeathTestOutcome.IN_PROGRESS
                self.read_fd_ = -1
                self.write_fd_ = -1

            def __del__(inout self):
                GTEST_DEATH_TEST_CHECK_(self.read_fd_ == -1)

            def Abort(inout self, reason: AbortReason):
                var status_ch = (kDeathTestLived if reason == TEST_DID_NOT_DIE else
                                 kDeathTestThrew if reason == TEST_THREW_EXCEPTION else
                                 kDeathTestReturned)
                GTEST_DEATH_TEST_CHECK_SYSCALL_(posix.Write(self.write_fd_, status_ch, 1))
                _exit(1)

            def Passed(self, status_ok: Bool) -> Bool:
                if not self.spawned():
                    return False
                var error_message = self.GetErrorLogs()
                var success = False
                var buffer = Message()
                buffer << "Death test: " << self.statement_ << "\n"
                match self.outcome_:
                    case DeathTestOutcome.LIVED:
                        buffer << "    Result: failed to die.\n"
                               << " Error msg:\n" << FormatDeathTestOutput(error_message)
                    case DeathTestOutcome.THREW:
                        buffer << "    Result: threw an exception.\n"
                               << " Error msg:\n" << FormatDeathTestOutput(error_message)
                    case DeathTestOutcome.RETURNED:
                        buffer << "    Result: illegal return in test statement.\n"
                               << " Error msg:\n" << FormatDeathTestOutput(error_message)
                    case DeathTestOutcome.DIED:
                        if status_ok:
                            if self.matcher_.Matches(error_message):
                                success = True
                            else:
                                var stream = OStringStream()
                                self.matcher_.DescribeTo(&stream)
                                buffer << "    Result: died but not with expected error.\n"
                                       << "  Expected: " << stream.str() << "\n"
                                       << "Actual msg:\n" << FormatDeathTestOutput(error_message)
                        else:
                            buffer << "    Result: died but not with expected exit code:\n"
                                   << "            " << ExitSummary(self.status_) << "\n"
                                   << "Actual msg:\n" << FormatDeathTestOutput(error_message)
                    case DeathTestOutcome.IN_PROGRESS:
                        GTEST_LOG_(FATAL) << "DeathTest::Passed somehow called before conclusion of test"
                DeathTest.set_last_death_test_message(buffer.GetString())
                return success

            def ReadAndInterpretStatusByte(self):
                var flag: Char
                var bytes_read: Int
                while True:
                    bytes_read = posix.Read(self.read_fd_, &flag, 1)
                    if bytes_read != -1:
                        break
                if bytes_read == 0:
                    self.set_outcome(DeathTestOutcome.DIED)
                else if bytes_read == 1:
                    match flag:
                        case kDeathTestReturned:
                            self.set_outcome(DeathTestOutcome.RETURNED)
                        case kDeathTestThrew:
                            self.set_outcome(DeathTestOutcome.THREW)
                        case kDeathTestLived:
                            self.set_outcome(DeathTestOutcome.LIVED)
                        case kDeathTestInternalError:
                            FailFromInternalError(self.read_fd_)
                        case _:
                            GTEST_LOG_(FATAL) << "Death test child process reported "
                                              << "unexpected status byte ("
                                              << static_cast[UInt32](flag) << ")"
                else:
                    GTEST_LOG_(FATAL) << "Read from death test child process failed: "
                                      << GetLastErrnoDescription()
                GTEST_DEATH_TEST_CHECK_SYSCALL_(posix.Close(self.read_fd_))
                self.set_read_fd(-1)

            def GetErrorLogs(self) -> String:
                return GetCapturedStderr()

            def statement(self) -> String:
                return self.statement_

            def spawned(self) -> Bool:
                return self.spawned_

            def set_spawned(inout self, is_spawned: Bool):
                self.spawned_ = is_spawned

            def status(self) -> Int:
                return self.status_

            def set_status(inout self, a_status: Int):
                self.status_ = a_status

            def outcome(self) -> DeathTestOutcome:
                return self.outcome_

            def set_outcome(inout self, an_outcome: DeathTestOutcome):
                self.outcome_ = an_outcome

            def read_fd(self) -> Int:
                return self.read_fd_

            def set_read_fd(inout self, fd: Int):
                self.read_fd_ = fd

            def write_fd(self) -> Int:
                return self.write_fd_

            def set_write_fd(inout self, fd: Int):
                self.write_fd_ = fd

        def FormatDeathTestOutput(output: String) -> String:
            var ret = String()
            var at: size_t = 0
            while True:
                var line_end = output.find('\n', at)
                ret += "[  DEATH   ] "
                if line_end == -1:
                    ret += output.substr(at)
                    break
                ret += output.substr(at, line_end + 1 - at)
                at = line_end + 1
            return ret

        // #if GTEST_OS_WINDOWS
        // WindowsDeathTest class (abbreviated)
        // #elif GTEST_OS_FUCHSIA
        // FuchsiaDeathTest class (abbreviated)
        // #else  // We are neither on Windows, nor on Fuchsia.
        struct ForkingDeathTest(DeathTestImpl):
            var child_pid_: Pid

            def __init__(inout self, statement: String, matcher: Matcher[String]):
                DeathTestImpl.__init__(self, statement, matcher)
                self.child_pid_ = -1

            def Wait(self) -> Int:
                if not self.spawned():
                    return 0
                self.ReadAndInterpretStatusByte()
                var status_value: Int
                GTEST_DEATH_TEST_CHECK_SYSCALL_(waitpid(self.child_pid_, &status_value, 0))
                self.set_status(status_value)
                return status_value

            def set_child_pid(inout self, child_pid: Pid):
                self.child_pid_ = child_pid

        struct NoExecDeathTest(ForkingDeathTest):
            def __init__(inout self, a_statement: String, matcher: Matcher[String]):
                ForkingDeathTest.__init__(self, a_statement, matcher)

            def AssumeRole(self) -> DeathTest.TestRole:
                var thread_count = GetThreadCount()
                if thread_count != 1:
                    GTEST_LOG_(WARNING) << DeathTestThreadWarning(thread_count)
                var pipe_fd: array[Int, 2]
                GTEST_DEATH_TEST_CHECK_(pipe(pipe_fd) != -1)
                DeathTest.set_last_death_test_message("")
                CaptureStderr()
                FlushInfoLog()
                var child_pid = fork()
                GTEST_DEATH_TEST_CHECK_(child_pid != -1)
                self.set_child_pid(child_pid)
                if child_pid == 0:
                    GTEST_DEATH_TEST_CHECK_SYSCALL_(close(pipe_fd[0]))
                    self.set_write_fd(pipe_fd[1])
                    LogToStderr()
                    GetUnitTestImpl().listeners().SuppressEventForwarding()
                    g_in_fast_death_test_child = true
                    return EXECUTE_TEST
                else:
                    GTEST_DEATH_TEST_CHECK_SYSCALL_(close(pipe_fd[1]))
                    self.set_read_fd(pipe_fd[0])
                    self.set_spawned(true)
                    return OVERSEE_TEST

        struct ExecDeathTest(ForkingDeathTest):
            var file_: String
            var line_: Int

            def __init__(inout self, a_statement: String, matcher: Matcher[String], file: String, line: Int):
                ForkingDeathTest.__init__(self, a_statement, matcher)
                self.file_ = file
                self.line_ = line

            def AssumeRole(self) -> DeathTest.TestRole:
                var impl = GetUnitTestImpl()
                var flag = impl.internal_run_death_test_flag()
                var info = impl.current_test_info()
                var death_test_index = info.result().death_test_count()
                if flag != None:
                    self.set_write_fd(flag.write_fd())
                    return EXECUTE_TEST
                var pipe_fd: array[Int, 2]
                GTEST_DEATH_TEST_CHECK_(pipe(pipe_fd) != -1)
                GTEST_DEATH_TEST_CHECK_(fcntl(pipe_fd[1], F_SETFD, 0) != -1)
                var filter_flag = String("--") + GTEST_FLAG_PREFIX_ + kFilterFlag + "=" + info.test_suite_name() + "." + info.name()
                var internal_flag = String("--") + GTEST_FLAG_PREFIX_ + kInternalRunDeathTestFlag + "=" + self.file_ + "|" + StreamableToString(self.line_) + "|" + StreamableToString(death_test_index) + "|" + StreamableToString(pipe_fd[1])
                var args = Arguments()
                args.AddArguments(GetArgvsForDeathTestChildProcess())
                args.AddArgument(filter_flag.c_str())
                args.AddArgument(internal_flag.c_str())
                DeathTest.set_last_death_test_message("")
                CaptureStderr()
                FlushInfoLog()
                var child_pid = ExecDeathTestSpawnChild(args.Argv(), pipe_fd[0])
                GTEST_DEATH_TEST_CHECK_SYSCALL_(close(pipe_fd[1]))
                self.set_child_pid(child_pid)
                self.set_read_fd(pipe_fd[0])
                self.set_spawned(true)
                return OVERSEE_TEST

            @staticmethod
            def GetArgvsForDeathTestChildProcess() -> List[String]:
                var args = GetInjectableArgvs()
                // #if defined(GTEST_EXTRA_DEATH_TEST_COMMAND_LINE_ARGS_)
                var extra_args = GTEST_EXTRA_DEATH_TEST_COMMAND_LINE_ARGS_()
                args.insert(args.end(), extra_args.begin(), extra_args.end())
                // #endif
                return args

        struct ExecDeathTestArgs:
            var argv: Pointer[Pointer[Int8]]
            var close_fd: Int

        // #if GTEST_OS_QNX
        // extern "C" char** environ;
        // #else  // GTEST_OS_QNX
        def ExecDeathTestChildMain(child_arg: Pointer[Void]) -> Int:
            var args = static_cast[Pointer[ExecDeathTestArgs]](child_arg)[0]
            GTEST_DEATH_TEST_CHECK_SYSCALL_(close(args.close_fd))
            var original_dir = UnitTest.GetInstance().original_working_dir()
            if chdir(original_dir) != 0:
                DeathTestAbort(String("chdir(\"") + original_dir + "\") failed: " + GetLastErrnoDescription())
                return EXIT_FAILURE
            execv(args.argv[0], args.argv)
            DeathTestAbort(String("execv(") + args.argv[0] + ", ...) in " + original_dir + " failed: " + GetLastErrnoDescription())
            return EXIT_FAILURE
        // #endif // GTEST_OS_QNX

        // #if GTEST_HAS_CLONE
        def StackLowerThanAddress(ptr: Pointer[Void], result: Pointer[Bool]) -> Bool:
            dummy: Int
            *result = less[Pointer[Void]](&dummy, ptr)

        def StackGrowsDown() -> Bool:
            dummy: Int
            result: Bool
            StackLowerThanAddress(&dummy, &result)
            return result
        // #endif // GTEST_HAS_CLONE

        def ExecDeathTestSpawnChild(argv: Pointer[Pointer[Int8]], close_fd: Int) -> Pid:
            var args = ExecDeathTestArgs(argv, close_fd)
            var child_pid: Pid = -1
            // #if GTEST_OS_QNX
            // QNX-specific code (omitted)
            // #else   // GTEST_OS_QNX
            // #if GTEST_OS_LINUX
            var saved_sigprof_action: sigaction
            var ignore_sigprof_action: sigaction
            memset(&ignore_sigprof_action, 0, sizeof(sigaction))
            sigemptyset(&ignore_sigprof_action.sa_mask)
            ignore_sigprof_action.sa_handler = SIG_IGN
            GTEST_DEATH_TEST_CHECK_SYSCALL_(sigaction(SIGPROF, &ignore_sigprof_action, &saved_sigprof_action))
            // #endif // GTEST_OS_LINUX
            // #if GTEST_HAS_CLONE
            var use_fork = GTEST_FLAG.death_test_use_fork
            if not use_fork:
                static var stack_grows_down = StackGrowsDown()
                var stack_size = getpagesize() * 2
                var stack = mmap(None, stack_size, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0)
                GTEST_DEATH_TEST_CHECK_(stack != MAP_FAILED)
                var kMaxStackAlignment: size_t = 64
                var stack_top = (static_cast[Pointer[Int8]](stack) + (stack_size - kMaxStackAlignment if stack_grows_down else 0))
                GTEST_DEATH_TEST_CHECK_(stack_size > kMaxStackAlignment and (IntPtr(stack_top) % kMaxStackAlignment) == 0)
                child_pid = clone(ExecDeathTestChildMain, stack_top, SIGCHLD, &args)
                GTEST_DEATH_TEST_CHECK_(munmap(stack, stack_size) != -1)
            // #else
            //   bool use_fork = true;
            // #endif // GTEST_HAS_CLONE
            if use_fork and (child_pid = fork()) == 0:
                ExecDeathTestChildMain(&args)
                _exit(0)
            // #endif // GTEST_OS_QNX
            // #if GTEST_OS_LINUX
            GTEST_DEATH_TEST_CHECK_SYSCALL_(sigaction(SIGPROF, &saved_sigprof_action, None))
            // #endif // GTEST_OS_LINUX
            GTEST_DEATH_TEST_CHECK_(child_pid != -1)
            return child_pid

        struct DefaultDeathTestFactory:
            def Create(self, statement: String, matcher: Matcher[String], file: String, line: Int, test: Pointer[DeathTest]) -> Bool:
                var impl = GetUnitTestImpl()
                var flag = impl.internal_run_death_test_flag()
                var death_test_index = impl.current_test_info().increment_death_test_count()
                if flag != None:
                    if death_test_index > flag.index():
                        DeathTest.set_last_death_test_message(
                            "Death test count (" + StreamableToString(death_test_index) +
                            ") somehow exceeded expected maximum (" + StreamableToString(flag.index()) + ")"
                        )
                        return False
                    if not (flag.file() == file and flag.line() == line and flag.index() == death_test_index):
                        *test = None
                        return True
                // #if GTEST_OS_WINDOWS
                //   if (GTEST_FLAG(death_test_style) == "threadsafe" ||
                //       GTEST_FLAG(death_test_style) == "fast") {
                //     *test = new WindowsDeathTest(statement, move(matcher), file, line);
                //   }
                // #elif GTEST_OS_FUCHSIA
                //   if (GTEST_FLAG(death_test_style) == "threadsafe" ||
                //       GTEST_FLAG(death_test_style) == "fast") {
                //     *test = new FuchsiaDeathTest(statement, move(matcher), file, line);
                //   }
                // #else
                if GTEST_FLAG.death_test_style == "threadsafe":
                    *test = ExecDeathTest(statement, matcher, file, line)
                else if GTEST_FLAG.death_test_style == "fast":
                    *test = NoExecDeathTest(statement, matcher)
                // #endif // GTEST_OS_WINDOWS
                else:
                    DeathTest.set_last_death_test_message(
                        "Unknown death test style \"" + GTEST_FLAG.death_test_style + "\" encountered"
                    )
                    return False
                return True

        // #if GTEST_OS_WINDOWS
        // Windows-specific GetStatusFileDescriptor (omitted)
        // #endif // GTEST_OS_WINDOWS

        def ParseInternalRunDeathTestFlag() -> Pointer[InternalRunDeathTestFlag]:
            if GTEST_FLAG.internal_run_death_test == "":
                return None
            var line: Int = -1
            var index: Int = -1
            var fields: List[String]
            SplitString(GTEST_FLAG.internal_run_death_test.c_str(), '|', &fields)
            var write_fd: Int = -1
            // #if GTEST_OS_WINDOWS
            //   unsigned int parent_process_id = 0;
            //   size_t write_handle_as_size_t = 0;
            //   size_t event_handle_as_size_t = 0;
            //   if (fields.size() != 6
            //       || !ParseNaturalNumber(fields[1], &line)
            //       || !ParseNaturalNumber(fields[2], &index)
            //       || !ParseNaturalNumber(fields[3], &parent_process_id)
            //       || !ParseNaturalNumber(fields[4], &write_handle_as_size_t)
            //       || !ParseNaturalNumber(fields[5], &event_handle_as_size_t)) {
            //     DeathTestAbort("Bad --gtest_internal_run_death_test flag: " +
            //                    GTEST_FLAG(internal_run_death_test));
            //   }
            //   write_fd = GetStatusFileDescriptor(parent_process_id,
            //                                      write_handle_as_size_t,
            //                                      event_handle_as_size_t);
            // #elif GTEST_OS_FUCHSIA
            //   if (fields.size() != 3
            //       || !ParseNaturalNumber(fields[1], &line)
            //       || !ParseNaturalNumber(fields[2], &index)) {
            //     DeathTestAbort("Bad --gtest_internal_run_death_test flag: "
            //         + GTEST_FLAG(internal_run_death_test));
            //   }
            // #else
            if fields.size() != 4 or not ParseNaturalNumber(fields[1], &line) or not ParseNaturalNumber(fields[2], &index) or not ParseNaturalNumber(fields[3], &write_fd):
                DeathTestAbort("Bad --gtest_internal_run_death_test flag: " + GTEST_FLAG.internal_run_death_test)
            // #endif // GTEST_OS_WINDOWS
            return InternalRunDeathTestFlag(fields[0], line, index, write_fd)

    // namespace internal
    // #endif // GTEST_HAS_DEATH_TEST
// namespace testing
<<<FILE>>>