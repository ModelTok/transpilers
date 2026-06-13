from libc import fprintf, fflush, stderr, exit
from exception import set_terminate
from gtest import testing, EXPECT_EQ

alias GTEST_HAS_EXCEPTIONS = True

def TerminateHandler():
    fprintf(stderr, "%s\n", "Unhandled C++ exception terminating the program.")
    fflush(None)
    exit(1)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    @parameter
    if GTEST_HAS_EXCEPTIONS:
        set_terminate(TerminateHandler)
    testing.InitGoogleTest(argc, argv)
    EXPECT_EQ(2, 3)
    return 0