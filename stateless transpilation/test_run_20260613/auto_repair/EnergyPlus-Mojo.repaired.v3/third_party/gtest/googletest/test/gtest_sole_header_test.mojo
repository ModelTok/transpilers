from gtest import *

def Subroutine():
    EXPECT_EQ(42, 42);

def NoFatalFailureTest_ExpectNoFatalFailure():
    EXPECT_NO_FATAL_FAILURE(pass);
    EXPECT_NO_FATAL_FAILURE(SUCCEED());
    EXPECT_NO_FATAL_FAILURE(Subroutine());
    EXPECT_NO_FATAL_FAILURE({ SUCCEED(); });

def NoFatalFailureTest_AssertNoFatalFailure():
    ASSERT_NO_FATAL_FAILURE(pass);
    ASSERT_NO_FATAL_FAILURE(SUCCEED());
    ASSERT_NO_FATAL_FAILURE(Subroutine());
    ASSERT_NO_FATAL_FAILURE({ SUCCEED(); });
// namespace