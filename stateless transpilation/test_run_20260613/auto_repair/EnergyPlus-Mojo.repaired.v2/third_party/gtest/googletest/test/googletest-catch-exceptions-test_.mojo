# #include <stdio.h>  // NOLINT
# #include <stdlib.h>  // For exit().
# #include "gtest/gtest.h"
# #if GTEST_HAS_SEH
# # include <windows.h>
# #endif
# #if GTEST_HAS_EXCEPTIONS
# # include <exception>  // For set_terminate().
# # include <stdexcept>
# #endif
from testing import Test

# #if GTEST_HAS_SEH
class SehExceptionInConstructorTest(Test):
    def __init__(self):
        RaiseException(42, 0, 0, None)
# TEST_F(SehExceptionInConstructorTest, ThrowsExceptionInConstructor) {}

class SehExceptionInDestructorTest(Test):
    def __del__(self) override:
        RaiseException(42, 0, 0, None)
# TEST_F(SehExceptionInDestructorTest, ThrowsExceptionInDestructor) {}

class SehExceptionInSetUpTestSuiteTest(Test):
    @staticmethod def SetUpTestSuite():
        RaiseException(42, 0, 0, None)
# TEST_F(SehExceptionInSetUpTestSuiteTest, ThrowsExceptionInSetUpTestSuite) {}

class SehExceptionInTearDownTestSuiteTest(Test):
    @staticmethod def TearDownTestSuite():
        RaiseException(42, 0, 0, None)
# TEST_F(SehExceptionInTearDownTestSuiteTest, ThrowsExceptionInTearDownTestSuite) {}

class SehExceptionInSetUpTest(Test):
        def SetUp(self) override:
            RaiseException(42, 0, 0, None)
# TEST_F(SehExceptionInSetUpTest, ThrowsExceptionInSetUp) {}

class SehExceptionInTearDownTest(Test):
        def TearDown(self) override:
            RaiseException(42, 0, 0, None)
# TEST_F(SehExceptionInTearDownTest, ThrowsExceptionInTearDown) {}

# TEST(SehExceptionTest, ThrowsSehException) {
#   RaiseException(42, 0, 0, NULL);
# }
# #endif  // GTEST_HAS_SEH

# #if GTEST_HAS_EXCEPTIONS
class CxxExceptionInConstructorTest(Test):
    def __init__(self):
        # GTEST_SUPPRESS_UNREACHABLE_CODE_WARNING_BELOW_(
        raise RuntimeError("Standard C++ exception")
    @staticmethod def TearDownTestSuite():
        print("CxxExceptionInConstructorTest::TearDownTestSuite() called as expected.\n")
        # printf("%s", "CxxExceptionInConstructorTest::TearDownTestSuite() called as expected.\n");
        def __del__(self) override:
            ADD_FAILURE() << "CxxExceptionInConstructorTest destructor called unexpectedly."
        def SetUp(self) override:
            ADD_FAILURE() << "CxxExceptionInConstructorTest::SetUp() called unexpectedly."
        def TearDown(self) override:
            ADD_FAILURE() << "CxxExceptionInConstructorTest::TearDown() called unexpectedly."
# TEST_F(CxxExceptionInConstructorTest, ThrowsExceptionInConstructor) {
#   ADD_FAILURE() << "CxxExceptionInConstructorTest test body called unexpectedly.";
# }

class CxxExceptionInSetUpTestSuiteTest(Test):
    def __init__(self):
        print("CxxExceptionInSetUpTestSuiteTest constructor called as expected.\n")
    @staticmethod def SetUpTestSuite():
        raise RuntimeError("Standard C++ exception")
    @staticmethod def TearDownTestSuite():
        print("CxxExceptionInSetUpTestSuiteTest::TearDownTestSuite() called as expected.\n")
        def __del__(self) override:
            print("CxxExceptionInSetUpTestSuiteTest destructor called as expected.\n")
        def SetUp(self) override:
            print("CxxExceptionInSetUpTestSuiteTest::SetUp() called as expected.\n")
        def TearDown(self) override:
            print("CxxExceptionInSetUpTestSuiteTest::TearDown() called as expected.\n")
# TEST_F(CxxExceptionInSetUpTestSuiteTest, ThrowsExceptionInSetUpTestSuite) {
#   printf("%s",
#          "CxxExceptionInSetUpTestSuiteTest test body called as expected.\n");
# }

class CxxExceptionInTearDownTestSuiteTest(Test):
    @staticmethod def TearDownTestSuite():
        raise RuntimeError("Standard C++ exception")
# TEST_F(CxxExceptionInTearDownTestSuiteTest, ThrowsExceptionInTearDownTestSuite) {}

class CxxExceptionInSetUpTest(Test):
    @staticmethod def TearDownTestSuite():
        print("CxxExceptionInSetUpTest::TearDownTestSuite() called as expected.\n")
        def __del__(self) override:
            print("CxxExceptionInSetUpTest destructor called as expected.\n")
        def SetUp(self) override:
            raise RuntimeError("Standard C++ exception")
        def TearDown(self) override:
            print("CxxExceptionInSetUpTest::TearDown() called as expected.\n")
# TEST_F(CxxExceptionInSetUpTest, ThrowsExceptionInSetUp) {
#   ADD_FAILURE() << "CxxExceptionInSetUpTest test body called unexpectedly.";
# }

class CxxExceptionInTearDownTest(Test):
    @staticmethod def TearDownTestSuite():
        print("CxxExceptionInTearDownTest::TearDownTestSuite() called as expected.\n")
        def __del__(self) override:
            print("CxxExceptionInTearDownTest destructor called as expected.\n")
        def TearDown(self) override:
            raise RuntimeError("Standard C++ exception")
# TEST_F(CxxExceptionInTearDownTest, ThrowsExceptionInTearDown) {}

class CxxExceptionInTestBodyTest(Test):
    @staticmethod def TearDownTestSuite():
        print("CxxExceptionInTestBodyTest::TearDownTestSuite() called as expected.\n")
        def __del__(self) override:
            print("CxxExceptionInTestBodyTest destructor called as expected.\n")
        def TearDown(self) override:
            print("CxxExceptionInTestBodyTest::TearDown() called as expected.\n")
# TEST_F(CxxExceptionInTestBodyTest, ThrowsStdCxxException) {
#   throw runtime_error("Standard C++ exception");
# }

# TEST(CxxExceptionTest, ThrowsNonStdCxxException) {
#   throw "C-string";
# }

def TerminateHandler():
    print("Unhandled C++ exception terminating the program.\n")
    fflush(None)
    exit(3)
# #endif  // GTEST_HAS_EXCEPTIONS

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    # #if GTEST_HAS_EXCEPTIONS
    set_terminate(TerminateHandler)
    # #endif
    InitGoogleTest(argc, argv)
    return run_all_tests()