from gtest import *
from stdlib import *
from stdio import *
from string import *
from stdexcept import *

def Fail(msg: String):
    printf("FAILURE: %s\n", msg)
    fflush(stdout)
    exit(1)

def TestFailureThrowsRuntimeError():
    testing.GTEST_FLAG(throw_on_failure) = True
    try:
        EXPECT_EQ(3, 3)
    except:
        Fail("A successful assertion wrongfully threw.")
    try:
        EXPECT_EQ(2, 3) << "Expected failure"
    except e as RuntimeError:
        if strstr(e.what(), "Expected failure") != None:
            return
        printf("%s",
               "A failed assertion did throw an exception of the right type, "
               "but the message is incorrect.  Instead of containing \"Expected "
               "failure\", it is:\n")
        Fail(e.what())
    except:
        Fail("A failed assertion threw the wrong type of exception.")
    Fail("A failed assertion should've thrown but didn't.")

def main(argc: Int, argv: Pointer[Pointer[Int8]]) -> Int:
    testing.InitGoogleTest(&argc, argv)
    TestFailureThrowsRuntimeError()
    return 0