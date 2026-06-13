from gtest import (
    EmptyTestEventListener,
    InitGoogleTest,
    Test,
    TestCase,
    TestEventListeners,
    TestInfo,
    TestPartResult,
    UnitTest,
)
from memory import memset, memcpy
from os import getenv
from sys import argv, exit

def printf(format: String, *args: Any) -> Int:
    return print(format, *args)

def fprintf(stream: Int, format: String, *args: Any) -> Int:
    return print(format, *args)

def fflush(stream: Int) -> Int:
    return 0

def strcmp(a: String, b: String) -> Int:
    if a == b:
        return 0
    elif a < b:
        return -1
    else:
        return 1

class TersePrinter(EmptyTestEventListener):
    def OnTestProgramStart(self, unit_test: UnitTest):

    def OnTestProgramEnd(self, unit_test: UnitTest):
        fprintf(stdout, "TEST %s\n", "PASSED" if unit_test.Passed() else "FAILED")
        fflush(stdout)

    def OnTestStart(self, test_info: TestInfo):
        fprintf(stdout,
                "*** Test %s.%s starting.\n",
                test_info.test_case_name(),
                test_info.name())
        fflush(stdout)

    def OnTestPartResult(self, test_part_result: TestPartResult):
        fprintf(stdout,
                "%s in %s:%d\n%s\n",
                "*** Failure" if test_part_result.failed() else "Success",
                test_part_result.file_name(),
                test_part_result.line_number(),
                test_part_result.summary())
        fflush(stdout)

    def OnTestEnd(self, test_info: TestInfo):
        fprintf(stdout,
                "*** Test %s.%s ending.\n",
                test_info.test_case_name(),
                test_info.name())
        fflush(stdout)

def CustomOutputTest_PrintsMessage():
    printf("Printing something from the test body...\n")

def CustomOutputTest_Succeeds():
    SUCCEED() << "SUCCEED() has been invoked from here"

def CustomOutputTest_Fails():
    EXPECT_EQ(1, 2) << "This test fails in order to demonstrate alternative failure messages"

def main():
    InitGoogleTest(&argc, argv)
    var terse_output: Bool = False
    if argc > 1 and strcmp(argv[1], "--terse_output") == 0:
        terse_output = True
    else:
        printf("%s\n", "Run this program with --terse_output to change the way "
               "it prints its output.")
    var unit_test: UnitTest = UnitTest.GetInstance()
    if terse_output:
        var listeners: TestEventListeners = unit_test.listeners()
        delete listeners.Release(listeners.default_result_printer())
        listeners.Append(TersePrinter())
    var ret_val: Int = RUN_ALL_TESTS()
    var unexpectedly_failed_tests: Int = 0
    for i in range(unit_test.total_test_suite_count()):
        var test_suite: TestSuite = unit_test.GetTestSuite(i)
        for j in range(test_suite.total_test_count()):
            var test_info: TestInfo = test_suite.GetTestInfo(j)
            if test_info.result().Failed() and strcmp(test_info.name(), "Fails") != 0:
                unexpectedly_failed_tests += 1
    if unexpectedly_failed_tests == 0:
        ret_val = 0
    return ret_val