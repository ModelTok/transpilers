from gtest import EmptyTestEventListener, TestPartResult, AssertionException, InitGoogleTest, UnitTest, RUN_ALL_TESTS, ASSERT_EQ, EXPECT_EQ, TEST
import sys

struct ThrowListener(EmptyTestEventListener):
    def OnTestPartResult(self, result: TestPartResult):
        if result.type() == TestPartResult.kFatalFailure:
            throw AssertionException(result)

def Fail(msg: String):
    print("FAILURE: " + msg)
    sys.stdout.flush()
    sys.exit(1)

def AssertFalse():
    ASSERT_EQ(2, 3, "Expected failure")

TEST("Test", "Test") {
    try:
        EXPECT_EQ(3, 3)
    except:
        Fail("A successful assertion wrongfully threw.")

    try:
        EXPECT_EQ(3, 4)
    except:
        Fail("A failed non-fatal assertion wrongfully threw.")

    try:
        AssertFalse()
    except e as AssertionException:
        if e.what().find("Expected failure") != -1:
            throw e
        print(
            "A failed assertion did throw an exception of the right type, "
            "but the message is incorrect.  Instead of containing \"Expected "
            "failure\", it is:\n"
        )
        Fail(e.what())
    except:
        Fail("A failed assertion threw the wrong type of exception.")

    Fail("A failed assertion should've thrown but didn't.")
}

var kTestForContinuingTest: Int = 0

TEST("Test", "Test2") {
    kTestForContinuingTest = 1
}

def main():
    var argc = len(sys.argv)
    var argv = sys.argv
    InitGoogleTest(argc, argv)
    UnitTest.GetInstance().listeners().Append(ThrowListener())
    var result = RUN_ALL_TESTS()
    if result == 0:
        print("RUN_ALL_TESTS returned ", result)
        Fail("Expected failure instead.")
    if kTestForContinuingTest == 0:
        Fail("Should have continued with other tests, but did not.")
    sys.exit(0)