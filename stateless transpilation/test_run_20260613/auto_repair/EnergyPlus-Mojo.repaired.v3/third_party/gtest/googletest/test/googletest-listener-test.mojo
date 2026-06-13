from gtest import AddGlobalTestEnvironment
from gtest import Environment
from gtest import InitGoogleTest
from gtest import Test
from gtest import TestSuite
from gtest import TestEventListener
from gtest import TestInfo
from gtest import TestPartResult
from gtest import UnitTest
from gtest import Message
from gtest import GTEST_CHECK_
from gtest import GTEST_FLAG
from gtest import RUN_ALL_TESTS
from gtest import SUCCEED
from gtest import TEST_F

alias GTEST_REMOVE_LEGACY_TEST_CASEAPI_ = False

var g_events: List[String] = List[String]()

namespace testing:
    namespace internal:
        class EventRecordingListener(TestEventListener):
            var name_: String

            def __init__(inout self, name: String):
                self.name_ = name

            def GetFullMethodName(self, name: String) -> String:
                return self.name_ + "." + name

            def OnTestProgramStart(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnTestProgramStart"))

            def OnTestIterationStart(self, unit_test: UnitTest, iteration: Int) raises:
                var message = Message()
                message << self.GetFullMethodName("OnTestIterationStart") << "(" << iteration << ")"
                g_events.push_back(message.GetString())

            def OnEnvironmentsSetUpStart(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsSetUpStart"))

            def OnEnvironmentsSetUpEnd(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsSetUpEnd"))

            if not GTEST_REMOVE_LEGACY_TEST_CASEAPI_:
                def OnTestCaseStart(self, test_case: TestCase) raises:
                    g_events.push_back(self.GetFullMethodName("OnTestCaseStart"))

            def OnTestStart(self, test_info: TestInfo) raises:
                g_events.push_back(self.GetFullMethodName("OnTestStart"))

            def OnTestPartResult(self, test_part_result: TestPartResult) raises:
                g_events.push_back(self.GetFullMethodName("OnTestPartResult"))

            def OnTestEnd(self, test_info: TestInfo) raises:
                g_events.push_back(self.GetFullMethodName("OnTestEnd"))

            if not GTEST_REMOVE_LEGACY_TEST_CASEAPI_:
                def OnTestCaseEnd(self, test_case: TestCase) raises:
                    g_events.push_back(self.GetFullMethodName("OnTestCaseEnd"))

            def OnEnvironmentsTearDownStart(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsTearDownStart"))

            def OnEnvironmentsTearDownEnd(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsTearDownEnd"))

            def OnTestIterationEnd(self, unit_test: UnitTest, iteration: Int) raises:
                var message = Message()
                message << self.GetFullMethodName("OnTestIterationEnd") << "(" << iteration << ")"
                g_events.push_back(message.GetString())

            def OnTestProgramEnd(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnTestProgramEnd"))

        class EventRecordingListener2(TestEventListener):
            var name_: String

            def __init__(inout self, name: String):
                self.name_ = name

            def GetFullMethodName(self, name: String) -> String:
                return self.name_ + "." + name

            def OnTestProgramStart(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnTestProgramStart"))

            def OnTestIterationStart(self, unit_test: UnitTest, iteration: Int) raises:
                var message = Message()
                message << self.GetFullMethodName("OnTestIterationStart") << "(" << iteration << ")"
                g_events.push_back(message.GetString())

            def OnEnvironmentsSetUpStart(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsSetUpStart"))

            def OnEnvironmentsSetUpEnd(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsSetUpEnd"))

            def OnTestSuiteStart(self, test_suite: TestSuite) raises:
                g_events.push_back(self.GetFullMethodName("OnTestSuiteStart"))

            def OnTestStart(self, test_info: TestInfo) raises:
                g_events.push_back(self.GetFullMethodName("OnTestStart"))

            def OnTestPartResult(self, test_part_result: TestPartResult) raises:
                g_events.push_back(self.GetFullMethodName("OnTestPartResult"))

            def OnTestEnd(self, test_info: TestInfo) raises:
                g_events.push_back(self.GetFullMethodName("OnTestEnd"))

            def OnTestSuiteEnd(self, test_suite: TestSuite) raises:
                g_events.push_back(self.GetFullMethodName("OnTestSuiteEnd"))

            def OnEnvironmentsTearDownStart(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsTearDownStart"))

            def OnEnvironmentsTearDownEnd(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnEnvironmentsTearDownEnd"))

            def OnTestIterationEnd(self, unit_test: UnitTest, iteration: Int) raises:
                var message = Message()
                message << self.GetFullMethodName("OnTestIterationEnd") << "(" << iteration << ")"
                g_events.push_back(message.GetString())

            def OnTestProgramEnd(self, unit_test: UnitTest) raises:
                g_events.push_back(self.GetFullMethodName("OnTestProgramEnd"))

        class EnvironmentInvocationCatcher(Environment):
            def SetUp(self) raises:
                g_events.push_back("Environment::SetUp")

            def TearDown(self) raises:
                g_events.push_back("Environment::TearDown")

        class ListenerTest(Test):
            @staticmethod
            def SetUpTestSuite():
                g_events.push_back("ListenerTest::SetUpTestSuite")

            @staticmethod
            def TearDownTestSuite():
                g_events.push_back("ListenerTest::TearDownTestSuite")

            def SetUp(self) raises:
                g_events.push_back("ListenerTest::SetUp")

            def TearDown(self) raises:
                g_events.push_back("ListenerTest::TearDown")

        TEST_F(ListenerTest, DoesFoo):
            g_events.push_back("ListenerTest::* Test Body")
            SUCCEED()

        TEST_F(ListenerTest, DoesBar):
            g_events.push_back("ListenerTest::* Test Body")
            SUCCEED()

from testing.internal import EnvironmentInvocationCatcher
from testing.internal import EventRecordingListener
from testing.internal import EventRecordingListener2

def VerifyResults(data: List[String], expected_data: List[String], expected_data_size: Int):
    var actual_size = data.size
    EXPECT_EQ(expected_data_size, actual_size)
    var shorter_size = expected_data_size if expected_data_size <= actual_size else actual_size
    var i: Int = 0
    for i in range(shorter_size):
        ASSERT_STREQ(expected_data[i], data[i].c_str()) << "at position " << i
    for i in range(shorter_size, actual_size):
        print("  Actual event #{}: {}".format(i, data[i]))

def main():
    var events: List[String] = List[String]()
    g_events = events
    InitGoogleTest(&argc, argv)
    UnitTest.GetInstance().listeners().Append(EventRecordingListener("1st"))
    UnitTest.GetInstance().listeners().Append(EventRecordingListener("2nd"))
    UnitTest.GetInstance().listeners().Append(EventRecordingListener2("3rd"))
    AddGlobalTestEnvironment(EnvironmentInvocationCatcher())
    GTEST_CHECK_(g_events.size == 0) << "AddGlobalTestEnvironment should not generate any events itself."
    GTEST_FLAG.repeat = 2
    var ret_val = RUN_ALL_TESTS()
    if not GTEST_REMOVE_LEGACY_TEST_CASEAPI_:
        var expected_events: List[String] = List[String]("1st.OnTestProgramStart",
                                                         "2nd.OnTestProgramStart",
                                                         "3rd.OnTestProgramStart",
                                                         "1st.OnTestIterationStart(0)",
                                                         "2nd.OnTestIterationStart(0)",
                                                         "3rd.OnTestIterationStart(0)",
                                                         "1st.OnEnvironmentsSetUpStart",
                                                         "2nd.OnEnvironmentsSetUpStart",
                                                         "3rd.OnEnvironmentsSetUpStart",
                                                         "Environment::SetUp",
                                                         "3rd.OnEnvironmentsSetUpEnd",
                                                         "2nd.OnEnvironmentsSetUpEnd",
                                                         "1st.OnEnvironmentsSetUpEnd",
                                                         "3rd.OnTestSuiteStart",
                                                         "1st.OnTestCaseStart",
                                                         "2nd.OnTestCaseStart",
                                                         "ListenerTest::SetUpTestSuite",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "ListenerTest::TearDownTestSuite",
                                                         "3rd.OnTestSuiteEnd",
                                                         "2nd.OnTestCaseEnd",
                                                         "1st.OnTestCaseEnd",
                                                         "1st.OnEnvironmentsTearDownStart",
                                                         "2nd.OnEnvironmentsTearDownStart",
                                                         "3rd.OnEnvironmentsTearDownStart",
                                                         "Environment::TearDown",
                                                         "3rd.OnEnvironmentsTearDownEnd",
                                                         "2nd.OnEnvironmentsTearDownEnd",
                                                         "1st.OnEnvironmentsTearDownEnd",
                                                         "3rd.OnTestIterationEnd(0)",
                                                         "2nd.OnTestIterationEnd(0)",
                                                         "1st.OnTestIterationEnd(0)",
                                                         "1st.OnTestIterationStart(1)",
                                                         "2nd.OnTestIterationStart(1)",
                                                         "3rd.OnTestIterationStart(1)",
                                                         "1st.OnEnvironmentsSetUpStart",
                                                         "2nd.OnEnvironmentsSetUpStart",
                                                         "3rd.OnEnvironmentsSetUpStart",
                                                         "Environment::SetUp",
                                                         "3rd.OnEnvironmentsSetUpEnd",
                                                         "2nd.OnEnvironmentsSetUpEnd",
                                                         "1st.OnEnvironmentsSetUpEnd",
                                                         "3rd.OnTestSuiteStart",
                                                         "1st.OnTestCaseStart",
                                                         "2nd.OnTestCaseStart",
                                                         "ListenerTest::SetUpTestSuite",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "ListenerTest::TearDownTestSuite",
                                                         "3rd.OnTestSuiteEnd",
                                                         "2nd.OnTestCaseEnd",
                                                         "1st.OnTestCaseEnd",
                                                         "1st.OnEnvironmentsTearDownStart",
                                                         "2nd.OnEnvironmentsTearDownStart",
                                                         "3rd.OnEnvironmentsTearDownStart",
                                                         "Environment::TearDown",
                                                         "3rd.OnEnvironmentsTearDownEnd",
                                                         "2nd.OnEnvironmentsTearDownEnd",
                                                         "1st.OnEnvironmentsTearDownEnd",
                                                         "3rd.OnTestIterationEnd(1)",
                                                         "2nd.OnTestIterationEnd(1)",
                                                         "1st.OnTestIterationEnd(1)",
                                                         "3rd.OnTestProgramEnd",
                                                         "2nd.OnTestProgramEnd",
                                                         "1st.OnTestProgramEnd")
    else:
        var expected_events: List[String] = List[String]("1st.OnTestProgramStart",
                                                         "2nd.OnTestProgramStart",
                                                         "3rd.OnTestProgramStart",
                                                         "1st.OnTestIterationStart(0)",
                                                         "2nd.OnTestIterationStart(0)",
                                                         "3rd.OnTestIterationStart(0)",
                                                         "1st.OnEnvironmentsSetUpStart",
                                                         "2nd.OnEnvironmentsSetUpStart",
                                                         "3rd.OnEnvironmentsSetUpStart",
                                                         "Environment::SetUp",
                                                         "3rd.OnEnvironmentsSetUpEnd",
                                                         "2nd.OnEnvironmentsSetUpEnd",
                                                         "1st.OnEnvironmentsSetUpEnd",
                                                         "3rd.OnTestSuiteStart",
                                                         "ListenerTest::SetUpTestSuite",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "ListenerTest::TearDownTestSuite",
                                                         "3rd.OnTestSuiteEnd",
                                                         "1st.OnEnvironmentsTearDownStart",
                                                         "2nd.OnEnvironmentsTearDownStart",
                                                         "3rd.OnEnvironmentsTearDownStart",
                                                         "Environment::TearDown",
                                                         "3rd.OnEnvironmentsTearDownEnd",
                                                         "2nd.OnEnvironmentsTearDownEnd",
                                                         "1st.OnEnvironmentsTearDownEnd",
                                                         "3rd.OnTestIterationEnd(0)",
                                                         "2nd.OnTestIterationEnd(0)",
                                                         "1st.OnTestIterationEnd(0)",
                                                         "1st.OnTestIterationStart(1)",
                                                         "2nd.OnTestIterationStart(1)",
                                                         "3rd.OnTestIterationStart(1)",
                                                         "1st.OnEnvironmentsSetUpStart",
                                                         "2nd.OnEnvironmentsSetUpStart",
                                                         "3rd.OnEnvironmentsSetUpStart",
                                                         "Environment::SetUp",
                                                         "3rd.OnEnvironmentsSetUpEnd",
                                                         "2nd.OnEnvironmentsSetUpEnd",
                                                         "1st.OnEnvironmentsSetUpEnd",
                                                         "3rd.OnTestSuiteStart",
                                                         "ListenerTest::SetUpTestSuite",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "1st.OnTestStart",
                                                         "2nd.OnTestStart",
                                                         "3rd.OnTestStart",
                                                         "ListenerTest::SetUp",
                                                         "ListenerTest::* Test Body",
                                                         "1st.OnTestPartResult",
                                                         "2nd.OnTestPartResult",
                                                         "3rd.OnTestPartResult",
                                                         "ListenerTest::TearDown",
                                                         "3rd.OnTestEnd",
                                                         "2nd.OnTestEnd",
                                                         "1st.OnTestEnd",
                                                         "ListenerTest::TearDownTestSuite",
                                                         "3rd.OnTestSuiteEnd",
                                                         "1st.OnEnvironmentsTearDownStart",
                                                         "2nd.OnEnvironmentsTearDownStart",
                                                         "3rd.OnEnvironmentsTearDownStart",
                                                         "Environment::TearDown",
                                                         "3rd.OnEnvironmentsTearDownEnd",
                                                         "2nd.OnEnvironmentsTearDownEnd",
                                                         "1st.OnEnvironmentsTearDownEnd",
                                                         "3rd.OnTestIterationEnd(1)",
                                                         "2nd.OnTestIterationEnd(1)",
                                                         "1st.OnTestIterationEnd(1)",
                                                         "3rd.OnTestProgramEnd",
                                                         "2nd.OnTestProgramEnd",
                                                         "1st.OnTestProgramEnd")
    VerifyResults(g_events, expected_events, expected_events.size)
    if UnitTest.GetInstance().Failed():
        ret_val = 1
    return ret_val