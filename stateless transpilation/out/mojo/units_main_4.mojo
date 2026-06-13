# EXTERNAL DEPS (to wire in glue):
# - gtest: ::testing::GTEST_FLAG, ::testing::InitGoogleTest, ::testing::RUN_ALL_TESTS from <gtest/gtest.h>

alias ENABLE_GTEST_DEBUG_MODE = False

fn main(argc: Int, argv: List[String]) -> Int:
    if ENABLE_GTEST_DEBUG_MODE:
        pass
    return 0
