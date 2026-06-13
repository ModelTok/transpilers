from gtest.gtest-printers import *
from stdio import *
from cctype import *
from cstdint import *
from cwchar import *
from ostream import *
from string import *
from type_traits import *
from gtest.internal.gtest-port import *
from src.gtest-internal-inl import *

namespace testing:
    namespace:
        using ::ostream

        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_MEMORY_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_ADDRESS_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_HWADDRESS_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_THREAD_")
        def PrintByteSegmentInObjectTo(obj_bytes: Pointer[UInt8], start: size_t, count: size_t, os: ostream):
            var text: StaticString[5] = ""
            for i in range(count):
                let j: size_t = start + i
                if i != 0:
                    if (j % 2) == 0:
                        *os << ' '
                    else:
                        *os << '-'
                GTEST_SNPRINTF_(text, sizeof(text), "%02X", obj_bytes[j])
                *os << text

        def PrintBytesInObjectToImpl(obj_bytes: Pointer[UInt8], count: size_t, os: ostream):
            *os << count << "-byte object <"
            let kThreshold: size_t = 132
            let kChunkSize: size_t = 64
            if count < kThreshold:
                PrintByteSegmentInObjectTo(obj_bytes, 0, count, os)
            else:
                PrintByteSegmentInObjectTo(obj_bytes, 0, kChunkSize, os)
                *os << " ... "
                let resume_pos: size_t = (count - kChunkSize + 1) // 2 * 2
                PrintByteSegmentInObjectTo(obj_bytes, resume_pos, count - resume_pos, os)
            *os << ">"

        def ToChar32[CharType: AnyType](in: CharType) -> char32_t:
            return static_cast[char32_t](static_cast[make_unsigned[CharType].type](in))

    namespace internal:
        def PrintBytesInObjectTo(obj_bytes: Pointer[UInt8], count: size_t, os: ostream):
            PrintBytesInObjectToImpl(obj_bytes, count, os)

        enum CharFormat:
            kAsIs
            kHexEscape
            kSpecialEscape

        def IsPrintableAscii(c: char32_t) -> bool:
            return 0x20 <= c and c <= 0x7E

        def PrintAsCharLiteralTo[Char: AnyType](c: Char, os: ostream) -> CharFormat:
            let u_c: char32_t = ToChar32(c)
            switch u_c:
                case L'\0':
                    *os << "\\0"
                    break
                case L'\'':
                    *os << "\\'"
                    break
                case L'\\':
                    *os << "\\\\"
                    break
                case L'\a':
                    *os << "\\a"
                    break
                case L'\b':
                    *os << "\\b"
                    break
                case L'\f':
                    *os << "\\f"
                    break
                case L'\n':
                    *os << "\\n"
                    break
                case L'\r':
                    *os << "\\r"
                    break
                case L'\t':
                    *os << "\\t"
                    break
                case L'\v':
                    *os << "\\v"
                    break
                default:
                    if IsPrintableAscii(u_c):
                        *os << static_cast[char](c)
                        return CharFormat.kAsIs
                    else:
                        let flags: ostream.fmtflags = os.flags()
                        *os << "\\x" << std.hex << std.uppercase << static_cast[int](u_c)
                        os.flags(flags)
                        return CharFormat.kHexEscape
            return CharFormat.kSpecialEscape

        def PrintAsStringLiteralTo(c: char32_t, os: ostream) -> CharFormat:
            switch c:
                case L'\'':
                    *os << "'"
                    return CharFormat.kAsIs
                case L'"':
                    *os << "\\\""
                    return CharFormat.kSpecialEscape
                default:
                    return PrintAsCharLiteralTo(c, os)

        def GetCharWidthPrefix(c: char) -> StaticString[0]:
            return ""

        def GetCharWidthPrefix(c: signed char) -> StaticString[0]:
            return ""

        def GetCharWidthPrefix(c: unsigned char) -> StaticString[0]:
            return ""

        #ifdef __cpp_char8_t
        def GetCharWidthPrefix(c: char8_t) -> StaticString[2]:
            return "u8"
        #endif

        def GetCharWidthPrefix(c: char16_t) -> StaticString[1]:
            return "u"

        def GetCharWidthPrefix(c: char32_t) -> StaticString[1]:
            return "U"

        def GetCharWidthPrefix(c: wchar_t) -> StaticString[1]:
            return "L"

        def PrintAsStringLiteralTo(c: char, os: ostream) -> CharFormat:
            return PrintAsStringLiteralTo(ToChar32(c), os)

        #ifdef __cpp_char8_t
        def PrintAsStringLiteralTo(c: char8_t, os: ostream) -> CharFormat:
            return PrintAsStringLiteralTo(ToChar32(c), os)
        #endif

        def PrintAsStringLiteralTo(c: char16_t, os: ostream) -> CharFormat:
            return PrintAsStringLiteralTo(ToChar32(c), os)

        def PrintAsStringLiteralTo(c: wchar_t, os: ostream) -> CharFormat:
            return PrintAsStringLiteralTo(ToChar32(c), os)

        def PrintCharAndCodeTo[Char: AnyType](c: Char, os: ostream):
            *os << GetCharWidthPrefix(c) << "'"
            let format: CharFormat = PrintAsCharLiteralTo(c, os)
            *os << "'"
            if c == 0:
                return
            *os << " (" << static_cast[int](c)
            if format == CharFormat.kHexEscape or (1 <= c and c <= 9):

            else:
                *os << ", 0x" << String.FormatHexInt(static_cast[int](c))
            *os << ")"

        def PrintTo(c: unsigned char, os: ::std.ostream):
            PrintCharAndCodeTo(c, os)

        def PrintTo(c: signed char, os: ::std.ostream):
            PrintCharAndCodeTo(c, os)

        def PrintTo(wc: wchar_t, os: ostream):
            PrintCharAndCodeTo(wc, os)

        def PrintTo(c: char32_t, os: ::std.ostream):
            *os << std.hex << "U+" << std.uppercase << std.setfill('0') << std.setw(4) << static_cast[uint32_t](c)

        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_MEMORY_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_ADDRESS_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_HWADDRESS_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_THREAD_")
        def PrintCharsAsStringTo[CharType: AnyType](begin: Pointer[CharType], len: size_t, os: ostream) -> CharFormat:
            let quote_prefix: Pointer[char] = GetCharWidthPrefix(*begin)
            *os << quote_prefix << "\""
            var is_previous_hex: bool = False
            var print_format: CharFormat = CharFormat.kAsIs
            for index in range(len):
                let cur: CharType = begin[index]
                if is_previous_hex and IsXDigit(cur):
                    *os << "\" " << quote_prefix << "\""
                is_previous_hex = (PrintAsStringLiteralTo(cur, os) == CharFormat.kHexEscape)
                if is_previous_hex:
                    print_format = CharFormat.kHexEscape
            *os << "\""
            return print_format

        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_MEMORY_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_ADDRESS_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_HWADDRESS_")
        @attribute("GTEST_ATTRIBUTE_NO_SANITIZE_THREAD_")
        def UniversalPrintCharArray[CharType: AnyType](begin: Pointer[CharType], len: size_t, os: ostream):
            if len > 0 and begin[len - 1] == '\0':
                PrintCharsAsStringTo(begin, len - 1, os)
                return
            PrintCharsAsStringTo(begin, len, os)
            *os << " (no terminating NUL)"

        def UniversalPrintArray(begin: Pointer[char], len: size_t, os: ostream):
            UniversalPrintCharArray(begin, len, os)

        #ifdef __cpp_char8_t
        def UniversalPrintArray(begin: Pointer[char8_t], len: size_t, os: ostream):
            UniversalPrintCharArray(begin, len, os)
        #endif

        def UniversalPrintArray(begin: Pointer[char16_t], len: size_t, os: ostream):
            UniversalPrintCharArray(begin, len, os)

        def UniversalPrintArray(begin: Pointer[char32_t], len: size_t, os: ostream):
            UniversalPrintCharArray(begin, len, os)

        def UniversalPrintArray(begin: Pointer[wchar_t], len: size_t, os: ostream):
            UniversalPrintCharArray(begin, len, os)

        namespace:
            def PrintCStringTo[Char: AnyType](s: Pointer[Char], os: ostream):
                if s == None:
                    *os << "NULL"
                else:
                    *os << ImplicitCast_[Pointer[void]](s) << " pointing to "
                    PrintCharsAsStringTo(s, std.char_traits[Char].length(s), os)

        def PrintTo(s: Pointer[char], os: ostream):
            PrintCStringTo(s, os)

        #ifdef __cpp_char8_t
        def PrintTo(s: Pointer[char8_t], os: ostream):
            PrintCStringTo(s, os)
        #endif

        def PrintTo(s: Pointer[char16_t], os: ostream):
            PrintCStringTo(s, os)

        def PrintTo(s: Pointer[char32_t], os: ostream):
            PrintCStringTo(s, os)

        #if !defined(_MSC_VER) or defined(_NATIVE_WCHAR_T_DEFINED)
        def PrintTo(s: Pointer[wchar_t], os: ostream):
            PrintCStringTo(s, os)
        #endif

        namespace:
            def ContainsUnprintableControlCodes(str: Pointer[char], length: size_t) -> bool:
                let s: Pointer[unsigned char] = reinterpret_cast[Pointer[unsigned char]](str)
                for i in range(length):
                    let ch: unsigned char = *s
                    s += 1
                    if std.iscntrl(ch):
                        switch ch:
                            case '\t':
                            case '\n':
                            case '\r':
                                break
                            default:
                                return True
                return False

            def IsUTF8TrailByte(t: unsigned char) -> bool:
                return 0x80 <= t and t <= 0xbf

            def IsValidUTF8(str: Pointer[char], length: size_t) -> bool:
                let s: Pointer[unsigned char] = reinterpret_cast[Pointer[unsigned char]](str)
                var i: size_t = 0
                while i < length:
                    let lead: unsigned char = s[i]
                    i += 1
                    if lead <= 0x7f:
                        continue
                    if lead < 0xc2:
                        return False
                    elif lead <= 0xdf and (i + 1) <= length and IsUTF8TrailByte(s[i]):
                        i += 1
                    elif 0xe0 <= lead and lead <= 0xef and (i + 2) <= length and IsUTF8TrailByte(s[i]) and IsUTF8TrailByte(s[i + 1]) and (lead != 0xe0 or s[i] >= 0xa0) and (lead != 0xed or s[i] < 0xa0):
                        i += 2
                    elif 0xf0 <= lead and lead <= 0xf4 and (i + 3) <= length and IsUTF8TrailByte(s[i]) and IsUTF8TrailByte(s[i + 1]) and IsUTF8TrailByte(s[i + 2]) and (lead != 0xf0 or s[i] >= 0x90) and (lead != 0xf4 or s[i] < 0x90):
                        i += 3
                    else:
                        return False
                return True

            def ConditionalPrintAsText(str: Pointer[char], length: size_t, os: ostream):
                if not ContainsUnprintableControlCodes(str, length) and IsValidUTF8(str, length):
                    *os << "\n    As Text: \"" << str << "\""

        def PrintStringTo(s: ::std.string, os: ostream):
            if PrintCharsAsStringTo(s.data(), s.size(), os) == CharFormat.kHexEscape:
                if GTEST_FLAG(print_utf8):
                    ConditionalPrintAsText(s.data(), s.size(), os)

        #ifdef __cpp_char8_t
        def PrintU8StringTo(s: ::std.u8string, os: ostream):
            PrintCharsAsStringTo(s.data(), s.size(), os)
        #endif

        def PrintU16StringTo(s: ::std.u16string, os: ostream):
            PrintCharsAsStringTo(s.data(), s.size(), os)

        def PrintU32StringTo(s: ::std.u32string, os: ostream):
            PrintCharsAsStringTo(s.data(), s.size(), os)

        #if GTEST_HAS_STD_WSTRING
        def PrintWideStringTo(s: ::std.wstring, os: ostream):
            PrintCharsAsStringTo(s.data(), s.size(), os)
        #endif