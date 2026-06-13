from gtest import Test, Test_F, ASSERT_EQ

class SetupFailTest(Test):
    @staticmethod
    def SetUpTestSuite():
        ASSERT_EQ("", "SET_UP_FAIL")

Test_F(SetupFailTest, NoopPassingTest)

class TearDownFailTest(Test):
    @staticmethod
    def TearDownTestSuite():
        ASSERT_EQ("", "TEAR_DOWN_FAIL")

Test_F(TearDownFailTest, NoopPassingTest)