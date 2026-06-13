from ..fuzzer-common import fixed_size, assign_from_buf, data_to_string
from ...fmt.core import format, format_to, arg, memory_buffer

const FMT_FUZZ_FORMAT_TO_STRING: Bool = True

def invoke_fmt[T: AnyType](data: Pointer[UInt8], size: Int, arg_name_size: UInt32) raises:
    @parameter
    if sizeof[T]() > fixed_size:
        # static_assert equivalent: compile-time check
        # Mojo doesn't have static_assert, but we can use @parameter if and raise error
        raise Error("fixed_size too small")
    if size <= fixed_size:
        return
    let value: T = assign_from_buf[T](data)
    data += fixed_size
    size -= fixed_size
    if arg_name_size <= 0 or arg_name_size >= size:
        return
    let arg_name: data_to_string = data_to_string(data, arg_name_size, True)
    data += arg_name_size
    size -= arg_name_size
    let format_str: data_to_string = data_to_string(data, size)
    try:
        @parameter
        if FMT_FUZZ_FORMAT_TO_STRING:
            let message: String = format(format_str.get(), arg(arg_name.data(), value))
        else:
            var out: memory_buffer = memory_buffer()
            format_to(out, format_str.get(), arg(arg_name.data(), value))
    except:

def invoke[CallbackType: AnyType](type: Int, callback: CallbackType) raises:
    match type:
        case 0:
            callback(bool())
        case 1:
            callback(Char())
        case 2:
            using sc = Int8
            callback(sc())
        case 3:
            using uc = UInt8
            callback(uc())
        case 4:
            callback(Int16())
        case 5:
            using us = UInt16
            callback(us())
        case 6:
            callback(Int32())
        case 7:
            callback(UInt32())
        case 8:
            callback(Int64())
        case 9:
            using ul = UInt64
            callback(ul())
        case 10:
            callback(Float32())
        case 11:
            callback(Float64())
        case 12:
            using LD = Float128
            callback(LD())

def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int raises:
    if size <= 3:
        return 0
    let type: UInt8 = data[0] & 0x0F
    let arg_name_size: UInt32 = (data[0] & 0xF0) >> 4
    data += 1
    size -= 1
    var invoke_lambda = fn[T: AnyType](arg: T) raises:
        var data_copy: Pointer[UInt8] = data
        var size_copy: Int = size
        var arg_name_size_copy: UInt32 = arg_name_size
        invoke_fmt[type[T]](data_copy, size_copy, arg_name_size_copy)
    invoke[type(invoke_lambda)](type, invoke_lambda)
    return 0