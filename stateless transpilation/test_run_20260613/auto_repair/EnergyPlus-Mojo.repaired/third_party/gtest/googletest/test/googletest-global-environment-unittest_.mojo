from gtest.gtest import *

class FailingEnvironment(Environment):
    def SetUp(self):
        FAIL() << "Canned environment setup error"

let g_environment_ = testing.AddGlobalTestEnvironment(FailingEnvironment())

testing.TEST("SomeTest", "DoesFoo", fn():
    FAIL() << "Unexpected call"
)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    testing.InitGoogleTest(&argc, argv)
    return testing.RUN_ALL_TESTS()