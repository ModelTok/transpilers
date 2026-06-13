from gtest.gtest import *
from src.gtest-internal-inl import *

enum FailureType:
    NO_FAILURE
    NON_FATAL_FAILURE
    FATAL_FAILURE

class MyEnvironment(testing.Environment):
    var failure_in_set_up_: FailureType
    var set_up_was_run_: Bool
    var tear_down_was_run_: Bool

    def __init__(inout self):
        self.Reset()

    def SetUp(inout self) override:
        self.set_up_was_run_ = True
        if self.failure_in_set_up_ == NON_FATAL_FAILURE:
            AddFailure("Expected non-fatal failure in global set-up.")
        elif self.failure_in_set_up_ == FATAL_FAILURE:
            Fail("Expected fatal failure in global set-up.")
        else:

    def TearDown(inout self) override:
        self.tear_down_was_run_ = True
        AddFailure("Expected non-fatal failure in global tear-down.")

    def Reset(inout self):
        self.failure_in_set_up_ = NO_FAILURE
        self.set_up_was_run_ = False
        self.tear_down_was_run_ = False

    def set_failure_in_set_up(inout self, type: FailureType):
        self.failure_in_set_up_ = type

    def set_up_was_run(self) -> Bool:
        return self.set_up_was_run_

    def tear_down_was_run(self) -> Bool:
        return self.tear_down_was_run_

var test_was_run: Bool = False

def FooTest_Bar():
    test_was_run = True

def Check(condition: Bool, msg: String):
    if not condition:
        printf("FAILED: %s\n", msg)
        testing.internal.posix.Abort()

def RunAllTests(inout env: MyEnvironment, failure: FailureType) -> Int32:
    env.Reset()
    env.set_failure_in_set_up(failure)
    test_was_run = False
    testing.internal.GetUnitTestImpl().ClearAdHocTestResult()
    return RUN_ALL_TESTS()

def main(argc: Int32, argv: Pointer[Pointer[UInt8]]):
    testing.InitGoogleTest(&argc, argv)
    var env = MyEnvironment()
    Check(testing.AddGlobalTestEnvironment(env) == env,
          "AddGlobalTestEnvironment() should return its argument.")
    Check(RunAllTests(env, NO_FAILURE) != 0,
          "RUN_ALL_TESTS() should return non-zero, as the global tear-down "
          "should generate a failure.")
    Check(test_was_run,
          "The tests should run, as the global set-up should generate no "
          "failure")
    Check(env.tear_down_was_run(),
          "The global tear-down should run, as the global set-up was run.")
    Check(RunAllTests(env, NON_FATAL_FAILURE) != 0,
          "RUN_ALL_TESTS() should return non-zero, as both the global set-up "
          "and the global tear-down should generate a non-fatal failure.")
    Check(test_was_run,
          "The tests should run, as the global set-up should generate no "
          "fatal failure.")
    Check(env.tear_down_was_run(),
          "The global tear-down should run, as the global set-up was run.")
    Check(RunAllTests(env, FATAL_FAILURE) != 0,
          "RUN_ALL_TESTS() should return non-zero, as the global set-up "
          "should generate a fatal failure.")
    Check(not test_was_run,
          "The tests should not run, as the global set-up should generate "
          "a fatal failure.")
    Check(env.tear_down_was_run(),
          "The global tear-down should run, as the global set-up was run.")
    testing.GTEST_FLAG_filter = "-*"
    Check(RunAllTests(env, NO_FAILURE) == 0,
          "RUN_ALL_TESTS() should return zero, as there is no test to run.")
    Check(not env.set_up_was_run(),
          "The global set-up should not run, as there is no test to run.")
    Check(not env.tear_down_was_run(),
          "The global tear-down should not run, "
          "as the global set-up was not run.")
    printf("PASS\n")
    return 0
<<<END_FILE>>>