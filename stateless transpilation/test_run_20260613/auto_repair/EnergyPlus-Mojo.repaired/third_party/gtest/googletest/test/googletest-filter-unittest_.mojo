from gtest import *

class FooTest(testing.Test):

def FooTest_Abc():

def FooTest_Xyz():
    testing.fail("Expected failure.")

class BarTest(testing.Test):

def BarTest_TestOne():

def BarTest_TestTwo():

def BarTest_TestThree():

def BarTest_DISABLED_TestFour():
    testing.fail("Expected failure.")

def BarTest_DISABLED_TestFive():
    testing.fail("Expected failure.")

class BazTest(testing.Test):

def BazTest_TestOne():
    testing.fail("Expected failure.")

def BazTest_TestA():

def BazTest_TestB():

def BazTest_DISABLED_TestC():
    testing.fail("Expected failure.")

class HasDeathTest(testing.Test):

def HasDeathTest_Test1():
    testing.expect_death_if_supported(lambda: exit(1), ".*")

def HasDeathTest_Test2():
    testing.expect_death_if_supported(lambda: exit(1), ".*")

class DISABLED_FoobarTest(testing.Test):

def DISABLED_FoobarTest_Test1():
    testing.fail("Expected failure.")

def DISABLED_FoobarTest_DISABLED_Test2():
    testing.fail("Expected failure.")

class DISABLED_FoobarbazTest(testing.Test):

def DISABLED_FoobarbazTest_TestA():
    testing.fail("Expected failure.")

class ParamTest(testing.TestWithParam[Int]):

def ParamTest_TestX():

def ParamTest_TestY():

testing.INSTANTIATE_TEST_SUITE_P("SeqP", ParamTest, testing.Values(1, 2))
testing.INSTANTIATE_TEST_SUITE_P("SeqQ", ParamTest, testing.Values(5, 6))

def main():
    testing.InitGoogleTest()
    return testing.RUN_ALL_TESTS()