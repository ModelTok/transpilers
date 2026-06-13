from gtest import *
#if GTEST_OS_WINDOWS
from windows import *
from stdlib import *
#endif
namespace:
    TEST(Foo, Bar):
        EXPECT_EQ(2, 3)
    #if GTEST_HAS_SEH && !GTEST_OS_WINDOWS_MOBILE
    def ExitWithExceptionCode(exception_pointers: *struct _EXCEPTION_POINTERS) -> LONG WINAPI:
        exit(exception_pointers.ExceptionRecord.ExceptionCode)
    #endif
def main(argc: Int, argv: **CChar) -> Int:
    #if GTEST_OS_WINDOWS
    SetErrorMode(SEM_NOGPFAULTERRORBOX | SEM_FAILCRITICALERRORS)
    #if GTEST_HAS_SEH && !GTEST_OS_WINDOWS_MOBILE
    SetUnhandledExceptionFilter(ExitWithExceptionCode)
    #endif
    #endif  // GTEST_OS_WINDOWS
    testing.InitGoogleTest(&argc, argv)
    return RUN_ALL_TESTS()