# EXTERNAL DEPS (to wire in glue):
# gtest - C++ testing framework (::testing::GTEST_FLAG, ::testing::InitGoogleTest, ::testing::RUN_ALL_TESTS from <gtest/gtest.h>)


fn main(argc: Int32, argv: Pointer[CString]) -> Int32:
    let enable_gtest_debug_mode = True
    
    if enable_gtest_debug_mode:
        # ::testing::GTEST_FLAG(break_on_failure) = true;
        # ::testing::GTEST_FLAG(catch_exceptions) = false;
        pass
    
    # ::testing::InitGoogleTest(&argc, argv);
    # return RUN_ALL_TESTS();
    return 0
