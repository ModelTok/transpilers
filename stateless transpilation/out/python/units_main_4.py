# EXTERNAL DEPS (to wire in glue):
# - gtest: ::testing::GTEST_FLAG, ::testing::InitGoogleTest, ::testing::RUN_ALL_TESTS from <gtest/gtest.h>

import sys

ENABLE_GTEST_DEBUG_MODE = False

def main(argc: int, argv: list[str]) -> int:
    if ENABLE_GTEST_DEBUG_MODE:
        pass
    return 0

if __name__ == '__main__':
    sys.exit(main(len(sys.argv), sys.argv))
