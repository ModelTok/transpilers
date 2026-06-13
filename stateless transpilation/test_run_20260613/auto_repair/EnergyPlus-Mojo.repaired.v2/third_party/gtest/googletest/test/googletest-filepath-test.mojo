from gtest.internal.gtest-filepath import FilePath
from gtest.gtest import *
from src.gtest-internal-inl import *
from memory import memset
from os import chdir, getcwd, remove, rmdir
from ctypes import c_char_p, c_int, c_void_p, POINTER, Structure, CFUNCTYPE, cdll
from sys import getattr as sys_getattr

# GTEST_OS_WINDOWS_MOBILE is not defined in Mojo, so we skip the Windows Mobile specific code
# and use the else branch directly.

def Test_GetCurrentDirTest_ReturnsCurrentDir():
    let original_dir = FilePath.GetCurrentDir()
    assert_false(original_dir.IsEmpty())
    posix.ChDir(GTEST_PATH_SEP_)
    let cwd = FilePath.GetCurrentDir()
    posix.ChDir(original_dir.c_str())
    # if GTEST_OS_WINDOWS or GTEST_OS_OS2
    #   const char* const cwd_without_drive = strchr(cwd.c_str(), ':');
    #   ASSERT_TRUE(cwd_without_drive != NULL);
    #   EXPECT_STREQ(GTEST_PATH_SEP_, cwd_without_drive + 1);
    # else
    assert_eq(GTEST_PATH_SEP_, cwd.string())
    # endif

def Test_IsEmptyTest_ReturnsTrueForEmptyPath():
    assert_true(FilePath("").IsEmpty())

def Test_IsEmptyTest_ReturnsFalseForNonEmptyPath():
    assert_false(FilePath("a").IsEmpty())
    assert_false(FilePath(".").IsEmpty())
    assert_false(FilePath("a/b").IsEmpty())
    assert_false(FilePath("a\\b\\").IsEmpty())

def Test_RemoveDirectoryNameTest_WhenEmptyName():
    assert_eq("", FilePath("").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_ButNoDirectory():
    assert_eq("afile", FilePath("afile").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_RootFileShouldGiveFileName():
    assert_eq("afile", FilePath(GTEST_PATH_SEP_ + "afile").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_WhereThereIsNoFileName():
    assert_eq("", FilePath("adir" + GTEST_PATH_SEP_).RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_ShouldGiveFileName():
    assert_eq("afile", FilePath("adir" + GTEST_PATH_SEP_ + "afile").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_ShouldAlsoGiveFileName():
    assert_eq("afile", FilePath("adir" + GTEST_PATH_SEP_ + "subdir" + GTEST_PATH_SEP_ + "afile").RemoveDirectoryName().string())

# if GTEST_HAS_ALT_PATH_SEP_
def Test_RemoveDirectoryNameTest_RootFileShouldGiveFileNameForAlternateSeparator():
    assert_eq("afile", FilePath("/afile").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_WhereThereIsNoFileNameForAlternateSeparator():
    assert_eq("", FilePath("adir/").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_ShouldGiveFileNameForAlternateSeparator():
    assert_eq("afile", FilePath("adir/afile").RemoveDirectoryName().string())

def Test_RemoveDirectoryNameTest_ShouldAlsoGiveFileNameForAlternateSeparator():
    assert_eq("afile", FilePath("adir/subdir/afile").RemoveDirectoryName().string())
# endif

def Test_RemoveFileNameTest_EmptyName():
    # if GTEST_OS_WINDOWS_MOBILE
    #   assert_eq(GTEST_PATH_SEP_, FilePath("").RemoveFileName().string())
    # else
    assert_eq("." + GTEST_PATH_SEP_, FilePath("").RemoveFileName().string())
    # endif

def Test_RemoveFileNameTest_ButNoFile():
    assert_eq("adir" + GTEST_PATH_SEP_, FilePath("adir" + GTEST_PATH_SEP_).RemoveFileName().string())

def Test_RemoveFileNameTest_GivesDirName():
    assert_eq("adir" + GTEST_PATH_SEP_, FilePath("adir" + GTEST_PATH_SEP_ + "afile").RemoveFileName().string())

def Test_RemoveFileNameTest_GivesDirAndSubDirName():
    assert_eq("adir" + GTEST_PATH_SEP_ + "subdir" + GTEST_PATH_SEP_, FilePath("adir" + GTEST_PATH_SEP_ + "subdir" + GTEST_PATH_SEP_ + "afile").RemoveFileName().string())

def Test_RemoveFileNameTest_GivesRootDir():
    assert_eq(GTEST_PATH_SEP_, FilePath(GTEST_PATH_SEP_ + "afile").RemoveFileName().string())

# if GTEST_HAS_ALT_PATH_SEP_
def Test_RemoveFileNameTest_ButNoFileForAlternateSeparator():
    assert_eq("adir" + GTEST_PATH_SEP_, FilePath("adir/").RemoveFileName().string())

def Test_RemoveFileNameTest_GivesDirNameForAlternateSeparator():
    assert_eq("adir" + GTEST_PATH_SEP_, FilePath("adir/afile").RemoveFileName().string())

def Test_RemoveFileNameTest_GivesDirAndSubDirNameForAlternateSeparator():
    assert_eq("adir" + GTEST_PATH_SEP_ + "subdir" + GTEST_PATH_SEP_, FilePath("adir/subdir/afile").RemoveFileName().string())

def Test_RemoveFileNameTest_GivesRootDirForAlternateSeparator():
    assert_eq(GTEST_PATH_SEP_, FilePath("/afile").RemoveFileName().string())
# endif

def Test_MakeFileNameTest_GenerateWhenNumberIsZero():
    let actual = FilePath.MakeFileName(FilePath("foo"), FilePath("bar"), 0, "xml")
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar.xml", actual.string())

def Test_MakeFileNameTest_GenerateFileNameNumberGtZero():
    let actual = FilePath.MakeFileName(FilePath("foo"), FilePath("bar"), 12, "xml")
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar_12.xml", actual.string())

def Test_MakeFileNameTest_GenerateFileNameWithSlashNumberIsZero():
    let actual = FilePath.MakeFileName(FilePath("foo" + GTEST_PATH_SEP_), FilePath("bar"), 0, "xml")
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar.xml", actual.string())

def Test_MakeFileNameTest_GenerateFileNameWithSlashNumberGtZero():
    let actual = FilePath.MakeFileName(FilePath("foo" + GTEST_PATH_SEP_), FilePath("bar"), 12, "xml")
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar_12.xml", actual.string())

def Test_MakeFileNameTest_GenerateWhenNumberIsZeroAndDirIsEmpty():
    let actual = FilePath.MakeFileName(FilePath(""), FilePath("bar"), 0, "xml")
    assert_eq("bar.xml", actual.string())

def Test_MakeFileNameTest_GenerateWhenNumberIsNotZeroAndDirIsEmpty():
    let actual = FilePath.MakeFileName(FilePath(""), FilePath("bar"), 14, "xml")
    assert_eq("bar_14.xml", actual.string())

def Test_ConcatPathsTest_WorksWhenDirDoesNotEndWithPathSep():
    let actual = FilePath.ConcatPaths(FilePath("foo"), FilePath("bar.xml"))
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar.xml", actual.string())

def Test_ConcatPathsTest_WorksWhenPath1EndsWithPathSep():
    let actual = FilePath.ConcatPaths(FilePath("foo" + GTEST_PATH_SEP_), FilePath("bar.xml"))
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar.xml", actual.string())

def Test_ConcatPathsTest_Path1BeingEmpty():
    let actual = FilePath.ConcatPaths(FilePath(""), FilePath("bar.xml"))
    assert_eq("bar.xml", actual.string())

def Test_ConcatPathsTest_Path2BeingEmpty():
    let actual = FilePath.ConcatPaths(FilePath("foo"), FilePath(""))
    assert_eq("foo" + GTEST_PATH_SEP_, actual.string())

def Test_ConcatPathsTest_BothPathBeingEmpty():
    let actual = FilePath.ConcatPaths(FilePath(""), FilePath(""))
    assert_eq("", actual.string())

def Test_ConcatPathsTest_Path1ContainsPathSep():
    let actual = FilePath.ConcatPaths(FilePath("foo" + GTEST_PATH_SEP_ + "bar"), FilePath("foobar.xml"))
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar" + GTEST_PATH_SEP_ + "foobar.xml", actual.string())

def Test_ConcatPathsTest_Path2ContainsPathSep():
    let actual = FilePath.ConcatPaths(FilePath("foo" + GTEST_PATH_SEP_), FilePath("bar" + GTEST_PATH_SEP_ + "bar.xml"))
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar" + GTEST_PATH_SEP_ + "bar.xml", actual.string())

def Test_ConcatPathsTest_Path2EndsWithPathSep():
    let actual = FilePath.ConcatPaths(FilePath("foo"), FilePath("bar" + GTEST_PATH_SEP_))
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar" + GTEST_PATH_SEP_, actual.string())

def Test_RemoveTrailingPathSeparatorTest_EmptyString():
    assert_eq("", FilePath("").RemoveTrailingPathSeparator().string())

def Test_RemoveTrailingPathSeparatorTest_FileNoSlashString():
    assert_eq("foo", FilePath("foo").RemoveTrailingPathSeparator().string())

def Test_RemoveTrailingPathSeparatorTest_ShouldRemoveTrailingSeparator():
    assert_eq("foo", FilePath("foo" + GTEST_PATH_SEP_).RemoveTrailingPathSeparator().string())
    # if GTEST_HAS_ALT_PATH_SEP_
    assert_eq("foo", FilePath("foo/").RemoveTrailingPathSeparator().string())
    # endif

def Test_RemoveTrailingPathSeparatorTest_ShouldRemoveLastSeparator():
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar", FilePath("foo" + GTEST_PATH_SEP_ + "bar" + GTEST_PATH_SEP_).RemoveTrailingPathSeparator().string())

def Test_RemoveTrailingPathSeparatorTest_ShouldReturnUnmodified():
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar", FilePath("foo" + GTEST_PATH_SEP_ + "bar").RemoveTrailingPathSeparator().string())

def Test_DirectoryTest_RootDirectoryExists():
    # if GTEST_OS_WINDOWS
    #   char current_drive[_MAX_PATH];
    #   current_drive[0] = static_cast<char>(_getdrive() + 'A' - 1);
    #   current_drive[1] = ':';
    #   current_drive[2] = '\\';
    #   current_drive[3] = '\0';
    #   EXPECT_TRUE(FilePath(current_drive).DirectoryExists());
    # else
    assert_true(FilePath("/").DirectoryExists())
    # endif

# if GTEST_OS_WINDOWS
def Test_DirectoryTest_RootOfWrongDriveDoesNotExists():
    let saved_drive_ = _getdrive()
    var drive = 'Z'
    while drive >= 'A':
        if _chdrive(drive - 'A' + 1) == -1:
            var non_drive = String("   ")
            non_drive[0] = drive
            non_drive[1] = ':'
            non_drive[2] = '\\'
            assert_false(FilePath(non_drive).DirectoryExists())
            break
        drive -= 1
    _chdrive(saved_drive_)
# endif

# if !GTEST_OS_WINDOWS_MOBILE
def Test_DirectoryTest_EmptyPathDirectoryDoesNotExist():
    assert_false(FilePath("").DirectoryExists())
# endif

def Test_DirectoryTest_CurrentDirectoryExists():
    # if GTEST_OS_WINDOWS
    #   ifndef _WIN32_CE
    #     EXPECT_TRUE(FilePath(".").DirectoryExists());
    #     EXPECT_TRUE(FilePath(".\\").DirectoryExists());
    #   endif
    # else
    assert_true(FilePath(".").DirectoryExists())
    assert_true(FilePath("./").DirectoryExists())
    # endif

def Test_NormalizeTest_MultipleConsecutiveSepaparatorsInMidstring():
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar", FilePath("foo" + GTEST_PATH_SEP_ + "bar").string())
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar", FilePath("foo" + GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + "bar").string())
    assert_eq("foo" + GTEST_PATH_SEP_ + "bar", FilePath("foo" + GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + "bar").string())

def Test_NormalizeTest_MultipleConsecutiveSepaparatorsAtStringStart():
    assert_eq(GTEST_PATH_SEP_ + "bar", FilePath(GTEST_PATH_SEP_ + "bar").string())
    assert_eq(GTEST_PATH_SEP_ + "bar", FilePath(GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + "bar").string())
    assert_eq(GTEST_PATH_SEP_ + "bar", FilePath(GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + "bar").string())

def Test_NormalizeTest_MultipleConsecutiveSepaparatorsAtStringEnd():
    assert_eq("foo" + GTEST_PATH_SEP_, FilePath("foo" + GTEST_PATH_SEP_).string())
    assert_eq("foo" + GTEST_PATH_SEP_, FilePath("foo" + GTEST_PATH_SEP_ + GTEST_PATH_SEP_).string())
    assert_eq("foo" + GTEST_PATH_SEP_, FilePath("foo" + GTEST_PATH_SEP_ + GTEST_PATH_SEP_ + GTEST_PATH_SEP_).string())

# if GTEST_HAS_ALT_PATH_SEP_
def Test_NormalizeTest_MixAlternateSeparatorAtStringEnd():
    assert_eq("foo" + GTEST_PATH_SEP_, FilePath("foo/").string())
    assert_eq("foo" + GTEST_PATH_SEP_, FilePath("foo" + GTEST_PATH_SEP_ + "/").string())
    assert_eq("foo" + GTEST_PATH_SEP_, FilePath("foo//" + GTEST_PATH_SEP_).string())
# endif

def Test_AssignmentOperatorTest_DefaultAssignedToNonDefault():
    let default_path = FilePath()
    let non_default_path = FilePath("path")
    non_default_path = default_path
    assert_eq("", non_default_path.string())
    assert_eq("", default_path.string())

def Test_AssignmentOperatorTest_NonDefaultAssignedToDefault():
    let non_default_path = FilePath("path")
    let default_path = FilePath()
    default_path = non_default_path
    assert_eq("path", default_path.string())
    assert_eq("path", non_default_path.string())

def Test_AssignmentOperatorTest_ConstAssignedToNonConst():
    let const_default_path = FilePath("const_path")
    let non_default_path = FilePath("path")
    non_default_path = const_default_path
    assert_eq("const_path", non_default_path.string())

struct DirectoryCreationTest(Test):
    var testdata_path_: FilePath
    var testdata_file_: FilePath
    var unique_file0_: FilePath
    var unique_file1_: FilePath

    def __init__(inout self):
        self.testdata_path_ = FilePath()
        self.testdata_file_ = FilePath()
        self.unique_file0_ = FilePath()
        self.unique_file1_ = FilePath()

    def SetUp(inout self):
        self.testdata_path_.Set(FilePath(TempDir() + GetCurrentExecutableName().string() + "_directory_creation" + GTEST_PATH_SEP_ + "test" + GTEST_PATH_SEP_))
        self.testdata_file_.Set(self.testdata_path_.RemoveTrailingPathSeparator())
        self.unique_file0_.Set(FilePath.MakeFileName(self.testdata_path_, FilePath("unique"), 0, "txt"))
        self.unique_file1_.Set(FilePath.MakeFileName(self.testdata_path_, FilePath("unique"), 1, "txt"))
        remove(self.testdata_file_.c_str())
        remove(self.unique_file0_.c_str())
        remove(self.unique_file1_.c_str())
        posix.RmDir(self.testdata_path_.c_str())

    def TearDown(inout self):
        remove(self.testdata_file_.c_str())
        remove(self.unique_file0_.c_str())
        remove(self.unique_file1_.c_str())
        posix.RmDir(self.testdata_path_.c_str())

    def CreateTextFile(inout self, filename: String):
        let f = posix.FOpen(filename, "w")
        fprintf(f, "text\n")
        fclose(f)

def Test_DirectoryCreationTest_CreateDirectoriesRecursively():
    var test = DirectoryCreationTest()
    test.SetUp()
    assert_false(test.testdata_path_.DirectoryExists())  # << test.testdata_path_.string()
    assert_true(test.testdata_path_.CreateDirectoriesRecursively())
    assert_true(test.testdata_path_.DirectoryExists())
    test.TearDown()

def Test_DirectoryCreationTest_CreateDirectoriesForAlreadyExistingPath():
    var test = DirectoryCreationTest()
    test.SetUp()
    assert_false(test.testdata_path_.DirectoryExists())  # << test.testdata_path_.string()
    assert_true(test.testdata_path_.CreateDirectoriesRecursively())
    assert_true(test.testdata_path_.CreateDirectoriesRecursively())
    test.TearDown()

def Test_DirectoryCreationTest_CreateDirectoriesAndUniqueFilename():
    var test = DirectoryCreationTest()
    test.SetUp()
    let file_path = FilePath(FilePath.GenerateUniqueFileName(test.testdata_path_, FilePath("unique"), "txt"))
    assert_eq(test.unique_file0_.string(), file_path.string())
    assert_false(file_path.FileOrDirectoryExists())
    test.testdata_path_.CreateDirectoriesRecursively()
    assert_false(file_path.FileOrDirectoryExists())
    test.CreateTextFile(file_path.c_str())
    assert_true(file_path.FileOrDirectoryExists())
    let file_path2 = FilePath(FilePath.GenerateUniqueFileName(test.testdata_path_, FilePath("unique"), "txt"))
    assert_eq(test.unique_file1_.string(), file_path2.string())
    assert_false(file_path2.FileOrDirectoryExists())
    test.CreateTextFile(file_path2.c_str())
    assert_true(file_path2.FileOrDirectoryExists())
    test.TearDown()

def Test_DirectoryCreationTest_CreateDirectoriesFail():
    var test = DirectoryCreationTest()
    test.SetUp()
    test.CreateTextFile(test.testdata_file_.c_str())
    assert_true(test.testdata_file_.FileOrDirectoryExists())
    assert_false(test.testdata_file_.DirectoryExists())
    assert_false(test.testdata_file_.CreateDirectoriesRecursively())
    test.TearDown()

def Test_NoDirectoryCreationTest_CreateNoDirectoriesForDefaultXmlFile():
    let test_detail_xml = FilePath("test_detail.xml")
    assert_false(test_detail_xml.CreateDirectoriesRecursively())

def Test_FilePathTest_DefaultConstructor():
    let fp = FilePath()
    assert_eq("", fp.string())

def Test_FilePathTest_CharAndCopyConstructors():
    let fp = FilePath("spicy")
    assert_eq("spicy", fp.string())
    let fp_copy = FilePath(fp)
    assert_eq("spicy", fp_copy.string())

def Test_FilePathTest_StringConstructor():
    let fp = FilePath(String("cider"))
    assert_eq("cider", fp.string())

def Test_FilePathTest_Set():
    let apple = FilePath("apple")
    var mac = FilePath("mac")
    mac.Set(apple)
    assert_eq("apple", mac.string())
    assert_eq("apple", apple.string())

def Test_FilePathTest_ToString():
    let file = FilePath("drink")
    assert_eq("drink", file.string())

def Test_FilePathTest_RemoveExtension():
    assert_eq("app", FilePath("app.cc").RemoveExtension("cc").string())
    assert_eq("app", FilePath("app.exe").RemoveExtension("exe").string())
    assert_eq("APP", FilePath("APP.EXE").RemoveExtension("exe").string())

def Test_FilePathTest_RemoveExtensionWhenThereIsNoExtension():
    assert_eq("app", FilePath("app").RemoveExtension("exe").string())

def Test_FilePathTest_IsDirectory():
    assert_false(FilePath("cola").IsDirectory())
    assert_true(FilePath("koala" + GTEST_PATH_SEP_).IsDirectory())
    # if GTEST_HAS_ALT_PATH_SEP_
    assert_true(FilePath("koala/").IsDirectory())
    # endif

def Test_FilePathTest_IsAbsolutePath():
    assert_false(FilePath("is" + GTEST_PATH_SEP_ + "relative").IsAbsolutePath())
    assert_false(FilePath("").IsAbsolutePath())
    # if GTEST_OS_WINDOWS
    #   assert_true(FilePath("c:\\" + GTEST_PATH_SEP_ + "is_not" + GTEST_PATH_SEP_ + "relative").IsAbsolutePath())
    #   assert_false(FilePath("c:foo" + GTEST_PATH_SEP_ + "bar").IsAbsolutePath())
    #   assert_true(FilePath("c:/" + GTEST_PATH_SEP_ + "is_not" + GTEST_PATH_SEP_ + "relative").IsAbsolutePath())
    # else
    assert_true(FilePath(GTEST_PATH_SEP_ + "is_not" + GTEST_PATH_SEP_ + "relative").IsAbsolutePath())
    # endif

def Test_FilePathTest_IsRootDirectory():
    # if GTEST_OS_WINDOWS
    #   assert_true(FilePath("a:\\").IsRootDirectory())
    #   assert_true(FilePath("Z:/").IsRootDirectory())
    #   assert_true(FilePath("e://").IsRootDirectory())
    #   assert_false(FilePath("").IsRootDirectory())
    #   assert_false(FilePath("b:").IsRootDirectory())
    #   assert_false(FilePath("b:a").IsRootDirectory())
    #   assert_false(FilePath("8:/").IsRootDirectory())
    #   assert_false(FilePath("c|/").IsRootDirectory())
    # else
    assert_true(FilePath("/").IsRootDirectory())
    assert_true(FilePath("//").IsRootDirectory())
    assert_false(FilePath("").IsRootDirectory())
    assert_false(FilePath("\\").IsRootDirectory())
    assert_false(FilePath("/x").IsRootDirectory())
    # endif