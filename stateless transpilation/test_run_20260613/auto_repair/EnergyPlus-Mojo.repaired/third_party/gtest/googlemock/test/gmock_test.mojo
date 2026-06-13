// #include "gmock/gmock.h"
// #include <string>
// #include "gtest/gtest.h"
// #include "gtest/internal/custom/gtest.h"
// #if !defined(GTEST_CUSTOM_INIT_GOOGLE_TEST_FUNCTION_)

from testing import GMOCK_FLAG, InitGoogleMock

# Placeholder functions for gtest macros (names preserved)
def EXPECT_STREQ(a: String, b: String):

def EXPECT_EQ(a: Int, b: Int):

def ASSERT_EQ(a: Int, b: Int):

# Template function (simplified to concrete for translation)
def TestInitGoogleMock[Char: AnyType, M: Int, N: Int](
    argv: Pointer[Char, M],
    new_argv: Pointer[Char, N],
    expected_gmock_verbose: String):
    var old_verbose = GMOCK_FLAG("verbose")
    var argc = M - 1
    InitGoogleMock(&argc, argv)
    ASSERT_EQ(N - 1, argc)
    for i in range(N):
        EXPECT_STREQ(new_argv[i], argv[i])
    EXPECT_EQ(expected_gmock_verbose, GMOCK_FLAG("verbose"))
    GMOCK_FLAG("verbose") = old_verbose

def InitGoogleMockTest_ParsesInvalidCommandLine():
    var argv: Pointer[String, 1] = Pointer[String, 1](new_argv -> {None})
    var new_argv: Pointer[String, 1] = Pointer[String, 1](new_argv -> {None})
    TestInitGoogleMock[String, 1, 1](argv, new_argv, GMOCK_FLAG("verbose"))

def InitGoogleMockTest_ParsesEmptyCommandLine():
    var argv: Pointer[String, 2] = Pointer[String, 2](new_argv -> {"foo.exe", None})
    var new_argv: Pointer[String, 2] = Pointer[String, 2](new_argv -> {"foo.exe", None})
    TestInitGoogleMock[String, 2, 2](argv, new_argv, GMOCK_FLAG("verbose"))

def InitGoogleMockTest_ParsesSingleFlag():
    var argv: Pointer[String, 3] = Pointer[String, 3](new_argv -> {"foo.exe", "--gmock_verbose=info", None})
    var new_argv: Pointer[String, 2] = Pointer[String, 2](new_argv -> {"foo.exe", None})
    TestInitGoogleMock[String, 3, 2](argv, new_argv, "info")

def InitGoogleMockTest_ParsesMultipleFlags():
    var old_default_behavior = GMOCK_FLAG("default_mock_behavior")
    var argv: Pointer[WideString, 4] = Pointer[WideString, 4](new_argv -> {L"foo.exe", L"--gmock_verbose=info",
                           L"--gmock_default_mock_behavior=2", None})
    var new_argv: Pointer[WideString, 2] = Pointer[WideString, 2](new_argv -> {L"foo.exe", None})
    TestInitGoogleMock[WideString, 4, 2](argv, new_argv, "info")
    EXPECT_EQ(2, GMOCK_FLAG("default_mock_behavior"))
    EXPECT_NE(2, old_default_behavior)
    GMOCK_FLAG("default_mock_behavior") = old_default_behavior

def InitGoogleMockTest_ParsesUnrecognizedFlag():
    var argv: Pointer[String, 3] = Pointer[String, 3](new_argv -> {"foo.exe", "--non_gmock_flag=blah", None})
    var new_argv: Pointer[String, 3] = Pointer[String, 3](new_argv -> {"foo.exe", "--non_gmock_flag=blah", None})
    TestInitGoogleMock[String, 3, 3](argv, new_argv, GMOCK_FLAG("verbose"))

def InitGoogleMockTest_ParsesGoogleMockFlagAndUnrecognizedFlag():
    var argv: Pointer[String, 4] = Pointer[String, 4](new_argv -> {"foo.exe", "--non_gmock_flag=blah",
                        "--gmock_verbose=error", None})
    var new_argv: Pointer[String, 3] = Pointer[String, 3](new_argv -> {"foo.exe", "--non_gmock_flag=blah", None})
    TestInitGoogleMock[String, 4, 3](argv, new_argv, "error")

def WideInitGoogleMockTest_ParsesInvalidCommandLine():
    var argv: Pointer[WideString, 1] = Pointer[WideString, 1](new_argv -> {None})
    var new_argv: Pointer[WideString, 1] = Pointer[WideString, 1](new_argv -> {None})
    TestInitGoogleMock[WideString, 1, 1](argv, new_argv, GMOCK_FLAG("verbose"))

def WideInitGoogleMockTest_ParsesEmptyCommandLine():
    var argv: Pointer[WideString, 2] = Pointer[WideString, 2](new_argv -> {L"foo.exe", None})
    var new_argv: Pointer[WideString, 2] = Pointer[WideString, 2](new_argv -> {L"foo.exe", None})
    TestInitGoogleMock[WideString, 2, 2](argv, new_argv, GMOCK_FLAG("verbose"))

def WideInitGoogleMockTest_ParsesSingleFlag():
    var argv: Pointer[WideString, 3] = Pointer[WideString, 3](new_argv -> {L"foo.exe", L"--gmock_verbose=info", None})
    var new_argv: Pointer[WideString, 2] = Pointer[WideString, 2](new_argv -> {L"foo.exe", None})
    TestInitGoogleMock[WideString, 3, 2](argv, new_argv, "info")

def WideInitGoogleMockTest_ParsesMultipleFlags():
    var old_default_behavior = GMOCK_FLAG("default_mock_behavior")
    var argv: Pointer[WideString, 4] = Pointer[WideString, 4](new_argv -> {L"foo.exe", L"--gmock_verbose=info",
                           L"--gmock_default_mock_behavior=2", None})
    var new_argv: Pointer[WideString, 2] = Pointer[WideString, 2](new_argv -> {L"foo.exe", None})
    TestInitGoogleMock[WideString, 4, 2](argv, new_argv, "info")
    EXPECT_EQ(2, GMOCK_FLAG("default_mock_behavior"))
    EXPECT_NE(2, old_default_behavior)
    GMOCK_FLAG("default_mock_behavior") = old_default_behavior

def WideInitGoogleMockTest_ParsesUnrecognizedFlag():
    var argv: Pointer[WideString, 3] = Pointer[WideString, 3](new_argv -> {L"foo.exe", L"--non_gmock_flag=blah", None})
    var new_argv: Pointer[WideString, 3] = Pointer[WideString, 3](new_argv -> {L"foo.exe", L"--non_gmock_flag=blah", None})
    TestInitGoogleMock[WideString, 3, 3](argv, new_argv, GMOCK_FLAG("verbose"))

def WideInitGoogleMockTest_ParsesGoogleMockFlagAndUnrecognizedFlag():
    var argv: Pointer[WideString, 4] = Pointer[WideString, 4](new_argv -> {L"foo.exe", L"--non_gmock_flag=blah",
                           L"--gmock_verbose=error", None})
    var new_argv: Pointer[WideString, 3] = Pointer[WideString, 3](new_argv -> {L"foo.exe", L"--non_gmock_flag=blah", None})
    TestInitGoogleMock[WideString, 4, 3](argv, new_argv, "error")

// #endif  // !defined(GTEST_CUSTOM_INIT_GOOGLE_TEST_FUNCTION_)

def FlagTest_IsAccessibleInCode():
    var dummy = testing.GMOCK_FLAG("catch_leaked_mocks") and testing.GMOCK_FLAG("verbose") == ""
    var _ = dummy