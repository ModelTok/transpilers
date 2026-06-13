from json_tool import *
from json.writer import *
from memory import *
from set import *
from sstream import *
from utility import *
from math import *
from cstdio import *
from float import *

# if !defined(JSON_IS_AMALGAMATION)
# include "json_tool.h"
# include <json/writer.h>
# endif // if !defined(JSON_IS_AMALGAMATION)
# include <cassert>
# include <cstring>
# include <iomanip>
# include <memory>
# include <set>
# include <sstream>
# include <utility>
# if __cplusplus >= 201103L
# include <cmath>
# include <cstdio>
# if !defined(isnan)
# define isnan isnan
# endif
# if !defined(isfinite)
# define isfinite isfinite
# endif
# else
# include <cmath>
# include <cstdio>
# if defined(_MSC_VER)
# if !defined(isnan)
# include <float.h>
# define isnan _isnan
# endif
# if !defined(isfinite)
# include <float.h>
# define isfinite _finite
# endif
# if !defined(_CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES)
# define _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES 1
# endif //_CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES
# endif //_MSC_VER
# if defined(__sun) && defined(__SVR4) // Solaris
# if !defined(isfinite)
# include <ieeefp.h>
# define isfinite finite
# endif
# endif
# if defined(__hpux)
# if !defined(isfinite)
# if defined(__ia64) && !defined(finite)
# define isfinite(x)                                                            \
  ((sizeof(x) == sizeof(float) ? _Isfinitef(x) : _IsFinite(x)))
# endif
# endif
# endif
# if !defined(isnan)
# define isnan(x) (x != x)
# endif
# if !defined(__APPLE__)
# if !defined(isfinite)
# define isfinite finite
# endif
# endif
# endif
# if defined(_MSC_VER)
# pragma warning(disable : 4996)
# endif

namespace Json:

# if __cplusplus >= 201103L || (defined(_CPPLIB_VER) && _CPPLIB_VER >= 520)
    using StreamWriterPtr = unique_ptr<StreamWriter>;
# else
    using StreamWriterPtr = auto_ptr<StreamWriter>;
# endif

    def valueToString(value: LargestInt) -> String:
        var buffer: UIntToStringBuffer
        var current: Pointer[char] = buffer.data() + sizeof(buffer)
        if value == Value.minLargestInt:
            uintToString(LargestUInt(Value.maxLargestInt) + 1, current)
            current -= 1
            current[0] = '-'
        elif value < 0:
            uintToString(LargestUInt(-value), current)
            current -= 1
            current[0] = '-'
        else:
            uintToString(LargestUInt(value), current)
        assert(current >= buffer.data())
        return String(current)

    def valueToString(value: LargestUInt) -> String:
        var buffer: UIntToStringBuffer
        var current: Pointer[char] = buffer.data() + sizeof(buffer)
        uintToString(value, current)
        assert(current >= buffer.data())
        return String(current)

# if defined(JSON_HAS_INT64)
    def valueToString(value: Int) -> String:
        return valueToString(LargestInt(value))

    def valueToString(value: UInt) -> String:
        return valueToString(LargestUInt(value))
# endif // # if defined(JSON_HAS_INT64)

    @staticmethod
    def valueToString(value: double, useSpecialFloats: bool, precision: unsigned int, precisionType: PrecisionType) -> String:
        if not isfinite(value):
            var reps: StaticArray[StaticArray[Pointer[char], 3], 2] = StaticArray[StaticArray[Pointer[char], 3], 2](
                StaticArray[Pointer[char], 3]("NaN", "-Infinity", "Infinity"),
                StaticArray[Pointer[char], 3]("null", "-1e+9999", "1e+9999")
            )
            return String(reps[0 if useSpecialFloats else 1][0 if isnan(value) else (1 if value < 0 else 2)])
        var buffer: String = String(size_t(36), '\0')
        while True:
            var len: int = jsoncpp_snprintf(
                buffer.data(), buffer.size(),
                "%.*g" if precisionType == PrecisionType.significantDigits else "%.*f",
                precision, value)
            assert(len >= 0)
            var wouldPrint: size_t = size_t(len)
            if wouldPrint >= buffer.size():
                buffer.resize(wouldPrint + 1)
                continue
            buffer.resize(wouldPrint)
            break
        buffer.erase(fixNumericLocale(buffer.begin(), buffer.end()), buffer.end())
        if precisionType == PrecisionType.decimalPlaces:
            buffer.erase(fixZerosInTheEnd(buffer.begin(), buffer.end()), buffer.end())
        if buffer.find('.') == buffer.npos and buffer.find('e') == buffer.npos:
            buffer += ".0"
        return buffer

    def valueToString(value: double, precision: unsigned int, precisionType: PrecisionType) -> String:
        return valueToString(value, False, precision, precisionType)

    def valueToString(value: bool) -> String:
        return "true" if value else "false"

    def isAnyCharRequiredQuoting(s: Pointer[char], n: size_t) -> bool:
        assert(s or not n)
        var end: Pointer[char] = s + n
        var cur: Pointer[char] = s
        while cur < end:
            if cur[0] == '\\' or cur[0] == '\"' or unsigned char(cur[0]) < ' ' or unsigned char(cur[0]) >= 0x80:
                return True
            cur += 1
        return False

    def utf8ToCodepoint(s: Pointer[char], e: Pointer[char]) -> unsigned int:
        var REPLACEMENT_CHARACTER: unsigned int = 0xFFFD
        var firstByte: unsigned int = unsigned char(s[0])
        if firstByte < 0x80:
            return firstByte
        if firstByte < 0xE0:
            if e - s < 2:
                return REPLACEMENT_CHARACTER
            var calculated: unsigned int = ((firstByte & 0x1F) << 6) | (unsigned int(s[1]) & 0x3F)
            s += 1
            return REPLACEMENT_CHARACTER if calculated < 0x80 else calculated
        if firstByte < 0xF0:
            if e - s < 3:
                return REPLACEMENT_CHARACTER
            var calculated: unsigned int = ((firstByte & 0x0F) << 12) | ((unsigned int(s[1]) & 0x3F) << 6) | (unsigned int(s[2]) & 0x3F)
            s += 2
            if calculated >= 0xD800 and calculated <= 0xDFFF:
                return REPLACEMENT_CHARACTER
            return REPLACEMENT_CHARACTER if calculated < 0x800 else calculated
        if firstByte < 0xF8:
            if e - s < 4:
                return REPLACEMENT_CHARACTER
            var calculated: unsigned int = ((firstByte & 0x07) << 18) | ((unsigned int(s[1]) & 0x3F) << 12) | ((unsigned int(s[2]) & 0x3F) << 6) | (unsigned int(s[3]) & 0x3F)
            s += 3
            return REPLACEMENT_CHARACTER if calculated < 0x10000 else calculated
        return REPLACEMENT_CHARACTER

    var hex2: StaticArray[char, 256] = StaticArray[char, 256](
        '0', '0', '0', '1', '0', '2', '0', '3', '0', '4', '0', '5', '0', '6', '0', '7',
        '0', '8', '0', '9', '0', 'a', '0', 'b', '0', 'c', '0', 'd', '0', 'e', '0', 'f',
        '1', '0', '1', '1', '1', '2', '1', '3', '1', '4', '1', '5', '1', '6', '1', '7',
        '1', '8', '1', '9', '1', 'a', '1', 'b', '1', 'c', '1', 'd', '1', 'e', '1', 'f',
        '2', '0', '2', '1', '2', '2', '2', '3', '2', '4', '2', '5', '2', '6', '2', '7',
        '2', '8', '2', '9', '2', 'a', '2', 'b', '2', 'c', '2', 'd', '2', 'e', '2', 'f',
        '3', '0', '3', '1', '3', '2', '3', '3', '3', '4', '3', '5', '3', '6', '3', '7',
        '3', '8', '3', '9', '3', 'a', '3', 'b', '3', 'c', '3', 'd', '3', 'e', '3', 'f',
        '4', '0', '4', '1', '4', '2', '4', '3', '4', '4', '4', '5', '4', '6', '4', '7',
        '4', '8', '4', '9', '4', 'a', '4', 'b', '4', 'c', '4', 'd', '4', 'e', '4', 'f',
        '5', '0', '5', '1', '5', '2', '5', '3', '5', '4', '5', '5', '5', '6', '5', '7',
        '5', '8', '5', '9', '5', 'a', '5', 'b', '5', 'c', '5', 'd', '5', 'e', '5', 'f',
        '6', '0', '6', '1', '6', '2', '6', '3', '6', '4', '6', '5', '6', '6', '6', '7',
        '6', '8', '6', '9', '6', 'a', '6', 'b', '6', 'c', '6', 'd', '6', 'e', '6', 'f',
        '7', '0', '7', '1', '7', '2', '7', '3', '7', '4', '7', '5', '7', '6', '7', '7',
        '7', '8', '7', '9', '7', 'a', '7', 'b', '7', 'c', '7', 'd', '7', 'e', '7', 'f',
        '8', '0', '8', '1', '8', '2', '8', '3', '8', '4', '8', '5', '8', '6', '8', '7',
        '8', '8', '8', '9', '8', 'a', '8', 'b', '8', 'c', '8', 'd', '8', 'e', '8', 'f',
        '9', '0', '9', '1', '9', '2', '9', '3', '9', '4', '9', '5', '9', '6', '9', '7',
        '9', '8', '9', '9', '9', 'a', '9', 'b', '9', 'c', '9', 'd', '9', 'e', '9', 'f',
        'a', '0', 'a', '1', 'a', '2', 'a', '3', 'a', '4', 'a', '5', 'a', '6', 'a', '7',
        'a', '8', 'a', '9', 'a', 'a', 'a', 'b', 'a', 'c', 'a', 'd', 'a', 'e', 'a', 'f',
        'b', '0', 'b', '1', 'b', '2', 'b', '3', 'b', '4', 'b', '5', 'b', '6', 'b', '7',
        'b', '8', 'b', '9', 'b', 'a', 'b', 'b', 'b', 'c', 'b', 'd', 'b', 'e', 'b', 'f',
        'c', '0', 'c', '1', 'c', '2', 'c', '3', 'c', '4', 'c', '5', 'c', '6', 'c', '7',
        'c', '8', 'c', '9', 'c', 'a', 'c', 'b', 'c', 'c', 'c', 'd', 'c', 'e', 'c', 'f',
        'd', '0', 'd', '1', 'd', '2', 'd', '3', 'd', '4', 'd', '5', 'd', '6', 'd', '7',
        'd', '8', 'd', '9', 'd', 'a', 'd', 'b', 'd', 'c', 'd', 'd', 'd', 'e', 'd', 'f',
        'e', '0', 'e', '1', 'e', '2', 'e', '3', 'e', '4', 'e', '5', 'e', '6', 'e', '7',
        'e', '8', 'e', '9', 'e', 'a', 'e', 'b', 'e', 'c', 'e', 'd', 'e', 'e', 'e', 'f',
        'f', '0', 'f', '1', 'f', '2', 'f', '3', 'f', '4', 'f', '5', 'f', '6', 'f', '7',
        'f', '8', 'f', '9', 'f', 'a', 'f', 'b', 'f', 'c', 'f', 'd', 'f', 'e', 'f', 'f'
    )

    def toHex16Bit(x: unsigned int) -> String:
        var hi: unsigned int = (x >> 8) & 0xff
        var lo: unsigned int = x & 0xff
        var result: String = String(4, ' ')
        result[0] = hex2[2 * hi]
        result[1] = hex2[2 * hi + 1]
        result[2] = hex2[2 * lo]
        result[3] = hex2[2 * lo + 1]
        return result

    def valueToQuotedStringN(value: Pointer[char], length: unsigned int, emitUTF8: bool = False) -> String:
        if value == None:
            return ""
        if not isAnyCharRequiredQuoting(value, length):
            return String("\"") + String(value) + "\""
        var maxsize: String.size_type = length * 2 + 3
        var result: String = String()
        result.reserve(maxsize)
        result += "\""
        var end: Pointer[char] = value + length
        var c: Pointer[char] = value
        while c != end:
            if c[0] == '\"':
                result += "\\\""
            elif c[0] == '\\':
                result += "\\\\"
            elif c[0] == '\b':
                result += "\\b"
            elif c[0] == '\f':
                result += "\\f"
            elif c[0] == '\n':
                result += "\\n"
            elif c[0] == '\r':
                result += "\\r"
            elif c[0] == '\t':
                result += "\\t"
            else:
                if emitUTF8:
                    result += c[0]
                else:
                    var codepoint: unsigned int = utf8ToCodepoint(c, end)
                    var FIRST_NON_CONTROL_CODEPOINT: unsigned int = 0x20
                    var LAST_NON_CONTROL_CODEPOINT: unsigned int = 0x7F
                    var FIRST_SURROGATE_PAIR_CODEPOINT: unsigned int = 0x10000
                    if FIRST_NON_CONTROL_CODEPOINT <= codepoint and codepoint <= LAST_NON_CONTROL_CODEPOINT:
                        result += char(codepoint)
                    elif codepoint < FIRST_SURROGATE_PAIR_CODEPOINT:
                        result += "\\u"
                        result += toHex16Bit(codepoint)
                    else:
                        codepoint -= FIRST_SURROGATE_PAIR_CODEPOINT
                        result += "\\u"
                        result += toHex16Bit((codepoint >> 10) + 0xD800)
                        result += "\\u"
                        result += toHex16Bit((codepoint & 0x3FF) + 0xDC00)
            c += 1
        result += "\""
        return result

    def valueToQuotedString(value: Pointer[char]) -> String:
        return valueToQuotedStringN(value, unsigned int(strlen(value)))

    @value
    struct Writer:
        def __del__(owned self):

    @value
    struct FastWriter:
        var yamlCompatibilityEnabled_: bool
        var dropNullPlaceholders_: bool
        var omitEndingLineFeed_: bool
        var document_: String

        def __init__(inout self):
            self.yamlCompatibilityEnabled_ = False
            self.dropNullPlaceholders_ = False
            self.omitEndingLineFeed_ = False
            self.document_ = String()

        def enableYAMLCompatibility(inout self):
            self.yamlCompatibilityEnabled_ = True

        def dropNullPlaceholders(inout self):
            self.dropNullPlaceholders_ = True

        def omitEndingLineFeed(inout self):
            self.omitEndingLineFeed_ = True

        def write(inout self, root: Value) -> String:
            self.document_.clear()
            self.writeValue(root)
            if not self.omitEndingLineFeed_:
                self.document_ += '\n'
            return self.document_

        def writeValue(inout self, value: Value):
            if value.type() == nullValue:
                if not self.dropNullPlaceholders_:
                    self.document_ += "null"
            elif value.type() == intValue:
                self.document_ += valueToString(value.asLargestInt())
            elif value.type() == uintValue:
                self.document_ += valueToString(value.asLargestUInt())
            elif value.type() == realValue:
                self.document_ += valueToString(value.asDouble())
            elif value.type() == stringValue:
                var str: Pointer[char]
                var end: Pointer[char]
                var ok: bool = value.getString(str, end)
                if ok:
                    self.document_ += valueToQuotedStringN(str, unsigned(end - str))
            elif value.type() == booleanValue:
                self.document_ += valueToString(value.asBool())
            elif value.type() == arrayValue:
                self.document_ += '['
                var size: ArrayIndex = value.size()
                var index: ArrayIndex = 0
                while index < size:
                    if index > 0:
                        self.document_ += ','
                    self.writeValue(value[index])
                    index += 1
                self.document_ += ']'
            elif value.type() == objectValue:
                var members: Value.Members = value.getMemberNames()
                self.document_ += '{'
                var it: Value.Members.Iterator = members.begin()
                while it != members.end():
                    var name: String = it[]
                    if it != members.begin():
                        self.document_ += ','
                    self.document_ += valueToQuotedStringN(name.data(), unsigned(name.length()))
                    self.document_ += ": " if self.yamlCompatibilityEnabled_ else ":"
                    self.writeValue(value[name])
                    it += 1
                self.document_ += '}'

    @value
    struct StyledWriter:
        var rightMargin_: unsigned int
        var document_: String
        var childValues_: List[String]
        var addChildValues_: bool
        var indentString_: String

        def __init__(inout self):
            self.rightMargin_ = 74
            self.document_ = String()
            self.childValues_ = List[String]()
            self.addChildValues_ = False
            self.indentString_ = String()

        def write(inout self, root: Value) -> String:
            self.document_.clear()
            self.addChildValues_ = False
            self.indentString_.clear()
            self.writeCommentBeforeValue(root)
            self.writeValue(root)
            self.writeCommentAfterValueOnSameLine(root)
            self.document_ += '\n'
            return self.document_

        def writeValue(inout self, value: Value):
            if value.type() == nullValue:
                self.pushValue("null")
            elif value.type() == intValue:
                self.pushValue(valueToString(value.asLargestInt()))
            elif value.type() == uintValue:
                self.pushValue(valueToString(value.asLargestUInt()))
            elif value.type() == realValue:
                self.pushValue(valueToString(value.asDouble()))
            elif value.type() == stringValue:
                var str: Pointer[char]
                var end: Pointer[char]
                var ok: bool = value.getString(str, end)
                if ok:
                    self.pushValue(valueToQuotedStringN(str, unsigned(end - str)))
                else:
                    self.pushValue("")
            elif value.type() == booleanValue:
                self.pushValue(valueToString(value.asBool()))
            elif value.type() == arrayValue:
                self.writeArrayValue(value)
            elif value.type() == objectValue:
                var members: Value.Members = value.getMemberNames()
                if members.empty():
                    self.pushValue("{}")
                else:
                    self.writeWithIndent("{")
                    self.indent()
                    var it: Value.Members.Iterator = members.begin()
                    while True:
                        var name: String = it[]
                        var childValue: Value = value[name]
                        self.writeCommentBeforeValue(childValue)
                        self.writeWithIndent(valueToQuotedString(name.c_str()))
                        self.document_ += " : "
                        self.writeValue(childValue)
                        it += 1
                        if it == members.end():
                            self.writeCommentAfterValueOnSameLine(childValue)
                            break
                        self.document_ += ','
                        self.writeCommentAfterValueOnSameLine(childValue)
                    self.unindent()
                    self.writeWithIndent("}")

        def writeArrayValue(inout self, value: Value):
            var size: unsigned int = value.size()
            if size == 0:
                self.pushValue("[]")
            else:
                var isArrayMultiLine: bool = self.isMultilineArray(value)
                if isArrayMultiLine:
                    self.writeWithIndent("[")
                    self.indent()
                    var hasChildValue: bool = not self.childValues_.empty()
                    var index: unsigned int = 0
                    while True:
                        var childValue: Value = value[index]
                        self.writeCommentBeforeValue(childValue)
                        if hasChildValue:
                            self.writeWithIndent(self.childValues_[index])
                        else:
                            self.writeIndent()
                            self.writeValue(childValue)
                        index += 1
                        if index == size:
                            self.writeCommentAfterValueOnSameLine(childValue)
                            break
                        self.document_ += ','
                        self.writeCommentAfterValueOnSameLine(childValue)
                    self.unindent()
                    self.writeWithIndent("]")
                else:
                    assert(self.childValues_.size() == size)
                    self.document_ += "[ "
                    var index: unsigned int = 0
                    while index < size:
                        if index > 0:
                            self.document_ += ", "
                        self.document_ += self.childValues_[index]
                        index += 1
                    self.document_ += " ]"

        def isMultilineArray(inout self, value: Value) -> bool:
            var size: ArrayIndex = value.size()
            var isMultiLine: bool = size * 3 >= self.rightMargin_
            self.childValues_.clear()
            var index: ArrayIndex = 0
            while index < size and not isMultiLine:
                var childValue: Value = value[index]
                isMultiLine = (childValue.isArray() or childValue.isObject()) and not childValue.empty()
                index += 1
            if not isMultiLine:
                self.childValues_.reserve(size)
                self.addChildValues_ = True
                var lineLength: ArrayIndex = 4 + (size - 1) * 2
                index = 0
                while index < size:
                    if self.hasCommentForValue(value[index]):
                        isMultiLine = True
                    self.writeValue(value[index])
                    lineLength += ArrayIndex(self.childValues_[index].length())
                    index += 1
                self.addChildValues_ = False
                isMultiLine = isMultiLine or lineLength >= self.rightMargin_
            return isMultiLine

        def pushValue(inout self, value: String):
            if self.addChildValues_:
                self.childValues_.push_back(value)
            else:
                self.document_ += value

        def writeIndent(inout self):
            if not self.document_.empty():
                var last: char = self.document_[self.document_.length() - 1]
                if last == ' ':
                    return
                if last != '\n':
                    self.document_ += '\n'
            self.document_ += self.indentString_

        def writeWithIndent(inout self, value: String):
            self.writeIndent()
            self.document_ += value

        def indent(inout self):
            self.indentString_ += String(self.indentSize_, ' ')

        def unindent(inout self):
            assert(self.indentString_.size() >= self.indentSize_)
            self.indentString_.resize(self.indentString_.size() - self.indentSize_)

        def writeCommentBeforeValue(inout self, root: Value):
            if not root.hasComment(commentBefore):
                return
            self.document_ += '\n'
            self.writeIndent()
            var comment: String = root.getComment(commentBefore)
            var iter: String.Iterator = comment.begin()
            while iter != comment.end():
                self.document_ += iter[]
                if iter[] == '\n' and ((iter + 1) != comment.end() and (iter + 1)[] == '/'):
                    self.writeIndent()
                iter += 1
            self.document_ += '\n'

        def writeCommentAfterValueOnSameLine(inout self, root: Value):
            if root.hasComment(commentAfterOnSameLine):
                self.document_ += " " + root.getComment(commentAfterOnSameLine)
            if root.hasComment(commentAfter):
                self.document_ += '\n'
                self.document_ += root.getComment(commentAfter)
                self.document_ += '\n'

        def hasCommentForValue(value: Value) -> bool:
            return value.hasComment(commentBefore) or value.hasComment(commentAfterOnSameLine) or value.hasComment(commentAfter)

    @value
    struct StyledStreamWriter:
        var document_: Pointer[OStream]
        var indentation_: String
        var addChildValues_: bool
        var indented_: bool
        var childValues_: List[String]
        var indentString_: String
        var rightMargin_: unsigned int

        def __init__(inout self, indentation: String):
            self.document_ = None
            self.indentation_ = indentation
            self.addChildValues_ = False
            self.indented_ = False
            self.childValues_ = List[String]()
            self.indentString_ = String()
            self.rightMargin_ = 74

        def write(inout self, out: OStream, root: Value):
            self.document_ = out
            self.addChildValues_ = False
            self.indentString_.clear()
            self.indented_ = True
            self.writeCommentBeforeValue(root)
            if not self.indented_:
                self.writeIndent()
            self.indented_ = True
            self.writeValue(root)
            self.writeCommentAfterValueOnSameLine(root)
            self.document_ << "\n"
            self.document_ = None

        def writeValue(inout self, value: Value):
            if value.type() == nullValue:
                self.pushValue("null")
            elif value.type() == intValue:
                self.pushValue(valueToString(value.asLargestInt()))
            elif value.type() == uintValue:
                self.pushValue(valueToString(value.asLargestUInt()))
            elif value.type() == realValue:
                self.pushValue(valueToString(value.asDouble()))
            elif value.type() == stringValue:
                var str: Pointer[char]
                var end: Pointer[char]
                var ok: bool = value.getString(str, end)
                if ok:
                    self.pushValue(valueToQuotedStringN(str, unsigned(end - str)))
                else:
                    self.pushValue("")
            elif value.type() == booleanValue:
                self.pushValue(valueToString(value.asBool()))
            elif value.type() == arrayValue:
                self.writeArrayValue(value)
            elif value.type() == objectValue:
                var members: Value.Members = value.getMemberNames()
                if members.empty():
                    self.pushValue("{}")
                else:
                    self.writeWithIndent("{")
                    self.indent()
                    var it: Value.Members.Iterator = members.begin()
                    while True:
                        var name: String = it[]
                        var childValue: Value = value[name]
                        self.writeCommentBeforeValue(childValue)
                        self.writeWithIndent(valueToQuotedString(name.c_str()))
                        self.document_ << " : "
                        self.writeValue(childValue)
                        it += 1
                        if it == members.end():
                            self.writeCommentAfterValueOnSameLine(childValue)
                            break
                        self.document_ << ","
                        self.writeCommentAfterValueOnSameLine(childValue)
                    self.unindent()
                    self.writeWithIndent("}")

        def writeArrayValue(inout self, value: Value):
            var size: unsigned int = value.size()
            if size == 0:
                self.pushValue("[]")
            else:
                var isArrayMultiLine: bool = self.isMultilineArray(value)
                if isArrayMultiLine:
                    self.writeWithIndent("[")
                    self.indent()
                    var hasChildValue: bool = not self.childValues_.empty()
                    var index: unsigned int = 0
                    while True:
                        var childValue: Value = value[index]
                        self.writeCommentBeforeValue(childValue)
                        if hasChildValue:
                            self.writeWithIndent(self.childValues_[index])
                        else:
                            if not self.indented_:
                                self.writeIndent()
                            self.indented_ = True
                            self.writeValue(childValue)
                            self.indented_ = False
                        index += 1
                        if index == size:
                            self.writeCommentAfterValueOnSameLine(childValue)
                            break
                        self.document_ << ","
                        self.writeCommentAfterValueOnSameLine(childValue)
                    self.unindent()
                    self.writeWithIndent("]")
                else:
                    assert(self.childValues_.size() == size)
                    self.document_ << "[ "
                    var index: unsigned int = 0
                    while index < size:
                        if index > 0:
                            self.document_ << ", "
                        self.document_ << self.childValues_[index]
                        index += 1
                    self.document_ << " ]"

        def isMultilineArray(inout self, value: Value) -> bool:
            var size: ArrayIndex = value.size()
            var isMultiLine: bool = size * 3 >= self.rightMargin_
            self.childValues_.clear()
            var index: ArrayIndex = 0
            while index < size and not isMultiLine:
                var childValue: Value = value[index]
                isMultiLine = (childValue.isArray() or childValue.isObject()) and not childValue.empty()
                index += 1
            if not isMultiLine:
                self.childValues_.reserve(size)
                self.addChildValues_ = True
                var lineLength: ArrayIndex = 4 + (size - 1) * 2
                index = 0
                while index < size:
                    if self.hasCommentForValue(value[index]):
                        isMultiLine = True
                    self.writeValue(value[index])
                    lineLength += ArrayIndex(self.childValues_[index].length())
                    index += 1
                self.addChildValues_ = False
                isMultiLine = isMultiLine or lineLength >= self.rightMargin_
            return isMultiLine

        def pushValue(inout self, value: String):
            if self.addChildValues_:
                self.childValues_.push_back(value)
            else:
                self.document_ << value

        def writeIndent(inout self):
            self.document_ << '\n' << self.indentString_

        def writeWithIndent(inout self, value: String):
            if not self.indented_:
                self.writeIndent()
            self.document_ << value
            self.indented_ = False

        def indent(inout self):
            self.indentString_ += self.indentation_

        def unindent(inout self):
            assert(self.indentString_.size() >= self.indentation_.size())
            self.indentString_.resize(self.indentString_.size() - self.indentation_.size())

        def writeCommentBeforeValue(inout self, root: Value):
            if not root.hasComment(commentBefore):
                return
            if not self.indented_:
                self.writeIndent()
            var comment: String = root.getComment(commentBefore)
            var iter: String.Iterator = comment.begin()
            while iter != comment.end():
                self.document_ << iter[]
                if iter[] == '\n' and ((iter + 1) != comment.end() and (iter + 1)[] == '/'):
                    self.document_ << self.indentString_
                iter += 1
            self.indented_ = False

        def writeCommentAfterValueOnSameLine(inout self, root: Value):
            if root.hasComment(commentAfterOnSameLine):
                self.document_ << ' ' << root.getComment(commentAfterOnSameLine)
            if root.hasComment(commentAfter):
                self.writeIndent()
                self.document_ << root.getComment(commentAfter)
            self.indented_ = False

        def hasCommentForValue(value: Value) -> bool:
            return value.hasComment(commentBefore) or value.hasComment(commentAfterOnSameLine) or value.hasComment(commentAfter)

    @value
    struct CommentStyle:
        enum Enum:
            None
            Most
            All

    @value
    struct BuiltStyledStreamWriter(StreamWriter):
        var childValues_: List[String]
        var indentString_: String
        var rightMargin_: unsigned int
        var indentation_: String
        var cs_: CommentStyle.Enum
        var colonSymbol_: String
        var nullSymbol_: String
        var endingLineFeedSymbol_: String
        var addChildValues_: bool
        var indented_: bool
        var useSpecialFloats_: bool
        var emitUTF8_: bool
        var precision_: unsigned int
        var precisionType_: PrecisionType

        def __init__(inout self, indentation: String, cs: CommentStyle.Enum, colonSymbol: String, nullSymbol: String, endingLineFeedSymbol: String, useSpecialFloats: bool, emitUTF8: bool, precision: unsigned int, precisionType: PrecisionType):
            self.rightMargin_ = 74
            self.indentation_ = indentation
            self.cs_ = cs
            self.colonSymbol_ = colonSymbol
            self.nullSymbol_ = nullSymbol
            self.endingLineFeedSymbol_ = endingLineFeedSymbol
            self.addChildValues_ = False
            self.indented_ = False
            self.useSpecialFloats_ = useSpecialFloats
            self.emitUTF8_ = emitUTF8
            self.precision_ = precision
            self.precisionType_ = precisionType
            self.childValues_ = List[String]()
            self.indentString_ = String()

        def write(inout self, root: Value, sout: OStream) -> int:
            self.sout_ = sout
            self.addChildValues_ = False
            self.indented_ = True
            self.indentString_.clear()
            self.writeCommentBeforeValue(root)
            if not self.indented_:
                self.writeIndent()
            self.indented_ = True
            self.writeValue(root)
            self.writeCommentAfterValueOnSameLine(root)
            self.sout_ << self.endingLineFeedSymbol_
            self.sout_ = None
            return 0

        def writeValue(inout self, value: Value):
            if value.type() == nullValue:
                self.pushValue(self.nullSymbol_)
            elif value.type() == intValue:
                self.pushValue(valueToString(value.asLargestInt()))
            elif value.type() == uintValue:
                self.pushValue(valueToString(value.asLargestUInt()))
            elif value.type() == realValue:
                self.pushValue(valueToString(value.asDouble(), self.useSpecialFloats_, self.precision_, self.precisionType_))
            elif value.type() == stringValue:
                var str: Pointer[char]
                var end: Pointer[char]
                var ok: bool = value.getString(str, end)
                if ok:
                    self.pushValue(valueToQuotedStringN(str, unsigned(end - str), self.emitUTF8_))
                else:
                    self.pushValue("")
            elif value.type() == booleanValue:
                self.pushValue(valueToString(value.asBool()))
            elif value.type() == arrayValue:
                self.writeArrayValue(value)
            elif value.type() == objectValue:
                var members: Value.Members = value.getMemberNames()
                if members.empty():
                    self.pushValue("{}")
                else:
                    self.writeWithIndent("{")
                    self.indent()
                    var it: Value.Members.Iterator = members.begin()
                    while True:
                        var name: String = it[]
                        var childValue: Value = value[name]
                        self.writeCommentBeforeValue(childValue)
                        self.writeWithIndent(valueToQuotedStringN(name.data(), unsigned(name.length()), self.emitUTF8_))
                        self.sout_ << self.colonSymbol_
                        self.writeValue(childValue)
                        it += 1
                        if it == members.end():
                            self.writeCommentAfterValueOnSameLine(childValue)
                            break
                        self.sout_ << ","
                        self.writeCommentAfterValueOnSameLine(childValue)
                    self.unindent()
                    self.writeWithIndent("}")

        def writeArrayValue(inout self, value: Value):
            var size: unsigned int = value.size()
            if size == 0:
                self.pushValue("[]")
            else:
                var isMultiLine: bool = (self.cs_ == CommentStyle.Enum.All) or self.isMultilineArray(value)
                if isMultiLine:
                    self.writeWithIndent("[")
                    self.indent()
                    var hasChildValue: bool = not self.childValues_.empty()
                    var index: unsigned int = 0
                    while True:
                        var childValue: Value = value[index]
                        self.writeCommentBeforeValue(childValue)
                        if hasChildValue:
                            self.writeWithIndent(self.childValues_[index])
                        else:
                            if not self.indented_:
                                self.writeIndent()
                            self.indented_ = True
                            self.writeValue(childValue)
                            self.indented_ = False
                        index += 1
                        if index == size:
                            self.writeCommentAfterValueOnSameLine(childValue)
                            break
                        self.sout_ << ","
                        self.writeCommentAfterValueOnSameLine(childValue)
                    self.unindent()
                    self.writeWithIndent("]")
                else:
                    assert(self.childValues_.size() == size)
                    self.sout_ << "["
                    if not self.indentation_.empty():
                        self.sout_ << " "
                    var index: unsigned int = 0
                    while index < size:
                        if index > 0:
                            self.sout_ << (", " if not self.indentation_.empty() else ",")
                        self.sout_ << self.childValues_[index]
                        index += 1
                    if not self.indentation_.empty():
                        self.sout_ << " "
                    self.sout_ << "]"

        def isMultilineArray(inout self, value: Value) -> bool:
            var size: ArrayIndex = value.size()
            var isMultiLine: bool = size * 3 >= self.rightMargin_
            self.childValues_.clear()
            var index: ArrayIndex = 0
            while index < size and not isMultiLine:
                var childValue: Value = value[index]
                isMultiLine = (childValue.isArray() or childValue.isObject()) and not childValue.empty()
                index += 1
            if not isMultiLine:
                self.childValues_.reserve(size)
                self.addChildValues_ = True
                var lineLength: ArrayIndex = 4 + (size - 1) * 2
                index = 0
                while index < size:
                    if self.hasCommentForValue(value[index]):
                        isMultiLine = True
                    self.writeValue(value[index])
                    lineLength += ArrayIndex(self.childValues_[index].length())
                    index += 1
                self.addChildValues_ = False
                isMultiLine = isMultiLine or lineLength >= self.rightMargin_
            return isMultiLine

        def pushValue(inout self, value: String):
            if self.addChildValues_:
                self.childValues_.push_back(value)
            else:
                self.sout_ << value

        def writeIndent(inout self):
            if not self.indentation_.empty():
                self.sout_ << '\n' << self.indentString_

        def writeWithIndent(inout self, value: String):
            if not self.indented_:
                self.writeIndent()
            self.sout_ << value
            self.indented_ = False

        def indent(inout self):
            self.indentString_ += self.indentation_

        def unindent(inout self):
            assert(self.indentString_.size() >= self.indentation_.size())
            self.indentString_.resize(self.indentString_.size() - self.indentation_.size())

        def writeCommentBeforeValue(inout self, root: Value):
            if self.cs_ == CommentStyle.Enum.None:
                return
            if not root.hasComment(commentBefore):
                return
            if not self.indented_:
                self.writeIndent()
            var comment: String = root.getComment(commentBefore)
            var iter: String.Iterator = comment.begin()
            while iter != comment.end():
                self.sout_ << iter[]
                if iter[] == '\n' and ((iter + 1) != comment.end() and (iter + 1)[] == '/'):
                    self.sout_ << self.indentString_
                iter += 1
            self.indented_ = False

        def writeCommentAfterValueOnSameLine(inout self, root: Value):
            if self.cs_ == CommentStyle.Enum.None:
                return
            if root.hasComment(commentAfterOnSameLine):
                self.sout_ << " " + root.getComment(commentAfterOnSameLine)
            if root.hasComment(commentAfter):
                self.writeIndent()
                self.sout_ << root.getComment(commentAfter)

        def hasCommentForValue(value: Value) -> bool:
            return value.hasComment(commentBefore) or value.hasComment(commentAfterOnSameLine) or value.hasComment(commentAfter)

    @value
    struct StreamWriter:
        var sout_: Pointer[OStream]

        def __init__(inout self):
            self.sout_ = None

        def __del__(owned self):

        @value
        struct Factory:
            def __del__(owned self):

    @value
    struct StreamWriterBuilder:
        var settings_: Value

        def __init__(inout self):
            self.settings_ = Value()
            self.setDefaults(self.settings_)

        def __del__(owned self):

        def newStreamWriter(inout self) -> StreamWriterPtr:
            var indentation: String = self.settings_["indentation"].asString()
            var cs_str: String = self.settings_["commentStyle"].asString()
            var pt_str: String = self.settings_["precisionType"].asString()
            var eyc: bool = self.settings_["enableYAMLCompatibility"].asBool()
            var dnp: bool = self.settings_["dropNullPlaceholders"].asBool()
            var usf: bool = self.settings_["useSpecialFloats"].asBool()
            var emitUTF8: bool = self.settings_["emitUTF8"].asBool()
            var pre: unsigned int = self.settings_["precision"].asUInt()
            var cs: CommentStyle.Enum = CommentStyle.Enum.All
            if cs_str == "All":
                cs = CommentStyle.Enum.All
            elif cs_str == "None":
                cs = CommentStyle.Enum.None
            else:
                throwRuntimeError("commentStyle must be 'All' or 'None'")
            var precisionType: PrecisionType = PrecisionType.significantDigits
            if pt_str == "significant":
                precisionType = PrecisionType.significantDigits
            elif pt_str == "decimal":
                precisionType = PrecisionType.decimalPlaces
            else:
                throwRuntimeError("precisionType must be 'significant' or 'decimal'")
            var colonSymbol: String = " : "
            if eyc:
                colonSymbol = ": "
            elif indentation.empty():
                colonSymbol = ":"
            var nullSymbol: String = "null"
            if dnp:
                nullSymbol.clear()
            if pre > 17:
                pre = 17
            var endingLineFeedSymbol: String = String()
            return StreamWriterPtr(BuiltStyledStreamWriter(indentation, cs, colonSymbol, nullSymbol, endingLineFeedSymbol, usf, emitUTF8, pre, precisionType))

        def validate(inout self, invalid: Pointer[Value]) -> bool:
            var my_invalid: Value = Value()
            if invalid == None:
                invalid = my_invalid
            var inv: Value = invalid[]
            var valid_keys: Set[String] = Set[String]()
            getValidWriterKeys(valid_keys)
            var keys: Value.Members = self.settings_.getMemberNames()
            var n: size_t = keys.size()
            var i: size_t = 0
            while i < n:
                var key: String = keys[i]
                if valid_keys.find(key) == valid_keys.end():
                    inv[key] = self.settings_[key]
                i += 1
            return inv.empty()

        def __getitem__(inout self, key: String) -> Value:
            return self.settings_[key]

        def setDefaults(inout self, settings: Pointer[Value]):
            settings[]["commentStyle"] = "All"
            settings[]["indentation"] = "\t"
            settings[]["enableYAMLCompatibility"] = False
            settings[]["dropNullPlaceholders"] = False
            settings[]["useSpecialFloats"] = False
            settings[]["emitUTF8"] = False
            settings[]["precision"] = 17
            settings[]["precisionType"] = "significant"

    def writeString(factory: StreamWriter.Factory, root: Value) -> String:
        var sout: OStringStream = OStringStream()
        var writer: StreamWriterPtr = factory.newStreamWriter()
        writer.write(root, sout)
        return sout.str()

    def operator<<(sout: OStream, root: Value) -> OStream:
        var builder: StreamWriterBuilder = StreamWriterBuilder()
        var writer: StreamWriterPtr = builder.newStreamWriter()
        writer.write(root, sout)
        return sout