from gtest.internal.gtest-port import *
from gtest.gtest-spi import *
from gtest.gtest-message import *
from gtest.internal.gtest-internal import *
from gtest.internal.gtest-string import *
from src.gtest-internal-inl import *
from memory import *
from os import *
from sys import *
from math import *
from utils import *

# include <limits.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <cstdint>
# include <fstream>
# include <memory>
# if GTEST_OS_WINDOWS
#  include <windows.h>
#  include <io.h>
#  include <sys/stat.h>
#  include <map>  // Used in ThreadLocal.
#  ifdef _MSC_VER
#   include <crtdbg.h>
#  endif  // _MSC_VER
# else
#  include <unistd.h>
# endif  // GTEST_OS_WINDOWS
# if GTEST_OS_MAC
#  include <mach/mach_init.h>
#  include <mach/task.h>
#  include <mach/vm_map.h>
# endif  // GTEST_OS_MAC
# if GTEST_OS_DRAGONFLY || GTEST_OS_FREEBSD || GTEST_OS_GNU_KFREEBSD || \
     GTEST_OS_NETBSD || GTEST_OS_OPENBSD
#  include <sys/sysctl.h>
#  if GTEST_OS_DRAGONFLY || GTEST_OS_FREEBSD || GTEST_OS_GNU_KFREEBSD
#   include <sys/user.h>
#  endif
# endif
# if GTEST_OS_QNX
#  include <devctl.h>
#  include <fcntl.h>
#  include <sys/procfs.h>
# endif  // GTEST_OS_QNX
# if GTEST_OS_AIX
#  include <procinfo.h>
#  include <sys/types.h>
# endif  // GTEST_OS_AIX
# if GTEST_OS_FUCHSIA
#  include <zircon/process.h>
#  include <zircon/syscalls.h>
# endif  // GTEST_OS_FUCHSIA

namespace testing:
    namespace internal:
        # if defined(_MSC_VER) || defined(__BORLANDC__)
        const kStdOutFileno: Int = 1
        const kStdErrFileno: Int = 2
        # else
        const kStdOutFileno: Int = STDOUT_FILENO
        const kStdErrFileno: Int = STDERR_FILENO
        # endif  // _MSC_VER

        # if GTEST_OS_LINUX
        namespace:
            def ReadProcFileField[T: AnyType](filename: String, field: Int) -> T:
                var dummy: String
                var file = ifstream(filename.c_str())
                while field > 0:
                    file >> dummy
                    field -= 1
                var output: T = 0
                file >> output
                return output
        # end namespace

        def GetThreadCount() -> size_t:
            const filename: String = (Message() << "/proc/" << getpid() << "/stat").GetString()
            return ReadProcFileField[size_t](filename, 19)

        # elif GTEST_OS_MAC
        def GetThreadCount() -> size_t:
            const task: task_t = mach_task_self()
            var thread_count: mach_msg_type_number_t
            var thread_list: thread_act_array_t
            const status: kern_return_t = task_threads(task, &thread_list, &thread_count)
            if status == KERN_SUCCESS:
                vm_deallocate(task,
                              reinterpret_cast[vm_address_t](thread_list),
                              sizeof(thread_t) * thread_count)
                return static_cast[size_t](thread_count)
            else:
                return 0

        # elif GTEST_OS_DRAGONFLY || GTEST_OS_FREEBSD || GTEST_OS_GNU_KFREEBSD || \
              GTEST_OS_NETBSD
        # if GTEST_OS_NETBSD
        # undef KERN_PROC
        # define KERN_PROC KERN_PROC2
        # define kinfo_proc kinfo_proc2
        # endif
        # if GTEST_OS_DRAGONFLY
        # define KP_NLWP(kp) (kp.kp_nthreads)
        # elif GTEST_OS_FREEBSD || GTEST_OS_GNU_KFREEBSD
        # define KP_NLWP(kp) (kp.ki_numthreads)
        # elif GTEST_OS_NETBSD
        # define KP_NLWP(kp) (kp.p_nlwps)
        # endif

        def GetThreadCount() -> size_t:
            var mib: Int[] = [
                CTL_KERN,
                KERN_PROC,
                KERN_PROC_PID,
                getpid(),
                # if GTEST_OS_NETBSD
                sizeof(struct kinfo_proc),
                1,
                # endif
            ]
            var miblen: u_int = sizeof(mib) / sizeof(mib[0])
            var info: struct kinfo_proc
            var size: size_t = sizeof(info)
            if sysctl(mib, miblen, &info, &size, NULL, 0):
                return 0
            return static_cast[size_t](KP_NLWP(info))

        # elif GTEST_OS_OPENBSD
        def GetThreadCount() -> size_t:
            var mib: Int[] = [
                CTL_KERN,
                KERN_PROC,
                KERN_PROC_PID | KERN_PROC_SHOW_THREADS,
                getpid(),
                sizeof(struct kinfo_proc),
                0,
            ]
            var miblen: u_int = sizeof(mib) / sizeof(mib[0])
            var size: size_t
            if sysctl(mib, miblen, NULL, &size, NULL, 0):
                return 0
            mib[5] = static_cast[Int](size / static_cast[size_t](mib[4]))
            var info: struct kinfo_proc[mib[5]]
            if sysctl(mib, miblen, &info, &size, NULL, 0):
                return 0
            var nthreads: size_t = 0
            for i in range(size / static_cast[size_t](mib[4])):
                if info[i].p_tid != -1:
                    nthreads += 1
            return nthreads

        # elif GTEST_OS_QNX
        def GetThreadCount() -> size_t:
            const fd: Int = open("/proc/self/as", O_RDONLY)
            if fd < 0:
                return 0
            var process_info: procfs_info
            const status: Int = devctl(fd, DCMD_PROC_INFO, &process_info, sizeof(process_info), None)
            close(fd)
            if status == EOK:
                return static_cast[size_t](process_info.num_threads)
            else:
                return 0

        # elif GTEST_OS_AIX
        def GetThreadCount() -> size_t:
            var entry: struct procentry64
            var pid: pid_t = getpid()
            var status: Int = getprocs64(&entry, sizeof(entry), None, 0, &pid, 1)
            if status == 1:
                return entry.pi_thcount
            else:
                return 0

        # elif GTEST_OS_FUCHSIA
        def GetThreadCount() -> size_t:
            var dummy_buffer: Int
            var avail: size_t
            var status: zx_status_t = zx_object_get_info(
                zx_process_self(),
                ZX_INFO_PROCESS_THREADS,
                &dummy_buffer,
                0,
                None,
                &avail)
            if status == ZX_OK:
                return avail
            else:
                return 0

        # else
        def GetThreadCount() -> size_t:
            return 0

        # endif  // GTEST_OS_LINUX

        # if GTEST_IS_THREADSAFE && GTEST_OS_WINDOWS
        def SleepMilliseconds(n: Int):
            ::Sleep(static_cast[DWORD](n))

        struct AutoHandle:
            var handle_: Handle

            def __init__(inout self):
                self.handle_ = INVALID_HANDLE_VALUE

            def __init__(inout self, handle: Handle):
                self.handle_ = handle

            def __del__(owned self):
                self.Reset()

            def Get(self) -> Handle:
                return self.handle_

            def Reset(inout self):
                self.Reset(INVALID_HANDLE_VALUE)

            def Reset(inout self, handle: HANDLE):
                if self.handle_ != handle:
                    if self.IsCloseable():
                        ::CloseHandle(self.handle_)
                    self.handle_ = handle
                else:
                    GTEST_CHECK_(not self.IsCloseable()) << "Resetting a valid handle to itself is likely a programmer error and thus not allowed."

            def IsCloseable(self) -> bool:
                return self.handle_ != None and self.handle_ != INVALID_HANDLE_VALUE

        struct Notification:
            var event_: AutoHandle

            def __init__(inout self):
                self.event_ = AutoHandle(::CreateEvent(None, TRUE, FALSE, None))
                GTEST_CHECK_(self.event_.Get() != None)

            def Notify(inout self):
                GTEST_CHECK_(::SetEvent(self.event_.Get()) != FALSE)

            def WaitForNotification(self):
                GTEST_CHECK_(::WaitForSingleObject(self.event_.Get(), INFINITE) == WAIT_OBJECT_0)

        struct Mutex:
            var owner_thread_id_: DWORD
            var type_: MutexType
            var critical_section_init_phase_: Int32
            var critical_section_: CRITICAL_SECTION*

            def __init__(inout self):
                self.owner_thread_id_ = 0
                self.type_ = kDynamic
                self.critical_section_init_phase_ = 0
                self.critical_section_ = new CRITICAL_SECTION
                ::InitializeCriticalSection(self.critical_section_)

            def __del__(owned self):
                if self.type_ == kDynamic:
                    ::DeleteCriticalSection(self.critical_section_)
                    delete self.critical_section_
                    self.critical_section_ = None

            def Lock(inout self):
                self.ThreadSafeLazyInit()
                ::EnterCriticalSection(self.critical_section_)
                self.owner_thread_id_ = ::GetCurrentThreadId()

            def Unlock(inout self):
                self.ThreadSafeLazyInit()
                self.owner_thread_id_ = 0
                ::LeaveCriticalSection(self.critical_section_)

            def AssertHeld(self):
                self.ThreadSafeLazyInit()
                GTEST_CHECK_(self.owner_thread_id_ == ::GetCurrentThreadId()) << "The current thread is not holding the mutex @" << self

        namespace:
            # ifdef _MSC_VER
            struct MemoryIsNotDeallocated:
                var old_crtdbg_flag_: Int

                def __init__(inout self):
                    self.old_crtdbg_flag_ = _CrtSetDbgFlag(_CRTDBG_REPORT_FLAG)
                    _CrtSetDbgFlag(self.old_crtdbg_flag_ & ~_CRTDBG_ALLOC_MEM_DF)

                def __del__(owned self):
                    _CrtSetDbgFlag(self.old_crtdbg_flag_)

                # GTEST_DISALLOW_COPY_AND_ASSIGN_(MemoryIsNotDeallocated)
            # endif  // _MSC_VER
        # end namespace

        def Mutex.ThreadSafeLazyInit(inout self):
            if self.type_ == kStatic:
                switch ::InterlockedCompareExchange(&self.critical_section_init_phase_, 1, 0):
                    case 0:
                        self.owner_thread_id_ = 0
                        # ifdef _MSC_VER
                        var memory_is_not_deallocated: MemoryIsNotDeallocated
                        # endif  // _MSC_VER
                        self.critical_section_ = new CRITICAL_SECTION
                        ::InitializeCriticalSection(self.critical_section_)
                        GTEST_CHECK_(::InterlockedCompareExchange(&self.critical_section_init_phase_, 2, 1) == 1)
                        break
                    case 1:
                        while ::InterlockedCompareExchange(&self.critical_section_init_phase_, 2, 2) != 2:
                            ::Sleep(0)
                        break
                    case 2:
                        break  // The mutex is already initialized and ready for use.
                    case _:
                        GTEST_CHECK_(false) << "Unexpected value of critical_section_init_phase_ while initializing a static mutex."

        namespace:
            struct ThreadWithParamSupport:
                def CreateThread(runnable: Runnable*, thread_can_start: Notification*) -> HANDLE:
                    var param: ThreadMainParam* = new ThreadMainParam(runnable, thread_can_start)
                    var thread_id: DWORD
                    var thread_handle: HANDLE = ::CreateThread(
                        None, 0,
                        &ThreadWithParamSupport.ThreadMain,
                        param, 0x0, &thread_id)
                    GTEST_CHECK_(thread_handle != None) << "CreateThread failed with error " << ::GetLastError() << "."
                    if thread_handle == None:
                        delete param
                    return thread_handle

                struct ThreadMainParam:
                    var runnable_: unique_ptr[Runnable]
                    var thread_can_start_: Notification*

                    def __init__(inout self, runnable: Runnable*, thread_can_start: Notification*):
                        self.runnable_ = unique_ptr[Runnable](runnable)
                        self.thread_can_start_ = thread_can_start

                def ThreadMain(ptr: void*) -> DWORD WINAPI:
                    var param: unique_ptr[ThreadMainParam] = unique_ptr[ThreadMainParam](static_cast[ThreadMainParam*](ptr))
                    if param.get().thread_can_start_ != None:
                        param.get().thread_can_start_.WaitForNotification()
                    param.get().runnable_.get().Run()
                    return 0

                # GTEST_DISALLOW_COPY_AND_ASSIGN_(ThreadWithParamSupport)
        # end namespace

        struct ThreadWithParamBase:
            var thread_: AutoHandle

            def __init__(inout self, runnable: Runnable*, thread_can_start: Notification*):
                self.thread_ = AutoHandle(ThreadWithParamSupport.CreateThread(runnable, thread_can_start))

            def __del__(owned self):
                self.Join()

            def Join(inout self):
                GTEST_CHECK_(::WaitForSingleObject(self.thread_.Get(), INFINITE) == WAIT_OBJECT_0) << "Failed to join the thread with error " << ::GetLastError() << "."

        struct ThreadLocalRegistryImpl:
            @staticmethod
            def GetValueOnCurrentThread(thread_local_instance: const ThreadLocalBase*) -> ThreadLocalValueHolderBase*:
                # ifdef _MSC_VER
                var memory_is_not_deallocated: MemoryIsNotDeallocated
                # endif  // _MSC_VER
                var current_thread: DWORD = ::GetCurrentThreadId()
                var lock: MutexLock = MutexLock(&mutex_)
                var thread_to_thread_locals: ThreadIdToThreadLocals* = GetThreadLocalsMapLocked()
                var thread_local_pos: ThreadIdToThreadLocals.iterator = thread_to_thread_locals.find(current_thread)
                if thread_local_pos == thread_to_thread_locals.end():
                    thread_local_pos = thread_to_thread_locals.insert(make_pair(current_thread, ThreadLocalValues())).first
                    StartWatcherThreadFor(current_thread)
                var thread_local_values: ThreadLocalValues& = thread_local_pos.second
                var value_pos: ThreadLocalValues.iterator = thread_local_values.find(thread_local_instance)
                if value_pos == thread_local_values.end():
                    value_pos = thread_local_values.insert(make_pair(thread_local_instance, shared_ptr[ThreadLocalValueHolderBase](thread_local_instance.NewValueForCurrentThread()))).first
                return value_pos.second.get()

            @staticmethod
            def OnThreadLocalDestroyed(thread_local_instance: const ThreadLocalBase*):
                var value_holders: vector[shared_ptr[ThreadLocalValueHolderBase]]
                {
                    var lock: MutexLock = MutexLock(&mutex_)
                    var thread_to_thread_locals: ThreadIdToThreadLocals* = GetThreadLocalsMapLocked()
                    for it in thread_to_thread_locals.begin() to thread_to_thread_locals.end():
                        var thread_local_values: ThreadLocalValues& = it.second
                        var value_pos: ThreadLocalValues.iterator = thread_local_values.find(thread_local_instance)
                        if value_pos != thread_local_values.end():
                            value_holders.push_back(value_pos.second)
                            thread_local_values.erase(value_pos)
                }

            @staticmethod
            def OnThreadExit(thread_id: DWORD):
                GTEST_CHECK_(thread_id != 0) << ::GetLastError()
                var value_holders: vector[shared_ptr[ThreadLocalValueHolderBase]]
                {
                    var lock: MutexLock = MutexLock(&mutex_)
                    var thread_to_thread_locals: ThreadIdToThreadLocals* = GetThreadLocalsMapLocked()
                    var thread_local_pos: ThreadIdToThreadLocals.iterator = thread_to_thread_locals.find(thread_id)
                    if thread_local_pos != thread_to_thread_locals.end():
                        var thread_local_values: ThreadLocalValues& = thread_local_pos.second
                        for value_pos in thread_local_values.begin() to thread_local_values.end():
                            value_holders.push_back(value_pos.second)
                        thread_to_thread_locals.erase(thread_local_pos)
                }

            # private:
            type ThreadLocalValues = map[const ThreadLocalBase*, shared_ptr[ThreadLocalValueHolderBase]]
            type ThreadIdToThreadLocals = map[DWORD, ThreadLocalValues]
            type ThreadIdAndHandle = pair[DWORD, HANDLE]

            @staticmethod
            def StartWatcherThreadFor(thread_id: DWORD):
                var thread: HANDLE = ::OpenThread(SYNCHRONIZE | THREAD_QUERY_INFORMATION, FALSE, thread_id)
                GTEST_CHECK_(thread != None)
                var watcher_thread_id: DWORD
                var watcher_thread: HANDLE = ::CreateThread(
                    None, 0,
                    &ThreadLocalRegistryImpl.WatcherThreadFunc,
                    reinterpret_cast[LPVOID](new ThreadIdAndHandle(thread_id, thread)),
                    CREATE_SUSPENDED, &watcher_thread_id)
                GTEST_CHECK_(watcher_thread != None)
                ::SetThreadPriority(watcher_thread, ::GetThreadPriority(::GetCurrentThread()))
                ::ResumeThread(watcher_thread)
                ::CloseHandle(watcher_thread)

            @staticmethod
            def WatcherThreadFunc(param: LPVOID) -> DWORD WINAPI:
                var tah: const ThreadIdAndHandle* = reinterpret_cast[const ThreadIdAndHandle*](param)
                GTEST_CHECK_(::WaitForSingleObject(tah.second, INFINITE) == WAIT_OBJECT_0)
                OnThreadExit(tah.first)
                ::CloseHandle(tah.second)
                delete tah
                return 0

            @staticmethod
            def GetThreadLocalsMapLocked() -> ThreadIdToThreadLocals*:
                mutex_.AssertHeld()
                # ifdef _MSC_VER
                var memory_is_not_deallocated: MemoryIsNotDeallocated
                # endif  // _MSC_VER
                static var map: ThreadIdToThreadLocals* = new ThreadIdToThreadLocals()
                return map

            static var mutex_: Mutex = Mutex(Mutex.kStaticMutex)
            static var thread_map_mutex_: Mutex = Mutex(Mutex.kStaticMutex)

        var mutex_: Mutex = ThreadLocalRegistryImpl.mutex_
        var thread_map_mutex_: Mutex = ThreadLocalRegistryImpl.thread_map_mutex_

        struct ThreadLocalRegistry:
            @staticmethod
            def GetValueOnCurrentThread(thread_local_instance: const ThreadLocalBase*) -> ThreadLocalValueHolderBase*:
                return ThreadLocalRegistryImpl.GetValueOnCurrentThread(thread_local_instance)

            @staticmethod
            def OnThreadLocalDestroyed(thread_local_instance: const ThreadLocalBase*):
                ThreadLocalRegistryImpl.OnThreadLocalDestroyed(thread_local_instance)

        # endif  // GTEST_IS_THREADSAFE && GTEST_OS_WINDOWS

        # if GTEST_USES_POSIX_RE
        struct RE:
            var is_valid_: bool
            var pattern_: char*
            var full_regex_: regex_t
            var partial_regex_: regex_t

            def __del__(owned self):
                if self.is_valid_:
                    regfree(&self.full_regex_)
                    regfree(&self.partial_regex_)
                free(const_cast[char*](self.pattern_))

            @staticmethod
            def FullMatch(str: const char*, re: const RE&) -> bool:
                if not re.is_valid_:
                    return false
                var match: regmatch_t
                return regexec(&re.full_regex_, str, 1, &match, 0) == 0

            @staticmethod
            def PartialMatch(str: const char*, re: const RE&) -> bool:
                if not re.is_valid_:
                    return false
                var match: regmatch_t
                return regexec(&re.partial_regex_, str, 1, &match, 0) == 0

            def Init(inout self, regex: const char*):
                self.pattern_ = posix.StrDup(regex)
                const full_regex_len: size_t = strlen(regex) + 10
                var full_pattern: char* = new char[full_regex_len]
                snprintf(full_pattern, full_regex_len, "^(%s)$", regex)
                self.is_valid_ = regcomp(&self.full_regex_, full_pattern, REG_EXTENDED) == 0
                if self.is_valid_:
                    const partial_regex: const char* = "()" if *regex == '\0' else regex
                    self.is_valid_ = regcomp(&self.partial_regex_, partial_regex, REG_EXTENDED) == 0
                EXPECT_TRUE(self.is_valid_) << "Regular expression \"" << regex << "\" is not a valid POSIX Extended regular expression."
                delete[] full_pattern

        # elif GTEST_USES_SIMPLE_RE
        def IsInSet(ch: char, str: const char*) -> bool:
            return ch != '\0' and strchr(str, ch) != None

        def IsAsciiDigit(ch: char) -> bool:
            return '0' <= ch and ch <= '9'

        def IsAsciiPunct(ch: char) -> bool:
            return IsInSet(ch, "^-!\"#$%&'()*+,./:;<=>?@[\\]_`{|}~")

        def IsRepeat(ch: char) -> bool:
            return IsInSet(ch, "?*+")

        def IsAsciiWhiteSpace(ch: char) -> bool:
            return IsInSet(ch, " \f\n\r\t\v")

        def IsAsciiWordChar(ch: char) -> bool:
            return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ('0' <= ch and ch <= '9') or ch == '_'

        def IsValidEscape(c: char) -> bool:
            return IsAsciiPunct(c) or IsInSet(c, "dDfnrsStvwW")

        def AtomMatchesChar(escaped: bool, pattern_char: char, ch: char) -> bool:
            if escaped:  # "\\p" where p is pattern_char.
                match pattern_char:
                    case 'd':
                        return IsAsciiDigit(ch)
                    case 'D':
                        return not IsAsciiDigit(ch)
                    case 'f':
                        return ch == '\f'
                    case 'n':
                        return ch == '\n'
                    case 'r':
                        return ch == '\r'
                    case 's':
                        return IsAsciiWhiteSpace(ch)
                    case 'S':
                        return not IsAsciiWhiteSpace(ch)
                    case 't':
                        return ch == '\t'
                    case 'v':
                        return ch == '\v'
                    case 'w':
                        return IsAsciiWordChar(ch)
                    case 'W':
                        return not IsAsciiWordChar(ch)
                return IsAsciiPunct(pattern_char) and pattern_char == ch
            return (pattern_char == '.' and ch != '\n') or pattern_char == ch

        def FormatRegexSyntaxError(regex: const char*, index: Int) -> String:
            return (Message() << "Syntax error at index " << index << " in simple regular expression \"" << regex << "\": ").GetString()

        def ValidateRegex(regex: const char*) -> bool:
            if regex == None:
                ADD_FAILURE() << "NULL is not a valid simple regular expression."
                return false
            var is_valid: bool = true
            var prev_repeatable: bool = false
            var i: Int = 0
            while regex[i]:
                if regex[i] == '\\':  # An escape sequence
                    i += 1
                    if regex[i] == '\0':
                        ADD_FAILURE() << FormatRegexSyntaxError(regex, i - 1) << "'\\' cannot appear at the end."
                        return false
                    if not IsValidEscape(regex[i]):
                        ADD_FAILURE() << FormatRegexSyntaxError(regex, i - 1) << "invalid escape sequence \"\\" << regex[i] << "\"."
                        is_valid = false
                    prev_repeatable = true
                else:  # Not an escape sequence.
                    const ch: char = regex[i]
                    if ch == '^' and i > 0:
                        ADD_FAILURE() << FormatRegexSyntaxError(regex, i) << "'^' can only appear at the beginning."
                        is_valid = false
                    elif ch == '$' and regex[i + 1] != '\0':
                        ADD_FAILURE() << FormatRegexSyntaxError(regex, i) << "'$' can only appear at the end."
                        is_valid = false
                    elif IsInSet(ch, "()[]{}|"):
                        ADD_FAILURE() << FormatRegexSyntaxError(regex, i) << "'" << ch << "' is unsupported."
                        is_valid = false
                    elif IsRepeat(ch) and not prev_repeatable:
                        ADD_FAILURE() << FormatRegexSyntaxError(regex, i) << "'" << ch << "' can only follow a repeatable token."
                        is_valid = false
                    prev_repeatable = not IsInSet(ch, "^$?*+")
                i += 1
            return is_valid

        def MatchRepetitionAndRegexAtHead(escaped: bool, c: char, repeat: char, regex: const char*, str: const char*) -> bool:
            const min_count: size_t = 1 if repeat == '+' else 0
            const max_count: size_t = 1 if repeat == '?' else static_cast[size_t](-1) - 1
            for i in range(max_count + 1):
                if i >= min_count and MatchRegexAtHead(regex, str + i):
                    return true
                if str[i] == '\0' or not AtomMatchesChar(escaped, c, str[i]):
                    return false
            return false

        def MatchRegexAtHead(regex: const char*, str: const char*) -> bool:
            if *regex == '\0':  # An empty regex matches a prefix of anything.
                return true
            if *regex == '$':
                return *str == '\0'
            const escaped: bool = *regex == '\\'
            if escaped:
                regex += 1
            if IsRepeat(regex[1]):
                return MatchRepetitionAndRegexAtHead(escaped, regex[0], regex[1], regex + 2, str)
            else:
                return (*str != '\0') and AtomMatchesChar(escaped, *regex, *str) and MatchRegexAtHead(regex + 1, str + 1)

        def MatchRegexAnywhere(regex: const char*, str: const char*) -> bool:
            if regex == None or str == None:
                return false
            if *regex == '^':
                return MatchRegexAtHead(regex + 1, str)
            while True:
                if MatchRegexAtHead(regex, str):
                    return true
                if *str == '\0':
                    break
                str += 1
            return false

        struct RE:
            var is_valid_: bool
            var pattern_: char*
            var full_pattern_: char*

            def __del__(owned self):
                free(const_cast[char*](self.pattern_))
                free(const_cast[char*](self.full_pattern_))

            @staticmethod
            def FullMatch(str: const char*, re: const RE&) -> bool:
                return re.is_valid_ and MatchRegexAnywhere(re.full_pattern_, str)

            @staticmethod
            def PartialMatch(str: const char*, re: const RE&) -> bool:
                return re.is_valid_ and MatchRegexAnywhere(re.pattern_, str)

            def Init(inout self, regex: const char*):
                self.pattern_ = None
                self.full_pattern_ = None
                if regex != None:
                    self.pattern_ = posix.StrDup(regex)
                self.is_valid_ = ValidateRegex(regex)
                if not self.is_valid_:
                    return
                const len: size_t = strlen(regex)
                var buffer: char* = static_cast[char*](malloc(len + 3))
                self.full_pattern_ = buffer
                if *regex != '^':
                    *buffer = '^'
                    buffer += 1  # Makes sure full_pattern_ starts with '^'.
                memcpy(buffer, regex, len)
                buffer += len
                if len == 0 or regex[len - 1] != '$':
                    *buffer = '$'
                    buffer += 1  # Makes sure full_pattern_ ends with '$'.
                *buffer = '\0'

        # endif  // GTEST_USES_POSIX_RE

        const kUnknownFile: char[] = "unknown file"

        @GTEST_API_
        def FormatFileLocation(file: const char*, line: Int) -> String:
            const file_name: String = kUnknownFile if file == None else String(file)
            if line < 0:
                return file_name + ":"
            # ifdef _MSC_VER
            return file_name + "(" + StreamableToString(line) + "):"
            # else
            return file_name + ":" + StreamableToString(line) + ":"
            # endif  // _MSC_VER

        @GTEST_API_
        def FormatCompilerIndependentFileLocation(file: const char*, line: Int) -> String:
            const file_name: String = kUnknownFile if file == None else String(file)
            if line < 0:
                return file_name
            else:
                return file_name + ":" + StreamableToString(line)

        struct GTestLog:
            var severity_: GTestLogSeverity

            def __init__(inout self, severity: GTestLogSeverity, file: const char*, line: Int):
                self.severity_ = severity
                const marker: const char* = (
                    "[  INFO ]" if severity == GTEST_INFO else
                    "[WARNING]" if severity == GTEST_WARNING else
                    "[ ERROR ]" if severity == GTEST_ERROR else
                    "[ FATAL ]"
                )
                self.GetStream() << ::endl << marker << " " << FormatFileLocation(file, line).c_str() << ": "

            def __del__(owned self):
                self.GetStream() << ::endl
                if self.severity_ == GTEST_FATAL:
                    fflush(stderr)
                    posix.Abort()

        @GTEST_DISABLE_MSC_DEPRECATED_PUSH_()
        # if GTEST_HAS_STREAM_REDIRECTION
        struct CapturedStream:
            var fd_: Int
            var uncaptured_fd_: Int
            var filename_: String

            def __init__(inout self, fd: Int):
                self.fd_ = fd
                self.uncaptured_fd_ = dup(fd)
                # if GTEST_OS_WINDOWS
                var temp_dir_path: char[MAX_PATH + 1] = {'\0'}
                var temp_file_path: char[MAX_PATH + 1] = {'\0'}
                ::GetTempPathA(sizeof(temp_dir_path), temp_dir_path)
                const success: UINT = ::GetTempFileNameA(temp_dir_path, "gtest_redir", 0, temp_file_path)
                GTEST_CHECK_(success != 0) << "Unable to create a temporary file in " << temp_dir_path
                const captured_fd: Int = creat(temp_file_path, _S_IREAD | _S_IWRITE)
                GTEST_CHECK_(captured_fd != -1) << "Unable to open temporary file " << temp_file_path
                self.filename_ = String(temp_file_path)
                # else
                var name_template: String
                #  if GTEST_OS_LINUX_ANDROID
                name_template = "/data/local/tmp/"
                #  elif GTEST_OS_IOS
                var user_temp_dir: char[PATH_MAX + 1]
                ::confstr(_CS_DARWIN_USER_TEMP_DIR, user_temp_dir, sizeof(user_temp_dir))
                name_template = String(user_temp_dir)
                if name_template.back() != GTEST_PATH_SEP_[0]:
                    name_template.push_back(GTEST_PATH_SEP_[0])
                #  else
                name_template = "/tmp/"
                #  endif
                name_template.append("gtest_captured_stream.XXXXXX")
                const captured_fd: Int = ::mkstemp(const_cast[char*](name_template.data()))
                if captured_fd == -1:
                    GTEST_LOG_(WARNING) << "Failed to create tmp file " << name_template << " for test; does the test have access to the /tmp directory?"
                self.filename_ = name_template
                # endif  // GTEST_OS_WINDOWS
                fflush(None)
                dup2(captured_fd, self.fd_)
                close(captured_fd)

            def __del__(owned self):
                remove(self.filename_.c_str())

            def GetCapturedString(inout self) -> String:
                if self.uncaptured_fd_ != -1:
                    fflush(None)
                    dup2(self.uncaptured_fd_, self.fd_)
                    close(self.uncaptured_fd_)
                    self.uncaptured_fd_ = -1
                var file: FILE* = posix.FOpen(self.filename_.c_str(), "r")
                if file == None:
                    GTEST_LOG_(FATAL) << "Failed to open tmp file " << self.filename_ << " for capturing stream."
                const content: String = ReadEntireFile(file)
                posix.FClose(file)
                return content

            # GTEST_DISALLOW_COPY_AND_ASSIGN_(CapturedStream)

        @GTEST_DISABLE_MSC_DEPRECATED_POP_()

        static var g_captured_stderr: CapturedStream* = None
        static var g_captured_stdout: CapturedStream* = None

        def CaptureStream(fd: Int, stream_name: const char*, stream: CapturedStream**):
            if *stream != None:
                GTEST_LOG_(FATAL) << "Only one " << stream_name << " capturer can exist at a time."
            *stream = new CapturedStream(fd)

        def GetCapturedStream(captured_stream: CapturedStream**) -> String:
            const content: String = (*captured_stream).GetCapturedString()
            delete *captured_stream
            *captured_stream = None
            return content

        def CaptureStdout():
            CaptureStream(kStdOutFileno, "stdout", &g_captured_stdout)

        def CaptureStderr():
            CaptureStream(kStdErrFileno, "stderr", &g_captured_stderr)

        def GetCapturedStdout() -> String:
            return GetCapturedStream(&g_captured_stdout)

        def GetCapturedStderr() -> String:
            return GetCapturedStream(&g_captured_stderr)

        # endif  // GTEST_HAS_STREAM_REDIRECTION

        def GetFileSize(file: FILE*) -> size_t:
            fseek(file, 0, SEEK_END)
            return static_cast[size_t](ftell(file))

        def ReadEntireFile(file: FILE*) -> String:
            const file_size: size_t = GetFileSize(file)
            var buffer: char* = new char[file_size]
            var bytes_last_read: size_t = 0  # # of bytes read in the last fread()
            var bytes_read: size_t = 0       # # of bytes read so far
            fseek(file, 0, SEEK_SET)
            while True:
                bytes_last_read = fread(buffer + bytes_read, 1, file_size - bytes_read, file)
                bytes_read += bytes_last_read
                if not (bytes_last_read > 0 and bytes_read < file_size):
                    break
            const content: String = String(buffer, bytes_read)
            delete[] buffer
            return content

        # if GTEST_HAS_DEATH_TEST
        static var g_injected_test_argvs: const vector[String]* = None  # Owned.

        def GetInjectableArgvs() -> vector[String]:
            if g_injected_test_argvs != None:
                return *g_injected_test_argvs
            return GetArgvs()

        def SetInjectableArgvs(new_argvs: const vector[String]*):
            if g_injected_test_argvs != new_argvs:
                delete g_injected_test_argvs
            g_injected_test_argvs = new_argvs

        def SetInjectableArgvs(new_argvs: const vector[String]&):
            SetInjectableArgvs(new vector[String](new_argvs.begin(), new_argvs.end()))

        def ClearInjectableArgvs():
            delete g_injected_test_argvs
            g_injected_test_argvs = None

        # endif  // GTEST_HAS_DEATH_TEST

        # if GTEST_OS_WINDOWS_MOBILE
        namespace posix:
            def Abort():
                DebugBreak()
                TerminateProcess(GetCurrentProcess(), 1)
        # end namespace
        # endif  // GTEST_OS_WINDOWS_MOBILE

        def FlagToEnvVar(flag: const char*) -> String:
            const full_flag: String = (Message() << GTEST_FLAG_PREFIX_ << flag).GetString()
            var env_var: Message
            for i in range(full_flag.length()):
                env_var << ToUpper(full_flag.c_str()[i])
            return env_var.GetString()

        def ParseInt32(src_text: const Message&, str: const char*, value: Int32*) -> bool:
            var end: char* = None
            const long_value: Int64 = strtol(str, &end, 10)
            if *end != '\0':
                var msg: Message
                msg << "WARNING: " << src_text << " is expected to be a 32-bit integer, but actually has value \"" << str << "\".\n"
                printf("%s", msg.GetString().c_str())
                fflush(stdout)
                return false
            const result: Int32 = static_cast[Int32](long_value)
            if long_value == LONG_MAX or long_value == LONG_MIN or result != long_value:
                var msg: Message
                msg << "WARNING: " << src_text << " is expected to be a 32-bit integer, but actually has value " << str << ", which overflows.\n"
                printf("%s", msg.GetString().c_str())
                fflush(stdout)
                return false
            *value = result
            return true

        def BoolFromGTestEnv(flag: const char*, default_value: bool) -> bool:
            # if defined(GTEST_GET_BOOL_FROM_ENV_)
            return GTEST_GET_BOOL_FROM_ENV_(flag, default_value)
            # else
            const env_var: String = FlagToEnvVar(flag)
            const string_value: const char* = posix.GetEnv(env_var.c_str())
            return default_value if string_value == None else strcmp(string_value, "0") != 0
            # endif  // defined(GTEST_GET_BOOL_FROM_ENV_)

        def Int32FromGTestEnv(flag: const char*, default_value: Int32) -> Int32:
            # if defined(GTEST_GET_INT32_FROM_ENV_)
            return GTEST_GET_INT32_FROM_ENV_(flag, default_value)
            # else
            const env_var: String = FlagToEnvVar(flag)
            const string_value: const char* = posix.GetEnv(env_var.c_str())
            if string_value == None:
                return default_value
            var result: Int32 = default_value
            if not ParseInt32(Message() << "Environment variable " << env_var, string_value, &result):
                printf("The default value %s is used.\n", (Message() << default_value).GetString().c_str())
                fflush(stdout)
                return default_value
            return result
            # endif  // defined(GTEST_GET_INT32_FROM_ENV_)

        def OutputFlagAlsoCheckEnvVar() -> String:
            var default_value_for_output_flag: String = ""
            const xml_output_file_env: const char* = posix.GetEnv("XML_OUTPUT_FILE")
            if None != xml_output_file_env:
                default_value_for_output_flag = String("xml:") + String(xml_output_file_env)
            return default_value_for_output_flag

        def StringFromGTestEnv(flag: const char*, default_value: const char*) -> const char*:
            # if defined(GTEST_GET_STRING_FROM_ENV_)
            return GTEST_GET_STRING_FROM_ENV_(flag, default_value)
            # else
            const env_var: String = FlagToEnvVar(flag)
            const value: const char* = posix.GetEnv(env_var.c_str())
            return default_value if value == None else value
            # endif  // defined(GTEST_GET_STRING_FROM_ENV_)

# end namespace internal
# end namespace testing