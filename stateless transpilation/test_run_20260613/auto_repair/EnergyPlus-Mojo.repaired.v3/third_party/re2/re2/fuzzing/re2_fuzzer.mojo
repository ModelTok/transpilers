from . import RE2, Regexp, Walker, StringPiece, Options
from . import (
    kRegexpConcat,
    kRegexpAlternate,
    kRegexpStar,
    kRegexpPlus,
    kRegexpQuest,
    kRegexpRepeat,
    kRegexpCapture,
    kRegexpLiteralString,
)
from fuzzer import FuzzedDataProvider

var dummy: UInt8 = 0

class SubexpressionWalker(Walker[Int]):
    def __init__(inout self): pass
    def __del__(owned self): pass

    def PostVisit(
        inout self,
        re: Regexp,
        parent_arg: Int,
        pre_arg: Int,
        child_args: Pointer[Int],
        nchild_args: Int,
    ) -> Int:
        var op = re.op()
        if op == kRegexpConcat or op == kRegexpAlternate:
            var max: Int = nchild_args
            for i in range(nchild_args):
                max = builtins.max(max, child_args[i])
            return max
        return -1

    def ShortVisit(
        inout self,
        re: Regexp,
        parent_arg: Int,
    ) -> Int:
        return parent_arg

    # deleted copy constructor/assignment omitted

class SubstringWalker(Walker[Int]):
    def __init__(inout self): pass
    def __del__(owned self): pass

    def PostVisit(
        inout self,
        re: Regexp,
        parent_arg: Int,
        pre_arg: Int,
        child_args: Pointer[Int],
        nchild_args: Int,
    ) -> Int:
        var op = re.op()
        if (
            op == kRegexpConcat
            or op == kRegexpAlternate
            or op == kRegexpStar
            or op == kRegexpPlus
            or op == kRegexpQuest
            or op == kRegexpRepeat
            or op == kRegexpCapture
        ):
            var max: Int = -1
            for i in range(nchild_args):
                max = builtins.max(max, child_args[i])
            return max
        elif op == kRegexpLiteralString:
            return re.nrunes()
        else:
            return -1

    def ShortVisit(
        inout self,
        re: Regexp,
        parent_arg: Int,
    ) -> Int:
        return parent_arg

    # deleted copy constructor/assignment omitted

def TestOneInput(
    pattern: StringPiece,
    options: RE2.Options,
    text: StringPiece,
):
    var char_class: Int = 0
    var backslash_p: Int = 0  # very expensive, so handle specially
    var i: Int = 0
    while i < pattern.size():
        if pattern[i] == ord('.') or pattern[i] == ord('k') or pattern[i] == ord('K') or pattern[i] == ord('s') or pattern[i] == ord('S'):
            char_class += 1
        if pattern[i] != ord('\\'):
            i += 1
            continue
        i += 1
        if i >= pattern.size():
            break
        if pattern[i] == ord('p') or pattern[i] == ord('P') or pattern[i] == ord('d') or pattern[i] == ord('D') or pattern[i] == ord('s') or pattern[i] == ord('S') or pattern[i] == ord('w') or pattern[i] == ord('W'):
            char_class += 1
        if pattern[i] == ord('p') or pattern[i] == ord('P'):
            backslash_p += 1
        i += 1
    if char_class > 9:
        return
    if backslash_p > 1:
        return
    Regexp.FUZZING_ONLY_set_maximum_repeat_count(10)
    var re = RE2(pattern, options)
    if not re.ok():
        return
    if SubexpressionWalker().Walk(re.Regexp(), -1) > 9:
        return
    if SubstringWalker().Walk(re.Regexp(), -1) > 9:
        return
    var size: Int = re.ProgramSize()
    if size > 9999:
        return
    var rsize: Int = re.ReverseProgramSize()
    if rsize > 9999:
        return
    var histogram = List[Int]()
    var fanout: Int = re.ProgramFanout(&histogram)
    if fanout > 9:
        return
    var rfanout: Int = re.ReverseProgramFanout(&histogram)
    if rfanout > 9:
        return
    if re.NumberOfCapturingGroups() == 0:
        var sp: StringPiece = text
        RE2.FullMatch(sp, re)
        RE2.PartialMatch(sp, re)
        RE2.Consume(&sp, re)
        sp = text  # Reset.
        RE2.FindAndConsume(&sp, re)
    else:
        var sp: StringPiece = text
        var s: Int16
        RE2.FullMatch(sp, re, &s)
        var l: Int
        RE2.PartialMatch(sp, re, &l)
        var f: Float32
        RE2.Consume(&sp, re, &f)
        sp = text  # Reset.
        var d: Float64
        RE2.FindAndConsume(&sp, re, &d)
    var s = String(text)
    RE2.Replace(&s, re, "")
    s = String(text)  # Reset.
    RE2.GlobalReplace(&s, re, "")
    var min: String
    var max: String
    re.PossibleMatchRange(&min, &max, 9)
    dummy += UInt8(re.NamedCapturingGroups().size())
    dummy += UInt8(re.CapturingGroupNames().size())
    dummy += UInt8(RE2.QuoteMeta(pattern).size())

def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int:
    if size == 0 or size > 4096:
        return 0
    var fdp = FuzzedDataProvider(data, size)
    var options = RE2.Options()
    options.set_encoding(RE2.Options.EncodingLatin1 if fdp.ConsumeBool() else RE2.Options.EncodingUTF8)
    options.set_posix_syntax(fdp.ConsumeBool())
    options.set_longest_match(fdp.ConsumeBool())
    options.set_log_errors(false)
    options.set_max_mem(64 << 20)
    options.set_literal(fdp.ConsumeBool())
    options.set_never_nl(fdp.ConsumeBool())
    options.set_dot_nl(fdp.ConsumeBool())
    options.set_never_capture(fdp.ConsumeBool())
    options.set_case_sensitive(not fdp.ConsumeBool())
    options.set_perl_classes(fdp.ConsumeBool())
    options.set_word_boundary(fdp.ConsumeBool())
    options.set_one_line(fdp.ConsumeBool())
    var pattern: String = fdp.ConsumeRandomLengthString(999)
    var text: String = fdp.ConsumeRandomLengthString(999)
    TestOneInput(pattern, options, text)
    return 0