from char.functions import uppercase, to_lower, equali
from TypeTraits import TypeTraits
from memory import memcpy
from sys import int_type
from utils import StringRef, StringRefLiteral

# Include equivalents for C++ standard library
from builtin import String as std_string
from builtin import StringRef as std_string_view
from builtin import Bool as bool
from builtin import Int as int
from builtin import Float64 as double
from builtin import Float32 as float
from builtin import Int8 as char
from builtin import Int16 as short_int
from builtin import Int32 as int32
from builtin import Int64 as long_int
from builtin import UInt8 as unsigned_char
from builtin import UInt16 as unsigned_short_int
from builtin import UInt32 as unsigned_int
from builtin import UInt64 as unsigned_long_int
from builtin import SIMD as long_long_int
from builtin import SIMD as unsigned_long_long_int
from builtin import Float16 as long_double

# Note: Mojo doesn't have direct equivalents for all C++ stdlib functions,
# so we implement them using built-in operations

def empty(s: std_string_view) -> bool:
    return s.empty()

def is_blank(s: std_string_view) -> bool:
    return (s.empty() or s.find_first_not_of(' ') == -1)

def not_blank(s: std_string_view) -> bool:
    return not is_blank(s)

def is_whitespace(s: std_string_view) -> bool:
    return (s.empty() or s.find_last_not_of(" \t\0") == -1)

def is_digit(s: std_string_view) -> bool:
    if s.empty():
        return False
    else:
        for c in s:
            if not c.isdigit():
                return False
        return True

def is_lower(s: std_string_view) -> bool:
    if s.empty():
        return False
    else:
        for c in s:
            if not c.islower():
                return False
        return True

def is_upper(s: std_string_view) -> bool:
    if s.empty():
        return False
    else:
        for c in s:
            if not c.isupper():
                return False
        return True

def has_lower(s: std_string_view) -> bool:
    for c in s:
        if c.islower():
            return True
    return False

def has_upper(s: std_string_view) -> bool:
    for c in s:
        if c.isupper():
            return True
    return False

def has(s: std_string_view, t: std_string_view) -> bool:
    return s.find(t) != -1

def has_char(s: std_string_view, c: char) -> bool:
    return s.find(c) != -1

def has_any_of(s: std_string_view, t: std_string_view) -> bool:
    return s.find_first_of(t) != -1

def has_prefix(s: std_string_view, pre: std_string_view, exact_case: bool = True) -> bool:
    pre_len = pre.length()
    if pre_len == 0:
        return False
    elif s.length() < pre_len:
        return False
    elif exact_case:
        for i in range(pre_len):
            if s[i] != pre[i]:
                return False
        return True
    else:
        for i in range(pre_len):
            if not equali(s[i], pre[i]):
                return False
        return True

def has_prefix_char(s: std_string_view, pre: char, exact_case: bool = True) -> bool:
    if s.length() == 0:
        return False
    elif exact_case:
        return s[0] == pre
    else:
        return equali(s[0], pre)

def has_prefixi(s: std_string_view, pre: std_string_view) -> bool:
    return has_prefix(s, pre, False)

def trimmed_whitespace(s: std_string_view) -> std_string:
    # Declaration copy for use below
    return _trimmed_whitespace_impl(s)

def is_type_bool(s: std_string) -> bool:
    t = trimmed_whitespace(s)
    if t.empty():
        return False
    elif t == "T" or t == "t" or t == "true":
        return True
    elif t == "F" or t == "f" or t == "false":
        return True
    else:
        # Try to read the string as 0/1 bool
        b_stream = std_string(t)
        b = b_stream.parse_bool()
        return b is not None

def is_tail(end: char*) -> bool:
    if end is None:
        return False
    while end[0].isspace():
        end += 1
    return end[0] == '\0'

def is_type_short_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    i = str_ptr.strtol(10, end)
    return (end != str_ptr) and is_tail(end) and (i >= -32768) and (i <= 32767)

def is_type_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    i = str_ptr.strtol(10, end)
    return (end != str_ptr) and is_tail(end) and (i >= -2147483648) and (i <= 2147483647)

def is_type_long_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtol(10, end)
    return (end != str_ptr) and is_tail(end)

def is_type_long_long_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtoll(10, end)
    return (end != str_ptr) and is_tail(end)

def is_type_unsigned_short_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    i = str_ptr.strtoul(10, end)
    return (end != str_ptr) and is_tail(end) and (i <= 65535)

def is_type_unsigned_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    i = str_ptr.strtoul(10, end)
    return (end != str_ptr) and is_tail(end) and (i <= 4294967295)

def is_type_unsigned_long_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtoul(10, end)
    return (end != str_ptr) and is_tail(end)

def is_type_unsigned_long_long_int(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtoull(10, end)
    return (end != str_ptr) and is_tail(end)

def is_type_float(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtof(end)
    return (end != str_ptr) and is_tail(end)

def is_type_double(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtod(end)
    return (end != str_ptr) and is_tail(end)

def is_type_long_double(s: std_string) -> bool:
    str_ptr = s.c_str()
    end = char*()
    _ = str_ptr.strtold(end)
    return (end != str_ptr) and is_tail(end)

def is_type_char(s: std_string) -> bool:
    return s.length() == 1

def is_bool(s: std_string) -> bool:
    return is_type_bool(s)

def is_short(s: std_string) -> bool:
    return is_type_short_int(s)

def is_int(s: std_string) -> bool:
    return is_type_int(s)

def is_longlong(s: std_string) -> bool:
    return is_type_long_long_int(s)

def is_ushort(s: std_string) -> bool:
    return is_type_unsigned_short_int(s)

def is_float(s: std_string) -> bool:
    return is_type_float(s)

def is_double(s: std_string) -> bool:
    return is_type_double(s)

def is_char(s: std_string) -> bool:
    return is_type_char(s)

def is_decimal(s: std_string, allow_sign: bool = True) -> bool:
    str_ptr = s.c_str()
    end = char*()
    i = str_ptr.strtol(10, end)
    return (end != str_ptr) and is_tail(end) and (allow_sign or (i >= 0))

def is_binary(s: std_string, allow_sign: bool = True) -> bool:
    str_ptr = s.c_str()
    end = char*()
    i = str_ptr.strtol(2, end)
    return (end != str_ptr) and is_tail(end) and (allow_sign or (i >= 0))

def is_bool_cstr(s: char*) -> bool:
    return is_type_bool(std_string(s))

def is_short_cstr(s: char*) -> bool:
    return is_type_short_int(std_string(s))

def is_int_cstr(s: char*) -> bool:
    return is_type_int(std_string(s))

def is_longlong_cstr(s: char*) -> bool:
    return is_type_long_long_int(std_string(s))

def is_ushort_cstr(s: char*) -> bool:
    return is_type_unsigned_short_int(std_string(s))

def is_float_cstr(s: char*) -> bool:
    return is_type_float(std_string(s))

def is_double_cstr(s: char*) -> bool:
    return is_type_double(std_string(s))

def is_char_cstr(s: char*) -> bool:
    return is_type_char(std_string(s))

def is_decimal_cstr(s: char*, allow_sign: bool = True) -> bool:
    end = char*()
    i = s.strtol(10, end)
    return (end != s) and is_tail(end) and (allow_sign or (i >= 0))

def is_binary_cstr(s: char*, allow_sign: bool = True) -> bool:
    end = char*()
    i = s.strtol(2, end)
    return (end != s) and is_tail(end) and (allow_sign or (i >= 0))

def equali_char(c: char, d: char) -> bool:
    return to_lower(c) == to_lower(d)

def equali(s: std_string_view, t: std_string_view) -> bool:
    s_len = s.length()
    if s_len != t.length():
        return False
    for i in range(s_len):
        if to_lower(s[i]) != to_lower(t[i]):
            return False
        i += 1
        if i == s_len:
            break
        if to_lower(s[i]) != to_lower(t[i]):
            return False
        i += 1
        if i == s_len:
            break
        if to_lower(s[i]) != to_lower(t[i]):
            return False
    return True

def equal(s: std_string_view, t: std_string_view, exact_case: bool = True) -> bool:
    if exact_case:
        return s == t
    else:
        return equali(s, t)

def lessthan_char(c: char, d: char) -> bool:
    return c < d

def lessthani_char(c: char, d: char) -> bool:
    return to_lower(c) < to_lower(d)

def lessthan(s: std_string_view, t: std_string_view, exact_case: bool = True) -> bool:
    if exact_case:
        return s < t
    else:
        return s.lower() < t.lower()

def lessthani(s: std_string_view, t: std_string_view) -> bool:
    return s.lower() < t.lower()

def llt(s: std_string_view, t: std_string_view) -> bool:
    return s < t

def lle(s: std_string_view, t: std_string_view) -> bool:
    return s <= t

def lge(s: std_string_view, t: std_string_view) -> bool:
    return s >= t

def lgt(s: std_string_view, t: std_string_view) -> bool:
    return s > t

def len(s: std_string_view) -> int:
    return s.length()

def len_trim(s: std_string_view) -> int:
    return s.find_last_not_of(' ') + 1

def index(s: std_string_view, t: std_string_view, last: bool = False) -> int:
    if last:
        return s.rfind(t)
    else:
        return s.find(t)

def index_char(s: std_string_view, t: char, last: bool = False) -> int:
    if last:
        return s.rfind(t)
    else:
        return s.find(t)

def rindex(s: std_string_view, t: std_string_view) -> int:
    return s.rfind(t)

def rindex_char(s: std_string_view, t: char) -> int:
    return s.rfind(t)

def indexi(s: std_string_view, t: std_string_view, last: bool = False) -> int:
    if last:
        i = s.rfind(t, 0, s.length(), equali_char)
        return i if i != -1 else -1
    else:
        i = s.find(t, 0, equali_char)
        return i if i != -1 else -1

def indexi_char(s: std_string_view, c: char, last: bool = False) -> int:
    if last:
        i = s.length() - 1
        while i >= 0:
            if equali_char(s[i], c):
                return i
            i -= 1
    else:
        for i in range(s.length()):
            if equali_char(s[i], c):
                return i
    return -1

def rindexi(s: std_string_view, t: std_string_view) -> int:
    return indexi(s, t, True)

def rindexi_char(s: std_string_view, t: char) -> int:
    return indexi_char(s, t, True)

def hasi(s: std_string_view, t: std_string_view) -> bool:
    return indexi(s, t) != -1

def hasi_char(s: std_string_view, t: char) -> bool:
    return indexi_char(s, t) != -1

def scan(s: std_string_view, t: std_string_view, last: bool = False) -> int:
    if last:
        return s.find_last_of(t)
    else:
        return s.find_first_of(t)

def scan_char(s: std_string_view, t: char, last: bool = False) -> int:
    if last:
        return s.find_last_of(t)
    else:
        return s.find_first_of(t)

def verify(s: std_string_view, t: std_string_view, last: bool = False) -> int:
    if last:
        return s.find_last_not_of(t)
    else:
        return s.find_first_not_of(t)

def verify_char(s: std_string_view, t: char, last: bool = False) -> int:
    if last:
        return s.find_last_not_of(t)
    else:
        return s.find_first_not_of(t)

def ichar(s: std_string_view) -> int:
    if not s.empty():
        return int(s[0])
    else:
        return 0

def uppercase_inplace(s: std_string) -> std_string:
    s_len = s.length()
    for i in range(s_len):
        s[i] = uppercase(s[i])
    return s

def trim(s: std_string) -> std_string:
    if not s.empty():
        ie = s.find_last_not_of(' ')
        if ie == -1:
            s.clear()
        elif ie + 1 < s.length():
            s.erase(ie + 1)
    return s

def strip_chars(s: std_string, chars: std_string) -> std_string:
    if not s.empty():
        ib = s.find_first_not_of(chars)
        ie = s.find_last_not_of(chars)
        if ib == -1 or ie == -1:
            s.clear()
        else:
            if ie < s.length() - 1:
                s.erase(ie + 1)
            if ib > 0:
                s.erase(0, ib)
    return s

def rstrip_chars(s: std_string, chars: std_string) -> std_string:
    if not s.empty():
        ie = s.find_last_not_of(chars)
        if ie == -1:
            s.clear()
        else:
            if ie < s.length() - 1:
                s.erase(ie + 1)
    return s

def strip(s: std_string) -> std_string:
    if not s.empty():
        ib = s.find_first_not_of(' ')
        ie = s.find_last_not_of(' ')
        if ib == -1 or ie == -1:
            s.clear()
        else:
            if ie < s.length() - 1:
                s.erase(ie + 1)
            if ib > 0:
                s.erase(0, ib)
    return s

def rstrip(s: std_string) -> std_string:
    if not s.empty():
        ie = s.find_last_not_of(' ')
        if ie == -1:
            s.clear()
        else:
            if ie < s.length() - 1:
                s.erase(ie + 1)
    return s

def pad(s: std_string, len: int) -> std_string:
    s_len = s.length()
    if s_len < len:
        s.append(len - s_len, ' ')
    return s

def pare(s: std_string, len: int) -> std_string:
    if s.length() > len:
        s.erase(len)
    return s

def size(s: std_string, len: int) -> std_string:
    s_len = s.length()
    if s_len < len:
        s.append(len - s_len, ' ')
    elif s_len > len:
        s.erase(len)
    return s

def center(s: std_string) -> std_string:
    s = centered(s, s.length())
    return s

def center_len(s: std_string, len: int) -> std_string:
    s = centered(s, len)
    return s

def unique(s: std_string) -> std_string:
    u = std_string()
    s_len = s.length()
    for i in range(s_len):
        if u.find(s[i]) == -1:
            u.push_back(s[i])
    s.swap(u)
    return s

def replace(s: std_string, a: std_string_view, b: std_string_view) -> std_string:
    la = a.length()
    lb = b.length()
    pos = 0
    while True:
        pos = s.find(a, pos)
        if pos == -1:
            break
        s.replace(pos, la, b)
        pos += lb
    return s

def quote(s: std_string) -> std_string:
    s = '"' + s + '"'
    return s

def overlay(s: std_string, t: std_string_view, pos: int = 0) -> std_string:
    t_len = t.length()
    l_len = pos + t_len
    if l_len > s.length():
        s.resize(l_len, ' ')
    s.replace(pos, t_len, t)
    return s

def blank(len: int) -> std_string:
    return std_string(len, ' ')

def uppercased(s: std_string_view) -> std_string:
    t = std_string(s)
    t_len = t.length()
    for i in range(t_len):
        t[i] = uppercase(t[i])
    return t

def ljustified(s: std_string_view) -> std_string:
    off = s.find_first_not_of(' ')
    if off > 0 and off != -1:
        return std_string(s.substr(off)) + std_string(off, ' ')
    else:
        return std_string(s)

def rjustified(s: std_string_view) -> std_string:
    s_len_trim = len_trim(s)
    off = s.length() - s_len_trim
    if off > 0:
        return std_string(off, ' ') + std_string(s.substr(0, s_len_trim))
    else:
        return std_string(s)

def trimmed(s: std_string_view) -> std_string:
    if s.empty():
        return std_string()
    else:
        ie = s.find_last_not_of(' ')
        if ie == -1:
            return std_string()
        elif ie < s.length() - 1:
            return std_string(s.substr(0, ie + 1))
        else:
            return std_string(s)

def _trimmed_whitespace_impl(s: std_string_view) -> std_string:
    WHITE = std_string_view(" \t\0", 3)
    if s.empty():
        return std_string()
    else:
        ie = s.find_last_not_of(WHITE)
        if ie == -1:
            return std_string()
        elif ie < s.length() - 1:
            return std_string(s.substr(0, ie + 1))
        else:
            return std_string(s)

def stripped_chars(s: std_string_view, chars: std_string_view) -> std_string:
    if s.empty():
        return std_string()
    else:
        ib = s.find_first_not_of(chars)
        ie = s.find_last_not_of(chars)
        if ib == -1 or ie == -1:
            return std_string()
        else:
            return std_string(s.substr(ib, ie - ib + 1))

def stripped(s: std_string_view) -> std_string:
    if s.empty():
        return std_string()
    else:
        ib = s.find_first_not_of(' ')
        ie = s.find_last_not_of(' ')
        if ib == -1 or ie == -1:
            return std_string()
        else:
            return std_string(s.substr(ib, ie - ib + 1))

def stripped_whitespace(s: std_string_view) -> std_string:
    WHITE = std_string_view(" \t\0", 3)
    if s.empty():
        return std_string()
    else:
        ib = s.find_first_not_of(WHITE)
        ie = s.find_last_not_of(WHITE)
        if ib == -1 or ie == -1:
            return std_string()
        else:
            return std_string(s.substr(ib, ie - ib + 1))

def sized(s: std_string_view, len: int) -> std_string:
    s_len = s.length()
    if s_len < len:
        return std_string(s) + std_string(len - s_len, ' ')
    elif s_len == len:
        return std_string(s)
    else:
        return std_string(s.substr(0, len))

def centered(s: std_string_view, len: int) -> std_string:
    t = stripped_whitespace(s)
    t_len = t.length()
    if t_len < len:
        off = (len - t_len) // 2
        return std_string(off, ' ') + t + std_string(len - t_len - off, ' ')
    elif t_len == len:
        return t
    else:
        off = (t_len - len) // 2
        return t.substr(off, len)

def centered_default(s: std_string_view) -> std_string:
    return centered(stripped_whitespace(s), s.length())

def replaced(s: std_string_view, a: std_string_view, b: std_string_view) -> std_string:
    r = std_string(s)
    replace(r, a, b)
    return r

def overlayed(s: std_string_view, t: std_string_view, pos: int = 0) -> std_string:
    r = std_string(s)
    overlay(r, t, pos)
    return r

def repeated(s: std_string_view, n: int) -> std_string:
    if n <= 0:
        return std_string()
    l = s.length()
    o = std_string()
    o.reserve(n * l)
    for i in range(n):
        o += s
    return o

def repeat(s: std_string_view, n: int) -> std_string:
    return repeated(s, n)

def head(s: std_string_view) -> std_string:
    if s.empty():
        return std_string()
    else:
        ie = s.find(' ')
        if ie == -1:
            return std_string(s)
        else:
            return std_string(s.substr(0, ie))

def operator_add(s: std_string, t: std_string) -> std_string:
    return std_string(s) + t

def operator_add_cstr(s: char*, t: std_string) -> std_string:
    return std_string(s) + t

def operator_add_str_cstr(s: std_string, t: char*) -> std_string:
    return s + std_string(t)