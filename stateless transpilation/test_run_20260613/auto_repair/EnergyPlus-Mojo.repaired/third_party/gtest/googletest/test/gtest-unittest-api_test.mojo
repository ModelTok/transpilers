from gtest import *
from gtest import Test, TestSuite, TestInfo, UnitTest, Environment, AssertionResult, AssertionSuccess, AssertionFailure, RecordProperty, InitGoogleTest, AddGlobalTestEnvironment, RUN_ALL_TESTS, GetTypeName, Types
from memory import memset
from string import String
from algorithm import sort

@value
struct LessByName[T: CollectionElement]:
    def __call__(self, a: T, b: T) -> Bool:
        return strcmp(a.name(), b.name()) < 0

class UnitTestHelper:
    @staticmethod
    def GetSortedTestSuites() -> Pointer[Pointer[TestSuite]]:
        var unit_test: UnitTest = UnitTest.GetInstance()
        var test_suites = Pointer[Pointer[TestSuite]].alloc(unit_test.total_test_suite_count())
        for i in range(unit_test.total_test_suite_count()):
            test_suites[i] = unit_test.GetTestSuite(i)
        sort(test_suites, test_suites + unit_test.total_test_suite_count(), LessByName[TestSuite]())
        return test_suites

    @staticmethod
    def FindTestSuite(name: String) -> Pointer[TestSuite]:
        var unit_test: UnitTest = UnitTest.GetInstance()
        for i in range(unit_test.total_test_suite_count()):
            var test_suite = unit_test.GetTestSuite(i)
            if strcmp(test_suite.name(), name) == 0:
                return test_suite
        return Pointer[TestSuite]()

    @staticmethod
    def GetSortedTests(test_suite: Pointer[TestSuite]) -> Pointer[Pointer[TestInfo]]:
        var tests = Pointer[Pointer[TestInfo]].alloc(test_suite.total_test_count())
        for i in range(test_suite.total_test_count()):
            tests[i] = test_suite.GetTestInfo(i)
        sort(tests, tests + test_suite.total_test_count(), LessByName[TestInfo]())
        return tests

@value
struct TestSuiteWithCommentTest[T: CollectionElement](Test):

TYPED_TEST_SUITE(TestSuiteWithCommentTest, Types[Int32])

TYPED_TEST(TestSuiteWithCommentTest, Dummy):

var kTypedTestSuites: Int32 = 1
var kTypedTests: Int32 = 1

TEST(ApiTest, UnitTestImmutableAccessorsWork):
    var unit_test: UnitTest = UnitTest.GetInstance()
    ASSERT_EQ(2 + kTypedTestSuites, unit_test.total_test_suite_count())
    EXPECT_EQ(1 + kTypedTestSuites, unit_test.test_suite_to_run_count())
    EXPECT_EQ(2, unit_test.disabled_test_count())
    EXPECT_EQ(5 + kTypedTests, unit_test.total_test_count())
    EXPECT_EQ(3 + kTypedTests, unit_test.test_to_run_count())
    var test_suites = UnitTestHelper.GetSortedTestSuites()
    EXPECT_STREQ("ApiTest", test_suites[0].name())
    EXPECT_STREQ("DISABLED_Test", test_suites[1].name())
    EXPECT_STREQ("TestSuiteWithCommentTest/0", test_suites[2].name())
    test_suites.free()
    RecordProperty("key", "value")

def IsNull(str: String) -> AssertionResult:
    if str != "":
        return AssertionFailure() + "argument is " + str
    return AssertionSuccess()

TEST(ApiTest, TestSuiteImmutableAccessorsWork):
    var test_suite = UnitTestHelper.FindTestSuite("ApiTest")
    ASSERT_TRUE(test_suite != Pointer[TestSuite]())
    EXPECT_STREQ("ApiTest", test_suite.name())
    EXPECT_TRUE(IsNull(test_suite.type_param()))
    EXPECT_TRUE(test_suite.should_run())
    EXPECT_EQ(1, test_suite.disabled_test_count())
    EXPECT_EQ(3, test_suite.test_to_run_count())
    ASSERT_EQ(4, test_suite.total_test_count())
    var tests = UnitTestHelper.GetSortedTests(test_suite)
    EXPECT_STREQ("DISABLED_Dummy1", tests[0].name())
    EXPECT_STREQ("ApiTest", tests[0].test_suite_name())
    EXPECT_TRUE(IsNull(tests[0].value_param()))
    EXPECT_TRUE(IsNull(tests[0].type_param()))
    EXPECT_FALSE(tests[0].should_run())
    EXPECT_STREQ("TestSuiteDisabledAccessorsWork", tests[1].name())
    EXPECT_STREQ("ApiTest", tests[1].test_suite_name())
    EXPECT_TRUE(IsNull(tests[1].value_param()))
    EXPECT_TRUE(IsNull(tests[1].type_param()))
    EXPECT_TRUE(tests[1].should_run())
    EXPECT_STREQ("TestSuiteImmutableAccessorsWork", tests[2].name())
    EXPECT_STREQ("ApiTest", tests[2].test_suite_name())
    EXPECT_TRUE(IsNull(tests[2].value_param()))
    EXPECT_TRUE(IsNull(tests[2].type_param()))
    EXPECT_TRUE(tests[2].should_run())
    EXPECT_STREQ("UnitTestImmutableAccessorsWork", tests[3].name())
    EXPECT_STREQ("ApiTest", tests[3].test_suite_name())
    EXPECT_TRUE(IsNull(tests[3].value_param()))
    EXPECT_TRUE(IsNull(tests[3].type_param()))
    EXPECT_TRUE(tests[3].should_run())
    tests.free()
    tests = Pointer[Pointer[TestInfo]]()
    test_suite = UnitTestHelper.FindTestSuite("TestSuiteWithCommentTest/0")
    ASSERT_TRUE(test_suite != Pointer[TestSuite]())
    EXPECT_STREQ("TestSuiteWithCommentTest/0", test_suite.name())
    EXPECT_STREQ(GetTypeName[Types[Int32]]().c_str(), test_suite.type_param())
    EXPECT_TRUE(test_suite.should_run())
    EXPECT_EQ(0, test_suite.disabled_test_count())
    EXPECT_EQ(1, test_suite.test_to_run_count())
    ASSERT_EQ(1, test_suite.total_test_count())
    tests = UnitTestHelper.GetSortedTests(test_suite)
    EXPECT_STREQ("Dummy", tests[0].name())
    EXPECT_STREQ("TestSuiteWithCommentTest/0", tests[0].test_suite_name())
    EXPECT_TRUE(IsNull(tests[0].value_param()))
    EXPECT_STREQ(GetTypeName[Types[Int32]]().c_str(), tests[0].type_param())
    EXPECT_TRUE(tests[0].should_run())
    tests.free()

TEST(ApiTest, TestSuiteDisabledAccessorsWork):
    var test_suite = UnitTestHelper.FindTestSuite("DISABLED_Test")
    ASSERT_TRUE(test_suite != Pointer[TestSuite]())
    EXPECT_STREQ("DISABLED_Test", test_suite.name())
    EXPECT_TRUE(IsNull(test_suite.type_param()))
    EXPECT_FALSE(test_suite.should_run())
    EXPECT_EQ(1, test_suite.disabled_test_count())
    EXPECT_EQ(0, test_suite.test_to_run_count())
    ASSERT_EQ(1, test_suite.total_test_count())
    var test_info = test_suite.GetTestInfo(0)
    EXPECT_STREQ("Dummy2", test_info.name())
    EXPECT_STREQ("DISABLED_Test", test_info.test_suite_name())
    EXPECT_TRUE(IsNull(test_info.value_param()))
    EXPECT_TRUE(IsNull(test_info.type_param()))
    EXPECT_FALSE(test_info.should_run())

TEST(ApiTest, DISABLED_Dummy1):

TEST(DISABLED_Test, Dummy2):

class FinalSuccessChecker(Environment):
    def TearDown(self):
        var unit_test: UnitTest = UnitTest.GetInstance()
        EXPECT_EQ(1 + kTypedTestSuites, unit_test.successful_test_suite_count())
        EXPECT_EQ(3 + kTypedTests, unit_test.successful_test_count())
        EXPECT_EQ(0, unit_test.failed_test_suite_count())
        EXPECT_EQ(0, unit_test.failed_test_count())
        EXPECT_TRUE(unit_test.Passed())
        EXPECT_FALSE(unit_test.Failed())
        ASSERT_EQ(2 + kTypedTestSuites, unit_test.total_test_suite_count())
        var test_suites = UnitTestHelper.GetSortedTestSuites()
        EXPECT_STREQ("ApiTest", test_suites[0].name())
        EXPECT_TRUE(IsNull(test_suites[0].type_param()))
        EXPECT_TRUE(test_suites[0].should_run())
        EXPECT_EQ(1, test_suites[0].disabled_test_count())
        ASSERT_EQ(4, test_suites[0].total_test_count())
        EXPECT_EQ(3, test_suites[0].successful_test_count())
        EXPECT_EQ(0, test_suites[0].failed_test_count())
        EXPECT_TRUE(test_suites[0].Passed())
        EXPECT_FALSE(test_suites[0].Failed())
        EXPECT_STREQ("DISABLED_Test", test_suites[1].name())
        EXPECT_TRUE(IsNull(test_suites[1].type_param()))
        EXPECT_FALSE(test_suites[1].should_run())
        EXPECT_EQ(1, test_suites[1].disabled_test_count())
        ASSERT_EQ(1, test_suites[1].total_test_count())
        EXPECT_EQ(0, test_suites[1].successful_test_count())
        EXPECT_EQ(0, test_suites[1].failed_test_count())
        EXPECT_STREQ("TestSuiteWithCommentTest/0", test_suites[2].name())
        EXPECT_STREQ(GetTypeName[Types[Int32]]().c_str(), test_suites[2].type_param())
        EXPECT_TRUE(test_suites[2].should_run())
        EXPECT_EQ(0, test_suites[2].disabled_test_count())
        ASSERT_EQ(1, test_suites[2].total_test_count())
        EXPECT_EQ(1, test_suites[2].successful_test_count())
        EXPECT_EQ(0, test_suites[2].failed_test_count())
        EXPECT_TRUE(test_suites[2].Passed())
        EXPECT_FALSE(test_suites[2].Failed())
        var test_suite = UnitTestHelper.FindTestSuite("ApiTest")
        var tests = UnitTestHelper.GetSortedTests(test_suite)
        EXPECT_STREQ("DISABLED_Dummy1", tests[0].name())
        EXPECT_STREQ("ApiTest", tests[0].test_suite_name())
        EXPECT_FALSE(tests[0].should_run())
        EXPECT_STREQ("TestSuiteDisabledAccessorsWork", tests[1].name())
        EXPECT_STREQ("ApiTest", tests[1].test_suite_name())
        EXPECT_TRUE(IsNull(tests[1].value_param()))
        EXPECT_TRUE(IsNull(tests[1].type_param()))
        EXPECT_TRUE(tests[1].should_run())
        EXPECT_TRUE(tests[1].result().Passed())
        EXPECT_EQ(0, tests[1].result().test_property_count())
        EXPECT_STREQ("TestSuiteImmutableAccessorsWork", tests[2].name())
        EXPECT_STREQ("ApiTest", tests[2].test_suite_name())
        EXPECT_TRUE(IsNull(tests[2].value_param()))
        EXPECT_TRUE(IsNull(tests[2].type_param()))
        EXPECT_TRUE(tests[2].should_run())
        EXPECT_TRUE(tests[2].result().Passed())
        EXPECT_EQ(0, tests[2].result().test_property_count())
        EXPECT_STREQ("UnitTestImmutableAccessorsWork", tests[3].name())
        EXPECT_STREQ("ApiTest", tests[3].test_suite_name())
        EXPECT_TRUE(IsNull(tests[3].value_param()))
        EXPECT_TRUE(IsNull(tests[3].type_param()))
        EXPECT_TRUE(tests[3].should_run())
        EXPECT_TRUE(tests[3].result().Passed())
        EXPECT_EQ(1, tests[3].result().test_property_count())
        var property = tests[3].result().GetTestProperty(0)
        EXPECT_STREQ("key", property.key())
        EXPECT_STREQ("value", property.value())
        tests.free()
        test_suite = UnitTestHelper.FindTestSuite("TestSuiteWithCommentTest/0")
        tests = UnitTestHelper.GetSortedTests(test_suite)
        EXPECT_STREQ("Dummy", tests[0].name())
        EXPECT_STREQ("TestSuiteWithCommentTest/0", tests[0].test_suite_name())
        EXPECT_TRUE(IsNull(tests[0].value_param()))
        EXPECT_STREQ(GetTypeName[Types[Int32]]().c_str(), tests[0].type_param())
        EXPECT_TRUE(tests[0].should_run())
        EXPECT_TRUE(tests[0].result().Passed())
        EXPECT_EQ(0, tests[0].result().test_property_count())
        tests.free()
        test_suites.free()

def main():
    InitGoogleTest()
    AddGlobalTestEnvironment(FinalSuccessChecker())
    return RUN_ALL_TESTS()