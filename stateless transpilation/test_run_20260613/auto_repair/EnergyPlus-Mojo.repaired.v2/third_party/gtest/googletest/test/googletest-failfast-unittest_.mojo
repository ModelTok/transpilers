from gtest import *

class HasFixtureTest(testing.Test):
    def Test0(self):

    def Test1(self):
        FAIL() << "Expected failure."
    def Test2(self):
        FAIL() << "Expected failure."
    def Test3(self):
        FAIL() << "Expected failure."
    def Test4(self):
        FAIL() << "Expected failure."

class HasSimpleTest(testing.Test):
    def Test0(self):

    def Test1(self):
        FAIL() << "Expected failure."
    def Test2(self):
        FAIL() << "Expected failure."
    def Test3(self):
        FAIL() << "Expected failure."
    def Test4(self):
        FAIL() << "Expected failure."

class HasDisabledTest(testing.Test):
    def Test0(self):

    def DISABLED_Test1(self):
        FAIL() << "Expected failure."
    def Test2(self):
        FAIL() << "Expected failure."
    def Test3(self):
        FAIL() << "Expected failure."
    def Test4(self):
        FAIL() << "Expected failure."

class HasDeathTest(testing.Test):
    def Test0(self):
        EXPECT_DEATH_IF_SUPPORTED(exit(1), ".*")
    def Test1(self):
        EXPECT_DEATH_IF_SUPPORTED(FAIL() << "Expected failure.", ".*")
    def Test2(self):
        EXPECT_DEATH_IF_SUPPORTED(FAIL() << "Expected failure.", ".*")
    def Test3(self):
        EXPECT_DEATH_IF_SUPPORTED(FAIL() << "Expected failure.", ".*")
    def Test4(self):
        EXPECT_DEATH_IF_SUPPORTED(FAIL() << "Expected failure.", ".*")

class DISABLED_HasDisabledSuite(testing.Test):
    def Test0(self):

    def Test1(self):
        FAIL() << "Expected failure."
    def Test2(self):
        FAIL() << "Expected failure."
    def Test3(self):
        FAIL() << "Expected failure."
    def Test4(self):
        FAIL() << "Expected failure."

class HasParametersTest(testing.TestWithParam[Int]):
    def Test1(self):
        FAIL() << "Expected failure."
    def Test2(self):
        FAIL() << "Expected failure."

INSTANTIATE_TEST_SUITE_P(HasParametersSuite, HasParametersTest,
                         testing.Values(1, 2))

class MyTestListener(testing.EmptyTestEventListener):
    def OnTestSuiteStart(self, test_suite: testing.TestSuite):
        print(f"We are in OnTestSuiteStart of {test_suite.name()}.")
    def OnTestStart(self, test_info: testing.TestInfo):
        print(f"We are in OnTestStart of {test_info.test_suite_name()}.{test_info.name()}.")
    def OnTestPartResult(self, test_part_result: testing.TestPartResult):
        print(f"We are in OnTestPartResult {test_part_result.file_name()}:{test_part_result.line_number()}.")
    def OnTestEnd(self, test_info: testing.TestInfo):
        print(f"We are in OnTestEnd of {test_info.test_suite_name()}.{test_info.name()}.")
    def OnTestSuiteEnd(self, test_suite: testing.TestSuite):
        print(f"We are in OnTestSuiteEnd of {test_suite.name()}.")

class HasSkipTest(testing.Test):
    def Test0(self):
        SUCCEED() << "Expected success."
    def Test1(self):
        GTEST_SKIP() << "Expected skip."
    def Test2(self):
        FAIL() << "Expected failure."
    def Test3(self):
        FAIL() << "Expected failure."
    def Test4(self):
        FAIL() << "Expected failure."

def main() -> Int32:
    testing.InitGoogleTest()
    testing.UnitTest.GetInstance().listeners().Append(MyTestListener())
    return RUN_ALL_TESTS()