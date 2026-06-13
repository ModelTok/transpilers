from time import localtime, TimeT, TM
from fuzzer-common import assign_from_buf, DataToString, fixed_size
from fmt import format, format_to, MemoryBuffer

alias FMT_FUZZ_FORMAT_TO_STRING = False

alias Bool = Bool
alias Char = UInt8
alias unsigned_char = UInt8
alias signed_char = SInt8
alias short = Int16
alias unsigned_short = UInt16
alias int = Int32
alias unsigned_int = UInt32
alias long = Int64
alias unsigned_long = UInt64
alias long_double = Float64
alias time_t = Int

def from_repr[T: AnyType, Repr: AnyType](r: Repr) -> Pointer[T]:
    @parameter
    if T == TM:
        let t = r as Int
        return localtime(t)
    else:
        return Pointer[T](address_of(r))

def invoke_fmt[T: AnyType, Repr: AnyType = T](data: Pointer[UInt8], size: Int):
    @parameter
    if not (sizeof[Repr]() <= fixed_size):
        compile_error("Nfixed is too small")
    if size <= fixed_size:
        return
    var repr = assign_from_buf[Repr](data)
    let value = from_repr[T](repr)
    if not value:
        return
    var data_ptr = data.offset(fixed_size)
    var size_remaining = size - fixed_size
    var format_str = DataToString(data_ptr, size_remaining)
    try:
        @parameter
        if FMT_FUZZ_FORMAT_TO_STRING:
            var message = format(format_str.get(), value[])
        else:
            var message = MemoryBuffer()
            format_to(message, format_str.get(), value[])
    except Exception:

def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int:
    if size <= 3:
        return 0
    var first = data[0]
    var data_ptr = data.offset(1)
    var size_remaining = size - 1
    match first:
        case 0:
            invoke_fmt[Bool](data_ptr, size_remaining)
        case 1:
            invoke_fmt[Char](data_ptr, size_remaining)
        case 2:
            invoke_fmt[unsigned_char](data_ptr, size_remaining)
        case 3:
            invoke_fmt[signed_char](data_ptr, size_remaining)
        case 4:
            invoke_fmt[short](data_ptr, size_remaining)
        case 5:
            invoke_fmt[unsigned_short](data_ptr, size_remaining)
        case 6:
            invoke_fmt[int](data_ptr, size_remaining)
        case 7:
            invoke_fmt[unsigned_int](data_ptr, size_remaining)
        case 8:
            invoke_fmt[long](data_ptr, size_remaining)
        case 9:
            invoke_fmt[unsigned_long](data_ptr, size_remaining)
        case 10:
            invoke_fmt[Float32](data_ptr, size_remaining)
        case 11:
            invoke_fmt[Float64](data_ptr, size_remaining)
        case 12:
            invoke_fmt[long_double](data_ptr, size_remaining)
        case 13:
            invoke_fmt[TM, time_t](data_ptr, size_remaining)
        case _:

    return 0