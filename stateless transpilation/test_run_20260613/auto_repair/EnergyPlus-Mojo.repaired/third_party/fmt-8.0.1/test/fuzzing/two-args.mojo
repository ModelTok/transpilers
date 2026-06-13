from fmt.format import format, format_to, memory_buffer, string_view
from cstdint import uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t
from exception import Exception
from string import String
from fuzzer-common import assign_from_buf, as_chars, fixed_size

def invoke_fmt[Item1: AnyType, Item2: AnyType](data: Pointer[uint8_t], size: size_t) raises:
    constrained[sizeof[Item1] <= fixed_size, "size1 exceeded"]
    constrained[sizeof[Item2] <= fixed_size, "size2 exceeded"]
    if size <= fixed_size + fixed_size:
        return
    var item1: Item1 = assign_from_buf[Item1](data)
    data += fixed_size
    size -= fixed_size
    var item2: Item2 = assign_from_buf[Item2](data)
    data += fixed_size
    size -= fixed_size
    var format_str = string_view(as_chars(data), size)
    #if FMT_FUZZ_FORMAT_TO_STRING
    var message: String = format(format_str, item1, item2)
    #else
    var message: memory_buffer
    format_to(message, format_str, item1, item2)
    #endif

def invoke[Callback: AnyType](index: int, callback: Callback) raises:
    @parameter
    if index == 0:
        callback(bool())
    elif index == 1:
        callback(char())
    elif index == 2:
        alias sc = signed char
        callback(sc())
    elif index == 3:
        alias uc = unsigned char
        callback(uc())
    elif index == 4:
        callback(short())
    elif index == 5:
        alias us = unsigned short
        callback(us())
    elif index == 6:
        callback(int())
    elif index == 7:
        callback(unsigned())
    elif index == 8:
        callback(long())
    elif index == 9:
        alias ul = unsigned long
        callback(ul())
    elif index == 10:
        callback(float())
    elif index == 11:
        callback(double())
    elif index == 12:
        alias LD = long double
        callback(LD())
    elif index == 13:
        alias ptr = void*
        callback(ptr())

@export
def LLVMFuzzerTestOneInput(data: Pointer[uint8_t], size: size_t) -> int raises:
    if size <= 3:
        return 0
    var type1 = data[0] & 0x0F
    var type2 = (data[0] & 0xF0) >> 4
    data += 1
    size -= 1
    try:
        invoke(type1, fn[param1: AnyType]() raises:
            invoke(type2, fn[param2: AnyType]() raises:
                invoke_fmt[decltype(param1), decltype(param2)](data, size)
            )
        )
    except e: Exception:

    return 0