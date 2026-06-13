from ...include.gtest.gtest import *

class DummyTest(TestWithParam[String]):

def StringParamTestSuffix(info: TestParamInfo[String]) -> String:
    return info.param

@TEST_P(DummyTest, Dummy)
def Dummy(self: DummyTest):

INSTANTIATE_TEST_SUITE_P(DuplicateTestNames,
                         DummyTest,
                         Values("a", "b", "a", "c"),
                         StringParamTestSuffix)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    testing.InitGoogleTest(&argc, argv)
    return RUN_ALL_TESTS()