# Mojo translation of gtest-filepath.cc
# Platform conditionals simulated with compile-time Bool constants

from gtest.internal.gtest-filepath import FilePath, String  # hypothetical
from gtest.internal.gtest-port import *
from gtest.gtest-message import *
from gtest.internal.gtest-string import *

# Platform constants (set for generic POSIX build)
const GTEST_OS_WINDOWS: Bool = False
const GTEST_OS_WINDOWS_MOBILE: Bool = False
const GTEST_OS_WINDOWS_PHONE: Bool = False
const GTEST_OS_WINDOWS_RT: Bool = False
const GTEST_OS_ESP8266: Bool = False
const GTEST_OS_ESP32: Bool = False
const GTEST_OS_XTENSA: Bool = False
const GTEST_OS_NACL: Bool = False
const GTEST_HAS_ALT_PATH_SEP: Bool = False

# Path separator constants
var kPathSeparator: UInt8
var kAlternatePathSeparator: UInt8
var kAlternatePathSeparatorString: String = ""
var kCurrentDirectoryString: String = ""

if GTEST_OS_WINDOWS:
    kPathSeparator = ord('\\')
    kAlternatePathSeparator = ord('/')
    kAlternatePathSeparatorString = "/"
    if GTEST_OS_WINDOWS_MOBILE:
        kCurrentDirectoryString = "\\"
        const kInvalidFileAttributes: UInt32 = 0xffffffff
    else:
        kCurrentDirectoryString = ".\\"
elif True:
    kPathSeparator = ord('/')
    kCurrentDirectoryString = "./"

# Define GTEST_PATH_MAX_ for non-Windows
if not GTEST_OS_WINDOWS:
    alias GTEST_PATH_MAX_ = 1024  # placeholder

# Static helper function
def IsPathSeparator(c: UInt8) -> Bool:
    if GTEST_HAS_ALT_PATH_SEP:
        return (c == kPathSeparator) or (c == kAlternatePathSeparator)
    else:
        return c == kPathSeparator

# FilePath methods
def FilePath.GetCurrentDir() -> FilePath:
    if GTEST_OS_WINDOWS_MOBILE or GTEST_OS_WINDOWS_PHONE or \
       GTEST_OS_WINDOWS_RT or GTEST_OS_ESP8266 or GTEST_OS_ESP32 or \
       GTEST_OS_XTENSA:
        return FilePath(kCurrentDirectoryString)
    elif GTEST_OS_WINDOWS:
        # Not implemented for Windows in this translation
        var cwd: String = ""
        return FilePath(cwd)
    else:
        # POSIX getcwd simulation
        var cwd: String = ""  # placeholder
        var result: String = ""  # dummy
        if GTEST_OS_NACL:
            return FilePath(kCurrentDirectoryString)
        return FilePath(result)

def FilePath.RemoveExtension(extension: String) -> FilePath:
    var dot_extension: String = "." + extension
    if String.EndsWithCaseInsensitive(self.pathname_, dot_extension):
        return FilePath(self.pathname_.substr(0, self.pathname_.length() - dot_extension.length()))
    return self

def FilePath.FindLastPathSeparator() -> String:
    # Use built-in rfind; Mojo string indexing is 0-based
    var last_sep: Int = self.c_str().rfind(kPathSeparator)
    if GTEST_HAS_ALT_PATH_SEP:
        var last_alt_sep: Int = self.c_str().rfind(kAlternatePathSeparator)
        if last_alt_sep != -1:
            if last_sep == -1 or last_alt_sep > last_sep:
                return String(self.c_str()[last_alt_sep:])
    if last_sep != -1:
        return String(self.c_str()[last_sep:])
    else:
        return ""

def FilePath.RemoveDirectoryName() -> FilePath:
    var last_sep: String = self.FindLastPathSeparator()
    if last_sep.length() > 0:
        return FilePath(last_sep[1:])
    else:
        return self

def FilePath.RemoveFileName() -> FilePath:
    var last_sep: String = self.FindLastPathSeparator()
    var dir: String
    if last_sep.length() > 0:
        dir = String(self.c_str()[0:last_sep.c_str().as_int() + 1])
    else:
        dir = kCurrentDirectoryString
    return FilePath(dir)

def FilePath.MakeFileName(directory: FilePath, base_name: FilePath, number: Int, extension: String) -> FilePath:
    var file: String
    if number == 0:
        file = base_name.string() + "." + extension
    else:
        file = base_name.string() + "_" + StreamableToString(number) + "." + extension
    return FilePath.ConcatPaths(directory, FilePath(file))

def FilePath.ConcatPaths(directory: FilePath, relative_path: FilePath) -> FilePath:
    if directory.IsEmpty():
        return relative_path
    var dir: FilePath = directory.RemoveTrailingPathSeparator()
    return FilePath(dir.string() + String(chr(kPathSeparator)) + relative_path.string())

def FilePath.FileOrDirectoryExists() -> Bool:
    if GTEST_OS_WINDOWS_MOBILE:
        # Placeholder
        return False
    else:
        var file_stat: posix.StatStruct = posix.StatStruct()
        return posix.Stat(self.pathname_.c_str(), file_stat) == 0

def FilePath.DirectoryExists() -> Bool:
    var result: Bool = False
    if GTEST_OS_WINDOWS:
        var path: FilePath = self
        if not self.IsRootDirectory():
            path = self.RemoveTrailingPathSeparator()
    else:
        var path: FilePath = self
    if GTEST_OS_WINDOWS_MOBILE:
        # Placeholder
        result = False
    else:
        var file_stat: posix.StatStruct = posix.StatStruct()
        result = (posix.Stat(path.c_str(), file_stat) == 0) and posix.IsDir(file_stat)
    return result

def FilePath.IsRootDirectory() -> Bool:
    if GTEST_OS_WINDOWS:
        return self.pathname_.length() == 3 and self.IsAbsolutePath()
    else:
        return self.pathname_.length() == 1 and IsPathSeparator(self.pathname_.c_str()[0])

def FilePath.IsAbsolutePath() -> Bool:
    var name: String = self.pathname_.c_str()
    if GTEST_OS_WINDOWS:
        return self.pathname_.length() >= 3 and \
               ((name[0] >= 'a' and name[0] <= 'z') or \
                (name[0] >= 'A' and name[0] <= 'Z')) and \
               name[1] == ':' and \
               IsPathSeparator(name[2])
    else:
        return IsPathSeparator(name[0])

def FilePath.GenerateUniqueFileName(directory: FilePath, base_name: FilePath, extension: String) -> FilePath:
    var full_pathname: FilePath
    var number: Int = 0
    while True:
        full_pathname.Set(FilePath.MakeFileName(directory, base_name, number, extension))
        number += 1
        if not full_pathname.FileOrDirectoryExists():
            break
    return full_pathname

def FilePath.IsDirectory() -> Bool:
    return (self.pathname_.length() > 0) and \
           IsPathSeparator(self.pathname_.c_str()[self.pathname_.length() - 1])

def FilePath.CreateDirectoriesRecursively() -> Bool:
    if not self.IsDirectory():
        return False
    if self.pathname_.length() == 0 or self.DirectoryExists():
        return True
    var parent: FilePath = self.RemoveTrailingPathSeparator().RemoveFileName()
    return parent.CreateDirectoriesRecursively() and self.CreateFolder()

def FilePath.CreateFolder() -> Bool:
    if GTEST_OS_WINDOWS_MOBILE:
        # Placeholder
        var result: Int = -1
        if result == -1:
            return self.DirectoryExists()
        return True
    elif GTEST_OS_WINDOWS:
        var result: Int = _mkdir(self.pathname_.c_str())
    elif GTEST_OS_ESP8266 or GTEST_OS_XTENSA:
        var result: Int = 0
    else:
        var result: Int = mkdir(self.pathname_.c_str(), 0o777)
    if result == -1:
        return self.DirectoryExists()
    return True

def FilePath.RemoveTrailingPathSeparator() -> FilePath:
    if self.IsDirectory():
        return FilePath(self.pathname_.substr(0, self.pathname_.length() - 1))
    else:
        return self

def FilePath.Normalize():
    var out: Int = 0
    for character in self.pathname_:
        if not IsPathSeparator(character):
            self.pathname_[out] = character
            out += 1
        elif out == 0 or self.pathname_[out - 1] != kPathSeparator:
            self.pathname_[out] = kPathSeparator
            out += 1
        else:
            continue
    self.pathname_.erase(out, self.pathname_.length())