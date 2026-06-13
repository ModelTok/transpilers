# EXTERNAL DEPS (to wire in glue):
# - InitGoogleTest: test framework initialization from gtest
# - RUN_ALL_TESTS: test runner from gtest

import sys

class _GTestFlags:
    break_on_failure: bool = False
    catch_exceptions: bool = True

GTEST_FLAG = _GTestFlags()

def InitGoogleTest(argc: int, argv: list[str]) -> None:
    """Initialize Google Test. Must be provided by gtest binding."""
    pass

def RUN_ALL_TESTS() -> int:
    """Run all registered tests. Must be provided by gtest binding."""
    return 0

def main(argc: int, argv: list[str]) -> int:
    ENABLE_GTEST_DEBUG_MODE = False
    
    if ENABLE_GTEST_DEBUG_MODE:
        GTEST_FLAG.break_on_failure = True
        GTEST_FLAG.catch_exceptions = False
    
    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()

if __name__ == '__main__':
    sys.exit(main(len(sys.argv), sys.argv))
