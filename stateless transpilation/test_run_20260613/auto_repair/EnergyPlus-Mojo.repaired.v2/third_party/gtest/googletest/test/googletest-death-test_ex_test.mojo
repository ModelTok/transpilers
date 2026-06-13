from ...gtest.gtest import *
from ...gtest.gtest-death-test import *
from ...gtest.gtest-spi import *

@parameter
if GTEST_HAS_DEATH_TEST:
    @parameter
    if GTEST_HAS_SEH:
        from windows import RaiseException
    @parameter
    if GTEST_HAS_EXCEPTIONS:
        from std import exception

        @TEST("CxxExceptionDeathTest", "ExceptionIsFailure")
        def ExceptionIsFailure():
            try:
                EXPECT_NONFATAL_FAILURE(EXPECT_DEATH(raise 1, ""), "threw an exception")
            except:
                FAIL("An exception escaped a death test macro invocation " +
                     "with catch_exceptions " +
                     ("enabled" if testing.GTEST_FLAG.catch_exceptions else "disabled"))

        class TestException(exception):
            def what(self) -> String:
                return "exceptional message"

        @TEST("CxxExceptionDeathTest", "PrintsMessageForStdExceptions")
        def PrintsMessageForStdExceptions():
            EXPECT_NONFATAL_FAILURE(EXPECT_DEATH(raise TestException(), ""), "exceptional message")
            EXPECT_NONFATAL_FAILURE(EXPECT_DEATH(raise TestException(), ""), __file__)

    @parameter
    if GTEST_HAS_SEH:
        @TEST("SehExceptionDeasTest", "CatchExceptionsDoesNotInterfere")
        def CatchExceptionsDoesNotInterfere():
            EXPECT_DEATH(RaiseException(42, 0x0, 0, None), "").with_message(
                "with catch_exceptions " +
                ("enabled" if testing.GTEST_FLAG.catch_exceptions else "disabled"))

def main():
    var args = sys.argv()
    testing.InitGoogleTest(args)
    testing.GTEST_FLAG.catch_exceptions = (GTEST_ENABLE_CATCH_EXCEPTIONS_ != 0)
    return RUN_ALL_TESTS()