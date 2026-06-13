from pathlib import Path
import os
import sys
import json
import shutil
import subprocess
from enum import IntEnum
from typing import Union, Optional, Any


@dataclass
struct ExternalDeps:
    path_char: String
    alt_path_char: String
    

struct FileTypes:
    alias Invalid = -1
    alias EpJSON = 0
    alias JSON = 1
    alias GLHE = 2
    alias last_json_type = 2
    alias CBOR = 3
    alias MsgPack = 4
    alias UBJSON = 5
    alias BSON = 6
    alias last_binary_json_type = 6
    alias IDF = 7
    alias IMF = 8
    alias CSV = 9
    alias TSV = 10
    alias TXT = 11
    alias ESO = 12
    alias MTR = 13
    alias last_flat_file_type = 13
    alias DDY = 14
    alias Num = 15


fn is_all_json_type(t: Int) -> Bool:
    return t > FileTypes.Invalid and t <= FileTypes.last_binary_json_type


fn is_json_type(t: Int) -> Bool:
    return t > FileTypes.Invalid and t <= FileTypes.last_json_type


fn is_binary_json_type(t: Int) -> Bool:
    return t > FileTypes.last_json_type and t <= FileTypes.last_binary_json_type


fn is_idf_type(t: Int) -> Bool:
    return t == FileTypes.IDF or t == FileTypes.IMF


fn is_flat_file_type(t: Int) -> Bool:
    return t > FileTypes.last_binary_json_type and t <= FileTypes.last_flat_file_type


var FILE_TYPES_EXT = InlineArray[StringLiteral, 15](
    "epJSON", "json", "glhe", "cbor", "msgpack", "ubjson", "bson",
    "idf", "imf", "csv", "tsv", "txt", "eso", "mtr", "ddy"
)

var FILE_TYPES_EXT_UC = InlineArray[StringLiteral, 15](
    "EPJSON", "JSON", "GLHE", "CBOR", "MSGPACK", "UBJSON", "BSON",
    "IDF", "IMF", "CSV", "TSV", "TXT", "ESO", "MTR", "DDY"
)

var EXE_EXTENSION: String = ".exe" if "win32" in str(sys.platform) else ""


@always_inline
fn get_path_char() -> String:
    return "/" if "win32" not in str(sys.platform) else "\\"


@always_inline
fn get_alt_path_char() -> String:
    return "\\" if "win32" not in str(sys.platform) else "/"


fn make_native_path(path: String) -> String:
    var result = path
    let path_char = get_path_char()
    let alt_path_char = get_alt_path_char()
    
    if "win32" in str(sys.platform):
        var temp = String()
        for char in path:
            if char == "\\":
                temp += "/"
            else:
                temp += char
        result = temp
    else:
        var temp = String()
        for char in result:
            if char == alt_path_char:
                temp += path_char
            else:
                temp += char
        result = temp
    
    return result


fn get_file_name(file_path: String) -> String:
    var name = String()
    var last_sep = -1
    
    for i in range(len(file_path)):
        if file_path[i] == "/" or file_path[i] == "\\":
            last_sep = i
    
    if last_sep >= 0:
        name = file_path[last_sep + 1:]
    else:
        name = file_path
    
    return name


fn get_parent_directory_path(file_path: String) -> String:
    var path_str = file_path
    let path_char = get_path_char()
    let alt_path_char = get_alt_path_char()
    
    while len(path_str) > 0 and (path_str[-1] == path_char or path_str[-1] == alt_path_char):
        path_str = path_str[:-1]
    
    if len(path_str) == 0:
        return "./"
    
    var last_sep = -1
    for i in range(len(path_str)):
        if path_str[i] == "/" or path_str[i] == "\\":
            last_sep = i
    
    if last_sep < 0:
        return "./"
    
    return path_str[:last_sep]


fn get_absolute_path(path: String) -> String:
    # Simplified absolute path resolution
    var parts = String()
    var i = 0
    
    while i < len(path):
        if path[i] == "/" or path[i] == "\\":
            if len(parts) == 0 or parts[-1] != "/":
                parts += "/"
        else:
            parts += path[i]
        i += 1
    
    return parts


fn get_program_path() -> String:
    if "darwin" in str(sys.platform):
        return ""
    elif "linux" in str(sys.platform):
        try:
            with open("/proc/self/exe") as f:
                return f.read().strip()
        except:
            return ""
    elif "win32" in str(sys.platform):
        return str(sys.executable)
    return ""


fn get_file_extension(file_path: String) -> String:
    var last_dot = -1
    
    for i in range(len(file_path)):
        if file_path[i] == ".":
            last_dot = i
    
    if last_dot < 0:
        return String()
    
    return file_path[last_dot + 1:]


fn get_enum_value(lookup_table: InlineArray[StringLiteral, 15], key: String) -> Int:
    for i in range(15):
        if String(lookup_table[i]) == key:
            return i
    return FileTypes.Invalid


fn get_file_type(file_path: String) -> Int:
    var string_extension = get_file_extension(file_path)
    var upper_ext = String()
    
    for char in string_extension:
        if char >= "a" and char <= "z":
            upper_ext += chr(ord(char) - 32)
        else:
            upper_ext += char
    
    return get_enum_value(FILE_TYPES_EXT_UC, upper_ext)


fn remove_file_extension(file_path: String) -> String:
    var last_dot = -1
    
    for i in range(len(file_path)):
        if file_path[i] == ".":
            last_dot = i
    
    if last_dot < 0:
        return file_path
    
    return file_path[:last_dot]


fn replace_file_extension(file_path: String, ext: String) -> String:
    var result = remove_file_extension(file_path)
    var ext_to_use = ext
    
    if not ext_to_use.startswith("."):
        ext_to_use = "." + ext_to_use
    
    return result + ext_to_use


fn make_directory(directory_path: String) -> None:
    if os.path.exists(directory_path):
        if not os.path.isdir(directory_path):
            print(f"ERROR: {get_absolute_path(directory_path)} already exists and is not a directory.")
            sys.exit(1)
    else:
        os.makedirs(directory_path, exist_ok=True)


fn path_exists(path: String) -> Bool:
    return os.path.exists(path)


fn directory_exists(directory_path: String) -> Bool:
    return os.path.exists(directory_path) and os.path.isdir(directory_path)


fn file_exists(file_path: String) -> Bool:
    return os.path.exists(file_path) and os.path.isfile(file_path)


fn move_file(file_path: String, destination_path: String) -> None:
    if not file_exists(file_path):
        return
    
    try:
        os.rename(file_path, destination_path)
    except:
        shutil.copy2(file_path, destination_path)
        os.unlink(file_path)


fn system_call(command: String) -> Int:
    if "win32" in str(sys.platform):
        return os.system(f'"{command}"')
    else:
        return os.system(command)


fn remove_file(file_path: String) -> Bool:
    if not file_exists(file_path):
        return False
    
    try:
        os.unlink(file_path)
        return True
    except:
        return False


fn link_file(file_path: String, link_path: String) -> None:
    if not file_exists(file_path):
        return
    
    if "win32" in str(sys.platform):
        shutil.copy2(file_path, link_path)
    else:
        os.symlink(file_path, link_path)


fn read_file(file_path: String, mode: String = "rb") -> String:
    if not file_exists(file_path):
        raise Error(f"File does not exists: {file_path}")
    
    if "r" not in mode and "b" not in mode:
        raise Error("ERROR - readFile: Bad openmode argument. Must include 'r' or 'b'")
    
    with open(file_path, mode) as f:
        return f.read()


fn read_json(file_path: String, mode: String = "rb") -> dict:
    if not file_exists(file_path):
        raise Error(f"File does not exists: {file_path}")
    
    if "r" not in mode and "b" not in mode:
        raise Error("ERROR - readFile: Bad openmode argument. Must include 'r' or 'b'")
    
    let file_type = get_file_type(file_path)
    
    with open(file_path, mode) as f:
        if file_type == FileTypes.EpJSON or file_type == FileTypes.JSON or file_type == FileTypes.GLHE:
            return json.load(f)
        elif file_type == FileTypes.CBOR:
            raise Error("CBOR not supported in this implementation")
        elif file_type == FileTypes.MsgPack:
            raise Error("MsgPack not supported in this implementation")
        elif file_type == FileTypes.UBJSON:
            raise Error("UBJSON not supported in this implementation")
        elif file_type == FileTypes.BSON:
            raise Error("BSON not supported in this implementation")
        else:
            raise Error("Invalid file extension. Must be epJSON, JSON, or other experimental extensions")


fn get_json_string(data: dict, file_type: Int, indent: Int = 4) -> String:
    if is_json_type(file_type):
        return json.dumps(data, indent=indent)
    elif is_binary_json_type(file_type):
        raise Error("Binary JSON types not supported in string conversion")
    else:
        raise Error("Must be a JSON type")


fn write_file(file_path: String, data: String, file_type: Int) -> None:
    if not (is_all_json_type(file_type) or is_flat_file_type(file_type)):
        raise Error("Must be a valid file type")
    
    with open(file_path, "w") as f:
        f.write(data)


fn write_file_json(file_path: String, data: dict, file_type: Int, indent: Int = 4) -> None:
    let json_str = get_json_string(data, file_type, indent)
    write_file(file_path, json_str, file_type)


fn to_string(p: String) -> String:
    return p


fn to_generic_string(p: String) -> String:
    var result = String()
    for char in p:
        if char == "\\":
            result += "/"
        else:
            result += char
    return result


fn append_suffix_to_path(output_file_prefix_full_path: String, suffix: String) -> String:
    return output_file_prefix_full_path + suffix
