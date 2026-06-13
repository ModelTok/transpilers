from builtin import Pointer
from testing import (
    GTEST_FLAG,
    InitGoogleTest,
    RUN_ALL_TESTS,
)

@parameter
if ENABLE_GTEST_DEBUG_MODE:
    testing.GTEST_FLAG.break_on_failure = True
    testing.GTEST_FLAG.catch_exceptions = False

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int32:
    testing.InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()