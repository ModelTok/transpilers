from testing import *
from testing import InitGoogleTest, RUN_ALL_TESTS

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    #if ENABLE_GTEST_DEBUG_MODE
        testing.GTEST_FLAG(break_on_failure) = true
        testing.GTEST_FLAG(catch_exceptions) = false
    #endif
    testing.InitGoogleTest(&argc, argv)
    return RUN_ALL_TESTS()