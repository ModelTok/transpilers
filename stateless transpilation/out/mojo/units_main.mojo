# EXTERNAL DEPS (to wire in glue):
# - InitGoogleTest: test framework initialization from gtest
# - RUN_ALL_TESTS: test runner from gtest

import sys

struct GTestFlags:
    var break_on_failure: Bool
    var catch_exceptions: Bool

var GTEST_FLAG = GTestFlags(break_on_failure=False, catch_exceptions=True)

fn InitGoogleTest(argc: Int, argv: Pointer[Pointer[StringRef]]) -> None:
    """Initialize Google Test. Must be provided by gtest binding."""
    pass

fn RUN_ALL_TESTS() -> Int:
    """Run all registered tests. Must be provided by gtest binding."""
    return 0

@export
fn main(argc: Int, argv: Pointer[Pointer[StringRef]]) -> Int:
    let ENABLE_GTEST_DEBUG_MODE = False
    
    if ENABLE_GTEST_DEBUG_MODE:
        GTEST_FLAG.break_on_failure = True
        GTEST_FLAG.catch_exceptions = False
    
    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()
