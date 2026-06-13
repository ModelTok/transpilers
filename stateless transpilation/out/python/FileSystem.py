import os
import sys
import json
import shutil
import subprocess
import ctypes
from pathlib import Path
from enum import IntEnum
from typing import Union, Optional, Any, Protocol
from dataclasses import dataclass

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.pathChar, .altpathChar (str) — from EnergyPlus/DataStringGlobals
# - Util.makeUPPER(str) -> str — from EnergyPlus/UtilityRoutines
# - FatalError(msg: str) — exception class from EnergyPlus/UtilityRoutines
# - CLI.narrow(wstr: str) -> str, CLI.widen(str) -> str — from CLI/CLI11 (identity on Unix)

class DataStringGlobalsStub:
    pathChar = os.sep
    altpathChar = '\\' if sys.platform != 'win32' else '/'

class UtilStub:
    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()

class FatalError(Exception):
    pass

class CLIStub:
    @staticmethod
    def narrow(s: str) -> str:
        return s
    
    @staticmethod
    def widen(s: str) -> str:
        return s

DataStringGlobals = DataStringGlobalsStub()
Util = UtilStub()
CLI = CLIStub()


class FileTypes(IntEnum):
    Invalid = -1
    EpJSON = 0
    JSON = 1
    GLHE = 2
    last_json_type = 2
    CBOR = 3
    MsgPack = 4
    UBJSON = 5
    BSON = 6
    last_binary_json_type = 6
    IDF = 7
    IMF = 8
    CSV = 9
    TSV = 10
    TXT = 11
    ESO = 12
    MTR = 13
    last_flat_file_type = 13
    DDY = 14
    Num = 15


EXE_EXTENSION = ".exe" if sys.platform == "win32" else ""

FILE_TYPES_EXT = [
    "epJSON", "json", "glhe", "cbor", "msgpack", "ubjson", "bson",
    "idf", "imf", "csv", "tsv", "txt", "eso", "mtr", "ddy"
]

FILE_TYPES_EXT_UC = [
    "EPJSON", "JSON", "GLHE", "CBOR", "MSGPACK", "UBJSON", "BSON",
    "IDF", "IMF", "CSV", "TSV", "TXT", "ESO", "MTR", "DDY"
]

assert len(FILE_TYPES_EXT) == FileTypes.Num
assert len(FILE_TYPES_EXT_UC) == FileTypes.Num
assert FILE_TYPES_EXT[-1]
assert FILE_TYPES_EXT_UC[-1]


def is_all_json_type(t: FileTypes) -> bool:
    return t > FileTypes.Invalid and t <= FileTypes.last_binary_json_type


def is_json_type(t: FileTypes) -> bool:
    return t > FileTypes.Invalid and t <= FileTypes.last_json_type


def is_binary_json_type(t: FileTypes) -> bool:
    return t > FileTypes.last_json_type and t <= FileTypes.last_binary_json_type


def is_idf_type(t: FileTypes) -> bool:
    return t == FileTypes.IDF or t == FileTypes.IMF


def is_flat_file_type(t: FileTypes) -> bool:
    return t > FileTypes.last_binary_json_type and t <= FileTypes.last_flat_file_type


def make_native_path(path: Union[str, Path]) -> Path:
    result = Path(path)
    if sys.platform == "win32":
        result = result.as_posix().replace("\\", "/")
        return Path(result)
    else:
        path_str = result.as_posix()
        path_str = path_str.replace(DataStringGlobals.altpathChar, DataStringGlobals.pathChar)
        return Path(path_str)


def get_file_name(file_path: Union[str, Path]) -> Path:
    return Path(file_path).name


def get_parent_directory_path(file_path: Union[str, Path]) -> Path:
    path_obj = Path(file_path)
    if sys.platform == "win32":
        path_str = path_obj.as_posix()
    else:
        path_str = str(path_obj)
    
    if path_str:
        while path_str and (path_str[-1] == DataStringGlobals.pathChar or path_str[-1] == DataStringGlobals.altpathChar):
            path_str = path_str[:-1]
    
    if not path_str:
        return Path("./")
    
    parent = Path(path_str).parent
    if not str(parent) or str(parent) == ".":
        return Path("./")
    return parent


def get_absolute_path(path: Union[str, Path]) -> Path:
    p = Path(path).resolve()
    
    while p.is_symlink():
        link_path = p.readlink()
        if link_path.is_absolute():
            p = link_path
        else:
            p = p.parent / link_path
    
    result = Path()
    for component in p.parts:
        if component == "..":
            if result.is_symlink() or (result.name == ".."):
                result = result / component
            else:
                result = result.parent
        elif component != ".":
            result = result / component
    
    return result


def get_program_path() -> Path:
    if sys.platform == "darwin":
        import mach_o_support
        return Path(mach_o_support.get_executable_path())
    elif sys.platform.startswith("linux"):
        try:
            return Path(os.readlink("/proc/self/exe"))
        except OSError:
            print("ERROR: Unable to locate executable.")
            sys.exit(1)
    elif sys.platform == "win32":
        return Path(sys.executable)
    return Path()


def get_file_extension(file_path: Union[str, Path]) -> Path:
    ext = Path(file_path).suffix
    if ext and ext.startswith("."):
        ext = ext[1:]
    return Path(ext)


def get_enum_value(lookup_table: list, key: str) -> int:
    try:
        return lookup_table.index(key)
    except ValueError:
        return FileTypes.Invalid


def get_file_type(file_path: Union[str, Path]) -> FileTypes:
    string_extension = Path(file_path).suffix
    if string_extension.startswith("."):
        string_extension = string_extension[1:]
    string_extension = string_extension.upper()
    enum_val = get_enum_value(FILE_TYPES_EXT_UC, string_extension)
    return FileTypes(enum_val)


def remove_file_extension(file_path: Union[str, Path]) -> Path:
    return Path(file_path).with_suffix("")


def replace_file_extension(file_path: Union[str, Path], ext: Union[str, Path]) -> Path:
    ext_str = str(ext)
    if not ext_str.startswith("."):
        ext_str = "." + ext_str
    return Path(file_path).with_suffix(ext_str)


def make_directory(directory_path: Union[str, Path]) -> None:
    dir_path = Path(directory_path)
    if dir_path.exists():
        if not dir_path.is_dir():
            print(f"ERROR: {get_absolute_path(dir_path)} already exists and is not a directory.")
            sys.exit(1)
    else:
        dir_path.mkdir(parents=True, exist_ok=True)


def path_exists(path: Union[str, Path]) -> bool:
    return Path(path).exists()


def directory_exists(directory_path: Union[str, Path]) -> bool:
    p = Path(directory_path)
    return p.exists() and p.is_dir()


def file_exists(file_path: Union[str, Path]) -> bool:
    p = Path(file_path)
    return p.exists() and p.is_file()


def move_file(file_path: Union[str, Path], destination_path: Union[str, Path]) -> None:
    src = Path(file_path)
    dst = Path(destination_path)
    
    if not file_exists(src):
        return
    
    try:
        src.rename(dst)
    except OSError:
        shutil.copy2(src, dst)
        src.unlink()


def system_call(command: str) -> int:
    if sys.platform == "win32":
        return os.system(f'"{command}"')
    else:
        return os.system(command)


def remove_file(file_path: Union[str, Path]) -> bool:
    p = Path(file_path)
    if not file_exists(p):
        return False
    try:
        p.unlink()
        return True
    except OSError:
        return False


def link_file(file_path: Union[str, Path], link_path: Union[str, Path]) -> None:
    src = Path(file_path)
    dst = Path(link_path)
    
    if not file_exists(src):
        return
    
    if sys.platform == "win32":
        shutil.copy2(src, dst)
    else:
        dst.symlink_to(src)


def read_file(file_path: Union[str, Path], mode: str = "rb") -> str:
    p = Path(file_path)
    
    if not file_exists(p):
        raise FatalError(f"File does not exists: {p}")
    
    if "r" not in mode and "b" not in mode:
        raise FatalError("ERROR - readFile: Bad openmode argument. Must include 'r' or 'b'")
    
    return p.read_bytes().decode('utf-8', errors='replace') if "b" in mode else p.read_text()


def read_json(file_path: Union[str, Path], mode: str = "rb") -> dict:
    p = Path(file_path)
    
    if not file_exists(p):
        raise FatalError(f"File does not exists: {p}")
    
    if "r" not in mode and "b" not in mode:
        raise FatalError("ERROR - readFile: Bad openmode argument. Must include 'r' or 'b'")
    
    file_type = get_file_type(p)
    
    with open(p, mode) as f:
        if file_type in (FileTypes.EpJSON, FileTypes.JSON, FileTypes.GLHE):
            return json.load(f)
        elif file_type == FileTypes.CBOR:
            import cbor2
            return cbor2.load(f)
        elif file_type == FileTypes.MsgPack:
            import msgpack
            return msgpack.unpackb(f.read())
        elif file_type == FileTypes.UBJSON:
            raise FatalError("UBJSON not supported in this implementation")
        elif file_type == FileTypes.BSON:
            import bson
            return bson.BSON(f.read()).decode()
        else:
            raise FatalError("Invalid file extension. Must be epJSON, JSON, or other experimental extensions")


def get_json_string(data: dict, file_type: FileTypes, indent: int = 4) -> str:
    if is_json_type(file_type):
        return json.dumps(data, indent=indent)
    elif is_binary_json_type(file_type):
        if file_type == FileTypes.CBOR:
            import cbor2
            return cbor2.dumps(data).decode('latin1')
        elif file_type == FileTypes.MsgPack:
            import msgpack
            return msgpack.packb(data).decode('latin1')
        elif file_type == FileTypes.BSON:
            import bson
            return bson.BSON.encode(data).decode('latin1')
        elif file_type == FileTypes.UBJSON:
            raise FatalError("UBJSON not supported")
    raise FatalError("Must be a JSON type")


def write_file(file_path: Union[str, Path], data: Union[str, dict], file_type: FileTypes, indent: int = 4) -> None:
    if not (is_all_json_type(file_type) or is_flat_file_type(file_type)):
        raise ValueError("Must be a valid file type")
    
    p = Path(file_path)
    
    if isinstance(data, dict):
        data_str = get_json_string(data, file_type, indent)
    else:
        data_str = data
    
    p.write_text(data_str)


def write_file_to_stream(stream: Any, data: Union[str, dict], file_type: FileTypes, indent: int = 4) -> None:
    if isinstance(data, dict):
        data_str = get_json_string(data, file_type, indent)
    else:
        data_str = data
    
    if hasattr(stream, 'write'):
        stream.write(data_str)
    else:
        stream.print(data_str)


def to_string(p: Union[str, Path]) -> str:
    return str(Path(p))


def to_generic_string(p: Union[str, Path]) -> str:
    return str(Path(p).as_posix())


def append_suffix_to_path(output_file_prefix_full_path: Union[str, Path], suffix: str) -> Path:
    return Path(str(output_file_prefix_full_path) + suffix)
