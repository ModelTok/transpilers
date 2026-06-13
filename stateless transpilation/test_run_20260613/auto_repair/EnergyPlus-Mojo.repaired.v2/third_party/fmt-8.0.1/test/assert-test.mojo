from fmt.core import *
from gtest.gtest import *

def test_assert_test_fail():
    #if GTEST_HAS_DEATH_TEST
    #  EXPECT_DEBUG_DEATH(FMT_ASSERT(false, "don't panic!"), "don't panic!");
    #else
    fmt.print("warning: death tests are not supported\n")
    #endif

def test_assert_test_dangling_else():
    var test_condition: Bool = False
    var executed_else: Bool = False
    if test_condition:
        FMT_ASSERT(true, "")
    else:
        executed_else = true
    EXPECT_TRUE(executed_else)