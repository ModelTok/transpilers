from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.DataStringGlobals import MatchVersion, pathChar
from EnergyPlus.FileSystem import (
    FileSystem,
    getFileType,
    is_flat_file_type,
    is_all_json_type,
    getFileExtension,
    removeFileExtension,
    getParentDirectoryPath,
    getProgramPath,
    pathExists,
    directoryExists,
    fileExists,
    makeDirectory,
    removeFile,
    moveFile,
    getAbsolutePath,
    getFileName,
    exeExtension,
)
import os
import pathlib

def main():

@unittest
def movefile_test():
    var filename: String = "FileSystemTest.idf"
    var line: String
    var buffer: StringRef = StringRef()
    var ofs = open(filename, "w")
    ofs.write("Version," + MatchVersion + ";\n")
    ofs.close()
    var ifs = open(filename, "r")
    buffer = ifs.read()
    assert_equal(buffer, "Version," + MatchVersion + ";\n")
    ifs.close()
    var filename_temp: String = "FileSystemTest_temp.idf"
    var ofs_temp = open(filename_temp, "w")
    ofs_temp.write("Version," + MatchVersion + ";\n")
    ofs_temp.close()
    FileSystem.moveFile(filename_temp, filename)
    var buffer_new: StringRef = StringRef()
    var ifs_new = open(filename, "r")
    buffer_new = ifs_new.read()
    assert_equal(buffer_new, "Version," + MatchVersion + ";\n")
    ifs_new.close()
    FileSystem.removeFile(filename)
    FileSystem.removeFile(filename_temp)

@unittest
def getAbsolutePath():
    var pathName: String = "FileSystemTest.idf"
    var absPathName: String = FileSystem.getAbsolutePath(pathName)
    assert_true(absPathName.find(pathName) != -1)
    var currentDirWithSep: String = "." + pathChar
    pathName = currentDirWithSep + "FileSystemTest.idf"
    absPathName = FileSystem.getAbsolutePath(pathName)
    assert_false(absPathName.find(currentDirWithSep) != -1)

@unittest
def FileSystemGetFileType():
    var filePath0: pathlib.Path = pathlib.Path("/eplus/myfile.idf")
    var ext = FileSystem.getFileType(filePath0)
    assert_equal(ext, FileSystem.FileTypes.IDF)
    var filePath1: pathlib.Path = pathlib.Path("./schedulefileA.CSV")
    ext = FileSystem.getFileType(filePath1)
    assert_true(FileSystem.FileTypes.CSV == ext)
    assert_true(FileSystem.is_flat_file_type(ext))
    var filePath2: pathlib.Path = pathlib.Path("./schedulefileB.Csv")
    ext = FileSystem.getFileType(filePath2)
    assert_true(FileSystem.FileTypes.CSV == ext)
    assert_true(FileSystem.is_flat_file_type(ext))
    var filePath3: pathlib.Path = pathlib.Path("./schedulefileC.csv")
    ext = FileSystem.getFileType(filePath3)
    assert_true(FileSystem.FileTypes.CSV == ext)
    assert_true(FileSystem.is_flat_file_type(ext))
    var filePath4: pathlib.Path = pathlib.Path("./jsonfileA.JSON")
    ext = FileSystem.getFileType(filePath4)
    assert_true(FileSystem.FileTypes.JSON == ext)
    assert_true(FileSystem.is_all_json_type(ext))
    var filePath5: pathlib.Path = pathlib.Path("./jsonfileB.Json")
    ext = FileSystem.getFileType(filePath5)
    assert_true(FileSystem.FileTypes.JSON == ext)
    assert_true(FileSystem.is_all_json_type(ext))
    var filePath6: pathlib.Path = pathlib.Path("./jsonfileC.json")
    ext = FileSystem.getFileType(filePath6)
    assert_true(FileSystem.FileTypes.JSON == ext)
    assert_true(FileSystem.is_all_json_type(ext))
    var filePath7: pathlib.Path = pathlib.Path("./epjsonfileA.epJSON")
    ext = FileSystem.getFileType(filePath7)
    assert_true(FileSystem.FileTypes.EpJSON == ext)
    assert_true(FileSystem.is_all_json_type(ext))
    var filePath8: pathlib.Path = pathlib.Path("./epjsonfileB.EPJSON")
    ext = FileSystem.getFileType(filePath8)
    assert_true(FileSystem.FileTypes.EpJSON == ext)
    assert_true(FileSystem.is_all_json_type(ext))
    var filePath9: pathlib.Path = pathlib.Path("./epjsonfileC.epjson")
    ext = FileSystem.getFileType(filePath9)
    assert_true(FileSystem.FileTypes.EpJSON == ext)
    assert_true(FileSystem.is_all_json_type(ext))

@unittest
def Others():
    {
        var pathName: String = "folder/FileSystemTest.txt.idf"
        assert_equal("idf", FileSystem.getFileExtension(pathName))
        assert_equal("folder/FileSystemTest.txt", FileSystem.removeFileExtension(pathName))
        assert_equal(pathlib.Path("folder"), FileSystem.getParentDirectoryPath(pathName))
    }
    {
        var pathName: String = "folder/FileSystemTest.txt"
        assert_equal("txt", FileSystem.getFileExtension(pathName))
        assert_equal("folder/FileSystemTest", FileSystem.removeFileExtension(pathName))
        assert_equal(pathlib.Path("folder"), FileSystem.getParentDirectoryPath(pathName))
    }
    {
        var pathName: String = "folder/FileSystemTest"
        assert_equal("", FileSystem.getFileExtension(pathName))
        assert_equal("folder/FileSystemTest", FileSystem.removeFileExtension(pathName))
        assert_equal(pathlib.Path("folder"), FileSystem.getParentDirectoryPath(pathName))
    }

@unittest
def getProgramPath():
    var programPath: pathlib.Path = FileSystem.getProgramPath()
    assert_true(FileSystem.pathExists(programPath))
    assert_true(programPath.string().find("energyplus_tests") != -1)
    var expectedPath: pathlib.Path = pathlib.Path("energyplus_tests")
    expectedPath = expectedPath.with_suffix(exeExtension)
    assert_equal(expectedPath, FileSystem.getFileName(programPath))
    assert_true(FileSystem.directoryExists(FileSystem.getParentDirectoryPath(programPath)))

@unittest
def getParentDirectoryPath():
    assert_equal(pathlib.Path("a/b"), FileSystem.getParentDirectoryPath("a/b/c"))
    assert_equal(pathlib.Path("a/b"), FileSystem.getParentDirectoryPath("a/b/c/"))
    assert_equal(pathlib.Path("./"), FileSystem.getParentDirectoryPath("a.idf"))

@unittest
def make_and_remove_Directory():
    os.remove_all("sandboxA")
    var dirPath: pathlib.Path = pathlib.Path("sandboxA/a")
    var rootPath: pathlib.Path = pathlib.Path("sandboxA")
    assert_equal(rootPath, FileSystem.getParentDirectoryPath(dirPath))
    assert_false(FileSystem.pathExists(rootPath))
    assert_false(FileSystem.fileExists(rootPath))
    assert_false(FileSystem.directoryExists(rootPath))
    assert_false(FileSystem.pathExists(dirPath))
    assert_false(FileSystem.fileExists(dirPath))
    assert_false(FileSystem.directoryExists(dirPath))
    FileSystem.makeDirectory(dirPath)
    assert_true(FileSystem.pathExists(rootPath))
    assert_false(FileSystem.fileExists(rootPath))
    assert_true(FileSystem.directoryExists(rootPath))
    assert_true(FileSystem.pathExists(dirPath))
    assert_false(FileSystem.fileExists(dirPath))
    assert_true(FileSystem.directoryExists(dirPath))
    var filePath: pathlib.Path = pathlib.Path("sandboxA/a/file.txt.idf")
    var ofs = open(filePath, "w")
    ofs.write("a")
    ofs.close()
    assert_true(FileSystem.pathExists(rootPath))
    assert_false(FileSystem.fileExists(rootPath))
    assert_true(FileSystem.directoryExists(rootPath))
    assert_true(FileSystem.pathExists(dirPath))
    assert_false(FileSystem.fileExists(dirPath))
    assert_true(FileSystem.directoryExists(dirPath))
    assert_true(FileSystem.pathExists(filePath))
    assert_true(FileSystem.fileExists(filePath))
    assert_false(FileSystem.directoryExists(filePath))
    os.remove_all("sandboxA")

@unittest
def Elaborate():
    FileSystem.makeDirectory("sandboxB")
    var pathName: String = "sandboxB/file1.txt.idf"
    var ofs = open(pathName, "w")
    ofs.write("a")
    ofs.close()
    assert_true(FileSystem.pathExists(pathName))
    assert_true(FileSystem.fileExists(pathName))
    assert_true(FileSystem.pathExists("sandboxB"))
    assert_true(FileSystem.directoryExists("sandboxB"))
    assert_true(FileSystem.directoryExists("sandboxB/"))
    assert_true(FileSystem.getAbsolutePath(pathName).size() > len(pathName))
    assert_true(
        pathlib.Path("sandboxB/") == FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(pathName))
    )
    assert_true(
        pathlib.Path("sandboxB") == FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(pathName))
    )
    assert_true(pathlib.Path("sandboxB") == FileSystem.getAbsolutePath("./sandboxB"))
    assert_true(pathlib.Path("sandboxB") == FileSystem.getAbsolutePath("./sandboxB/../sandboxB"))
    FileSystem.removeFile(pathName)
    assert_false(FileSystem.pathExists(pathName))
    assert_false(FileSystem.fileExists(pathName))
    os.remove_all("sandboxB")

# ifndef _WIN32
@unittest
def getAbsolutePath_WithSymlink():
    os.remove_all("sandboxSymlink")
    var productsDir: pathlib.Path = pathlib.Path("sandboxSymlink/Products")
    pathlib.Path(productsDir).mkdir(parents=True)
    var exeName: String = "energyplus-9.5.0"
    var exePath: pathlib.Path = productsDir / exeName
    var symlinkPath: pathlib.Path = productsDir / "energyplus"
    assert_false(FileSystem.fileExists(exePath))
    assert_false(FileSystem.fileExists(symlinkPath))
    var ofs = open(exePath, "w")
    ofs.write("a")
    ofs.close()
    assert_true(FileSystem.fileExists(exePath))
    assert_false(FileSystem.fileExists(symlinkPath))
    pathlib.Path(symlinkPath).symlink_to("energyplus-9.5.0")
    assert_true(FileSystem.fileExists(exePath))
    assert_true(FileSystem.fileExists(symlinkPath))
    assert_false(pathlib.Path(exePath).is_symlink())
    assert_true(pathlib.Path(symlinkPath).is_symlink())
    assert_equal(exeName, pathlib.Path(symlinkPath).readlink())
    assert_equal(FileSystem.getAbsolutePath(exePath), FileSystem.getAbsolutePath(symlinkPath))
    os.remove_all("sandboxSymlink")
# endif