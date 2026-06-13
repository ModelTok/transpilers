from sys import exit
from gtest import *
from src.gtest-internal-inl import *

# using ::cout;  // omitted

namespace testing:
    # TEST(GTestEnvVarTest, Dummy) {}  // translated to empty function
    def GTestEnvVarTest_Dummy():

    def PrintFlag(flag: String):
        if flag == "break_on_failure":
            print(GTEST_FLAG.break_on_failure)
            return
        if flag == "catch_exceptions":
            print(GTEST_FLAG.catch_exceptions)
            return
        if flag == "color":
            print(GTEST_FLAG.color)
            return
        if flag == "death_test_style":
            print(GTEST_FLAG.death_test_style)
            return
        if flag == "death_test_use_fork":
            print(GTEST_FLAG.death_test_use_fork)
            return
        if flag == "fail_fast":
            print(GTEST_FLAG.fail_fast)
            return
        if flag == "filter":
            print(GTEST_FLAG.filter)
            return
        if flag == "output":
            print(GTEST_FLAG.output)
            return
        if flag == "brief":
            print(GTEST_FLAG.brief)
            return
        if flag == "print_time":
            print(GTEST_FLAG.print_time)
            return
        if flag == "repeat":
            print(GTEST_FLAG.repeat)
            return
        if flag == "stack_trace_depth":
            print(GTEST_FLAG.stack_trace_depth)
            return
        if flag == "throw_on_failure":
            print(GTEST_FLAG.throw_on_failure)
            return
        print("Invalid flag name " + flag + ".  Valid names are break_on_failure, color, filter, etc.\n")
        exit(1)

def main():
    var args = sys.argv()
    var argc = len(args)
    # In Mojo, assume InitGoogleTest takes a mutable list and an int
    testing.InitGoogleTest(argc, args)
    if argc != 2:
        print("Usage: googletest-env-var-test_ NAME_OF_FLAG")
        return 1
    testing.PrintFlag(args[1])
    return 0