# #include <gtest/gtest.h>
def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
# #ifdef ENABLE_GTEST_DEBUG_MODE
#     ::testing::GTEST_FLAG(break_on_failure) = true;
#     ::testing::GTEST_FLAG(catch_exceptions) = false;
# #endif
    testing.InitGoogleTest(&argc, argv)
    return RUN_ALL_TESTS()