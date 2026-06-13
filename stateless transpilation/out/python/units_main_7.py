import sys

# EXTERNAL DEPS (to wire in glue):
# - gtest: Google Test C++ testing framework

class _GTestFlags:
    def __init__(self) -> None:
        self.break_on_failure: bool = False
        self.catch_exceptions: bool = True

class _GTest:
    def __init__(self) -> None:
        self.GTEST_FLAG = _GTestFlags()

    def InitGoogleTest(self, argc: int, argv: list[str]) -> None:
        pass

    def RUN_ALL_TESTS(self) -> int:
        return 0

try:
    from gtest import GTEST_FLAG, InitGoogleTest, RUN_ALL_TESTS
except ImportError:
    _gtest_instance = _GTest()
    GTEST_FLAG = _gtest_instance.GTEST_FLAG
    InitGoogleTest = _gtest_instance.InitGoogleTest
    RUN_ALL_TESTS = _gtest_instance.RUN_ALL_TESTS

def main(argc: int, argv: list[str]) -> int:
    ENABLE_GTEST_DEBUG_MODE = True
    if ENABLE_GTEST_DEBUG_MODE:
        GTEST_FLAG.break_on_failure = True
        GTEST_FLAG.catch_exceptions = False

    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()

if __name__ == '__main__':
    sys.exit(main(len(sys.argv), sys.argv))
