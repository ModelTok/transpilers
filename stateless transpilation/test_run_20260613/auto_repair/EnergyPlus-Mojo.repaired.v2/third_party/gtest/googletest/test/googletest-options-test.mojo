from gtest import *
from gtest.internal import *

# Conditional imports based on OS (using if statements with GTEST_OS_* constants)
if GTEST_OS_WINDOWS_MOBILE:
    from windows import *
elif GTEST_OS_WINDOWS:
    from direct import *
elif GTEST_OS_OS2:
    from strings import *
endif  # GTEST_OS_WINDOWS_MOBILE

from gtest-internal-inl import *  

namespace testing:
    namespace internal:
        namespace:

            def GetAbsolutePathOf(relative_path: FilePath) -> FilePath:
                return FilePath.ConcatPaths(FilePath.GetCurrentDir(), relative_path)

            @TEST
            def XmlOutputTest_GetOutputFormatDefault():
                GTEST_FLAG.output = ""
                EXPECT_STREQ("", UnitTestOptions.GetOutputFormat().c_str())

            @TEST
            def XmlOutputTest_GetOutputFormat():
                GTEST_FLAG.output = "xml:filename"
                EXPECT_STREQ("xml", UnitTestOptions.GetOutputFormat().c_str())

            @TEST
            def XmlOutputTest_GetOutputFileDefault():
                GTEST_FLAG.output = ""
                EXPECT_EQ(GetAbsolutePathOf(FilePath("test_detail.xml")).string(),
                    UnitTestOptions.GetAbsolutePathToOutputFile())

            @TEST
            def XmlOutputTest_GetOutputFileSingleFile():
                GTEST_FLAG.output = "xml:filename.abc"
                EXPECT_EQ(GetAbsolutePathOf(FilePath("filename.abc")).string(),
                    UnitTestOptions.GetAbsolutePathToOutputFile())

            @TEST
            def XmlOutputTest_GetOutputFileFromDirectoryPath():
                GTEST_FLAG.output = "xml:path" + GTEST_PATH_SEP_
                var expected_output_file: std.string = \
                    GetAbsolutePathOf(
                        FilePath(std.string("path") + GTEST_PATH_SEP_ +
                                 GetCurrentExecutableName().string() + ".xml")).string()
                var output_file: std.string = \
                    UnitTestOptions.GetAbsolutePathToOutputFile()
                if GTEST_OS_WINDOWS:
                    EXPECT_STRCASEEQ(expected_output_file.c_str(), output_file.c_str())
                else:
                    EXPECT_EQ(expected_output_file, output_file.c_str())
                endif

            @TEST
            def OutputFileHelpersTest_GetCurrentExecutableName():
                var exe_str: std.string = GetCurrentExecutableName().string()
                if GTEST_OS_WINDOWS:
                    var success: bool = \
                        _strcmpi("googletest-options-test", exe_str.c_str()) == 0 or \
                        _strcmpi("gtest-options-ex_test", exe_str.c_str()) == 0 or \
                        _strcmpi("gtest_all_test", exe_str.c_str()) == 0 or \
                        _strcmpi("gtest_dll_test", exe_str.c_str()) == 0
                elif GTEST_OS_OS2:
                    var success: bool = \
                        strcasecmp("googletest-options-test", exe_str.c_str()) == 0 or \
                        strcasecmp("gtest-options-ex_test", exe_str.c_str()) == 0 or \
                        strcasecmp("gtest_all_test", exe_str.c_str()) == 0 or \
                        strcasecmp("gtest_dll_test", exe_str.c_str()) == 0
                elif GTEST_OS_FUCHSIA:
                    var success: bool = exe_str == "app"
                else:
                    var success: bool = \
                        exe_str == "googletest-options-test" or \
                        exe_str == "gtest_all_test" or \
                        exe_str == "lt-gtest_all_test" or \
                        exe_str == "gtest_dll_test"
                endif  # GTEST_OS_WINDOWS
                if not success:
                    FAIL() << "GetCurrentExecutableName() returns " << exe_str
                endif

            if not GTEST_OS_FUCHSIA:
                class XmlOutputChangeDirTest(Test):
                    var original_working_dir_: FilePath

                    def SetUp(self) override:
                        original_working_dir_ = FilePath.GetCurrentDir()
                        posix.ChDir("..")
                        EXPECT_NE(original_working_dir_.string(),
                                  FilePath.GetCurrentDir().string())

                    def TearDown(self) override:
                        posix.ChDir(original_working_dir_.string().c_str())

                @TEST_F(XmlOutputChangeDirTest)
                def PreserveOriginalWorkingDirWithDefault(self):
                    GTEST_FLAG.output = ""
                    EXPECT_EQ(FilePath.ConcatPaths(original_working_dir_,
                                                    FilePath("test_detail.xml")).string(),
                              UnitTestOptions.GetAbsolutePathToOutputFile())

                @TEST_F(XmlOutputChangeDirTest)
                def PreserveOriginalWorkingDirWithDefaultXML(self):
                    GTEST_FLAG.output = "xml"
                    EXPECT_EQ(FilePath.ConcatPaths(original_working_dir_,
                                                    FilePath("test_detail.xml")).string(),
                              UnitTestOptions.GetAbsolutePathToOutputFile())

                @TEST_F(XmlOutputChangeDirTest)
                def PreserveOriginalWorkingDirWithRelativeFile(self):
                    GTEST_FLAG.output = "xml:filename.abc"
                    EXPECT_EQ(FilePath.ConcatPaths(original_working_dir_,
                                                    FilePath("filename.abc")).string(),
                              UnitTestOptions.GetAbsolutePathToOutputFile())

                @TEST_F(XmlOutputChangeDirTest)
                def PreserveOriginalWorkingDirWithRelativePath(self):
                    GTEST_FLAG.output = "xml:path" + GTEST_PATH_SEP_
                    var expected_output_file: std.string = \
                        FilePath.ConcatPaths(
                            original_working_dir_,
                            FilePath(std.string("path") + GTEST_PATH_SEP_ +
                                     GetCurrentExecutableName().string() + ".xml")).string()
                    var output_file: std.string = \
                        UnitTestOptions.GetAbsolutePathToOutputFile()
                    if GTEST_OS_WINDOWS:
                        EXPECT_STRCASEEQ(expected_output_file.c_str(), output_file.c_str())
                    else:
                        EXPECT_EQ(expected_output_file, output_file.c_str())
                    endif

                @TEST_F(XmlOutputChangeDirTest)
                def PreserveOriginalWorkingDirWithAbsoluteFile(self):
                    if GTEST_OS_WINDOWS:
                        GTEST_FLAG.output = "xml:c:\\tmp\\filename.abc"
                        EXPECT_EQ(FilePath("c:\\tmp\\filename.abc").string(),
                                  UnitTestOptions.GetAbsolutePathToOutputFile())
                    else:
                        GTEST_FLAG.output = "xml:/tmp/filename.abc"
                        EXPECT_EQ(FilePath("/tmp/filename.abc").string(),
                                  UnitTestOptions.GetAbsolutePathToOutputFile())
                    endif

                @TEST_F(XmlOutputChangeDirTest)
                def PreserveOriginalWorkingDirWithAbsolutePath(self):
                    if GTEST_OS_WINDOWS:
                        var path: std.string = "c:\\tmp\\"
                    else:
                        var path: std.string = "/tmp/"
                    endif
                    GTEST_FLAG.output = "xml:" + path
                    var expected_output_file: std.string = \
                        path + GetCurrentExecutableName().string() + ".xml"
                    var output_file: std.string = \
                        UnitTestOptions.GetAbsolutePathToOutputFile()
                    if GTEST_OS_WINDOWS:
                        EXPECT_STRCASEEQ(expected_output_file.c_str(), output_file.c_str())
                    else:
                        EXPECT_EQ(expected_output_file, output_file.c_str())
                    endif
            endif  # !GTEST_OS_FUCHSIA

        endnamespace
    endnamespace
endnamespace