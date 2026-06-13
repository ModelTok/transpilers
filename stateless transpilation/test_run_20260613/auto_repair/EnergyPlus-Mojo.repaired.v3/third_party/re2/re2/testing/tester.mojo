from ..stringpiece import StringPiece
from ..prog import Prog
from ..regexp import Regexp, RegexpStatus
from ..re2 import RE2
from util.pcre import PCRE, PCRE_Options, PCRE_Arg
from util.util import BeginPtr, EndPtr, arraysize
from util.flags import GetFlag
from util.logging import LOG_INFO, LOG_ERROR, LOG_FATAL, LOG_QFATAL, VLOG
from util.strutil import CEscape, StringPrintf

# Define flags as global variables (simulating DEFINE_FLAG)
let FLAGS_dump_prog: Bool = False
let FLAGS_log_okay: Bool = False
let FLAGS_dump_rprog: Bool = False
let FLAGS_max_regexp_failures: Int = 100
let FLAGS_regexp_engines: String = ""

# UsingPCRE imported from util.pcre (assume exists)
from util.pcre import UsingPCRE

enum Engine:
    kEngineBacktrack = 0
    kEngineNFA = 1
    kEngineDFA = 2
    kEngineDFA1 = 3
    kEngineOnePass = 4
    kEngineBitState = 5
    kEngineRE2 = 6
    kEngineRE2a = 7
    kEngineRE2b = 8
    kEnginePCRE = 9
    kEngineMax = 10

def operator_plus_plus(inout e: Engine, unused: Int32):
    e = Engine(Int(e) + 1)

def operator_plus(e: Engine, i: Int32) -> Engine:
    return Engine(Int(e) + i)

# Global array of engine names
var engine_names: StaticArray[String, 10] = [
    "Backtrack",
    "NFA",
    "DFA",
    "DFA1",
    "OnePass",
    "BitState",
    "RE2",
    "RE2a",
    "RE2b",
    "PCRE",
]

def EngineName(e: Engine) -> String:
    assert e >= 0
    assert e < arraysize(engine_names)
    assert engine_names[e] != None
    return engine_names[e]

def Engines() -> UInt32:
    var did_parse: Bool = False
    var cached_engines: UInt32 = 0
    if did_parse:
        return cached_engines
    if GetFlag(FLAGS_regexp_engines).empty():
        cached_engines = ~0
    else:
        for i in range(Engine(0), kEngineMax):
            if GetFlag(FLAGS_regexp_engines).find(EngineName(i)) != -1:
                cached_engines |= 1 << i
    if cached_engines == 0:
        LOG_INFO("Warning: no engines enabled.")
    if not UsingPCRE:
        cached_engines &= ~(1 << kEnginePCRE)
    for i in range(Engine(0), kEngineMax):
        if cached_engines & (1 << i):
            LOG_INFO(EngineName(i) + " enabled")
    did_parse = True
    return cached_engines

struct TestInstance:
    struct Result:
        var skipped: Bool = False
        var matched: Bool = False
        var untrusted: Bool = False
        var have_submatch: Bool = False
        var have_submatch0: Bool = False
        var submatch: StaticArray[StringPiece, 17]  # kMaxSubmatch = 17

        def __init__(inout self):
            self.ClearSubmatch()

        def ClearSubmatch(inout self):
            for i in range(17):
                self.submatch[i] = StringPiece()

    var regexp_str_: StringPiece
    var kind_: Prog.MatchKind
    var flags_: Regexp.ParseFlags
    var error_: Bool
    var regexp_: Regexp
    var num_captures_: Int
    var prog_: Prog
    var rprog_: Prog
    var re_: PCRE
    var re2_: RE2

    def __init__(inout self, regexp_str: StringPiece, kind: Prog.MatchKind, flags: Regexp.ParseFlags):
        self.regexp_str_ = regexp_str
        self.kind_ = kind
        self.flags_ = flags
        self.error_ = False
        self.regexp_ = None
        self.num_captures_ = 0
        self.prog_ = None
        self.rprog_ = None
        self.re_ = None
        self.re2_ = None

        VLOG(1, CEscape(regexp_str))

        var status = RegexpStatus()
        self.regexp_ = Regexp.Parse(regexp_str, flags, status)
        if self.regexp_ == None:
            LOG_INFO("Cannot parse: " + CEscape(self.regexp_str_) + " mode: " + FormatMode(flags))
            self.error_ = True
            return

        self.num_captures_ = self.regexp_.NumCaptures()
        self.prog_ = self.regexp_.CompileToProg(0)
        if self.prog_ == None:
            LOG_INFO("Cannot compile: " + CEscape(self.regexp_str_))
            self.error_ = True
            return

        if GetFlag(FLAGS_dump_prog):
            LOG_INFO("Prog for  regexp " + CEscape(self.regexp_str_) + " (" + FormatKind(self.kind_) + ", " + FormatMode(flags) + ")\n" + self.prog_.Dump())

        if Engines() & ((1 << kEngineDFA) | (1 << kEngineDFA1)):
            self.rprog_ = self.regexp_.CompileToReverseProg(0)
            if self.rprog_ == None:
                LOG_INFO("Cannot reverse compile: " + CEscape(self.regexp_str_))
                self.error_ = True
                return
            if GetFlag(FLAGS_dump_rprog):
                LOG_INFO(self.rprog_.Dump())

        var re: String = String(self.regexp_str)
        if not (flags & Regexp.OneLine):
            re = "(?m)" + re
        if flags & Regexp.NonGreedy:
            re = "(?U)" + re
        if flags & Regexp.DotNL:
            re = "(?s)" + re

        if Engines() & ((1 << kEngineRE2) | (1 << kEngineRE2a) | (1 << kEngineRE2b)):
            var options = RE2.Options()
            if flags & Regexp.Latin1:
                options.set_encoding(RE2.Options.EncodingLatin1)
            if self.kind_ == Prog.kLongestMatch:
                options.set_longest_match(True)
            self.re2_ = RE2(re, options)
            if not self.re2_.error().empty():
                LOG_INFO("Cannot RE2: " + CEscape(re))
                self.error_ = True
                return

        if (Engines() & (1 << kEnginePCRE)) and self.regexp_.MimicsPCRE() and self.kind_ != Prog.kLongestMatch:
            var o = PCRE_Options()
            o.set_option(PCRE.UTF8)
            if flags & Regexp.Latin1:
                o.set_option(PCRE.None)
            self.re_ = PCRE("(" + re + ")", o)
            if not self.re_.error().empty():
                LOG_INFO("Cannot PCRE: " + CEscape(re))
                self.error_ = True
                return

    def __del__(inout self):
        if self.regexp_ != None:
            self.regexp_.Decref()
        delete self.prog_
        delete self.rprog_
        delete self.re_
        delete self.re2_

    def RunSearch(inout self, type_: Engine, orig_text: StringPiece, orig_context: StringPiece, anchor: Prog.Anchor, inout result: Result):
        if self.regexp_ == None:
            result.skipped = True
            return

        var nsubmatch: Int = 1 + self.num_captures_
        if nsubmatch > 17:
            nsubmatch = 17

        var text = orig_text
        var context = orig_context

        if type_ == kEngineBacktrack:
            if self.prog_ == None:
                result.skipped = True
                break
            result.matched = self.prog_.UnsafeSearchBacktrack(text, context, anchor, self.kind_, result.submatch, nsubmatch)
            result.have_submatch = True

        elif type_ == kEngineNFA:
            if self.prog_ == None:
                result.skipped = True
                break
            result.matched = self.prog_.SearchNFA(text, context, anchor, self.kind_, result.submatch, nsubmatch)
            result.have_submatch = True

        elif type_ == kEngineDFA:
            if self.prog_ == None:
                result.skipped = True
                break
            result.matched = self.prog_.SearchDFA(text, context, anchor, self.kind_, None, &result.skipped, None)

        elif type_ == kEngineDFA1:
            if self.prog_ == None or self.rprog_ == None:
                result.skipped = True
                break
            result.matched = self.prog_.SearchDFA(text, context, anchor, self.kind_, result.submatch, &result.skipped, None)
            if result.matched:
                if not self.rprog_.SearchDFA(result.submatch[0], context, Prog.kAnchored, Prog.kLongestMatch, result.submatch, &result.skipped, None):
                    LOG_ERROR("Reverse DFA inconsistency: " + CEscape(self.regexp_str_) + " on " + CEscape(text))
                    result.matched = False
            result.have_submatch0 = True

        elif type_ == kEngineOnePass:
            if self.prog_ == None or not self.prog_.IsOnePass() or anchor == Prog.kUnanchored or nsubmatch > Prog.kMaxOnePassCapture:
                result.skipped = True
                break
            result.matched = self.prog_.SearchOnePass(text, context, anchor, self.kind_, result.submatch, nsubmatch)
            result.have_submatch = True

        elif type_ == kEngineBitState:
            if self.prog_ == None or not self.prog_.CanBitState():
                result.skipped = True
                break
            result.matched = self.prog_.SearchBitState(text, context, anchor, self.kind_, result.submatch, nsubmatch)
            result.have_submatch = True

        elif type_ == kEngineRE2 or type_ == kEngineRE2a or type_ == kEngineRE2b:
            if self.re2_ == None or EndPtr(text) != EndPtr(context):
                result.skipped = True
            else:
                var re_anchor: RE2.Anchor
                if anchor == Prog.kAnchored:
                    re_anchor = RE2.ANCHOR_START
                else:
                    re_anchor = RE2.UNANCHORED
                if self.kind_ == Prog.kFullMatch:
                    re_anchor = RE2.ANCHOR_BOTH
                result.matched = self.re2_.Match(
                    context,
                    (BeginPtr(text) - BeginPtr(context)) as size_t,
                    (EndPtr(text) - BeginPtr(context)) as size_t,
                    re_anchor,
                    result.submatch,
                    nsubmatch)
                result.have_submatch = nsubmatch > 0

        elif type_ == kEnginePCRE:
            if self.re_ == None or BeginPtr(text) != BeginPtr(context) or EndPtr(text) != EndPtr(context):
                result.skipped = True
            elif (self.regexp_str_.find("\\v") != -1 and
                  (text.find('\n') != -1 or text.find('\f') != -1 or text.find('\r') != -1)):
                result.skipped = True
            elif ((self.regexp_str_.find("\\s") != -1 or self.regexp_str_.find("\\S") != -1) and
                  text.find('\v') != -1):
                result.skipped = True
            else:
                var argptr = new PCRE.ArgPtr[nsubmatch]
                var a = new PCRE.Arg[nsubmatch]
                for i in range(nsubmatch):
                    a[i] = PCRE.Arg(&result.submatch[i])
                    argptr[i] = &a[i]
                var consumed: size_t
                var pcre_anchor: PCRE.Anchor
                if anchor == Prog.kAnchored:
                    pcre_anchor = PCRE.ANCHOR_START
                else:
                    pcre_anchor = PCRE.UNANCHORED
                if self.kind_ == Prog.kFullMatch:
                    pcre_anchor = PCRE.ANCHOR_BOTH
                self.re_.ClearHitLimit()
                result.matched = self.re_.DoMatch(text, pcre_anchor, &consumed, argptr, nsubmatch)
                if self.re_.HitLimit():
                    result.untrusted = True
                    delete[] argptr
                    delete[] a
                else:
                    result.have_submatch = True
                    delete[] argptr
                    delete[] a

        if not result.matched:
            result.ClearSubmatch()

def ResultOkay(r: Result, correct: Result) -> Bool:
    if r.skipped:
        return True
    if r.matched != correct.matched:
        return False
    if r.have_submatch or r.have_submatch0:
        for i in range(17):
            if correct.submatch[i].data() != r.submatch[i].data() or correct.submatch[i].size() != r.submatch[i].size():
                return False
            if not r.have_submatch:
                break
    return True

def TestInstance.RunCase(inout self, text: StringPiece, context: StringPiece, anchor: Prog.Anchor) -> Bool:
    var correct = Result()
    self.RunSearch(kEngineBacktrack, text, context, anchor, &correct)
    if correct.skipped:
        if self.regexp_ == None:
            return True
        LOG_ERROR("Skipped backtracking! " + CEscape(self.regexp_str_) + " " + FormatMode(self.flags_))
        return False

    VLOG(1, "Try: regexp " + CEscape(self.regexp_str_) + " text " + CEscape(text) + " (" + FormatKind(self.kind_) + ", " + FormatAnchor(anchor) + ", " + FormatMode(self.flags_) + ")")

    var all_okay: Bool = True
    for i in range(kEngineBacktrack+1, kEngineMax):
        if not (Engines() & (1 << i)):
            continue
        var r = Result()
        self.RunSearch(Engine(i), text, context, anchor, &r)
        if ResultOkay(r, correct):
            if GetFlag(FLAGS_log_okay):
                self.LogMatch("Skipped: " if r.skipped else "Okay: ", Engine(i), text, context, anchor)
            continue
        if i == kEnginePCRE and NonASCII(text):
            continue
        if not r.untrusted:
            all_okay = False
        self.LogMatch("(Untrusted) Mismatch: " if r.untrusted else "Mismatch: ", Engine(i), text, context, anchor)
        if r.matched != correct.matched:
            if r.matched:
                LOG_INFO("   Should not match (but does).")
            else:
                LOG_INFO("   Should match (but does not).")
                continue
        for j in range(1 + self.num_captures_):
            if r.submatch[j].data() != correct.submatch[j].data() or r.submatch[j].size() != correct.submatch[j].size():
                LOG_INFO(StringPrintf("   $%d: should be %s is %s", j, FormatCapture(text, correct.submatch[j]), FormatCapture(text, r.submatch[j])))
            else:
                LOG_INFO(StringPrintf("   $%d: %s ok", j, FormatCapture(text, r.submatch[j])))

    if not all_okay:
        var max_regexp_failures: Int = GetFlag(FLAGS_max_regexp_failures)
        if max_regexp_failures > 0:
            max_regexp_failures -= 1
            if max_regexp_failures == 0:
                LOG_QFATAL("Too many regexp failures.")
    return all_okay

def TestInstance.LogMatch(inout self, prefix: String, e: Engine, text: StringPiece, context: StringPiece, anchor: Prog.Anchor):
    LOG_INFO(prefix + EngineName(e) + " regexp " + CEscape(self.regexp_str_) + " " + CEscape(self.regexp_.ToString()) + " text " + CEscape(text) + " (" + (BeginPtr(text) - BeginPtr(context)).to_string() + "," + (EndPtr(text) - BeginPtr(context)).to_string() + ") of context " + CEscape(context) + " (" + FormatKind(self.kind_) + ", " + FormatAnchor(anchor) + ", " + FormatMode(self.flags_) + ")")

var kinds: StaticArray[Prog.MatchKind, 3] = [
    Prog.kFirstMatch,
    Prog.kLongestMatch,
    Prog.kFullMatch,
]

struct Tester:
    var error_: Bool
    var v_: List[Owned[TestInstance]]

    def __init__(inout self, regexp: StringPiece):
        self.error_ = False
        for i in range(arraysize(kinds)):
            for j in range(arraysize(parse_modes)):
                var t = new TestInstance(regexp, kinds[i], parse_modes[j].parse_flags)
                self.error_ = self.error_ or t.error()
                self.v_.push_back(t)

    def __del__(inout self):
        for i in range(len(self.v_)):
            delete self.v_[i]

    def TestCase(inout self, text: StringPiece, context: StringPiece, anchor: Prog.Anchor) -> Bool:
        var okay: Bool = True
        for i in range(len(self.v_)):
            okay = okay and (not self.v_[i].error()) and self.v_[i].RunCase(text, context, anchor)
        return okay

    def TestInput(inout self, text: StringPiece) -> Bool:
        var okay = self.TestInputInContext(text, text)
        if not text.empty():
            var sp = text
            sp.remove_prefix(1)
            okay = okay and self.TestInputInContext(sp, text)
            sp = text
            sp.remove_suffix(1)
            okay = okay and self.TestInputInContext(sp, text)
        return okay

    def TestInputInContext(inout self, text: StringPiece, context: StringPiece) -> Bool:
        var okay: Bool = True
        for i in range(arraysize(anchors)):
            okay = okay and self.TestCase(text, context, anchors[i])
        return okay

var anchors: StaticArray[Prog.Anchor, 2] = [
    Prog.kAnchored,
    Prog.kUnanchored
]

def TestRegexpOnText(regexp: StringPiece, text: StringPiece) -> Bool:
    var t = Tester(regexp)
    return t.TestInput(text)

# Helper functions (from original C++ file)

def FormatCapture(text: StringPiece, s: StringPiece) -> String:
    if s.data() == None:
        return "(?,?)"
    return StringPrintf("(%td,%td)",
                        BeginPtr(s) - BeginPtr(text),
                        EndPtr(s) - BeginPtr(text))

def NonASCII(text: StringPiece) -> Bool:
    for i in range(text.size()):
        if (text[i] as UInt8) >= 0x80:
            return True
    return False

def FormatKind(kind: Prog.MatchKind) -> String:
    if kind == Prog.kFullMatch:
        return "full match"
    elif kind == Prog.kLongestMatch:
        return "longest match"
    elif kind == Prog.kFirstMatch:
        return "first match"
    elif kind == Prog.kManyMatch:
        return "many match"
    return "???"

def FormatAnchor(anchor: Prog.Anchor) -> String:
    if anchor == Prog.kAnchored:
        return "anchored"
    elif anchor == Prog.kUnanchored:
        return "unanchored"
    return "???"

struct ParseMode:
    var parse_flags: Regexp.ParseFlags
    var desc: String

let single_line: Regexp.ParseFlags = Regexp.LikePerl
let multi_line: Regexp.ParseFlags = (Regexp.LikePerl & ~Regexp.OneLine) as Regexp.ParseFlags

var parse_modes: StaticArray[ParseMode, 5] = [
    ParseMode(single_line, "single-line"),
    ParseMode(single_line | Regexp.Latin1, "single-line, latin1"),
    ParseMode(multi_line, "multiline"),
    ParseMode(multi_line | Regexp.NonGreedy, "multiline, nongreedy"),
    ParseMode(multi_line | Regexp.Latin1, "multiline, latin1"),
]

def FormatMode(flags: Regexp.ParseFlags) -> String:
    for i in range(arraysize(parse_modes)):
        if parse_modes[i].parse_flags == flags:
            return parse_modes[i].desc
    return StringPrintf("%#x", flags as UInt32)

# The constants kMaxSubmatch is used inside Result struct (17)
let kMaxSubmatch: Int = 17