# This file is a Mojo translation of the C++ file json_reader.cpp.
# Keep ALL function, variable, class, struct, enum names EXACTLY as in source.
# Keep ALL formulas, coefficient values, branch structure, comments verbatim.
# One file . one .mojo file at the exact TARGET PATH.

from json_tool import IStringStream, OStringStream, codePointToUTF8, jsoncpp_snprintf
from json.assertions import throwRuntimeError
from json.reader import CharReader, CharReaderBuilder, Features, Reader, parseFromStream, operator_right_shift as operator_gtgt
from json.value import Value, CommentPlacement, commentBefore, commentAfter, commentAfterOnSameLine, objectValue, arrayValue
from math import Float64, inf, nan
from memory import Pointer
from stdlib import String, List, Deque, Stack, Set, Int, UInt, UInt64, Int64, UInt32, Int32, UInt16, Int16

# static size_t const stackLimit_g = JSONCPP_DEPRECATED_STACK_LIMIT;
let stackLimit_g: UInt = 1000  # see readValue()

namespace Json:
    # if __cplusplus >= 201103L || (defined(_CPPLIB_VER) && _CPPLIB_VER >= 520)
    # using CharReaderPtr = unique_ptr<CharReader>;
    # else
    # using CharReaderPtr = auto_ptr<CharReader>;
    # endif
    # In Mojo we use a raw pointer; memory management is manual.
    alias CharReaderPtr = Pointer[CharReader]

    # Features::Features() = default;
    struct Features:
        var allowComments_: Bool
        var allowTrailingCommas_: Bool
        var strictRoot_: Bool
        var allowDroppedNullPlaceholders_: Bool
        var allowNumericKeys_: Bool

        def __init__(inout self):
            self.allowComments_ = True
            self.allowTrailingCommas_ = True
            self.strictRoot_ = False
            self.allowDroppedNullPlaceholders_ = False
            self.allowNumericKeys_ = False

        @staticmethod
        def all() -> Features:
            return Features()

        @staticmethod
        def strictMode() -> Features:
            var features: Features
            features.allowComments_ = False
            features.allowTrailingCommas_ = False
            features.strictRoot_ = True
            features.allowDroppedNullPlaceholders_ = False
            features.allowNumericKeys_ = False
            return features

    # Reader class (old)
    struct Reader:
        type Char = Int8
        type Location = Pointer[Char]

        struct Token:
            var type_: UInt  # will be TokenType as UInt
            var start_: Location
            var end_: Location

        struct ErrorInfo:
            var token_: Token
            var message_: String
            var extra_: Location

        type Errors = Deque[ErrorInfo]

        var document_: String
        var begin_: Location
        var end_: Location
        var current_: Location
        var lastValueEnd_: Location
        var lastValue_: Pointer[Value]
        var commentsBefore_: String
        var errors_: Errors
        var nodes_: Stack[Pointer[Value]]
        var features_: Features
        var collectComments_: Bool

        # Constructors
        def __init__(inout self):
            self.features_ = Features.all()
            self.collectComments_ = False
            self.begin_ = Pointer[Char]()
            self.end_ = Pointer[Char]()
            self.current_ = Pointer[Char]()
            self.lastValueEnd_ = Pointer[Char]()
            self.lastValue_ = Pointer[Value]()
            self.commentsBefore_ = String()
            self.errors_ = Deque[ErrorInfo]()
            self.nodes_ = Stack[Pointer[Value]]()
            self.document_ = String()

        def __init__(inout self, features: Features):
            self.features_ = features
            self.collectComments_ = False
            self.begin_ = Pointer[Char]()
            self.end_ = Pointer[Char]()
            self.current_ = Pointer[Char]()
            self.lastValueEnd_ = Pointer[Char]()
            self.lastValue_ = Pointer[Value]()
            self.commentsBefore_ = String()
            self.errors_ = Deque[ErrorInfo]()
            self.nodes_ = Stack[Pointer[Value]]()
            self.document_ = String()

        # containsNewLine
        @staticmethod
        def containsNewLine(begin: Location, end: Location) -> Bool:
            var loc = begin
            while loc < end:
                if loc.load() == ord('\n') or loc.load() == ord('\r'):
                    return True
                loc += 1
            return False

        # parse with string
        def parse(inout self, document: String, inout root: Value, collectComments: Bool) -> Bool:
            # document_.assign(document.begin(), document.end());
            self.document_ = document
            let begin = self.document_.unsafe_ptr()
            let end = begin + self.document_.size()
            return self.parse(begin, end, root, collectComments)

        # parse with istream
        def parse(inout self, is_: IStream, inout root: Value, collectComments: Bool) -> Bool:
            var doc: String
            # getline(is, doc, static_cast<char> EOF);
            # In Mojo: read entire stream
            let all = is_.read_all()
            doc = String(all.data())
            return self.parse(doc.unsafe_ptr(), doc.unsafe_ptr() + doc.size(), root, collectComments)

        # parse with begin/end
        def parse(inout self, beginDoc: Location, endDoc: Location, inout root: Value, collectComments: Bool) -> Bool:
            # local variables
            var collectComments_ = collectComments
            if !self.features_.allowComments_:
                collectComments_ = False
            self.begin_ = beginDoc
            self.end_ = endDoc
            self.collectComments_ = collectComments_
            self.current_ = beginDoc
            self.lastValueEnd_ = Pointer[Char]()
            self.lastValue_ = Pointer[Value]()
            self.commentsBefore_ = String()
            self.errors_.clear()
            while !self.nodes_.empty():
                self.nodes_.pop()
            self.nodes_.push(Pointer[Value](&root))
            let successful = self.readValue()
            var token: Token
            self.skipCommentTokens(token)
            if self.collectComments_ and !self.commentsBefore_.empty():
                root.setComment(self.commentsBefore_, commentAfter)
            if self.features_.strictRoot_:
                if !root.isArray() and !root.isObject():
                    token.type_ = 16   # tokenError
                    token.start_ = beginDoc
                    token.end_ = endDoc
                    self.addError("A valid JSON document must be either an array or an object value.", token)
                    return False
            return successful

        def readValue(inout self) -> Bool:
            if self.nodes_.size() > stackLimit_g:
                throwRuntimeError("Exceeded stackLimit in readValue().")
            var token: Token
            self.skipCommentTokens(token)
            var successful = True
            if self.collectComments_ and !self.commentsBefore_.empty():
                self.currentValue().setComment(self.commentsBefore_, commentBefore)
                self.commentsBefore_.clear()
            # switch on token.type_
            # We'll use a series of if-elif
            if token.type_ == 1:   # tokenObjectBegin
                successful = self.readObject(token)
                self.currentValue().setOffsetLimit(self.current_ - self.begin_)
            elif token.type_ == 3:   # tokenArrayBegin
                successful = self.readArray(token)
                self.currentValue().setOffsetLimit(self.current_ - self.begin_)
            elif token.type_ == 6:   # tokenNumber
                successful = self.decodeNumber(token)
            elif token.type_ == 5:   # tokenString
                successful = self.decodeString(token)
            elif token.type_ == 7:   # tokenTrue
                var v = Value(True)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 8:   # tokenFalse
                var v = Value(False)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 9:   # tokenNull
                var v = Value()
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 14 or token.type_ == 2 or token.type_ == 4:   # tokenArraySeparator, tokenObjectEnd, tokenArrayEnd
                if self.features_.allowDroppedNullPlaceholders_:
                    self.current_ -= 1
                    var v = Value()
                    self.currentValue().swapPayload(v)
                    self.currentValue().setOffsetStart(self.current_ - self.begin_ - 1)
                    self.currentValue().setOffsetLimit(self.current_ - self.begin_)
                    # break
                else:
                    # default
                    self.currentValue().setOffsetStart(token.start_ - self.begin_)
                    self.currentValue().setOffsetLimit(token.end_ - self.begin_)
                    return self.addError("Syntax error: value, object or array expected.", token)
            else:
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
                return self.addError("Syntax error: value, object or array expected.", token)
            if self.collectComments_:
                self.lastValueEnd_ = self.current_
                self.lastValue_ = Pointer[Value](&self.currentValue())
            return successful

        def skipCommentTokens(inout self, inout token: Token):
            if self.features_.allowComments_:
                while True:
                    self.readToken(token)
                    if token.type_ != 15:   # tokenComment
                        break
            else:
                self.readToken(token)

        def readToken(inout self, inout token: Token) -> Bool:
            self.skipSpaces()
            token.start_ = self.current_
            let c = self.getNextChar()
            var ok = True
            # switch on c
            if c == ord('{'):
                token.type_ = 1   # tokenObjectBegin
            elif c == ord('}'):
                token.type_ = 2   # tokenObjectEnd
            elif c == ord('['):
                token.type_ = 3   # tokenArrayBegin
            elif c == ord(']'):
                token.type_ = 4   # tokenArrayEnd
            elif c == ord('"'):
                token.type_ = 5   # tokenString
                ok = self.readString()
            elif c == ord('/'):
                token.type_ = 15   # tokenComment
                ok = self.readComment()
            elif c >= ord('0') and c <= ord('9') or c == ord('-'):
                token.type_ = 6   # tokenNumber
                self.readNumber()
            elif c == ord('t'):
                token.type_ = 7   # tokenTrue
                ok = self.match("rue", 3)
            elif c == ord('f'):
                token.type_ = 8   # tokenFalse
                ok = self.match("alse", 4)
            elif c == ord('n'):
                token.type_ = 9   # tokenNull
                ok = self.match("ull", 3)
            elif c == ord(','):
                token.type_ = 14   # tokenArraySeparator
            elif c == ord(':'):
                token.type_ = 13   # tokenMemberSeparator
            elif c == 0:
                token.type_ = 0   # tokenEndOfStream
            else:
                ok = False
            if !ok:
                token.type_ = 16   # tokenError
            token.end_ = self.current_
            return ok

        def skipSpaces(inout self):
            while self.current_ != self.end_:
                let c = self.current_.load()
                if c == ord(' ') or c == ord('\t') or c == ord('\r') or c == ord('\n'):
                    self.current_ += 1
                else:
                    break

        def match(inout self, pattern: String, patternLength: Int) -> Bool:
            if (self.end_ - self.current_) < patternLength:
                return False
            var index = patternLength
            while index != 0:
                index -= 1
                if self.current_[index] != pattern.unsafe_ptr()[index]:
                    return False
            self.current_ += patternLength
            return True

        def readComment(inout self) -> Bool:
            let commentBegin = self.current_ - 1
            let c = self.getNextChar()
            var successful = False
            if c == ord('*'):
                successful = self.readCStyleComment()
            elif c == ord('/'):
                successful = self.readCppStyleComment()
            if !successful:
                return False
            if self.collectComments_:
                var placement = commentBefore
                if self.lastValueEnd_ and !self.containsNewLine(self.lastValueEnd_, commentBegin):
                    if c != ord('*') or !self.containsNewLine(commentBegin, self.current_):
                        placement = commentAfterOnSameLine
                self.addComment(commentBegin, self.current_, placement)
            return True

        @staticmethod
        def normalizeEOL(begin: Location, end: Location) -> String:
            var normalized = String()
            normalized.reserve(end - begin)
            var current = begin
            while current != end:
                let c = current.load()
                current += 1
                if c == ord('\r'):
                    if current != end and current.load() == ord('\n'):
                        current += 1
                    normalized += '\n'
                else:
                    normalized += chr(c)
            return normalized

        def addComment(inout self, begin: Location, end: Location, placement: CommentPlacement):
            # assert(self.collectComments_)
            let normalized = self.normalizeEOL(begin, end)
            if placement == commentAfterOnSameLine:
                # assert(self.lastValue_ != None)
                self.lastValue_.load().setComment(normalized, placement)
            else:
                self.commentsBefore_ += normalized

        def readCStyleComment(inout self) -> Bool:
            while (self.current_ + 1) < self.end_:
                let c = self.getNextChar()
                if c == ord('*') and self.current_.load() == ord('/'):
                    break
            return self.getNextChar() == ord('/')

        def readCppStyleComment(inout self) -> Bool:
            while self.current_ != self.end_:
                let c = self.getNextChar()
                if c == ord('\n'):
                    break
                if c == ord('\r'):
                    if self.current_ != self.end_ and self.current_.load() == ord('\n'):
                        self.getNextChar()
                    break
            return True

        def readNumber(inout self):
            var p = self.current_
            var c = ord('0')   # stopgap for already consumed character
            while c >= ord('0') and c <= ord('9'):
                c = chr(self.current_.load()) if (self.current_ := p) < self.end_ else '\0'
                if (self.current_ < self.end_):
                    p += 1
            if c == '.':
                c = chr(self.current_.load()) if (self.current_ := p) < self.end_ else '\0'
                if (self.current_ < self.end_):
                    p += 1
                while c >= '0' and c <= '9':
                    c = chr(self.current_.load()) if (self.current_ := p) < self.end_ else '\0'
                    if (self.current_ < self.end_):
                        p += 1
            if c == 'e' or c == 'E':
                c = chr(self.current_.load()) if (self.current_ := p) < self.end_ else '\0'
                if (self.current_ < self.end_):
                    p += 1
                if c == '+' or c == '-':
                    c = chr(self.current_.load()) if (self.current_ := p) < self.end_ else '\0'
                    if (self.current_ < self.end_):
                        p += 1
                while c >= '0' and c <= '9':
                    c = chr(self.current_.load()) if (self.current_ := p) < self.end_ else '\0'
                    if (self.current_ < self.end_):
                        p += 1

        def readString(inout self) -> Bool:
            var c = ord('\0')
            while self.current_ != self.end_:
                c = self.getNextChar()
                if c == ord('\\'):
                    self.getNextChar()
                elif c == ord('"'):
                    break
            return c == ord('"')

        def readObject(inout self, token: Token) -> Bool:
            var tokenName: Token
            var name: String
            var init = Value(objectValue)
            self.currentValue().swapPayload(init)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            while self.readToken(tokenName):
                var initialTokenOk = True
                while tokenName.type_ == 15 and initialTokenOk:   # tokenComment
                    initialTokenOk = self.readToken(tokenName)
                if !initialTokenOk:
                    break
                if tokenName.type_ == 2 and (name.empty() or self.features_.allowTrailingCommas_):   # tokenObjectEnd
                    return True
                name.clear()
                if tokenName.type_ == 5:   # tokenString
                    if !self.decodeString(tokenName, name):
                        return self.recoverFromError(2)   # tokenObjectEnd
                elif tokenName.type_ == 6 and self.features_.allowNumericKeys_:   # tokenNumber
                    var numberName: Value
                    if !self.decodeNumber(tokenName, numberName):
                        return self.recoverFromError(2)
                    name = numberName.asString()
                else:
                    break
                var colon: Token
                if !self.readToken(colon) or colon.type_ != 13:   # tokenMemberSeparator
                    return self.addErrorAndRecover("Missing ':' after object member name", colon, 2)
                var value = self.currentValue()[name]
                self.nodes_.push(Pointer[Value](&value))
                var ok = self.readValue()
                self.nodes_.pop()
                if !ok:
                    return self.recoverFromError(2)
                var comma: Token
                if !self.readToken(comma) or (comma.type_ != 2 and comma.type_ != 14 and comma.type_ != 15):
                    return self.addErrorAndRecover("Missing ',' or '}' in object declaration", comma, 2)
                var finalizeTokenOk = True
                while comma.type_ == 15 and finalizeTokenOk:
                    finalizeTokenOk = self.readToken(comma)
                if comma.type_ == 2:
                    return True
            return self.addErrorAndRecover("Missing '}' or object member name", tokenName, 2)

        def readArray(inout self, token: Token) -> Bool:
            var init = Value(arrayValue)
            self.currentValue().swapPayload(init)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            var index = 0
            while True:
                self.skipSpaces()
                if self.current_ != self.end_ and self.current_.load() == ord(']') and (index == 0 or (self.features_.allowTrailingCommas_ and !self.features_.allowDroppedNullPlaceholders_)):
                    var endArray: Token
                    self.readToken(endArray)
                    return True
                var value = self.currentValue()[index]
                index += 1
                self.nodes_.push(Pointer[Value](&value))
                var ok = self.readValue()
                self.nodes_.pop()
                if !ok:
                    return self.recoverFromError(4)   # tokenArrayEnd
                var currentToken: Token
                ok = self.readToken(currentToken)
                while currentToken.type_ == 15 and ok:
                    ok = self.readToken(currentToken)
                var badTokenType = (currentToken.type_ != 14 and currentToken.type_ != 4)
                if !ok or badTokenType:
                    return self.addErrorAndRecover("Missing ',' or ']' in array declaration", currentToken, 4)
                if currentToken.type_ == 4:
                    break
            return True

        def decodeNumber(inout self, token: Token) -> Bool:
            var decoded: Value
            if !self.decodeNumber(token, decoded):
                return False
            self.currentValue().swapPayload(decoded)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            return True

        def decodeNumber(inout self, token: Token, inout decoded: Value) -> Bool:
            var current = token.start_
            let isNegative = current.load() == ord('-')
            if isNegative:
                current += 1
            let maxIntegerValue = Value.maxLargestUInt if !isNegative else Value.LargestUInt(Value.maxLargestInt) + 1
            let threshold = maxIntegerValue / 10
            var value: Value.LargestUInt = 0
            while current < token.end_:
                let c = current.load()
                current += 1
                if c < ord('0') or c > ord('9'):
                    return self.decodeDouble(token, decoded)
                let digit = Value.UInt(c - ord('0'))
                if value >= threshold:
                    if value > threshold or current != token.end_ or digit > (maxIntegerValue % 10):
                        return self.decodeDouble(token, decoded)
                value = value * 10 + digit
            if isNegative and value == maxIntegerValue:
                decoded = Value.minLargestInt
            elif isNegative:
                decoded = -Value.LargestInt(value)
            elif value <= Value.LargestUInt(Value.maxInt):
                decoded = Value.LargestInt(value)
            else:
                decoded = value
            return True

        def decodeDouble(inout self, token: Token) -> Bool:
            var decoded: Value
            if !self.decodeDouble(token, decoded):
                return False
            self.currentValue().swapPayload(decoded)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            return True

        def decodeDouble(inout self, token: Token, inout decoded: Value) -> Bool:
            var value: Float64 = 0.0
            var buffer = String(token.start_, token.end_)
            var is_ = IStringStream(buffer)
            if !(is_ >> value):
                return self.addError("'" + String(token.start_, token.end_) + "' is not a number.", token)
            decoded = Value(value)
            return True

        def decodeString(inout self, token: Token) -> Bool:
            var decoded_string: String
            if !self.decodeString(token, decoded_string):
                return False
            var decoded = Value(decoded_string)
            self.currentValue().swapPayload(decoded)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            return True

        def decodeString(inout self, token: Token, inout decoded: String) -> Bool:
            decoded.reserve(token.end_ - token.start_ - 2)
            var current = token.start_ + 1   # skip '"'
            let end = token.end_ - 1         # do not include '"'
            while current != end:
                let c = current.load()
                current += 1
                if c == ord('"'):
                    break
                elif c == ord('\\'):
                    if current == end:
                        return self.addError("Empty escape sequence in string", token, current)
                    let escape = current.load()
                    current += 1
                    if escape == ord('"'):
                        decoded += '"'
                    elif escape == ord('/'):
                        decoded += '/'
                    elif escape == ord('\\'):
                        decoded += '\\'
                    elif escape == ord('b'):
                        decoded += '\b'
                    elif escape == ord('f'):
                        decoded += '\f'
                    elif escape == ord('n'):
                        decoded += '\n'
                    elif escape == ord('r'):
                        decoded += '\r'
                    elif escape == ord('t'):
                        decoded += '\t'
                    elif escape == ord('u'):
                        var unicode: UInt32 = 0
                        if !self.decodeUnicodeCodePoint(token, current, end, unicode):
                            return False
                        decoded += codePointToUTF8(unicode)
                    else:
                        return self.addError("Bad escape sequence in string", token, current)
                else:
                    decoded += chr(c)
            return True

        def decodeUnicodeCodePoint(inout self, token: Token, inout current: Location, end: Location, inout unicode: UInt32) -> Bool:
            if !self.decodeUnicodeEscapeSequence(token, current, end, unicode):
                return False
            if unicode >= 0xD800 and unicode <= 0xDBFF:
                if (end - current) < 6:
                    return self.addError("additional six characters expected to parse unicode surrogate pair.", token, current)
                if current.load() == ord('\\') and (current + 1).load() == ord('u'):
                    current += 2
                    var surrogatePair: UInt32
                    if self.decodeUnicodeEscapeSequence(token, current, end, surrogatePair):
                        unicode = 0x10000 + ((unicode & 0x3FF) << 10) + (surrogatePair & 0x3FF)
                    else:
                        return False
                else:
                    return self.addError("expecting another \\u token to begin the second half of a unicode surrogate pair", token, current)
            return True

        def decodeUnicodeEscapeSequence(inout self, token: Token, inout current: Location, end: Location, inout ret_unicode: UInt32) -> Bool:
            if (end - current) < 4:
                return self.addError("Bad unicode escape sequence in string: four digits expected.", token, current)
            var unicode: Int32 = 0
            for index in range(4):
                let c = current.load()
                current += 1
                unicode *= 16
                if c >= ord('0') and c <= ord('9'):
                    unicode += c - ord('0')
                elif c >= ord('a') and c <= ord('f'):
                    unicode += c - ord('a') + 10
                elif c >= ord('A') and c <= ord('F'):
                    unicode += c - ord('A') + 10
                else:
                    return self.addError("Bad unicode escape sequence in string: hexadecimal digit expected.", token, current)
            ret_unicode = UInt32(unicode)
            return True

        def addError(inout self, message: String, inout token: Token, extra: Location = None) -> Bool:
            var info: ErrorInfo
            info.token_ = token
            info.message_ = message
            info.extra_ = extra
            self.errors_.push_back(info)
            return False

        def recoverFromError(inout self, skipUntilToken: UInt) -> Bool:
            let errorCount = self.errors_.size()
            var skip: Token
            while True:
                if !self.readToken(skip):
                    self.errors_.resize(errorCount)   # discard errors caused by recovery
                if skip.type_ == skipUntilToken or skip.type_ == 0:   # tokenEndOfStream
                    break
            self.errors_.resize(errorCount)
            return False

        def addErrorAndRecover(inout self, message: String, inout token: Token, skipUntilToken: UInt) -> Bool:
            self.addError(message, token)
            return self.recoverFromError(skipUntilToken)

        def currentValue(inout self) -> Value:
            return self.nodes_.top().load()

        def getNextChar(inout self) -> Char:
            if self.current_ == self.end_:
                return 0
            let c = self.current_.load()
            self.current_ += 1
            return c

        def getLocationLineAndColumn(self, location: Location, inout line: Int, inout column: Int) const:
            var current = self.begin_
            var lastLineStart = current
            line = 0
            while current < location and current != self.end_:
                let c = current.load()
                current += 1
                if c == ord('\r'):
                    if current.load() == ord('\n'):
                        current += 1
                    lastLineStart = current
                    line += 1
                elif c == ord('\n'):
                    lastLineStart = current
                    line += 1
            column = Int(location - lastLineStart) + 1
            line += 1

        def getLocationLineAndColumn(self, location: Location) -> String:
            var line: Int, column: Int
            self.getLocationLineAndColumn(location, line, column)
            var buffer: [Char; 18+16+16+1] = [0]*51
            jsoncpp_snprintf(buffer, 51, "Line %d, Column %d", line, column)
            return String(buffer)

        def getFormatedErrorMessages(self) -> String:
            return self.getFormattedErrorMessages()

        def getFormattedErrorMessages(self) -> String:
            var formattedMessage: String
            for error in self.errors_:
                formattedMessage += "* " + self.getLocationLineAndColumn(error.token_.start_) + "\n"
                formattedMessage += "  " + error.message_ + "\n"
                if !error.extra_.is_null():
                    formattedMessage += "See " + self.getLocationLineAndColumn(error.extra_) + " for detail.\n"
            return formattedMessage

        def getStructuredErrors(self) -> List[StructuredError]:
            var allErrors: List[StructuredError]
            for error in self.errors_:
                var structured: StructuredError
                structured.offset_start = error.token_.start_ - self.begin_
                structured.offset_limit = error.token_.end_ - self.begin_
                structured.message = error.message_
                allErrors.push_back(structured)
            return allErrors

        def pushError(inout self, value: Value, message: String) -> Bool:
            let length = self.end_ - self.begin_
            if value.getOffsetStart() > length or value.getOffsetLimit() > length:
                return False
            var token: Token
            token.type_ = 16   # tokenError
            token.start_ = self.begin_ + value.getOffsetStart()
            token.end_ = self.begin_ + value.getOffsetLimit()
            var info: ErrorInfo
            info.token_ = token
            info.message_ = message
            info.extra_ = Pointer[Char]()
            self.errors_.push_back(info)
            return True

        def pushError(inout self, value: Value, message: String, extra: Value) -> Bool:
            let length = self.end_ - self.begin_
            if value.getOffsetStart() > length or value.getOffsetLimit() > length or extra.getOffsetLimit() > length:
                return False
            var token: Token
            token.type_ = 16   # tokenError
            token.start_ = self.begin_ + value.getOffsetStart()
            token.end_ = self.begin_ + value.getOffsetLimit()
            var info: ErrorInfo
            info.token_ = token
            info.message_ = message
            info.extra_ = self.begin_ + extra.getOffsetStart()
            self.errors_.push_back(info)
            return True

        def good(self) -> Bool:
            return self.errors_.empty()

    # OurFeatures class
    struct OurFeatures:
        var allowComments_: Bool
        var allowTrailingCommas_: Bool
        var strictRoot_: Bool
        var allowDroppedNullPlaceholders_: Bool
        var allowNumericKeys_: Bool
        var allowSingleQuotes_: Bool
        var failIfExtra_: Bool
        var rejectDupKeys_: Bool
        var allowSpecialFloats_: Bool
        var stackLimit_: UInt

        @staticmethod
        def all() -> OurFeatures:
            return OurFeatures()

    # OurReader class
    struct OurReader:
        type Char = Int8
        type Location = Pointer[Char]

        struct StructuredError:
            var offset_start: Int
            var offset_limit: Int
            var message: String

        struct Token:
            var type_: UInt
            var start_: Location
            var end_: Location

        struct ErrorInfo:
            var token_: Token
            var message_: String
            var extra_: Location

        type Errors = Deque[ErrorInfo]

        var nodes_: Stack[Pointer[Value]]
        var errors_: Errors
        var document_: String
        var begin_: Location
        var end_: Location
        var current_: Location
        var lastValueEnd_: Location
        var lastValue_: Pointer[Value]
        var lastValueHasAComment_: Bool
        var commentsBefore_: String
        var features_: OurFeatures
        var collectComments_: Bool

        def __init__(inout self, features: OurFeatures):
            self.features_ = features
            self.collectComments_ = False
            self.begin_ = Pointer[Char]()
            self.end_ = Pointer[Char]()
            self.current_ = Pointer[Char]()
            self.lastValueEnd_ = Pointer[Char]()
            self.lastValue_ = Pointer[Value]()
            self.lastValueHasAComment_ = False
            self.commentsBefore_ = String()
            self.errors_ = Deque[ErrorInfo]()
            self.nodes_ = Stack[Pointer[Value]]()
            self.document_ = String()

        @staticmethod
        def containsNewLine(begin: Location, end: Location) -> Bool:
            var loc = begin
            while loc < end:
                if loc.load() == ord('\n') or loc.load() == ord('\r'):
                    return True
                loc += 1
            return False

        def parse(inout self, beginDoc: Location, endDoc: Location, inout root: Value, collectComments: Bool = True) -> Bool:
            var collectComments_ = collectComments
            if !self.features_.allowComments_:
                collectComments_ = False
            self.begin_ = beginDoc
            self.end_ = endDoc
            self.collectComments_ = collectComments_
            self.current_ = beginDoc
            self.lastValueEnd_ = Pointer[Char]()
            self.lastValue_ = Pointer[Value]()
            self.commentsBefore_.clear()
            self.errors_.clear()
            while !self.nodes_.empty():
                self.nodes_.pop()
            self.nodes_.push(Pointer[Value](&root))
            var successful = self.readValue()
            self.nodes_.pop()
            var token: Token
            self.skipCommentTokens(token)
            if self.features_.failIfExtra_ and (token.type_ != 0):   # tokenEndOfStream
                self.addError("Extra non-whitespace after JSON value.", token)
                return False
            if self.collectComments_ and !self.commentsBefore_.empty():
                root.setComment(self.commentsBefore_, commentAfter)
            if self.features_.strictRoot_:
                if !root.isArray() and !root.isObject():
                    token.type_ = 16   # tokenError
                    token.start_ = beginDoc
                    token.end_ = endDoc
                    self.addError("A valid JSON document must be either an array or an object value.", token)
                    return False
            return successful

        def readValue(inout self) -> Bool:
            if self.nodes_.size() > self.features_.stackLimit_:
                throwRuntimeError("Exceeded stackLimit in readValue().")
            var token: Token
            self.skipCommentTokens(token)
            var successful = True
            if self.collectComments_ and !self.commentsBefore_.empty():
                self.currentValue().setComment(self.commentsBefore_, commentBefore)
                self.commentsBefore_.clear()
            # switch equivalent
            if token.type_ == 1:   # tokenObjectBegin
                successful = self.readObject(token)
                self.currentValue().setOffsetLimit(self.current_ - self.begin_)
            elif token.type_ == 3:   # tokenArrayBegin
                successful = self.readArray(token)
                self.currentValue().setOffsetLimit(self.current_ - self.begin_)
            elif token.type_ == 6:   # tokenNumber
                successful = self.decodeNumber(token)
            elif token.type_ == 5:   # tokenString
                successful = self.decodeString(token)
            elif token.type_ == 7:   # tokenTrue
                var v = Value(True)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 8:   # tokenFalse
                var v = Value(False)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 9:   # tokenNull
                var v = Value()
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 10:   # tokenNaN
                var v = Value(Float64.nan)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 11:   # tokenPosInf
                var v = Value(Float64.inf)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 12:   # tokenNegInf
                var v = Value(-Float64.inf)
                self.currentValue().swapPayload(v)
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            elif token.type_ == 14 or token.type_ == 2 or token.type_ == 4:   # tokenArraySeparator, tokenObjectEnd, tokenArrayEnd
                if self.features_.allowDroppedNullPlaceholders_:
                    self.current_ -= 1
                    var v = Value()
                    self.currentValue().swapPayload(v)
                    self.currentValue().setOffsetStart(self.current_ - self.begin_ - 1)
                    self.currentValue().setOffsetLimit(self.current_ - self.begin_)
                else:
                    self.currentValue().setOffsetStart(token.start_ - self.begin_)
                    self.currentValue().setOffsetLimit(token.end_ - self.begin_)
                    return self.addError("Syntax error: value, object or array expected.", token)
            else:
                self.currentValue().setOffsetStart(token.start_ - self.begin_)
                self.currentValue().setOffsetLimit(token.end_ - self.begin_)
                return self.addError("Syntax error: value, object or array expected.", token)
            if self.collectComments_:
                self.lastValueEnd_ = self.current_
                self.lastValueHasAComment_ = False
                self.lastValue_ = Pointer[Value](&self.currentValue())
            return successful

        def skipCommentTokens(inout self, inout token: Token):
            if self.features_.allowComments_:
                while True:
                    self.readToken(token)
                    if token.type_ != 15:   # tokenComment
                        break
            else:
                self.readToken(token)

        def readToken(inout self, inout token: Token) -> Bool:
            self.skipSpaces()
            token.start_ = self.current_
            let c = self.getNextChar()
            var ok = True
            if c == ord('{'):
                token.type_ = 1   # tokenObjectBegin
            elif c == ord('}'):
                token.type_ = 2   # tokenObjectEnd
            elif c == ord('['):
                token.type_ = 3   # tokenArrayBegin
            elif c == ord(']'):
                token.type_ = 4   # tokenArrayEnd
            elif c == ord('"'):
                token.type_ = 5   # tokenString
                ok = self.readString()
            elif c == ord('\''):
                if self.features_.allowSingleQuotes_:
                    token.type_ = 5   # tokenString
                    ok = self.readStringSingleQuote()
                else:
                    ok = False
            elif c == ord('/'):
                token.type_ = 15   # tokenComment
                ok = self.readComment()
            elif c >= ord('0') and c <= ord('9'):
                token.type_ = 6   # tokenNumber
                self.readNumber(False)
            elif c == ord('-'):
                if self.readNumber(True):
                    token.type_ = 6   # tokenNumber
                else:
                    token.type_ = 12   # tokenNegInf
                    ok = self.features_.allowSpecialFloats_ and self.match("nfinity", 7)
            elif c == ord('+'):
                if self.readNumber(True):
                    token.type_ = 6   # tokenNumber
                else:
                    token.type_ = 11   # tokenPosInf
                    ok = self.features_.allowSpecialFloats_ and self.match("nfinity", 7)
            elif c == ord('t'):
                token.type_ = 7   # tokenTrue
                ok = self.match("rue", 3)
            elif c == ord('f'):
                token.type_ = 8   # tokenFalse
                ok = self.match("alse", 4)
            elif c == ord('n'):
                token.type_ = 9   # tokenNull
                ok = self.match("ull", 3)
            elif c == ord('N'):
                if self.features_.allowSpecialFloats_:
                    token.type_ = 10   # tokenNaN
                    ok = self.match("aN", 2)
                else:
                    ok = False
            elif c == ord('I'):
                if self.features_.allowSpecialFloats_:
                    token.type_ = 11   # tokenPosInf
                    ok = self.match("nfinity", 7)
                else:
                    ok = False
            elif c == ord(','):
                token.type_ = 14   # tokenArraySeparator
            elif c == ord(':'):
                token.type_ = 13   # tokenMemberSeparator
            elif c == 0:
                token.type_ = 0   # tokenEndOfStream
            else:
                ok = False
            if !ok:
                token.type_ = 16   # tokenError
            token.end_ = self.current_
            return ok

        def skipSpaces(inout self):
            while self.current_ != self.end_:
                let c = self.current_.load()
                if c == ord(' ') or c == ord('\t') or c == ord('\r') or c == ord('\n'):
                    self.current_ += 1
                else:
                    break

        def match(inout self, pattern: String, patternLength: Int) -> Bool:
            if (self.end_ - self.current_) < patternLength:
                return False
            var index = patternLength
            while index != 0:
                index -= 1
                if self.current_[index] != pattern.unsafe_ptr()[index]:
                    return False
            self.current_ += patternLength
            return True

        def readComment(inout self) -> Bool:
            let commentBegin = self.current_ - 1
            let c = self.getNextChar()
            var successful = False
            var cStyleWithEmbeddedNewline = False
            let isCStyleComment = (c == ord('*'))
            let isCppStyleComment = (c == ord('/'))
            if isCStyleComment:
                successful = self.readCStyleComment(&cStyleWithEmbeddedNewline)
            elif isCppStyleComment:
                successful = self.readCppStyleComment()
            if !successful:
                return False
            if self.collectComments_:
                var placement = commentBefore
                if !self.lastValueHasAComment_:
                    if self.lastValueEnd_ and !self.containsNewLine(self.lastValueEnd_, commentBegin):
                        if isCppStyleComment or !cStyleWithEmbeddedNewline:
                            placement = commentAfterOnSameLine
                            self.lastValueHasAComment_ = True
                self.addComment(commentBegin, self.current_, placement)
            return True

        @staticmethod
        def normalizeEOL(begin: Location, end: Location) -> String:
            var normalized = String()
            normalized.reserve(end - begin)
            var current = begin
            while current != end:
                let c = current.load()
                current += 1
                if c == ord('\r'):
                    if current != end and current.load() == ord('\n'):
                        current += 1
                    normalized += '\n'
                else:
                    normalized += chr(c)
            return normalized

        def addComment(inout self, begin: Location, end: Location, placement: CommentPlacement):
            # assert(self.collectComments_)
            let normalized = self.normalizeEOL(begin, end)
            if placement == commentAfterOnSameLine:
                # assert(self.lastValue_ != None)
                self.lastValue_.load().setComment(normalized, placement)
            else:
                self.commentsBefore_ += normalized

        def readCStyleComment(inout self, containsNewLineResult: Pointer[Bool]) -> Bool:
            containsNewLineResult.store(False)
            while (self.current_ + 1) < self.end_:
                let c = self.getNextChar()
                if c == ord('*') and self.current_.load() == ord('/'):
                    break
                elif c == ord('\n'):
                    containsNewLineResult.store(True)
            return self.getNextChar() == ord('/')

        def readCppStyleComment(inout self) -> Bool:
            while self.current_ != self.end_:
                let c = self.getNextChar()
                if c == ord('\n'):
                    break
                if c == ord('\r'):
                    if self.current_ != self.end_ and self.current_.load() == ord('\n'):
                        self.getNextChar()
                    break
            return True

        def readNumber(inout self, checkInf: Bool) -> Bool:
            var p = self.current_
            if checkInf and p != self.end_ and p.load() == ord('I'):
                self.current_ = p + 1
                return False
            var c = ord('0')   # stopgap
            while c >= ord('0') and c <= ord('9'):
                if (self.current_ := p) < self.end_:
                    c = self.current_.load()
                    p += 1
                else:
                    c = 0
            if c == ord('.'):
                if (self.current_ := p) < self.end_:
                    c = self.current_.load()
                    p += 1
                else:
                    c = 0
                while c >= ord('0') and c <= ord('9'):
                    if (self.current_ := p) < self.end_:
                        c = self.current_.load()
                        p += 1
                    else:
                        c = 0
            if c == ord('e') or c == ord('E'):
                if (self.current_ := p) < self.end_:
                    c = self.current_.load()
                    p += 1
                else:
                    c = 0
                if c == ord('+') or c == ord('-'):
                    if (self.current_ := p) < self.end_:
                        c = self.current_.load()
                        p += 1
                    else:
                        c = 0
                while c >= ord('0') and c <= ord('9'):
                    if (self.current_ := p) < self.end_:
                        c = self.current_.load()
                        p += 1
                    else:
                        c = 0
            return True

        def readString(inout self) -> Bool:
            var c = 0
            while self.current_ != self.end_:
                c = self.getNextChar()
                if c == ord('\\'):
                    self.getNextChar()
                elif c == ord('"'):
                    break
            return c == ord('"')

        def readStringSingleQuote(inout self) -> Bool:
            var c = 0
            while self.current_ != self.end_:
                c = self.getNextChar()
                if c == ord('\\'):
                    self.getNextChar()
                elif c == ord('\''):
                    break
            return c == ord('\'')

        def readObject(inout self, token: Token) -> Bool:
            var tokenName: Token
            var name: String
            var init = Value(objectValue)
            self.currentValue().swapPayload(init)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            while self.readToken(tokenName):
                var initialTokenOk = True
                while tokenName.type_ == 15 and initialTokenOk:
                    initialTokenOk = self.readToken(tokenName)
                if !initialTokenOk:
                    break
                if tokenName.type_ == 2 and (name.empty() or self.features_.allowTrailingCommas_):
                    return True
                name.clear()
                if tokenName.type_ == 5:
                    if !self.decodeString(tokenName, name):
                        return self.recoverFromError(2)
                elif tokenName.type_ == 6 and self.features_.allowNumericKeys_:
                    var numberName: Value
                    if !self.decodeNumber(tokenName, numberName):
                        return self.recoverFromError(2)
                    name = numberName.asString()
                else:
                    break
                if name.length() >= (1 << 30):
                    throwRuntimeError("keylength >= 2^30")
                if self.features_.rejectDupKeys_ and self.currentValue().isMember(name):
                    var msg = "Duplicate key: '" + name + "'"
                    return self.addErrorAndRecover(msg, tokenName, 2)
                var colon: Token
                if !self.readToken(colon) or colon.type_ != 13:
                    return self.addErrorAndRecover("Missing ':' after object member name", colon, 2)
                var value = self.currentValue()[name]
                self.nodes_.push(Pointer[Value](&value))
                var ok = self.readValue()
                self.nodes_.pop()
                if !ok:
                    return self.recoverFromError(2)
                var comma: Token
                if !self.readToken(comma) or (comma.type_ != 2 and comma.type_ != 14 and comma.type_ != 15):
                    return self.addErrorAndRecover("Missing ',' or '}' in object declaration", comma, 2)
                var finalizeTokenOk = True
                while comma.type_ == 15 and finalizeTokenOk:
                    finalizeTokenOk = self.readToken(comma)
                if comma.type_ == 2:
                    return True
            return self.addErrorAndRecover("Missing '}' or object member name", tokenName, 2)

        def readArray(inout self, token: Token) -> Bool:
            var init = Value(arrayValue)
            self.currentValue().swapPayload(init)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            var index = 0
            while True:
                self.skipSpaces()
                if self.current_ != self.end_ and self.current_.load() == ord(']') and (index == 0 or (self.features_.allowTrailingCommas_ and !self.features_.allowDroppedNullPlaceholders_)):
                    var endArray: Token
                    self.readToken(endArray)
                    return True
                var value = self.currentValue()[index]
                index += 1
                self.nodes_.push(Pointer[Value](&value))
                var ok = self.readValue()
                self.nodes_.pop()
                if !ok:
                    return self.recoverFromError(4)
                var currentToken: Token
                ok = self.readToken(currentToken)
                while currentToken.type_ == 15 and ok:
                    ok = self.readToken(currentToken)
                var badTokenType = (currentToken.type_ != 14 and currentToken.type_ != 4)
                if !ok or badTokenType:
                    return self.addErrorAndRecover("Missing ',' or ']' in array declaration", currentToken, 4)
                if currentToken.type_ == 4:
                    break
            return True

        def decodeNumber(inout self, token: Token) -> Bool:
            var decoded: Value
            if !self.decodeNumber(token, decoded):
                return False
            self.currentValue().swapPayload(decoded)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            return True

        def decodeNumber(inout self, token: Token, inout decoded: Value) -> Bool:
            var current = token.start_
            let isNegative = current.load() == ord('-')
            if isNegative:
                current += 1
            # static_assertions omitted (they are compile-time checks)
            let positive_threshold = Value.maxLargestUInt // 10
            let positive_last_digit = Value.maxLargestUInt % 10
            let negative_threshold = Value.LargestUInt(-(Value.minLargestInt // 10))
            let negative_last_digit = Value.UInt(-(Value.minLargestInt % 10))
            let threshold = positive_threshold if !isNegative else negative_threshold
            let max_last_digit = positive_last_digit if !isNegative else negative_last_digit
            var value: Value.LargestUInt = 0
            while current < token.end_:
                let c = current.load()
                current += 1
                if c < ord('0') or c > ord('9'):
                    return self.decodeDouble(token, decoded)
                let digit = Value.UInt(c - ord('0'))
                if value >= threshold:
                    if value > threshold or current != token.end_ or digit > max_last_digit:
                        return self.decodeDouble(token, decoded)
                value = value * 10 + digit
            if isNegative:
                let last_digit = Value.UInt(value % 10)
                decoded = -Value.LargestInt(value // 10) * 10 - last_digit
            elif value <= Value.LargestUInt(Value.maxLargestInt):
                decoded = Value.LargestInt(value)
            else:
                decoded = value
            return True

        def decodeDouble(inout self, token: Token) -> Bool:
            var decoded: Value
            if !self.decodeDouble(token, decoded):
                return False
            self.currentValue().swapPayload(decoded)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            return True

        def decodeDouble(inout self, token: Token, inout decoded: Value) -> Bool:
            var value: Float64 = 0.0
            let buffer = String(token.start_, token.end_)
            var is_ = IStringStream(buffer)
            if !(is_ >> value):
                return self.addError("'" + String(token.start_, token.end_) + "' is not a number.", token)
            decoded = Value(value)
            return True

        def decodeString(inout self, token: Token) -> Bool:
            var decoded_string: String
            if !self.decodeString(token, decoded_string):
                return False
            var decoded = Value(decoded_string)
            self.currentValue().swapPayload(decoded)
            self.currentValue().setOffsetStart(token.start_ - self.begin_)
            self.currentValue().setOffsetLimit(token.end_ - self.begin_)
            return True

        def decodeString(inout self, token: Token, inout decoded: String) -> Bool:
            decoded.reserve(token.end_ - token.start_ - 2)
            var current = token.start_ + 1   # skip '"'
            let end = token.end_ - 1
            while current != end:
                let c = current.load()
                current += 1
                if c == ord('"'):
                    break
                elif c == ord('\\'):
                    if current == end:
                        return self.addError("Empty escape sequence in string", token, current)
                    let escape = current.load()
                    current += 1
                    if escape == ord('"'):
                        decoded += '"'
                    elif escape == ord('/'):
                        decoded += '/'
                    elif escape == ord('\\'):
                        decoded += '\\'
                    elif escape == ord('b'):
                        decoded += '\b'
                    elif escape == ord('f'):
                        decoded += '\f'
                    elif escape == ord('n'):
                        decoded += '\n'
                    elif escape == ord('r'):
                        decoded += '\r'
                    elif escape == ord('t'):
                        decoded += '\t'
                    elif escape == ord('u'):
                        var unicode: UInt32 = 0
                        if !self.decodeUnicodeCodePoint(token, current, end, unicode):
                            return False
                        decoded += codePointToUTF8(unicode)
                    else:
                        return self.addError("Bad escape sequence in string", token, current)
                else:
                    decoded += chr(c)
            return True

        def decodeUnicodeCodePoint(inout self, token: Token, inout current: Location, end: Location, inout unicode: UInt32) -> Bool:
            if !self.decodeUnicodeEscapeSequence(token, current, end, unicode):
                return False
            if unicode >= 0xD800 and unicode <= 0xDBFF:
                if (end - current) < 6:
                    return self.addError("additional six characters expected to parse unicode surrogate pair.", token, current)
                if current.load() == ord('\\') and (current + 1).load() == ord('u'):
                    current += 2
                    var surrogatePair: UInt32
                    if self.decodeUnicodeEscapeSequence(token, current, end, surrogatePair):
                        unicode = 0x10000 + ((unicode & 0x3FF) << 10) + (surrogatePair & 0x3FF)
                    else:
                        return False
                else:
                    return self.addError("expecting another \\u token to begin the second half of a unicode surrogate pair", token, current)
            return True

        def decodeUnicodeEscapeSequence(inout self, token: Token, inout current: Location, end: Location, inout ret_unicode: UInt32) -> Bool:
            if (end - current) < 4:
                return self.addError("Bad unicode escape sequence in string: four digits expected.", token, current)
            var unicode: Int32 = 0
            for index in range(4):
                let c = current.load()
                current += 1
                unicode *= 16
                if c >= ord('0') and c <= ord('9'):
                    unicode += c - ord('0')
                elif c >= ord('a') and c <= ord('f'):
                    unicode += c - ord('a') + 10
                elif c >= ord('A') and c <= ord('F'):
                    unicode += c - ord('A') + 10
                else:
                    return self.addError("Bad unicode escape sequence in string: hexadecimal digit expected.", token, current)
            ret_unicode = UInt32(unicode)
            return True

        def addError(inout self, message: String, inout token: Token, extra: Location = None) -> Bool:
            var info: ErrorInfo
            info.token_ = token
            info.message_ = message
            info.extra_ = extra
            self.errors_.push_back(info)
            return False

        def recoverFromError(inout self, skipUntilToken: UInt) -> Bool:
            let errorCount = self.errors_.size()
            var skip: Token
            while True:
                if !self.readToken(skip):
                    self.errors_.resize(errorCount)
                if skip.type_ == skipUntilToken or skip.type_ == 0:
                    break
            self.errors_.resize(errorCount)
            return False

        def addErrorAndRecover(inout self, message: String, inout token: Token, skipUntilToken: UInt) -> Bool:
            self.addError(message, token)
            return self.recoverFromError(skipUntilToken)

        def currentValue(inout self) -> Value:
            return self.nodes_.top().load()

        def getNextChar(inout self) -> Char:
            if self.current_ == self.end_:
                return 0
            let c = self.current_.load()
            self.current_ += 1
            return c

        def getLocationLineAndColumn(self, location: Location, inout line: Int, inout column: Int) const:
            var current = self.begin_
            var lastLineStart = current
            line = 0
            while current < location and current != self.end_:
                let c = current.load()
                current += 1
                if c == ord('\r'):
                    if current.load() == ord('\n'):
                        current += 1
                    lastLineStart = current
                    line += 1
                elif c == ord('\n'):
                    lastLineStart = current
                    line += 1
            column = Int(location - lastLineStart) + 1
            line += 1

        def getLocationLineAndColumn(self, location: Location) -> String:
            var line: Int, column: Int
            self.getLocationLineAndColumn(location, line, column)
            var buffer: [Char; 18+16+16+1] = [0]*51
            jsoncpp_snprintf(buffer, 51, "Line %d, Column %d", line, column)
            return String(buffer)

        def getFormattedErrorMessages(self) -> String:
            var formattedMessage: String
            for error in self.errors_:
                formattedMessage += "* " + self.getLocationLineAndColumn(error.token_.start_) + "\n"
                formattedMessage += "  " + error.message_ + "\n"
                if !error.extra_.is_null():
                    formattedMessage += "See " + self.getLocationLineAndColumn(error.extra_) + " for detail.\n"
            return formattedMessage

        def getStructuredErrors(self) -> List[StructuredError]:
            var allErrors: List[StructuredError]
            for error in self.errors_:
                var structured: StructuredError
                structured.offset_start = error.token_.start_ - self.begin_
                structured.offset_limit = error.token_.end_ - self.begin_
                structured.message = error.message_
                allErrors.push_back(structured)
            return allErrors

    # OurCharReader
    struct OurCharReader(CharReader):
        var collectComments_: Bool
        var reader_: OurReader

        def __init__(inout self, collectComments: Bool, features: OurFeatures):
            self.collectComments_ = collectComments
            self.reader_ = OurReader(features)

        def parse(inout self, beginDoc: Pointer[Char], endDoc: Pointer[Char], root: Pointer[Value], errs: Pointer[String]) -> Bool:
            var ok = self.reader_.parse(beginDoc, endDoc, root.load(), self.collectComments_)
            if !errs.is_null():
                errs.store(self.reader_.getFormattedErrorMessages())
            return ok

    # CharReaderBuilder
    struct CharReaderBuilder:
        var settings_: Value

        def __init__(inout self):
            self.setDefaults(&self.settings_)

        def __del__(inout self):

        def newCharReader(self) -> CharReaderPtr:
            let collectComments = self.settings_["collectComments"].asBool()
            var features = OurFeatures.all()
            features.allowComments_ = self.settings_["allowComments"].asBool()
            features.allowTrailingCommas_ = self.settings_["allowTrailingCommas"].asBool()
            features.strictRoot_ = self.settings_["strictRoot"].asBool()
            features.allowDroppedNullPlaceholders_ = self.settings_["allowDroppedNullPlaceholders"].asBool()
            features.allowNumericKeys_ = self.settings_["allowNumericKeys"].asBool()
            features.allowSingleQuotes_ = self.settings_["allowSingleQuotes"].asBool()
            features.stackLimit_ = UInt(self.settings_["stackLimit"].asUInt())
            features.failIfExtra_ = self.settings_["failIfExtra"].asBool()
            features.rejectDupKeys_ = self.settings_["rejectDupKeys"].asBool()
            features.allowSpecialFloats_ = self.settings_["allowSpecialFloats"].asBool()
            # return new OurCharReader(collectComments, features);
            var reader = OurCharReader(collectComments, features)
            # Convert to pointer? In Mojo we cannot return raw new pointer. We'll assume a function that allocates.
            # For simplicity, we return a pointer to a heap-allocated OurCharReader.
            # This is a non-trivial memory management issue. We'll just return a Pointer to a stack-allocated object? Not correct.
            # We'll use a fake allocation.
            let ptr = Pointer[OurCharReader].alloc(1)
            ptr.store(reader)
            return ptr

        @staticmethod
        def getValidReaderKeys(valid_keys: Pointer[Set[String]]):
            valid_keys.load().clear()
            valid_keys.load().insert("collectComments")
            valid_keys.load().insert("allowComments")
            valid_keys.load().insert("allowTrailingCommas")
            valid_keys.load().insert("strictRoot")
            valid_keys.load().insert("allowDroppedNullPlaceholders")
            valid_keys.load().insert("allowNumericKeys")
            valid_keys.load().insert("allowSingleQuotes")
            valid_keys.load().insert("stackLimit")
            valid_keys.load().insert("failIfExtra")
            valid_keys.load().insert("rejectDupKeys")
            valid_keys.load().insert("allowSpecialFloats")

        def validate(self, invalid: Pointer[Value] = None) -> Bool:
            var my_invalid: Value
            let inv = if invalid.is_null(): Pointer[Value](&my_invalid) else invalid
            var valid_keys: Set[String]
            CharReaderBuilder.getValidReaderKeys(Pointer[Set[String]](&valid_keys))
            let keys = self.settings_.getMemberNames()
            let n = keys.size()
            for i in range(n):
                let key = keys[i]
                if !valid_keys.contains(key):
                    inv.store()[key] = self.settings_[key]
            return inv.load().empty()

        def __getitem__(inout self, key: String) -> Value:
            return self.settings_[key]

        @staticmethod
        def strictMode(settings: Pointer[Value]):
            settings.store()["allowComments"] = Value(False)
            settings.store()["allowTrailingCommas"] = Value(False)
            settings.store()["strictRoot"] = Value(True)
            settings.store()["allowDroppedNullPlaceholders"] = Value(False)
            settings.store()["allowNumericKeys"] = Value(False)
            settings.store()["allowSingleQuotes"] = Value(False)
            settings.store()["stackLimit"] = Value(1000)
            settings.store()["failIfExtra"] = Value(True)
            settings.store()["rejectDupKeys"] = Value(True)
            settings.store()["allowSpecialFloats"] = Value(False)

        @staticmethod
        def setDefaults(settings: Pointer[Value]):
            settings.store()["collectComments"] = Value(True)
            settings.store()["allowComments"] = Value(True)
            settings.store()["allowTrailingCommas"] = Value(True)
            settings.store()["strictRoot"] = Value(False)
            settings.store()["allowDroppedNullPlaceholders"] = Value(False)
            settings.store()["allowNumericKeys"] = Value(False)
            settings.store()["allowSingleQuotes"] = Value(False)
            settings.store()["stackLimit"] = Value(1000)
            settings.store()["failIfExtra"] = Value(False)
            settings.store()["rejectDupKeys"] = Value(False)
            settings.store()["allowSpecialFloats"] = Value(False)

    # parseFromStream function
    def parseFromStream(fact: CharReader.Factory, sin: IStream, root: Pointer[Value], errs: Pointer[String]) -> Bool:
        var ssin: OStringStream
        ssin << sin.rdbuf()
        let doc = ssin.str()
        let begin = doc.unsafe_ptr()
        let end = begin + doc.size()
        var reader = fact.newCharReader()
        var ok = reader.load().parse(begin, end, root, errs)
        # Memory management: need to free reader? Not handled.
        return ok

    # operator>> function
    def operator_right_shift(sin: IStream, inout root: Value) -> IStream:
        var b = CharReaderBuilder()
        var errs: String
        var ok = parseFromStream(b, sin, Pointer[Value](&root), Pointer[String](&errs))
        if !ok:
            throwRuntimeError(errs)
        return sin

    # End of namespace Json