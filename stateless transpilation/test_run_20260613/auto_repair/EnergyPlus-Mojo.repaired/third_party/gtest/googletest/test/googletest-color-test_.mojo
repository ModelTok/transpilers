from gtest import *
from src.gtest-internal-inl import ShouldUseColor

@TEST
struct GTestColorTest:
    @Test
    def Dummy():

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    testing.InitGoogleTest(argc, argv)
    if ShouldUseColor(True):
        printf("YES\n")
        return 1
    else:
        printf("NO\n")
        return 0