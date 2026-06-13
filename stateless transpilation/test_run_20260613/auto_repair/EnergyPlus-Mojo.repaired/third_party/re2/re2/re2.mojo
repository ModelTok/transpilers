from re2.re2 import RE2, StringPiece, LazyRE2
from util.util import *
from util.logging import *
from util.strutil import *
from util.utf import *
from re2.prog import Prog
from re2.regexp import Regexp, RegexpStatusCode, RegexpStatus
from re2.sparse_array import SparseArray
from memory import Pointer
from threading import OnceFlag, Mutex, call_once
from math import *
from os import *
from sys import *
from ctypes import *
from builtins import *

# Constants
const kMaxArgs: Int = 16
const kVecSize: Int = 1 + kMaxArgs

# Static variables (initialized once)
var empty_string: Pointer[String] = Pointer[String]()
var empty_named_groups: Pointer[Dict[String, Int]] = Pointer[Dict[String, Int]]()
var empty_group_names: Pointer[Dict[Int, String]] = Pointer[Dict[Int, String]]()

# Helper function to convert RegexpStatusCode to RE2.ErrorCode
def RegexpErrorToRE2(code: RegexpStatusCode) -> RE2.ErrorCode:
    match code:
        case RegexpStatusCode.kRegexpSuccess:
            return RE2.ErrorCode.NoError
        case RegexpStatusCode.kRegexpInternalError:
            return RE2.ErrorCode.ErrorInternal
        case RegexpStatusCode.kRegexpBadEscape:
            return RE2.ErrorCode.ErrorBadEscape
        case RegexpStatusCode.kRegexpBadCharClass:
            return RE2.ErrorCode.ErrorBadCharClass
        case RegexpStatusCode.kRegexpBadCharRange:
            return RE2.ErrorCode.ErrorBadCharRange
        case RegexpStatusCode.kRegexpMissingBracket:
            return RE2.ErrorCode.ErrorMissingBracket
        case RegexpStatusCode.kRegexpMissingParen:
            return RE2.ErrorCode.ErrorMissingParen
        case RegexpStatusCode.kRegexpUnexpectedParen:
            return RE2.ErrorCode.ErrorUnexpectedParen
        case RegexpStatusCode.kRegexpTrailingBackslash:
            return RE2.ErrorCode.ErrorTrailingBackslash
        case RegexpStatusCode.kRegexpRepeatArgument:
            return RE2.ErrorCode.ErrorRepeatArgument
        case RegexpStatusCode.kRegexpRepeatSize:
            return RE2.ErrorCode.ErrorRepeatSize
        case RegexpStatusCode.kRegexpRepeatOp:
            return RE2.ErrorCode.ErrorRepeatOp
        case RegexpStatusCode.kRegexpBadPerlOp:
            return RE2.ErrorCode.ErrorBadPerlOp
        case RegexpStatusCode.kRegexpBadUTF8:
            return RE2.ErrorCode.ErrorBadUTF8
        case RegexpStatusCode.kRegexpBadNamedCapture:
            return RE2.ErrorCode.ErrorBadNamedCapture
        case _:
            return RE2.ErrorCode.ErrorInternal

def trunc(pattern: StringPiece) -> String:
    if pattern.size() < 100:
        return String(pattern)
    return String(pattern.substr(0, 100)) + "..."

# RE2 class implementation
@value
struct RE2:
    # Nested types
    enum ErrorCode:
        NoError = 0
        ErrorInternal
        ErrorBadEscape
        ErrorBadCharClass
        ErrorBadCharRange
        ErrorMissingBracket
        ErrorMissingParen
        ErrorUnexpectedParen
        ErrorTrailingBackslash
        ErrorRepeatArgument
        ErrorRepeatSize
        ErrorRepeatOp
        ErrorBadPerlOp
        ErrorBadUTF8
        ErrorBadNamedCapture
        ErrorPatternTooLarge

    enum CannedOptions:
        DefaultOptions = 0
        Latin1
        POSIX
        Quiet

    enum Anchor:
        UNANCHORED
        ANCHOR_START
        ANCHOR_BOTH

    # Options class
    @value
    struct Options:
        static const kDefaultMaxMem: Int = 8 << 20

        enum Encoding:
            EncodingUTF8 = 1
            EncodingLatin1

        var encoding_: Encoding
        var posix_syntax_: Bool
        var longest_match_: Bool
        var log_errors_: Bool
        var max_mem_: Int64
        var literal_: Bool
        var never_nl_: Bool
        var dot_nl_: Bool
        var never_capture_: Bool
        var case_sensitive_: Bool
        var perl_classes_: Bool
        var word_boundary_: Bool
        var one_line_: Bool

        def __init__(inout self):
            self.encoding_ = Encoding.EncodingUTF8
            self.posix_syntax_ = False
            self.longest_match_ = False
            self.log_errors_ = True
            self.max_mem_ = kDefaultMaxMem
            self.literal_ = False
            self.never_nl_ = False
            self.dot_nl_ = False
            self.never_capture_ = False
            self.case_sensitive_ = True
            self.perl_classes_ = False
            self.word_boundary_ = False
            self.one_line_ = False

        def __init__(inout self, opt: CannedOptions):
            self.encoding_ = Encoding.EncodingLatin1 if opt == CannedOptions.Latin1 else Encoding.EncodingUTF8
            self.posix_syntax_ = (opt == CannedOptions.POSIX)
            self.longest_match_ = (opt == CannedOptions.POSIX)
            self.log_errors_ = (opt != CannedOptions.Quiet)
            self.max_mem_ = kDefaultMaxMem
            self.literal_ = False
            self.never_nl_ = False
            self.dot_nl_ = False
            self.never_capture_ = False
            self.case_sensitive_ = True
            self.perl_classes_ = False
            self.word_boundary_ = False
            self.one_line_ = False

        def encoding(self) -> Encoding:
            return self.encoding_

        def set_encoding(inout self, encoding: Encoding):
            self.encoding_ = encoding

        def posix_syntax(self) -> Bool:
            return self.posix_syntax_

        def set_posix_syntax(inout self, b: Bool):
            self.posix_syntax_ = b

        def longest_match(self) -> Bool:
            return self.longest_match_

        def set_longest_match(inout self, b: Bool):
            self.longest_match_ = b

        def log_errors(self) -> Bool:
            return self.log_errors_

        def set_log_errors(inout self, b: Bool):
            self.log_errors_ = b

        def max_mem(self) -> Int64:
            return self.max_mem_

        def set_max_mem(inout self, m: Int64):
            self.max_mem_ = m

        def literal(self) -> Bool:
            return self.literal_

        def set_literal(inout self, b: Bool):
            self.literal_ = b

        def never_nl(self) -> Bool:
            return self.never_nl_

        def set_never_nl(inout self, b: Bool):
            self.never_nl_ = b

        def dot_nl(self) -> Bool:
            return self.dot_nl_

        def set_dot_nl(inout self, b: Bool):
            self.dot_nl_ = b

        def never_capture(self) -> Bool:
            return self.never_capture_

        def set_never_capture(inout self, b: Bool):
            self.never_capture_ = b

        def case_sensitive(self) -> Bool:
            return self.case_sensitive_

        def set_case_sensitive(inout self, b: Bool):
            self.case_sensitive_ = b

        def perl_classes(self) -> Bool:
            return self.perl_classes_

        def set_perl_classes(inout self, b: Bool):
            self.perl_classes_ = b

        def word_boundary(self) -> Bool:
            return self.word_boundary_

        def set_word_boundary(inout self, b: Bool):
            self.word_boundary_ = b

        def one_line(self) -> Bool:
            return self.one_line_

        def set_one_line(inout self, b: Bool):
            self.one_line_ = b

        def Copy(inout self, src: Options):
            self = src

        def ParseFlags(self) -> Int:
            var flags: Int = Regexp.ClassNL
            match self.encoding():
                case _:
                    if self.log_errors():
                        LOG(ERROR, "Unknown encoding " + String(self.encoding()))
                case Options.Encoding.EncodingUTF8:

                case Options.Encoding.EncodingLatin1:
                    flags |= Regexp.Latin1
            if not self.posix_syntax():
                flags |= Regexp.LikePerl
            if self.literal():
                flags |= Regexp.Literal
            if self.never_nl():
                flags |= Regexp.NeverNL
            if self.dot_nl():
                flags |= Regexp.DotNL
            if self.never_capture():
                flags |= Regexp.NeverCapture
            if not self.case_sensitive():
                flags |= Regexp.FoldCase
            if self.perl_classes():
                flags |= Regexp.PerlClasses
            if self.word_boundary():
                flags |= Regexp.PerlB
            if self.one_line():
                flags |= Regexp.OneLine
            return flags

    # Arg class
    @value
    struct Arg:
        # Parser function type
        typealias Parser = def (str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool

        var arg_: Pointer[None]
        var parser_: Parser

        def __init__(inout self):
            self.arg_ = Pointer[None]()
            self.parser_ = DoNothing

        def __init__(inout self, ptr: Pointer[None]):
            self.arg_ = ptr
            self.parser_ = DoNothing

        # Template constructors simulated with overloads
        # For types that can be parsed with 3 arguments (str, n, dest)
        def __init__[T: AnyType](inout self, ptr: Pointer[T]) where T: Parse3ary:
            self.arg_ = ptr
            self.parser_ = DoParse3ary[T]

        # For types that can be parsed with 4 arguments (str, n, dest, radix)
        def __init__[T: AnyType](inout self, ptr: Pointer[T]) where T: Parse4ary:
            self.arg_ = ptr
            self.parser_ = DoParse4ary[T]

        # For types with ParseFrom method
        def __init__[T: AnyType](inout self, ptr: Pointer[T]) where T: CanParseFrom:
            self.arg_ = ptr
            self.parser_ = DoParseFrom[T]

        # Custom parser constructor
        def __init__(inout self, ptr: Pointer[None], parser: Parser):
            self.arg_ = ptr
            self.parser_ = parser

        def Parse(self, str: Pointer[UInt8], n: UInt) -> Bool:
            return self.parser_(str, n, self.arg_)

        # Static helper functions
        def DoNothing(str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            return True

        def DoParse3ary[T: AnyType](str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            return re2_internal.Parse(str, n, dest as Pointer[T])

        def DoParse4ary[T: AnyType](str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            return re2_internal.Parse(str, n, dest as Pointer[T], 10)

        def DoParseFrom[T: AnyType](str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            if dest is None:
                return True
            return (dest as Pointer[T]).ParseFrom(str, n)

    # Static methods for CRadix, Hex, Octal
    def CRadix[T: AnyType](ptr: Pointer[T]) -> Arg:
        return Arg(ptr, def (str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            return re2_internal.Parse(str, n, dest as Pointer[T], 0)
        )

    def Hex[T: AnyType](ptr: Pointer[T]) -> Arg:
        return Arg(ptr, def (str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            return re2_internal.Parse(str, n, dest as Pointer[T], 16)
        )

    def Octal[T: AnyType](ptr: Pointer[T]) -> Arg:
        return Arg(ptr, def (str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
            return re2_internal.Parse(str, n, dest as Pointer[T], 8)
        )

    # RE2 member variables
    var pattern_: String
    var options_: Options
    var entire_regexp_: Pointer[Regexp]
    var error_: Pointer[String]
    var error_code_: ErrorCode
    var error_arg_: String
    var prefix_: String
    var prefix_foldcase_: Bool
    var suffix_regexp_: Pointer[Regexp]
    var prog_: Pointer[Prog]
    var num_captures_: Int
    var is_one_pass_: Bool
    var rprog_: Pointer[Prog]
    var named_groups_: Pointer[Dict[String, Int]]
    var group_names_: Pointer[Dict[Int, String]]
    var rprog_once_: OnceFlag
    var named_groups_once_: OnceFlag
    var group_names_once_: OnceFlag

    # Constructors
    def __init__(inout self, pattern: Pointer[UInt8]):
        self.Init(StringPiece(pattern), Options(Options.CannedOptions.DefaultOptions))

    def __init__(inout self, pattern: String):
        self.Init(StringPiece(pattern), Options(Options.CannedOptions.DefaultOptions))

    def __init__(inout self, pattern: StringPiece):
        self.Init(pattern, Options(Options.CannedOptions.DefaultOptions))

    def __init__(inout self, pattern: StringPiece, options: Options):
        self.Init(pattern, options)

    # Destructor
    def __del__(owned self):
        if self.suffix_regexp_:
            self.suffix_regexp_.Decref()
        if self.entire_regexp_:
            self.entire_regexp_.Decref()
        if self.prog_:
            del self.prog_
        if self.rprog_:
            del self.rprog_
        if self.error_ != empty_string:
            del self.error_
        if self.named_groups_ != None and self.named_groups_ != empty_named_groups:
            del self.named_groups_
        if self.group_names_ != None and self.group_names_ != empty_group_names:
            del self.group_names_

    # Methods
    def ok(self) -> Bool:
        return self.error_code() == ErrorCode.NoError

    def pattern(self) -> String:
        return self.pattern_

    def error(self) -> String:
        return self.error_[]

    def error_code(self) -> ErrorCode:
        return self.error_code_

    def error_arg(self) -> String:
        return self.error_arg_

    def ProgramSize(self) -> Int:
        if self.prog_ is None:
            return -1
        return self.prog_.size()

    def ReverseProgramSize(self) -> Int:
        if self.prog_ is None:
            return -1
        var prog: Pointer[Prog] = self.ReverseProg()
        if prog is None:
            return -1
        return prog.size()

    def ProgramFanout(self, histogram: Pointer[List[Int]]) -> Int:
        if self.prog_ is None:
            return -1
        return Fanout(self.prog_, histogram)

    def ReverseProgramFanout(self, histogram: Pointer[List[Int]]) -> Int:
        if self.prog_ is None:
            return -1
        var prog: Pointer[Prog] = self.ReverseProg()
        if prog is None:
            return -1
        return Fanout(prog, histogram)

    def Regexp(self) -> Pointer[Regexp]:
        return self.entire_regexp_

    def NumberOfCapturingGroups(self) -> Int:
        return self.num_captures_

    def NamedCapturingGroups(self) -> Dict[String, Int]:
        call_once(self.named_groups_once_, def (re: Pointer[RE2]):
            if re.suffix_regexp_ != None:
                re.named_groups_ = re.suffix_regexp_.NamedCaptures()
            if re.named_groups_ is None:
                re.named_groups_ = empty_named_groups
        , self)
        return self.named_groups_[]

    def CapturingGroupNames(self) -> Dict[Int, String]:
        call_once(self.group_names_once_, def (re: Pointer[RE2]):
            if re.suffix_regexp_ != None:
                re.group_names_ = re.suffix_regexp_.CaptureNames()
            if re.group_names_ is None:
                re.group_names_ = empty_group_names
        , self)
        return self.group_names_[]

    def options(self) -> Options:
        return self.options_

    # Static matching methods
    def FullMatchN(text: StringPiece, re: RE2, args: Pointer[Arg], n: Int) -> Bool:
        return re.DoMatch(text, Anchor.ANCHOR_BOTH, None, args, n)

    def PartialMatchN(text: StringPiece, re: RE2, args: Pointer[Arg], n: Int) -> Bool:
        return re.DoMatch(text, Anchor.UNANCHORED, None, args, n)

    def ConsumeN(input: Pointer[StringPiece], re: RE2, args: Pointer[Arg], n: Int) -> Bool:
        var consumed: UInt = 0
        if re.DoMatch(input[], Anchor.ANCHOR_START, &consumed, args, n):
            input.remove_prefix(consumed)
            return True
        else:
            return False

    def FindAndConsumeN(input: Pointer[StringPiece], re: RE2, args: Pointer[Arg], n: Int) -> Bool:
        var consumed: UInt = 0
        if re.DoMatch(input[], Anchor.UNANCHORED, &consumed, args, n):
            input.remove_prefix(consumed)
            return True
        else:
            return False

    # Variadic template helpers (simplified: we use the N versions)
    # The Apply function is not needed in Mojo because we can directly call the N versions.

    def FullMatch(text: StringPiece, re: RE2, *args: Arg) -> Bool:
        var n: Int = len(args)
        var args_arr: Pointer[Arg] = Pointer[Arg].alloc(n)
        for i in range(n):
            args_arr[i] = args[i]
        var result = FullMatchN(text, re, args_arr, n)
        Pointer[Arg].free(args_arr)
        return result

    def PartialMatch(text: StringPiece, re: RE2, *args: Arg) -> Bool:
        var n: Int = len(args)
        var args_arr: Pointer[Arg] = Pointer[Arg].alloc(n)
        for i in range(n):
            args_arr[i] = args[i]
        var result = PartialMatchN(text, re, args_arr, n)
        Pointer[Arg].free(args_arr)
        return result

    def Consume(input: Pointer[StringPiece], re: RE2, *args: Arg) -> Bool:
        var n: Int = len(args)
        var args_arr: Pointer[Arg] = Pointer[Arg].alloc(n)
        for i in range(n):
            args_arr[i] = args[i]
        var result = ConsumeN(input, re, args_arr, n)
        Pointer[Arg].free(args_arr)
        return result

    def FindAndConsume(input: Pointer[StringPiece], re: RE2, *args: Arg) -> Bool:
        var n: Int = len(args)
        var args_arr: Pointer[Arg] = Pointer[Arg].alloc(n)
        for i in range(n):
            args_arr[i] = args[i]
        var result = FindAndConsumeN(input, re, args_arr, n)
        Pointer[Arg].free(args_arr)
        return result

    def Replace(str: Pointer[String], re: RE2, rewrite: StringPiece) -> Bool:
        var vec: List[StringPiece] = List[StringPiece](kVecSize)
        var nvec: Int = 1 + MaxSubmatch(rewrite)
        if nvec > 1 + re.NumberOfCapturingGroups():
            return False
        if nvec > kVecSize:
            return False
        if not re.Match(str[], 0, str[].size(), Anchor.UNANCHORED, vec, nvec):
            return False
        var s: String = ""
        if not re.Rewrite(&s, rewrite, vec, nvec):
            return False
        # assert vec[0].data() >= str->data()
        # assert vec[0].data() + vec[0].size() <= str->data() + str->size()
        str.replace(vec[0].data() - str.data(), vec[0].size(), s)
        return True

    def GlobalReplace(str: Pointer[String], re: RE2, rewrite: StringPiece) -> Int:
        var vec: List[StringPiece] = List[StringPiece](kVecSize)
        var nvec: Int = 1 + MaxSubmatch(rewrite)
        if nvec > 1 + re.NumberOfCapturingGroups():
            return False
        if nvec > kVecSize:
            return False
        var p: Pointer[UInt8] = str.data()
        var ep: Pointer[UInt8] = p + str.size()
        var lastend: Pointer[UInt8] = None
        var out: String = ""
        var count: Int = 0
        # FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION not defined, use normal loop
        while p <= ep:
            if not re.Match(str[], (p - str.data()) as UInt, str.size(), Anchor.UNANCHORED, vec, nvec):
                break
            if p < vec[0].data():
                out.append(p, vec[0].data() - p)
            if vec[0].data() == lastend and vec[0].empty():
                if re.options().encoding() == Options.Encoding.EncodingUTF8 and fullrune(p, min(4, ep - p) as Int):
                    var r: Rune = 0
                    var n: Int = chartorune(&r, p)
                    if r > Runemax:
                        n = 1
                        r = Runeerror
                    if not (n == 1 and r == Runeerror):
                        out.append(p, n)
                        p += n
                        continue
                if p < ep:
                    out.append(p, 1)
                p += 1
                continue
            re.Rewrite(&out, rewrite, vec, nvec)
            p = vec[0].data() + vec[0].size()
            lastend = p
            count += 1
        if count == 0:
            return 0
        if p < ep:
            out.append(p, ep - p)
        swap(out, str[])
        return count

    def Extract(text: StringPiece, re: RE2, rewrite: StringPiece, out: Pointer[String]) -> Bool:
        var vec: List[StringPiece] = List[StringPiece](kVecSize)
        var nvec: Int = 1 + MaxSubmatch(rewrite)
        if nvec > 1 + re.NumberOfCapturingGroups():
            return False
        if nvec > kVecSize:
            return False
        if not re.Match(text, 0, text.size(), Anchor.UNANCHORED, vec, nvec):
            return False
        out.clear()
        return re.Rewrite(out, rewrite, vec, nvec)

    def QuoteMeta(unquoted: StringPiece) -> String:
        var result: String = ""
        result.reserve(unquoted.size() << 1)
        for ii in range(unquoted.size()):
            if (unquoted[ii] < 'a' or unquoted[ii] > 'z') and \
               (unquoted[ii] < 'A' or unquoted[ii] > 'Z') and \
               (unquoted[ii] < '0' or unquoted[ii] > '9') and \
               unquoted[ii] != '_' and \
               (unquoted[ii] & 128) == 0:
                if unquoted[ii] == '\0':
                    result += "\\x00"
                    continue
                result += '\\'
            result += unquoted[ii]
        return result

    def PossibleMatchRange(self, min: Pointer[String], max: Pointer[String], maxlen: Int) -> Bool:
        if self.prog_ is None:
            return False
        var n: Int = self.prefix_.size() as Int
        if n > maxlen:
            n = maxlen
        min[] = self.prefix_.substr(0, n)
        max[] = self.prefix_.substr(0, n)
        if self.prefix_foldcase_:
            for i in range(n):
                var c: UInt8 = min[][i]
                if 'a' <= c and c <= 'z':
                    min[][i] = (c + ('A' - 'a')) as UInt8
        var dmin: String = ""
        var dmax: String = ""
        maxlen -= n
        if maxlen > 0 and self.prog_.PossibleMatchRange(&dmin, &dmax, maxlen):
            min.append(dmin)
            max.append(dmax)
        elif not max[].empty():
            PrefixSuccessor(max)
        else:
            min[] = ""
            max[] = ""
            return False
        return True

    def Match(self, text: StringPiece, startpos: UInt, endpos: UInt, re_anchor: Anchor, submatch: Pointer[StringPiece], nsubmatch: Int) -> Bool:
        if not self.ok():
            if self.options_.log_errors():
                LOG(ERROR, "Invalid RE2: " + self.error_[])
            return False
        if startpos > endpos or endpos > text.size():
            if self.options_.log_errors():
                LOG(ERROR, "RE2: invalid startpos, endpos pair. [startpos: " + String(startpos) + ", endpos: " + String(endpos) + ", text size: " + String(text.size()) + "]")
            return False
        var subtext: StringPiece = text
        subtext.remove_prefix(startpos)
        subtext.remove_suffix(text.size() - endpos)
        var match: StringPiece = StringPiece()
        var matchp: Pointer[StringPiece] = &match
        if nsubmatch == 0:
            matchp = None
        var ncap: Int = 1 + self.NumberOfCapturingGroups()
        if ncap > nsubmatch:
            ncap = nsubmatch
        if self.prog_.anchor_start() and startpos != 0:
            return False
        if self.prog_.anchor_end() and endpos != text.size():
            return False
        if self.prog_.anchor_start() and self.prog_.anchor_end():
            re_anchor = Anchor.ANCHOR_BOTH
        elif self.prog_.anchor_start() and re_anchor != Anchor.ANCHOR_BOTH:
            re_anchor = Anchor.ANCHOR_START
        var prefixlen: UInt = 0
        if not self.prefix_.empty():
            if startpos != 0:
                return False
            prefixlen = self.prefix_.size()
            if prefixlen > subtext.size():
                return False
            if self.prefix_foldcase_:
                if ascii_strcasecmp(self.prefix_.data(), subtext.data(), prefixlen) != 0:
                    return False
            else:
                if memcmp(self.prefix_.data(), subtext.data(), prefixlen) != 0:
                    return False
            subtext.remove_prefix(prefixlen)
            if re_anchor != Anchor.ANCHOR_BOTH:
                re_anchor = Anchor.ANCHOR_START
        var anchor: Prog.Anchor = Prog.Anchor.kUnanchored
        var kind: Prog.MatchKind = Prog.MatchKind.kFirstMatch
        if self.options_.longest_match():
            kind = Prog.MatchKind.kLongestMatch
        var can_one_pass: Bool = self.is_one_pass_ and ncap <= Prog.kMaxOnePassCapture
        var can_bit_state: Bool = self.prog_.CanBitState()
        var bit_state_text_max_size: UInt = self.prog_.bit_state_text_max_size()
        # thread_local context
        # hooks::context = this (not implemented in Mojo, skip)
        var dfa_failed: Bool = False
        var skipped_test: Bool = False
        match re_anchor:
            case Anchor.UNANCHORED:
                if self.prog_.anchor_end():
                    var prog: Pointer[Prog] = self.ReverseProg()
                    if prog is None:
                        skipped_test = True
                        break
                    if not prog.SearchDFA(subtext, text, Prog.Anchor.kAnchored, Prog.MatchKind.kLongestMatch, matchp, &dfa_failed, None):
                        if dfa_failed:
                            if self.options_.log_errors():
                                LOG(ERROR, "DFA out of memory: pattern length " + String(self.pattern_.size()) + ", program size " + String(prog.size()) + ", list count " + String(prog.list_count()) + ", bytemap range " + String(prog.bytemap_range()))
                            skipped_test = True
                            break
                        return False
                    if matchp is None:
                        return True
                    break
                if not self.prog_.SearchDFA(subtext, text, anchor, kind, matchp, &dfa_failed, None):
                    if dfa_failed:
                        if self.options_.log_errors():
                            LOG(ERROR, "DFA out of memory: pattern length " + String(self.pattern_.size()) + ", program size " + String(self.prog_.size()) + ", list count " + String(self.prog_.list_count()) + ", bytemap range " + String(self.prog_.bytemap_range()))
                        skipped_test = True
                        break
                    return False
                if matchp is None:
                    return True
                var prog2: Pointer[Prog] = self.ReverseProg()
                if prog2 is None:
                    skipped_test = True
                    break
                if not prog2.SearchDFA(match, text, Prog.Anchor.kAnchored, Prog.MatchKind.kLongestMatch, &match, &dfa_failed, None):
                    if dfa_failed:
                        if self.options_.log_errors():
                            LOG(ERROR, "DFA out of memory: pattern length " + String(self.pattern_.size()) + ", program size " + String(prog2.size()) + ", list count " + String(prog2.list_count()) + ", bytemap range " + String(prog2.bytemap_range()))
                        skipped_test = True
                        break
                    if self.options_.log_errors():
                        LOG(ERROR, "SearchDFA inconsistency")
                    return False
                break
            case Anchor.ANCHOR_BOTH:
                kind = Prog.MatchKind.kFullMatch
                anchor = Prog.Anchor.kAnchored
                if can_one_pass and text.size() <= 4096 and (ncap > 1 or text.size() <= 16):
                    skipped_test = True
                    break
                if can_bit_state and text.size() <= bit_state_text_max_size and ncap > 1:
                    skipped_test = True
                    break
                if not self.prog_.SearchDFA(subtext, text, anchor, kind, &match, &dfa_failed, None):
                    if dfa_failed:
                        if self.options_.log_errors():
                            LOG(ERROR, "DFA out of memory: pattern length " + String(self.pattern_.size()) + ", program size " + String(self.prog_.size()) + ", list count " + String(self.prog_.list_count()) + ", bytemap range " + String(self.prog_.bytemap_range()))
                        skipped_test = True
                        break
                    return False
                break
            case Anchor.ANCHOR_START:
                anchor = Prog.Anchor.kAnchored
                if can_one_pass and text.size() <= 4096 and (ncap > 1 or text.size() <= 16):
                    skipped_test = True
                    break
                if can_bit_state and text.size() <= bit_state_text_max_size and ncap > 1:
                    skipped_test = True
                    break
                if not self.prog_.SearchDFA(subtext, text, anchor, kind, &match, &dfa_failed, None):
                    if dfa_failed:
                        if self.options_.log_errors():
                            LOG(ERROR, "DFA out of memory: pattern length " + String(self.pattern_.size()) + ", program size " + String(self.prog_.size()) + ", list count " + String(self.prog_.list_count()) + ", bytemap range " + String(self.prog_.bytemap_range()))
                        skipped_test = True
                        break
                    return False
                break
            case _:
                LOG(DFATAL, "Unexpected re_anchor value: " + String(re_anchor))
                return False
        if not skipped_test and ncap <= 1:
            if ncap == 1:
                submatch[0] = match
        else:
            var subtext1: StringPiece = StringPiece()
            if skipped_test:
                subtext1 = subtext
            else:
                subtext1 = match
                anchor = Prog.Anchor.kAnchored
                kind = Prog.MatchKind.kFullMatch
            if can_one_pass and anchor != Prog.Anchor.kUnanchored:
                if not self.prog_.SearchOnePass(subtext1, text, anchor, kind, submatch, ncap):
                    if not skipped_test and self.options_.log_errors():
                        LOG(ERROR, "SearchOnePass inconsistency")
                    return False
            elif can_bit_state and subtext1.size() <= bit_state_text_max_size:
                if not self.prog_.SearchBitState(subtext1, text, anchor, kind, submatch, ncap):
                    if not skipped_test and self.options_.log_errors():
                        LOG(ERROR, "SearchBitState inconsistency")
                    return False
            else:
                if not self.prog_.SearchNFA(subtext1, text, anchor, kind, submatch, ncap):
                    if not skipped_test and self.options_.log_errors():
                        LOG(ERROR, "SearchNFA inconsistency")
                    return False
        if prefixlen > 0 and nsubmatch > 0:
            submatch[0] = StringPiece(submatch[0].data() - prefixlen, submatch[0].size() + prefixlen)
        for i in range(ncap, nsubmatch):
            submatch[i] = StringPiece()
        return True

    def DoMatch(self, text: StringPiece, re_anchor: Anchor, consumed: Pointer[UInt], args: Pointer[Arg], n: Int) -> Bool:
        if not self.ok():
            if self.options_.log_errors():
                LOG(ERROR, "Invalid RE2: " + self.error_[])
            return False
        if self.NumberOfCapturingGroups() < n:
            return False
        var nvec: Int = 0
        if n == 0 and consumed is None:
            nvec = 0
        else:
            nvec = n + 1
        var vec: Pointer[StringPiece] = None
        var stkvec: List[StringPiece] = List[StringPiece](kVecSize)
        var heapvec: Pointer[StringPiece] = None
        if nvec <= kVecSize:
            vec = stkvec.data()
        else:
            heapvec = Pointer[StringPiece].alloc(nvec)
            vec = heapvec
        if not self.Match(text, 0, text.size(), re_anchor, vec, nvec):
            if heapvec:
                Pointer[StringPiece].free(heapvec)
            return False
        if consumed is not None:
            consumed[] = (EndPtr(vec[0]) - BeginPtr(text)) as UInt
        if n == 0 or args is None:
            if heapvec:
                Pointer[StringPiece].free(heapvec)
            return True
        for i in range(n):
            var s: StringPiece = vec[i+1]
            if not args[i].Parse(s.data(), s.size()):
                if heapvec:
                    Pointer[StringPiece].free(heapvec)
                return False
        if heapvec:
            Pointer[StringPiece].free(heapvec)
        return True

    def CheckRewriteString(self, rewrite: StringPiece, error: Pointer[String]) -> Bool:
        var max_token: Int = -1
        var s: Pointer[UInt8] = rewrite.data()
        var end: Pointer[UInt8] = s + rewrite.size()
        while s < end:
            var c: Int = s[]
            if c != '\\':
                s += 1
                continue
            s += 1
            if s == end:
                error[] = "Rewrite schema error: '\\' not allowed at end."
                return False
            c = s[]
            if c == '\\':
                s += 1
                continue
            if not isdigit(c):
                error[] = "Rewrite schema error: '\\' must be followed by a digit or '\\'."
                return False
            var n: Int = (c - '0')
            if max_token < n:
                max_token = n
            s += 1
        if max_token > self.NumberOfCapturingGroups():
            error[] = StringPrintf("Rewrite schema requests %d matches, but the regexp only has %d parenthesized subexpressions.", max_token, self.NumberOfCapturingGroups())
            return False
        return True

    def MaxSubmatch(rewrite: StringPiece) -> Int:
        var max: Int = 0
        var s: Pointer[UInt8] = rewrite.data()
        var end: Pointer[UInt8] = s + rewrite.size()
        while s < end:
            if s[] == '\\':
                s += 1
                var c: Int = (s < end) ? s[] : -1
                if isdigit(c):
                    var n: Int = (c - '0')
                    if n > max:
                        max = n
            s += 1
        return max

    def Rewrite(self, out: Pointer[String], rewrite: StringPiece, vec: Pointer[StringPiece], veclen: Int) -> Bool:
        var s: Pointer[UInt8] = rewrite.data()
        var end: Pointer[UInt8] = s + rewrite.size()
        while s < end:
            if s[] != '\\':
                out.push_back(s[])
                s += 1
                continue
            s += 1
            var c: Int = (s < end) ? s[] : -1
            if isdigit(c):
                var n: Int = (c - '0')
                if n >= veclen:
                    if self.options_.log_errors():
                        LOG(ERROR, "invalid substitution \\" + String(n) + " from " + String(veclen) + " groups")
                    return False
                var snip: StringPiece = vec[n]
                if not snip.empty():
                    out.append(snip.data(), snip.size())
            elif c == '\\':
                out.push_back('\\')
            else:
                if self.options_.log_errors():
                    LOG(ERROR, "invalid rewrite pattern: " + String(rewrite.data()))
                return False
            s += 1
        return True

    # Private methods
    def Init(inout self, pattern: StringPiece, options: Options):
        var empty_once: OnceFlag = OnceFlag()
        call_once(empty_once, def ():
            empty_string = Pointer[String].alloc()
            empty_string[] = String()
            empty_named_groups = Pointer[Dict[String, Int]].alloc()
            empty_named_groups[] = Dict[String, Int]()
            empty_group_names = Pointer[Dict[Int, String]].alloc()
            empty_group_names[] = Dict[Int, String]()
        )
        self.pattern_ = String(pattern.data(), pattern.size())
        self.options_.Copy(options)
        self.entire_regexp_ = None
        self.error_ = empty_string
        self.error_code_ = ErrorCode.NoError
        self.error_arg_.clear()
        self.prefix_.clear()
        self.prefix_foldcase_ = False
        self.suffix_regexp_ = None
        self.prog_ = None
        self.num_captures_ = -1
        self.is_one_pass_ = False
        self.rprog_ = None
        self.named_groups_ = None
        self.group_names_ = None
        var status: RegexpStatus = RegexpStatus()
        self.entire_regexp_ = Regexp.Parse(self.pattern_, self.options_.ParseFlags() as Regexp.ParseFlags, &status)
        if self.entire_regexp_ is None:
            if self.options_.log_errors():
                LOG(ERROR, "Error parsing '" + trunc(StringPiece(self.pattern_)) + "': " + status.Text())
            self.error_ = Pointer[String].alloc()
            self.error_[] = status.Text()
            self.error_code_ = RegexpErrorToRE2(status.code())
            self.error_arg_ = String(status.error_arg())
            return
        var suffix: Pointer[Regexp] = None
        if self.entire_regexp_.RequiredPrefix(&self.prefix_, &self.prefix_foldcase_, &suffix):
            self.suffix_regexp_ = suffix
        else:
            self.suffix_regexp_ = self.entire_regexp_.Incref()
        self.prog_ = self.suffix_regexp_.CompileToProg(self.options_.max_mem() * 2 // 3)
        if self.prog_ is None:
            if self.options_.log_errors():
                LOG(ERROR, "Error compiling '" + trunc(StringPiece(self.pattern_)) + "'")
            self.error_ = Pointer[String].alloc()
            self.error_[] = "pattern too large - compile failed"
            self.error_code_ = RE2.ErrorCode.ErrorPatternTooLarge
            return
        self.num_captures_ = self.suffix_regexp_.NumCaptures()
        self.is_one_pass_ = self.prog_.IsOnePass()

    def ReverseProg(self) -> Pointer[Prog]:
        call_once(self.rprog_once_, def (re: Pointer[RE2]):
            re.rprog_ = re.suffix_regexp_.CompileToReverseProg(re.options_.max_mem() // 3)
            if re.rprog_ is None:
                if re.options_.log_errors():
                    LOG(ERROR, "Error reverse compiling '" + trunc(StringPiece(re.pattern_)) + "'")
        , self)
        return self.rprog_

# Helper functions (not part of RE2 class)
def FindMSBSet(n: UInt32) -> Int:
    DCHECK_NE(n, 0)
    # Using builtin clz
    return 31 ^ __builtin_clz(n)

def Fanout(prog: Pointer[Prog], histogram: Pointer[List[Int]]) -> Int:
    var fanout: SparseArray[Int] = SparseArray[Int](prog.size())
    prog.Fanout(&fanout)
    var data: List[Int] = List[Int](32)
    for i in range(32):
        data.append(0)
    var size: Int = 0
    var it: SparseArray[Int].Iterator = fanout.begin()
    while it != fanout.end():
        if it.value() == 0:
            it += 1
            continue
        var value: UInt32 = it.value()
        var bucket: Int = FindMSBSet(value)
        bucket += 1 if (value & (value-1)) != 0 else 0
        data[bucket] += 1
        size = max(size, bucket+1)
        it += 1
    if histogram is not None:
        histogram.assign(data.data(), data.data() + size)
    return size - 1

def ascii_strcasecmp(a: Pointer[UInt8], b: Pointer[UInt8], len: UInt) -> Int:
    var ae: Pointer[UInt8] = a + len
    while a < ae:
        var x: UInt8 = a[]
        var y: UInt8 = b[]
        if 'A' <= y and y <= 'Z':
            y += ('a' - 'A')
        if x != y:
            return x - y
        a += 1
        b += 1
    return 0

# re2_internal namespace
@value
struct re2_internal:
    # Parse functions for various types
    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[None]) -> Bool:
        return (dest is None)

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[String]) -> Bool:
        if dest is None:
            return True
        dest.assign(str, n)
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[StringPiece]) -> Bool:
        if dest is None:
            return True
        dest[] = StringPiece(str, n)
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[UInt8]) -> Bool:
        if n != 1:
            return False
        if dest is None:
            return True
        dest[] = str[0]
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Int8]) -> Bool:
        if n != 1:
            return False
        if dest is None:
            return True
        dest[] = str[0] as Int8
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[UInt8]) -> Bool:
        if n != 1:
            return False
        if dest is None:
            return True
        dest[] = str[0]
        return True

    # Number parsing helpers
    const kMaxNumberLength: Int = 32

    def TerminateNumber(buf: Pointer[UInt8], nbuf: UInt, str: Pointer[UInt8], np: Pointer[UInt], accept_spaces: Bool) -> Pointer[UInt8]:
        var n: UInt = np[]
        if n == 0:
            return ""
        if n > 0 and isspace(str[0]):
            if not accept_spaces:
                return ""
            while n > 0 and isspace(str[0]):
                n -= 1
                str += 1
        var neg: Bool = False
        if n >= 1 and str[0] == '-':
            neg = True
            n -= 1
            str += 1
        if n >= 3 and str[0] == '0' and str[1] == '0':
            while n >= 3 and str[2] == '0':
                n -= 1
                str += 1
        if neg:
            n += 1
            str -= 1
        if n > nbuf - 1:
            return ""
        memmove(buf, str, n)
        if neg:
            buf[0] = '-'
        buf[n] = '\0'
        np[] = n
        return buf

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Float32]) -> Bool:
        if n == 0:
            return False
        const kMaxLength: Int = 200
        var buf: List[UInt8] = List[UInt8](kMaxLength+1)
        str = TerminateNumber(buf.data(), kMaxLength+1, str, &n, True)
        var end: Pointer[UInt8] = None
        errno = 0
        var r: Float32 = strtof(str, &end)
        if end != str + n:
            return False
        if errno != 0:
            return False
        if dest is None:
            return True
        dest[] = r
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Float64]) -> Bool:
        if n == 0:
            return False
        const kMaxLength: Int = 200
        var buf: List[UInt8] = List[UInt8](kMaxLength+1)
        str = TerminateNumber(buf.data(), kMaxLength+1, str, &n, True)
        var end: Pointer[UInt8] = None
        errno = 0
        var r: Float64 = strtod(str, &end)
        if end != str + n:
            return False
        if errno != 0:
            return False
        if dest is None:
            return True
        dest[] = r
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Int64], radix: Int) -> Bool:
        if n == 0:
            return False
        var buf: List[UInt8] = List[UInt8](kMaxNumberLength+1)
        str = TerminateNumber(buf.data(), kMaxNumberLength+1, str, &n, False)
        var end: Pointer[UInt8] = None
        errno = 0
        var r: Int64 = strtol(str, &end, radix)
        if end != str + n:
            return False
        if errno != 0:
            return False
        if dest is None:
            return True
        dest[] = r
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[UInt64], radix: Int) -> Bool:
        if n == 0:
            return False
        var buf: List[UInt8] = List[UInt8](kMaxNumberLength+1)
        str = TerminateNumber(buf.data(), kMaxNumberLength+1, str, &n, False)
        if str[0] == '-':
            return False
        var end: Pointer[UInt8] = None
        errno = 0
        var r: UInt64 = strtoul(str, &end, radix)
        if end != str + n:
            return False
        if errno != 0:
            return False
        if dest is None:
            return True
        dest[] = r
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Int16], radix: Int) -> Bool:
        var r: Int64 = 0
        if not Parse(str, n, &r, radix):
            return False
        if (r as Int16) != r:
            return False
        if dest is None:
            return True
        dest[] = r as Int16
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[UInt16], radix: Int) -> Bool:
        var r: UInt64 = 0
        if not Parse(str, n, &r, radix):
            return False
        if (r as UInt16) != r:
            return False
        if dest is None:
            return True
        dest[] = r as UInt16
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Int32], radix: Int) -> Bool:
        var r: Int64 = 0
        if not Parse(str, n, &r, radix):
            return False
        if (r as Int32) != r:
            return False
        if dest is None:
            return True
        dest[] = r as Int32
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[UInt32], radix: Int) -> Bool:
        var r: UInt64 = 0
        if not Parse(str, n, &r, radix):
            return False
        if (r as UInt32) != r:
            return False
        if dest is None:
            return True
        dest[] = r as UInt32
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[Int64], radix: Int) -> Bool:
        if n == 0:
            return False
        var buf: List[UInt8] = List[UInt8](kMaxNumberLength+1)
        str = TerminateNumber(buf.data(), kMaxNumberLength+1, str, &n, False)
        var end: Pointer[UInt8] = None
        errno = 0
        var r: Int64 = strtoll(str, &end, radix)
        if end != str + n:
            return False
        if errno != 0:
            return False
        if dest is None:
            return True
        dest[] = r
        return True

    def Parse(str: Pointer[UInt8], n: UInt, dest: Pointer[UInt64], radix: Int) -> Bool:
        if n == 0:
            return False
        var buf: List[UInt8] = List[UInt8](kMaxNumberLength+1)
        str = TerminateNumber(buf.data(), kMaxNumberLength+1, str, &n, False)
        if str[0] == '-':
            return False
        var end: Pointer[UInt8] = None
        errno = 0
        var r: UInt64 = strtoull(str, &end, radix)
        if end != str + n:
            return False
        if errno != 0:
            return False
        if dest is None:
            return True
        dest[] = r
        return True

# hooks namespace
@value
struct hooks:
    # thread_local context (not fully supported, placeholder)
    # var context: Pointer[RE2] = None

    # Hook types
    typealias DFAStateCacheResetCallback = def (DFAStateCacheReset) -> None
    typealias DFASearchFailureCallback = def (DFASearchFailure) -> None

    @value
    struct DFAStateCacheReset:
        var state_budget: Int64
        var state_cache_size: UInt

    @value
    struct DFASearchFailure:

    # Hook storage (using atomic pointers)
    var dfa_state_cache_reset_hook: Atomic[Pointer[DFAStateCacheResetCallback]] = Atomic[Pointer[DFAStateCacheResetCallback]](&DoNothing[DFAStateCacheReset])
    var dfa_search_failure_hook: Atomic[Pointer[DFASearchFailureCallback]] = Atomic[Pointer[DFASearchFailureCallback]](&DoNothing[DFASearchFailure])

    def DoNothing[T: AnyType](arg: T):

    def SetDFAStateCacheResetHook(cb: Pointer[DFAStateCacheResetCallback]):
        dfa_state_cache_reset_hook.store(cb, memory_order_release)

    def GetDFAStateCacheResetHook() -> Pointer[DFAStateCacheResetCallback]:
        return dfa_state_cache_reset_hook.load(memory_order_acquire)

    def SetDFASearchFailureHook(cb: Pointer[DFASearchFailureCallback]):
        dfa_search_failure_hook.store(cb, memory_order_release)

    def GetDFASearchFailureHook() -> Pointer[DFASearchFailureCallback]:
        return dfa_search_failure_hook.load(memory_order_acquire)

# End of file