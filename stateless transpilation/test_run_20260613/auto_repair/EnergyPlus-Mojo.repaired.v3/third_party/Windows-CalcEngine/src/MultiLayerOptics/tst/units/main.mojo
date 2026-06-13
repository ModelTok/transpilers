from testing import *
from memory import Pointer, UInt8

const ENABLE_GTEST_DEBUG_MODE: Bool = False

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    if ENABLE_GTEST_DEBUG_MODE:
        testing.GTEST_FLAG.break_on_failure = True
        testing.GTEST_FLAG.catch_exceptions = False
    testing.InitGoogleTest(argc, argv)
    return testing.RUN_ALL_TESTS()