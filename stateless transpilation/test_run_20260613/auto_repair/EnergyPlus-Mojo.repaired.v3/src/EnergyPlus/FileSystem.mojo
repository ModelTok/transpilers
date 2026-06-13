from DataStringGlobals import DataStringGlobals
from UtilityRoutines import Util
from  import FatalError
from memory import memset_zero
from os import environ, system as os_system
from pathlib import Path
from sys import exit as sys_exit
from time import sleep
import json
import cbor
import msgpack
import ubjson
import bson

# Constants
exeExtension: String = ".exe" if environ.get("OS", "") == "Windows_NT" else ""

# FileTypes enum
@value
struct FileTypes:
    Invalid: Int = -1
    EpJSON: Int = 0
    JSON: Int = 1
    GLHE: Int = 2
    last_json_type: Int = 2
    CBOR: Int = 3
    MsgPack: Int = 4
    UBJSON: Int = 5
    BSON: Int = 6
    last_binary_json_type: Int = 6
    IDF: Int = 7
    IMF: Int = 8
    CSV: Int = 9
    TSV: Int = 10
    TXT: Int = 11
    ESO: Int = 12
    MTR: Int = 13
    last_flat_file_type: Int = 13
    DDY: Int = 14
    Num: Int = 15

# FileTypesExt arrays
var FileTypesExt: StaticArray[String, 15] = StaticArray[String, 15](
    "epJSON", "json", "glhe", "cbor", "msgpack", "ubjson", "bson", "idf", "imf", "csv", "tsv", "txt", "eso", "mtr", "ddy"
)

var FileTypesExtUC: StaticArray[String, 15] = StaticArray[String, 15](
    "EPJSON", "JSON", "GLHE", "CBOR", "MSGPACK", "UBJSON", "BSON", "IDF", "IMF", "CSV", "TSV", "TXT", "ESO", "MTR", "DDY"
)

# Helper functions
def is_all_json_type(t: Int) -> Bool:
    return t > FileTypes.Invalid and t <= FileTypes.last_binary_json_type

def is_json_type(t: Int) -> Bool:
    return t > FileTypes.Invalid and t <= FileTypes.last_json_type

def is_binary_json_type(t: Int) -> Bool:
    return t > FileTypes.last_json_type and t <= FileTypes.last_binary_json_type

def is_idf_type(t: Int) -> Bool:
    return t == FileTypes.IDF or t == FileTypes.IMF

def is_flat_file_type(t: Int) -> Bool:
    return t > FileTypes.last_binary_json_type and t <= FileTypes.last_flat_file_type

def makeNativePath(path: Path) -> Path:
    var result: Path = path
    # On non-Windows, replace altpathChar with pathChar
    var tempPathAsStr: String = result.make_preferred().string()
    tempPathAsStr = tempPathAsStr.replace(DataStringGlobals.altpathChar, DataStringGlobals.pathChar)
    result = Path(tempPathAsStr)
    return result

def getFileName(filePath: Path) -> Path:
    return filePath.filename()

def getParentDirectoryPath(path: Path) -> Path:
    var pathStr: String = path.string()
    if not pathStr.empty():
        while (pathStr.back() == DataStringGlobals.pathChar) or (pathStr.back() == DataStringGlobals.altpathChar):
            pathStr = pathStr.erase(pathStr.size() - 1)
    var parent_path: Path = Path(pathStr).parent_path()
    if parent_path.empty():
        parent_path = Path("./")
    return parent_path

def getAbsolutePath(path: Path) -> Path:
    var p: Path = path.absolute()
    while p.is_symlink():
        var linkpath: Path = p.read_symlink()
        if linkpath.is_absolute():
            p = linkpath
        else:
            p = p.parent_path() / linkpath
    var result: Path = Path()
    for it in p:
        if it == Path(".."):
            if result.is_symlink() or (result.filename() == Path("..")):
                result = result / it
            else:
                result = result.parent_path()
        elif it != Path("."):
            result = result / it
    return result

def getProgramPath() -> Path:
    # Simplified: use /proc/self/exe on Linux, fallback to environment
    var executableRelativePath: String = ""
    # On Linux, read /proc/self/exe
    try:
        executableRelativePath = Path("/proc/self/exe").readlink()
    except:
        # Fallback: use argv[0] or environment
        executableRelativePath = environ.get("_", "")
    return Path(executableRelativePath)

def getFileExtension(filePath: Path) -> Path:
    var pext: String = toString(filePath.extension())
    if not pext.empty():
        pext = pext[1:]  # Remove leading dot
    return Path(pext)

def getFileType(filePath: Path) -> Int:
    var stringExtension: String = toString(filePath.extension())
    stringExtension = stringExtension.substr(stringExtension.rfind(".") + 1)
    return getEnumValue(FileTypesExtUC, Util.makeUPPER(stringExtension))

def removeFileExtension(filePath: Path) -> Path:
    return Path(filePath).replace_extension()

def replaceFileExtension(filePath: Path, ext: Path) -> Path:
    return Path(filePath).replace_extension(ext)

def makeDirectory(directoryPath: Path):
    if pathExists(directoryPath):
        if not directoryExists(directoryPath):
            print("ERROR: " + toString(getAbsolutePath(directoryPath)) + " already exists and is not a directory.")
            sys_exit(1)
    else:
        directoryPath.create_directories()

def pathExists(path: Path) -> Bool:
    return path.exists()

def directoryExists(directoryPath: Path) -> Bool:
    return directoryPath.exists() and directoryPath.is_dir()

def fileExists(filePath: Path) -> Bool:
    return filePath.exists() and not filePath.is_dir()

def moveFile(filePath: Path, destination: Path):
    if not fileExists(filePath):
        return
    try:
        Path(filePath).rename(destination)
    except:
        filePath.copy(destination, copy_options=CopyOptions.update_existing)
        filePath.remove()

def systemCall(command: String) -> Int:
    return os_system(command)

def removeFile(filePath: Path) -> Bool:
    if not fileExists(filePath):
        return False
    return filePath.remove()

def linkFile(filePath: Path, linkPath: Path):
    if not fileExists(filePath):
        return
    # On non-Windows, create symlink
    filePath.create_symlink(linkPath)

def readFile(filePath: Path, mode: Int = 0) -> String:
    if not fileExists(filePath):
        raise FatalError("File does not exists: " + filePath.string())
    if (mode & (1 | 2)) == 0:  # in | binary
        raise FatalError("ERROR - readFile: Bad openmode argument. Must be ios_base::in or ios_base::binary")
    var file_size: Int = filePath.file_size()
    var file: FileHandle = filePath.open(mode)
    if not file.is_open():
        raise FatalError("Could not open file: " + filePath.string())
    var result: String = String(file_size, '\0')
    file.read(result.data(), file_size)
    return result

def readJSON(filePath: Path, mode: Int = 0) -> Dict:
    if not fileExists(filePath):
        raise FatalError("File does not exists: " + filePath.string())
    if (mode & (1 | 2)) == 0:
        raise FatalError("ERROR - readFile: Bad openmode argument. Must be ios_base::in or ios_base::binary")
    var file: FileHandle = filePath.open(mode)
    if not file.is_open():
        raise FatalError("Could not open file: " + filePath.string())
    var ext: Int = getFileType(filePath)
    if ext == FileTypes.EpJSON or ext == FileTypes.JSON or ext == FileTypes.GLHE:
        return json.parse(file)
    elif ext == FileTypes.CBOR:
        return cbor.load(file)
    elif ext == FileTypes.MsgPack:
        return msgpack.load(file)
    elif ext == FileTypes.UBJSON:
        return ubjson.load(file)
    elif ext == FileTypes.BSON:
        return bson.load(file)
    else:
        raise FatalError("Invalid file extension. Must be epJSON, JSON, or other experimental extensions")

def toString(p: Path) -> String:
    return p.string()

def toGenericString(p: Path) -> String:
    return p.generic_string()

def appendSuffixToPath(outputFilePrefixFullPath: Path, suffix: String) -> Path:
    return Path(outputFilePrefixFullPath.string() + suffix)

# Helper function for getEnumValue
def getEnumValue(arr: StaticArray[String, 15], key: String) -> Int:
    for i in range(arr.size):
        if arr[i] == key:
            return i
    return -1