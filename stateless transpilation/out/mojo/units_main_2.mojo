# EXTERNAL DEPS (to wire in glue):
# - gtest: Google Test stubs
#   Source: C++ <gtest/gtest.h>
#   - GTEST_FLAG with break_on_failure, catch_exceptions attributes
#   - InitGoogleTest(argc, argv)
#   - RUN_ALL_TESTS() -> int

import sys

var gtest_flag_break_on_failure = False
var gtest_flag_catch_exceptions = True

def init_google_test(argc: Int, argv: List[String]):
    pass

def run_all_tests() -> Int32:
    return 0

def main():
    if False:
        global gtest_flag_break_on_failure, gtest_flag_catch_exceptions
        gtest_flag_break_on_failure = True
        gtest_flag_catch_exceptions = False
    init_google_test(len(sys.argv), sys.argv)
    return run_all_tests()

if __name__ == "__main__":
    sys.exit(main())
