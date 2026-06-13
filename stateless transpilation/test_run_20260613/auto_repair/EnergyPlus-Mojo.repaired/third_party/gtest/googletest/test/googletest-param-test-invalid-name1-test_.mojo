from gtest import TestWithParam, TEST_P, INSTANTIATE_TEST_SUITE_P, Values, PrintToStringParamName, InitGoogleTest, RUN_ALL_TESTS

class DummyTest(TestWithParam[String]):

@TEST_P(DummyTest, Dummy)
def Dummy():

INSTANTIATE_TEST_SUITE_P(InvalidTestName, DummyTest, Values("InvalidWithQuotes"), PrintToStringParamName())

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()