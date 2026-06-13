from gtest import *

alias ENABLE_GTEST_DEBUG_MODE = False

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    if ENABLE_GTEST_DEBUG_MODE:
        testing.GTEST_FLAG.break_on_failure = True
        testing.GTEST_FLAG.catch_exceptions = False
    testing.init_google_test(argc, argv)
    return testing.run_all_tests()