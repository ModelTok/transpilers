from gmock.gmock import HasSubstr, GoogleTestFailureException
from gtest.gtest import TEST, FAIL, EXPECT_THAT

# if GTEST_HAS_EXCEPTIONS
let GTEST_HAS_EXCEPTIONS: Bool = True
if GTEST_HAS_EXCEPTIONS:
    class NonDefaultConstructible:
        def __init__(inout self, dummy: Int = 0):  # constructor, default parameter to match class MockFoo:
        def GetNonDefaultConstructible(inout self) -> NonDefaultConstructible:
            raise RuntimeError("has no default value")  # simulate MOCK_METHOD0 behavior when no default

    def DefaultValueTest_ThrowsRuntimeErrorWhenNoDefaultValue():
        let mock = MockFoo()
        try:
            mock.GetNonDefaultConstructible()
            FAIL() << "GetNonDefaultConstructible()'s return type has no default " \
                   << "value, so Google Mock should have thrown."
        except GoogleTestFailureException as unused:
            FAIL() << "Google Test does not try to catch an exception of type " \
                   << "GoogleTestFailureException, which is used for reporting " \
                   << "a failure to other testing frameworks.  Google Mock should " \
                   << "not throw a GoogleTestFailureException as it will kill the " \
                   << "entire test program instead of just the current TEST."
        except e: RuntimeError:
            EXPECT_THAT(str(e), HasSubstr("has no default value"))
    TEST(DefaultValueTest, ThrowsRuntimeErrorWhenNoDefaultValue)
        DefaultValueTest_ThrowsRuntimeErrorWhenNoDefaultValue()
# endif