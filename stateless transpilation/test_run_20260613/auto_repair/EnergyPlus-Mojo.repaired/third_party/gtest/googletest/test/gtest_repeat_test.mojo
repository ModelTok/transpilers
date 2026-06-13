from stdlib import *
from gtest import *
from src.gtest-internal-inl import *

namespace testing:
    GTEST_DECLARE_string_(death_test_style)
    GTEST_DECLARE_string_(filter)
    GTEST_DECLARE_int32_(repeat)

using testing.GTEST_FLAG(death_test_style)
using testing.GTEST_FLAG(filter)
using testing.GTEST_FLAG(repeat)

namespace:

    def GTEST_CHECK_INT_EQ_(expected: Int, actual: Int):
        let expected_val = expected
        let actual_val = actual
        if testing.internal.IsTrue(expected_val != actual_val):
            std.cout << "Value of: " #actual "\n"
            std.cout << "  Actual: " << actual_val << "\n"
            std.cout << "Expected: " #expected "\n"
            std.cout << "Which is: " << expected_val << "\n"
            testing.internal.posix.Abort()

    var g_environment_set_up_count: Int = 0
    var g_environment_tear_down_count: Int = 0

    class MyEnvironment(testing.Environment):
        def __init__(inout self):

        def SetUp(inout self):
            g_environment_set_up_count += 1
        def TearDown(inout self):
            g_environment_tear_down_count += 1

    var g_should_fail_count: Int = 0

    @TEST
    def FooTest_ShouldFail():
        g_should_fail_count += 1
        EXPECT_EQ(0, 1) << "Expected failure."

    var g_should_pass_count: Int = 0

    @TEST
    def FooTest_ShouldPass():
        g_should_pass_count += 1

    var g_death_test_count: Int = 0

    @TEST
    def BarDeathTest_ThreadSafeAndFast():
        g_death_test_count += 1
        GTEST_FLAG(death_test_style) = "threadsafe"
        EXPECT_DEATH_IF_SUPPORTED(testing.internal.posix.Abort(), "")
        GTEST_FLAG(death_test_style) = "fast"
        EXPECT_DEATH_IF_SUPPORTED(testing.internal.posix.Abort(), "")

    var g_param_test_count: Int = 0
    let kNumberOfParamTests: Int = 10

    class MyParamTest(testing.TestWithParam[Int]):

    @TEST_P
    def MyParamTest_ShouldPass():
        GTEST_CHECK_INT_EQ_(g_param_test_count % kNumberOfParamTests, GetParam())
        g_param_test_count += 1

    INSTANTIATE_TEST_SUITE_P(MyParamSequence, MyParamTest, testing.Range(0, kNumberOfParamTests))

    def ResetCounts():
        g_environment_set_up_count = 0
        g_environment_tear_down_count = 0
        g_should_fail_count = 0
        g_should_pass_count = 0
        g_death_test_count = 0
        g_param_test_count = 0

    def CheckCounts(expected: Int):
        GTEST_CHECK_INT_EQ_(expected, g_environment_set_up_count)
        GTEST_CHECK_INT_EQ_(expected, g_environment_tear_down_count)
        GTEST_CHECK_INT_EQ_(expected, g_should_fail_count)
        GTEST_CHECK_INT_EQ_(expected, g_should_pass_count)
        GTEST_CHECK_INT_EQ_(expected, g_death_test_count)
        GTEST_CHECK_INT_EQ_(expected * kNumberOfParamTests, g_param_test_count)

    def TestRepeatUnspecified():
        ResetCounts()
        GTEST_CHECK_INT_EQ_(1, RUN_ALL_TESTS())
        CheckCounts(1)

    def TestRepeat(repeat: Int):
        GTEST_FLAG(repeat) = repeat
        ResetCounts()
        GTEST_CHECK_INT_EQ_(repeat > 0 ? 1 : 0, RUN_ALL_TESTS())
        CheckCounts(repeat)

    def TestRepeatWithEmptyFilter(repeat: Int):
        GTEST_FLAG(repeat) = repeat
        GTEST_FLAG(filter) = "None"
        ResetCounts()
        GTEST_CHECK_INT_EQ_(0, RUN_ALL_TESTS())
        CheckCounts(0)

    def TestRepeatWithFilterForSuccessfulTests(repeat: Int):
        GTEST_FLAG(repeat) = repeat
        GTEST_FLAG(filter) = "*-*ShouldFail"
        ResetCounts()
        GTEST_CHECK_INT_EQ_(0, RUN_ALL_TESTS())
        GTEST_CHECK_INT_EQ_(repeat, g_environment_set_up_count)
        GTEST_CHECK_INT_EQ_(repeat, g_environment_tear_down_count)
        GTEST_CHECK_INT_EQ_(0, g_should_fail_count)
        GTEST_CHECK_INT_EQ_(repeat, g_should_pass_count)
        GTEST_CHECK_INT_EQ_(repeat, g_death_test_count)
        GTEST_CHECK_INT_EQ_(repeat * kNumberOfParamTests, g_param_test_count)

    def TestRepeatWithFilterForFailedTests(repeat: Int):
        GTEST_FLAG(repeat) = repeat
        GTEST_FLAG(filter) = "*ShouldFail"
        ResetCounts()
        GTEST_CHECK_INT_EQ_(1, RUN_ALL_TESTS())
        GTEST_CHECK_INT_EQ_(repeat, g_environment_set_up_count)
        GTEST_CHECK_INT_EQ_(repeat, g_environment_tear_down_count)
        GTEST_CHECK_INT_EQ_(repeat, g_should_fail_count)
        GTEST_CHECK_INT_EQ_(0, g_should_pass_count)
        GTEST_CHECK_INT_EQ_(0, g_death_test_count)
        GTEST_CHECK_INT_EQ_(0, g_param_test_count)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    testing.InitGoogleTest(argc, argv)
    testing.AddGlobalTestEnvironment(MyEnvironment())
    TestRepeatUnspecified()
    TestRepeat(0)
    TestRepeat(1)
    TestRepeat(5)
    TestRepeatWithEmptyFilter(2)
    TestRepeatWithEmptyFilter(3)
    TestRepeatWithFilterForSuccessfulTests(3)
    TestRepeatWithFilterForFailedTests(4)
    printf("PASS\n")
    return 0