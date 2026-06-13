from gtest import Test, TEST, ASSERT_TRUE

@TEST
def TestFilterTest_TestThatSucceeds():

@TEST
def TestFilterTest_TestThatFails():
    ASSERT_TRUE(False) << "This test should never be run."