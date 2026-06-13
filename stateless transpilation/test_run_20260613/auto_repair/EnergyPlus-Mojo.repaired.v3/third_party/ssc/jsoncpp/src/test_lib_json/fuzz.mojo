from json import CharReaderBuilder, CharReader, Value, Exception
from memory import Pointer
from builtin import Int, UInt8, UInt32

@ffi(linkage="C")
def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int:
    var builder = CharReaderBuilder()
    if size < sizeof[UInt32]():
        return 0
    var hash_settings = (UInt32(data[0]) |
                        (UInt32(data[1]) << 8) |
                        (UInt32(data[2]) << 16) |
                        (UInt32(data[3]) << 24))
    data += sizeof[UInt32]()
    size -= sizeof[UInt32]()
    builder.settings_["failIfExtra"] = hash_settings & (1 << 0)
    builder.settings_["allowComments_"] = hash_settings & (1 << 1)
    builder.settings_["strictRoot_"] = hash_settings & (1 << 2)
    builder.settings_["allowDroppedNullPlaceholders_"] = hash_settings & (1 << 3)
    builder.settings_["allowNumericKeys_"] = hash_settings & (1 << 4)
    builder.settings_["allowSingleQuotes_"] = hash_settings & (1 << 5)
    builder.settings_["failIfExtra_"] = hash_settings & (1 << 6)
    builder.settings_["rejectDupKeys_"] = hash_settings & (1 << 7)
    builder.settings_["allowSpecialFloats_"] = hash_settings & (1 << 8)
    builder.settings_["collectComments"] = hash_settings & (1 << 9)
    builder.settings_["allowTrailingCommas_"] = hash_settings & (1 << 10)
    let reader = builder.newCharReader()
    var root = Value()
    let data_str = data.bitcast[Pointer[UInt8]]()
    try:
        reader.parse(data_str, data_str + size, root, None)
    except Exception:

    return 0