from gtest import (
    Test,
    TestWithParam,
    TestEventListeners,
    UnitTest,
    Values,
    InitGoogleTest,
    RUN_ALL_TESTS,
    RecordProperty,
    SUCCEED,
    FAIL,
    ASSERT_EQ,
    EXPECT_EQ,
    GTEST_SKIP,
    TYPED_TEST_SUITE,
    TYPED_TEST,
    TYPED_TEST_SUITE_P,
    TYPED_TEST_P,
    REGISTER_TYPED_TEST_SUITE_P,
    INSTANTIATE_TYPED_TEST_SUITE_P,
    INSTANTIATE_TEST_SUITE_P,
    TEST_F,
    TEST,
    TEST_P,
    Types,
)

class SuccessfulTest(Test):

TEST_F(SuccessfulTest, Succeeds):
    SUCCEED() << "This is a success."
    ASSERT_EQ(1, 1)

class FailedTest(Test):

TEST_F(FailedTest, Fails):
    ASSERT_EQ(1, 2)

class DisabledTest(Test):

TEST_F(DisabledTest, DISABLED_test_not_run):
    FAIL() << "Unexpected failure: Disabled test should not be run"

class SkippedTest(Test):

TEST_F(SkippedTest, Skipped):
    GTEST_SKIP()

TEST_F(SkippedTest, SkippedWithMessage):
    GTEST_SKIP() << "It is good practice to tell why you skip a test."

TEST_F(SkippedTest, SkippedAfterFailure):
    EXPECT_EQ(1, 2)
    GTEST_SKIP() << "It is good practice to tell why you skip a test."

TEST(MixedResultTest, Succeeds):
    EXPECT_EQ(1, 1)
    ASSERT_EQ(1, 1)

TEST(MixedResultTest, Fails):
    EXPECT_EQ(1, 2)
    ASSERT_EQ(2, 3)

TEST(MixedResultTest, DISABLED_test):
    FAIL() << "Unexpected failure: Disabled test should not be run"

TEST(XmlQuotingTest, OutputsCData):
    FAIL() << "XML output: "
              "<?xml encoding=\"utf-8\"><top><![CDATA[cdata text]]></top>"

TEST(InvalidCharactersTest, InvalidCharactersInMessage):
    FAIL() << "Invalid characters in brackets [\x1\x2]"

class PropertyRecordingTest(Test):
    @staticmethod
    def SetUpTestSuite():
        RecordProperty("SetUpTestSuite", "yes")
    @staticmethod
    def TearDownTestSuite():
        RecordProperty("TearDownTestSuite", "aye")

TEST_F(PropertyRecordingTest, OneProperty):
    RecordProperty("key_1", "1")

TEST_F(PropertyRecordingTest, IntValuedProperty):
    RecordProperty("key_int", 1)

TEST_F(PropertyRecordingTest, ThreeProperties):
    RecordProperty("key_1", "1")
    RecordProperty("key_2", "2")
    RecordProperty("key_3", "3")

TEST_F(PropertyRecordingTest, TwoValuesForOneKeyUsesLastValue):
    RecordProperty("key_1", "1")
    RecordProperty("key_1", "2")

TEST(NoFixtureTest, RecordProperty):
    RecordProperty("key", "1")

def ExternalUtilityThatCallsRecordProperty(key: String, value: Int):
    Test.RecordProperty(key, value)

def ExternalUtilityThatCallsRecordProperty(key: String, value: String):
    Test.RecordProperty(key, value)

TEST(NoFixtureTest, ExternalUtilityThatCallsRecordIntValuedProperty):
    ExternalUtilityThatCallsRecordProperty("key_for_utility_int", 1)

TEST(NoFixtureTest, ExternalUtilityThatCallsRecordStringValuedProperty):
    ExternalUtilityThatCallsRecordProperty("key_for_utility_string", "1")

class ValueParamTest(TestWithParam[Int]):

TEST_P(ValueParamTest, HasValueParamAttribute):

TEST_P(ValueParamTest, AnotherTestThatHasValueParamAttribute):

INSTANTIATE_TEST_SUITE_P(Single, ValueParamTest, Values(33, 42))

class TypedTest(Test):

alias TypedTestTypes = Types[Int, Int64]

TYPED_TEST_SUITE(TypedTest, TypedTestTypes)

TYPED_TEST(TypedTest, HasTypeParamAttribute):

class TypeParameterizedTestSuite(Test):

TYPED_TEST_SUITE_P(TypeParameterizedTestSuite)

TYPED_TEST_P(TypeParameterizedTestSuite, HasTypeParamAttribute):

REGISTER_TYPED_TEST_SUITE_P(TypeParameterizedTestSuite, HasTypeParamAttribute)

alias TypeParameterizedTestSuiteTypes = Types[Int, Int64]

INSTANTIATE_TYPED_TEST_SUITE_P(Single, TypeParameterizedTestSuite, TypeParameterizedTestSuiteTypes)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    InitGoogleTest(argc, argv)
    if argc > 1 and strcmp(argv[1], "--shut_down_xml") == 0:
        var listeners: TestEventListeners = UnitTest.GetInstance().listeners()
        delete listeners.Release(listeners.default_xml_generator())
    Test.RecordProperty("ad_hoc_property", "42")
    return RUN_ALL_TESTS()