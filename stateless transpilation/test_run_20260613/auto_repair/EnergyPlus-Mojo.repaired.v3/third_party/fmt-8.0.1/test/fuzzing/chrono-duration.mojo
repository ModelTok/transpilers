from fuzzer-common import assign_from_buf, fixed_size, as_chars
from fmt import format, memory_buffer, format_to, string_view, back_inserter
from std.chrono import duration
from std import atto, femto, pico, nano, micro, milli, centi, deci, deca, kilo, mega, giga, tera, peta, exa

def invoke_inner[Period: AnyType, Rep: AnyType](format_str: string_view, rep: Rep):
    var value = duration[Rep, Period](rep)
    try:
        # if FMT_FUZZ_FORMAT_TO_STRING
        var message: String = format(format_str, value)
        # else
        # var buf = memory_buffer()
        # format_to(back_inserter(buf), format_str, value)
    except:

def invoke_outer[Rep: AnyType](data: Pointer[UInt8], size: Int, period: Int):
    static_assert(sizeof[Rep]() <= fixed_size, "fixed size is too small")
    if size <= fixed_size + 1:
        return
    var rep: Rep = assign_from_buf[Rep](data)
    data += fixed_size
    size -= fixed_size
    var format_str: string_view = as_chars(data)  # size is used implicitly via string_view
    switch period:
        case 1:
            invoke_inner[atto, Rep](format_str, rep)
        case 2:
            invoke_inner[femto, Rep](format_str, rep)
        case 3:
            invoke_inner[pico, Rep](format_str, rep)
        case 4:
            invoke_inner[nano, Rep](format_str, rep)
        case 5:
            invoke_inner[micro, Rep](format_str, rep)
        case 6:
            invoke_inner[milli, Rep](format_str, rep)
        case 7:
            invoke_inner[centi, Rep](format_str, rep)
        case 8:
            invoke_inner[deci, Rep](format_str, rep)
        case 9:
            invoke_inner[deca, Rep](format_str, rep)
        case 10:
            invoke_inner[kilo, Rep](format_str, rep)
        case 11:
            invoke_inner[mega, Rep](format_str, rep)
        case 12:
            invoke_inner[giga, Rep](format_str, rep)
        case 13:
            invoke_inner[tera, Rep](format_str, rep)
        case 14:
            invoke_inner[peta, Rep](format_str, rep)
        case 15:
            invoke_inner[exa, Rep](format_str, rep)
        default:

def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int:
    if size <= 4:
        return 0
    var representation: UInt8 = data[0]
    var period: UInt8 = data[1]
    data += 2
    size -= 2
    switch representation:
        case 1:
            invoke_outer[Int8](data, size, period)
        case 2:
            invoke_outer[Int8](data, size, period)  # signed char -> Int8
        case 3:
            invoke_outer[UInt8](data, size, period)
        case 4:
            invoke_outer[Int16](data, size, period)
        case 5:
            invoke_outer[UInt16](data, size, period)
        case 6:
            invoke_outer[Int32](data, size, period)
        case 7:
            invoke_outer[UInt32](data, size, period)
        case 8:
            invoke_outer[Int64](data, size, period)
        case 9:
            invoke_outer[UInt64](data, size, period)
        case 10:
            invoke_outer[Float32](data, size, period)
        case 11:
            invoke_outer[Float64](data, size, period)
        case 12:
            invoke_outer[Float64](data, size, period)  # long double -> Float64 (mojo no long double)
        default:

    return 0