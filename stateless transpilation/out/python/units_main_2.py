# EXTERNAL DEPS (to wire in glue):
# - gtest: Google Test stubs
#   Source: C++ <gtest/gtest.h>
#   - GTEST_FLAG with break_on_failure, catch_exceptions attributes
#   - InitGoogleTest(argc, argv)
#   - RUN_ALL_TESTS() -> int

import sys

class GTEST_FLAG:
    break_on_failure = False
    catch_exceptions = True

def InitGoogleTest(argc, argv):
    pass

def RUN_ALL_TESTS():
    return 0

ENABLE_GTEST_DEBUG_MODE = False

def main(argc, argv):
    if ENABLE_GTEST_DEBUG_MODE:
        GTEST_FLAG.break_on_failure = True
        GTEST_FLAG.catch_exceptions = False
    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()

if __name__ == "__main__":
    sys.exit(main(len(sys.argv), sys.argv))
