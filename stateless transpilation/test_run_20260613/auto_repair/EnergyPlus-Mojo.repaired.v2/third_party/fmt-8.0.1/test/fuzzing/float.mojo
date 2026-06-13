from fmt import format_to, memory_buffer, string_view
from fuzzer_common import assign_from_buf
from math import isnan, signbit
from sys import float_info

# extern C function for strtod (from <cstdlib>)
@extern
def strtod(s: Pointer[UInt8], endptr: Pointer[Pointer[UInt8]]) -> Float64

def check_round_trip(format_str: fmt.string_view, value: Float64) raises:
    var buffer = fmt.memory_buffer()
    fmt.format_to(buffer, format_str, value)
    if isnan(value):
        var nan: String = if signbit(value): "-nan" else: "nan"
        if fmt.string_view(buffer.data(), buffer.size()) != nan:
            raise Error("round trip failure")
        return
    buffer.push_back('\0')
    var ptr: Pointer[UInt8] = Pointer[UInt8]()
    var endptr: Pointer[Pointer[UInt8]] = Pointer[Pointer[UInt8]](address_of(ptr))
    if strtod(buffer.data(), endptr) != value:
        raise Error("round trip failure")
    if ptr + 1 != buffer.end():
        raise Error("unparsed output")

@export
def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int:
    var is_iec559: Bool = (float_info.radix == 2) and (float_info.mant_dig == 53)
    if size <= sizeof[Float64]() or not is_iec559:
        return 0
    check_round_trip("{}", assign_from_buf[Float64](data))
    check_round_trip("{:.50g}", assign_from_buf[Float64](data))
    return 0