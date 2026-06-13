from util.util import *
from util.logging import *
from util.strutil import *
from util.utf import *
from .pod_array import *
from regexp import *
from stringpiece import *
from unicode_casefold import *
from unicode_groups import *
from re2.walker-inl import *

# if defined(RE2_USE_ICU)
# include "unicode/uniset.h"
# include "unicode/unistr.h"
# include "unicode/utypes.h"
# endif

namespace re2:

    var maximum_repeat_count: Int = 1000

    def Regexp.FUZZING_ONLY_set_maximum_repeat_count(i: Int):
        maximum_repeat_count = i

    @value
    struct Regexp.ParseState:
        var flags_: ParseFlags
        var whole_regexp_: StringPiece
        var status_: RegexpStatus
        var stacktop_: Regexp
        var ncap_: Int
        var rune_max_: Int

        def __init__(inout self, flags: ParseFlags, whole_regexp: StringPiece, status: RegexpStatus):
            self.flags_ = flags
            self.whole_regexp_ = whole_regexp
            self.status_ = status
            self.stacktop_ = None
            self.ncap_ = 0
            if self.flags_ & Latin1:
                self.rune_max_ = 0xFF
            else:
                self.rune_max_ = Runemax

        def __del__(owned self):
            var next: Regexp
            var re: Regexp = self.stacktop_
            while re is not None:
                next = re.down_
                re.down_ = None
                if re.op() == kLeftParen:
                    delete re.name_
                re.Decref()
                re = next

        def FinishRegexp(self, re: Regexp) -> Regexp:
            if re is None:
                return None
            re.down_ = None
            if re.op_ == kRegexpCharClass and re.ccb_ is not None:
                var ccb: CharClassBuilder = re.ccb_
                re.ccb_ = None
                re.cc_ = ccb.GetCharClass()
                delete ccb
            return re

        def PushRegexp(inout self, re: Regexp) -> Bool:
            self.MaybeConcatString(-1, NoParseFlags)
            if re.op_ == kRegexpCharClass and re.ccb_ is not None:
                re.ccb_.RemoveAbove(self.rune_max_)
                if re.ccb_.size() == 1:
                    var r: Rune = re.ccb_.begin().lo
                    re.Decref()
                    re = Regexp(kRegexpLiteral, self.flags_)
                    re.rune_ = r
                elif re.ccb_.size() == 2:
                    var r: Rune = re.ccb_.begin().lo
                    if 'A' <= r and r <= 'Z' and re.ccb_.Contains(r + 'a' - 'A'):
                        re.Decref()
                        re = Regexp(kRegexpLiteral, self.flags_ | FoldCase)
                        re.rune_ = r + 'a' - 'A'
            if not self.IsMarker(re.op()):
                re.simple_ = re.ComputeSimple()
            re.down_ = self.stacktop_
            self.stacktop_ = re
            return True

        def PushLiteral(inout self, r: Rune) -> Bool:
            if (self.flags_ & FoldCase) and CycleFoldRune(r) != r:
                var re: Regexp = Regexp(kRegexpCharClass, self.flags_ & ~FoldCase)
                re.ccb_ = CharClassBuilder()
                var r1: Rune = r
                while True:
                    if not (self.flags_ & NeverNL) or r != '\n':
                        re.ccb_.AddRange(r, r)
                    r = CycleFoldRune(r)
                    if r == r1:
                        break
                return self.PushRegexp(re)
            if (self.flags_ & NeverNL) and r == '\n':
                return self.PushRegexp(Regexp(kRegexpNoMatch, self.flags_))
            if self.MaybeConcatString(r, self.flags_):
                return True
            var re: Regexp = Regexp(kRegexpLiteral, self.flags_)
            re.rune_ = r
            return self.PushRegexp(re)

        def PushCaret(inout self) -> Bool:
            if self.flags_ & OneLine:
                return self.PushSimpleOp(kRegexpBeginText)
            return self.PushSimpleOp(kRegexpBeginLine)

        def PushWordBoundary(inout self, word: Bool) -> Bool:
            if word:
                return self.PushSimpleOp(kRegexpWordBoundary)
            return self.PushSimpleOp(kRegexpNoWordBoundary)

        def PushDollar(inout self) -> Bool:
            if self.flags_ & OneLine:
                var oflags: Regexp.ParseFlags = self.flags_
                self.flags_ = self.flags_ | WasDollar
                var ret: Bool = self.PushSimpleOp(kRegexpEndText)
                self.flags_ = oflags
                return ret
            return self.PushSimpleOp(kRegexpEndLine)

        def PushDot(inout self) -> Bool:
            if (self.flags_ & DotNL) and not (self.flags_ & NeverNL):
                return self.PushSimpleOp(kRegexpAnyChar)
            var re: Regexp = Regexp(kRegexpCharClass, self.flags_ & ~FoldCase)
            re.ccb_ = CharClassBuilder()
            re.ccb_.AddRange(0, '\n' - 1)
            re.ccb_.AddRange('\n' + 1, self.rune_max_)
            return self.PushRegexp(re)

        def PushSimpleOp(inout self, op: RegexpOp) -> Bool:
            var re: Regexp = Regexp(op, self.flags_)
            return self.PushRegexp(re)

        def PushRepeatOp(inout self, op: RegexpOp, s: StringPiece, nongreedy: Bool) -> Bool:
            if self.stacktop_ is None or self.IsMarker(self.stacktop_.op()):
                self.status_.set_code(kRegexpRepeatArgument)
                self.status_.set_error_arg(s)
                return False
            var fl: Regexp.ParseFlags = self.flags_
            if nongreedy:
                fl = fl ^ NonGreedy
            if op == self.stacktop_.op() and fl == self.stacktop_.parse_flags():
                return True
            if (self.stacktop_.op() == kRegexpStar or
                self.stacktop_.op() == kRegexpPlus or
                self.stacktop_.op() == kRegexpQuest) and fl == self.stacktop_.parse_flags():
                self.stacktop_.op_ = kRegexpStar
                return True
            var re: Regexp = Regexp(op, fl)
            re.AllocSub(1)
            re.down_ = self.stacktop_.down_
            re.sub()[0] = self.FinishRegexp(self.stacktop_)
            re.simple_ = re.ComputeSimple()
            self.stacktop_ = re
            return True

        def PushRepetition(inout self, min: Int, max: Int, s: StringPiece, nongreedy: Bool) -> Bool:
            if (max != -1 and max < min) or min > maximum_repeat_count or max > maximum_repeat_count:
                self.status_.set_code(kRegexpRepeatSize)
                self.status_.set_error_arg(s)
                return False
            if self.stacktop_ is None or self.IsMarker(self.stacktop_.op()):
                self.status_.set_code(kRegexpRepeatArgument)
                self.status_.set_error_arg(s)
                return False
            var fl: Regexp.ParseFlags = self.flags_
            if nongreedy:
                fl = fl ^ NonGreedy
            var re: Regexp = Regexp(kRegexpRepeat, fl)
            re.min_ = min
            re.max_ = max
            re.AllocSub(1)
            re.down_ = self.stacktop_.down_
            re.sub()[0] = self.FinishRegexp(self.stacktop_)
            re.simple_ = re.ComputeSimple()
            self.stacktop_ = re
            if min >= 2 or max >= 2:
                var w: RepetitionWalker = RepetitionWalker()
                if w.Walk(self.stacktop_, maximum_repeat_count) == 0:
                    self.status_.set_code(kRegexpRepeatSize)
                    self.status_.set_error_arg(s)
                    return False
            return True

        def IsMarker(self, op: RegexpOp) -> Bool:
            return op >= kLeftParen

        def DoLeftParen(inout self, name: StringPiece) -> Bool:
            var re: Regexp = Regexp(kLeftParen, self.flags_)
            re.cap_ = self.ncap_ + 1
            self.ncap_ += 1
            if name.data() is not None:
                re.name_ = String(name)
            return self.PushRegexp(re)

        def DoLeftParenNoCapture(inout self) -> Bool:
            var re: Regexp = Regexp(kLeftParen, self.flags_)
            re.cap_ = -1
            return self.PushRegexp(re)

        def DoVerticalBar(inout self) -> Bool:
            self.MaybeConcatString(-1, NoParseFlags)
            self.DoConcatenation()
            var r1: Regexp
            var r2: Regexp
            r1 = self.stacktop_
            if r1 is not None:
                r2 = r1.down_
                if r2 is not None and r2.op() == kVerticalBar:
                    var r3: Regexp = r2.down_
                    if r3 is not None and (r1.op() == kRegexpAnyChar or r3.op() == kRegexpAnyChar):
                        if r3.op() == kRegexpAnyChar and (r1.op() == kRegexpLiteral or r1.op() == kRegexpCharClass or r1.op() == kRegexpAnyChar):
                            self.stacktop_ = r2
                            r1.Decref()
                            return True
                        if r1.op() == kRegexpAnyChar and (r3.op() == kRegexpLiteral or r3.op() == kRegexpCharClass or r3.op() == kRegexpAnyChar):
                            r1.down_ = r3.down_
                            r2.down_ = r1
                            self.stacktop_ = r2
                            r3.Decref()
                            return True
                    r1.down_ = r2.down_
                    r2.down_ = r1
                    self.stacktop_ = r2
                    return True
            return self.PushSimpleOp(kVerticalBar)

        def DoRightParen(inout self) -> Bool:
            self.DoAlternation()
            var r1: Regexp
            var r2: Regexp
            r1 = self.stacktop_
            if r1 is None:
                self.status_.set_code(kRegexpUnexpectedParen)
                self.status_.set_error_arg(self.whole_regexp_)
                return False
            r2 = r1.down_
            if r2 is None or r2.op() != kLeftParen:
                self.status_.set_code(kRegexpUnexpectedParen)
                self.status_.set_error_arg(self.whole_regexp_)
                return False
            self.stacktop_ = r2.down_
            var re: Regexp = r2
            self.flags_ = re.parse_flags()
            if re.cap_ > 0:
                re.op_ = kRegexpCapture
                re.AllocSub(1)
                re.sub()[0] = self.FinishRegexp(r1)
                re.simple_ = re.ComputeSimple()
            else:
                re.Decref()
                re = r1
            return self.PushRegexp(re)

        def DoFinish(inout self) -> Regexp:
            self.DoAlternation()
            var re: Regexp = self.stacktop_
            if re is not None and re.down_ is not None:
                self.status_.set_code(kRegexpMissingParen)
                self.status_.set_error_arg(self.whole_regexp_)
                return None
            self.stacktop_ = None
            return self.FinishRegexp(re)

        def DoConcatenation(inout self):
            var r1: Regexp = self.stacktop_
            if r1 is None or self.IsMarker(r1.op()):
                var re: Regexp = Regexp(kRegexpEmptyMatch, self.flags_)
                self.PushRegexp(re)
            self.DoCollapse(kRegexpConcat)

        def DoAlternation(inout self):
            self.DoVerticalBar()
            var r1: Regexp = self.stacktop_
            self.stacktop_ = r1.down_
            r1.Decref()
            self.DoCollapse(kRegexpAlternate)

        def DoCollapse(inout self, op: RegexpOp):
            var n: Int = 0
            var next: Regexp = None
            var sub: Regexp
            sub = self.stacktop_
            while sub is not None and not self.IsMarker(sub.op()):
                next = sub.down_
                if sub.op_ == op:
                    n += sub.nsub_
                else:
                    n += 1
                sub = next
            if self.stacktop_ is not None and self.stacktop_.down_ == next:
                return
            var subs: PODArray[Regexp] = PODArray[Regexp](n)
            next = None
            var i: Int = n
            sub = self.stacktop_
            while sub is not None and not self.IsMarker(sub.op()):
                next = sub.down_
                if sub.op_ == op:
                    var sub_subs: Regexp = sub.sub()
                    var k: Int = sub.nsub_ - 1
                    while k >= 0:
                        i -= 1
                        subs[i] = sub_subs[k].Incref()
                        k -= 1
                    sub.Decref()
                else:
                    i -= 1
                    subs[i] = self.FinishRegexp(sub)
                sub = next
            var re: Regexp = ConcatOrAlternate(op, subs.data(), n, self.flags_, True)
            re.simple_ = re.ComputeSimple()
            re.down_ = next
            self.stacktop_ = re

        def MaybeConcatString(inout self, r: Int, flags: ParseFlags) -> Bool:
            var re1: Regexp
            var re2: Regexp
            re1 = self.stacktop_
            if re1 is None:
                return False
            re2 = re1.down_
            if re2 is None:
                return False
            if re1.op_ != kRegexpLiteral and re1.op_ != kRegexpLiteralString:
                return False
            if re2.op_ != kRegexpLiteral and re2.op_ != kRegexpLiteralString:
                return False
            if (re1.parse_flags_ & FoldCase) != (re2.parse_flags_ & FoldCase):
                return False
            if re2.op_ == kRegexpLiteral:
                var rune: Rune = re2.rune_
                re2.op_ = kRegexpLiteralString
                re2.nrunes_ = 0
                re2.runes_ = None
                re2.AddRuneToString(rune)
            if re1.op_ == kRegexpLiteral:
                re2.AddRuneToString(re1.rune_)
            else:
                var i: Int = 0
                while i < re1.nrunes_:
                    re2.AddRuneToString(re1.runes_[i])
                    i += 1
                re1.nrunes_ = 0
                delete[] re1.runes_
                re1.runes_ = None
            if r >= 0:
                re1.op_ = kRegexpLiteral
                re1.rune_ = r
                re1.parse_flags_ = UInt16(flags)
                return True
            self.stacktop_ = re2
            re1.Decref()
            return False

        def ParseCharClass(inout self, s: StringPiece, out_re: Regexp, status: RegexpStatus) -> Bool:
            var whole_class: StringPiece = s
            if s.empty() or s[0] != '[':
                status.set_code(kRegexpInternalError)
                status.set_error_arg(StringPiece())
                return False
            var negated: Bool = False
            var re: Regexp = Regexp(kRegexpCharClass, self.flags_ & ~FoldCase)
            re.ccb_ = CharClassBuilder()
            s.remove_prefix(1)
            if not s.empty() and s[0] == '^':
                s.remove_prefix(1)
                negated = True
                if not (self.flags_ & ClassNL) or (self.flags_ & NeverNL):
                    re.ccb_.AddRange('\n', '\n')
            var first: Bool = True
            while not s.empty() and (s[0] != ']' or first):
                if s[0] == '-' and not first and not (self.flags_ & PerlX) and (s.size() == 1 or s[1] != ']'):
                    var t: StringPiece = s
                    t.remove_prefix(1)
                    var r: Rune
                    var n: Int = StringPieceToRune(r, t, status)
                    if n < 0:
                        re.Decref()
                        return False
                    status.set_code(kRegexpBadCharRange)
                    status.set_error_arg(StringPiece(s.data(), 1 + n))
                    re.Decref()
                    return False
                first = False
                if s.size() > 2 and s[0] == '[' and s[1] == ':':
                    var parse_result: ParseStatus = ParseCCName(s, self.flags_, re.ccb_, status)
                    if parse_result == kParseOk:
                        continue
                    elif parse_result == kParseError:
                        re.Decref()
                        return False
                    else:

                if s.size() > 2 and s[0] == '\\' and (s[1] == 'p' or s[1] == 'P'):
                    var parse_result: ParseStatus = ParseUnicodeGroup(s, self.flags_, re.ccb_, status)
                    if parse_result == kParseOk:
                        continue
                    elif parse_result == kParseError:
                        re.Decref()
                        return False
                    else:

                var g: UGroup = MaybeParsePerlCCEscape(s, self.flags_)
                if g is not None:
                    AddUGroup(re.ccb_, g, g.sign, self.flags_)
                    continue
                var rr: RuneRange
                if not self.ParseCCRange(s, rr, whole_class, status):
                    re.Decref()
                    return False
                re.ccb_.AddRangeFlags(rr.lo, rr.hi, self.flags_ | Regexp.ClassNL)
            if s.empty():
                status.set_code(kRegexpMissingBracket)
                status.set_error_arg(whole_class)
                re.Decref()
                return False
            s.remove_prefix(1)
            if negated:
                re.ccb_.Negate()
            out_re = re
            return True

        def ParseCCCharacter(inout self, s: StringPiece, rp: Rune, whole_class: StringPiece, status: RegexpStatus) -> Bool:
            if s.empty():
                status.set_code(kRegexpMissingBracket)
                status.set_error_arg(whole_class)
                return False
            if s[0] == '\\':
                return ParseEscape(s, rp, status, self.rune_max_)
            return StringPieceToRune(rp, s, status) >= 0

        def ParseCCRange(inout self, s: StringPiece, rr: RuneRange, whole_class: StringPiece, status: RegexpStatus) -> Bool:
            var os: StringPiece = s
            if not self.ParseCCCharacter(s, rr.lo, whole_class, status):
                return False
            if s.size() >= 2 and s[0] == '-' and s[1] != ']':
                s.remove_prefix(1)
                if not self.ParseCCCharacter(s, rr.hi, whole_class, status):
                    return False
                if rr.hi < rr.lo:
                    status.set_code(kRegexpBadCharRange)
                    status.set_error_arg(StringPiece(os.data(), s.data() - os.data()))
                    return False
            else:
                rr.hi = rr.lo
            return True

        def ParsePerlFlags(inout self, s: StringPiece) -> Bool:
            var t: StringPiece = s
            if not (self.flags_ & PerlX) or t.size() < 2 or t[0] != '(' or t[1] != '?':
                LOG(DFATAL, "Bad call to ParseState::ParsePerlFlags")
                self.status_.set_code(kRegexpInternalError)
                return False
            t.remove_prefix(2)
            if t.size() > 2 and t[0] == 'P' and t[1] == '<':
                var end: Int = t.find('>', 2)
                if end == StringPiece.npos:
                    if not IsValidUTF8(s, self.status_):
                        return False
                    self.status_.set_code(kRegexpBadNamedCapture)
                    self.status_.set_error_arg(s)
                    return False
                var capture: StringPiece = StringPiece(t.data() - 2, end + 3)
                var name: StringPiece = StringPiece(t.data() + 2, end - 2)
                if not IsValidUTF8(name, self.status_):
                    return False
                if not IsValidCaptureName(name):
                    self.status_.set_code(kRegexpBadNamedCapture)
                    self.status_.set_error_arg(capture)
                    return False
                if not self.DoLeftParen(name):
                    return False
                s.remove_prefix(capture.data() + capture.size() - s.data())
                return True
            var negated: Bool = False
            var sawflags: Bool = False
            var nflags: Int = self.flags_
            var c: Rune
            var done: Bool = False
            while not done:
                if t.empty():
                    goto BadPerlOp
                if StringPieceToRune(c, t, self.status_) < 0:
                    return False
                if c == 'i':
                    sawflags = True
                    if negated:
                        nflags &= ~FoldCase
                    else:
                        nflags |= FoldCase
                elif c == 'm':
                    sawflags = True
                    if negated:
                        nflags |= OneLine
                    else:
                        nflags &= ~OneLine
                elif c == 's':
                    sawflags = True
                    if negated:
                        nflags &= ~DotNL
                    else:
                        nflags |= DotNL
                elif c == 'U':
                    sawflags = True
                    if negated:
                        nflags &= ~NonGreedy
                    else:
                        nflags |= NonGreedy
                elif c == '-':
                    if negated:
                        goto BadPerlOp
                    negated = True
                    sawflags = False
                elif c == ':':
                    if not self.DoLeftParenNoCapture():
                        return False
                    done = True
                elif c == ')':
                    done = True
                else:
                    goto BadPerlOp
            if negated and not sawflags:
                goto BadPerlOp
            self.flags_ = Regexp.ParseFlags(nflags)
            s = t
            return True
        BadPerlOp:
            self.status_.set_code(kRegexpBadPerlOp)
            self.status_.set_error_arg(StringPiece(s.data(), t.data() - s.data()))
            return False

    def LookupCaseFold(f: CaseFold, n: Int, r: Rune) -> CaseFold:
        var ef: CaseFold = f + n
        while n > 0:
            var m: Int = n // 2
            if f[m].lo <= r and r <= f[m].hi:
                return f[m]
            if r < f[m].lo:
                n = m
            else:
                f += m + 1
                n -= m + 1
        if f < ef:
            return f
        return None

    def ApplyFold(f: CaseFold, r: Rune) -> Rune:
        if f.delta == EvenOddSkip:
            if (r - f.lo) % 2:
                return r
            # FALLTHROUGH_INTENDED
            if r % 2 == 0:
                return r + 1
            return r - 1
        elif f.delta == EvenOdd:
            if r % 2 == 0:
                return r + 1
            return r - 1
        elif f.delta == OddEvenSkip:
            if (r - f.lo) % 2:
                return r
            # FALLTHROUGH_INTENDED
            if r % 2 == 1:
                return r + 1
            return r - 1
        elif f.delta == OddEven:
            if r % 2 == 1:
                return r + 1
            return r - 1
        else:
            return r + f.delta

    def CycleFoldRune(r: Rune) -> Rune:
        var f: CaseFold = LookupCaseFold(unicode_casefold, num_unicode_casefold, r)
        if f is None or r < f.lo:
            return r
        return ApplyFold(f, r)

    def AddFoldedRange(cc: CharClassBuilder, lo: Rune, hi: Rune, depth: Int):
        if depth > 10:
            LOG(DFATAL, "AddFoldedRange recurses too much.")
            return
        if not cc.AddRange(lo, hi):
            return
        while lo <= hi:
            var f: CaseFold = LookupCaseFold(unicode_casefold, num_unicode_casefold, lo)
            if f is None:
                break
            if lo < f.lo:
                lo = f.lo
                continue
            var lo1: Rune = lo
            var hi1: Rune = min(hi, f.hi)
            if f.delta == EvenOdd:
                if lo1 % 2 == 1:
                    lo1 -= 1
                if hi1 % 2 == 0:
                    hi1 += 1
            elif f.delta == OddEven:
                if lo1 % 2 == 0:
                    lo1 -= 1
                if hi1 % 2 == 1:
                    hi1 += 1
            else:
                lo1 += f.delta
                hi1 += f.delta
            AddFoldedRange(cc, lo1, hi1, depth + 1)
            lo = f.hi + 1

    @value
    struct RepetitionWalker(Regexp.Walker[Int]):
        def PreVisit(self, re: Regexp, parent_arg: Int, stop: Bool) -> Int:
            var arg: Int = parent_arg
            if re.op() == kRegexpRepeat:
                var m: Int = re.max()
                if m < 0:
                    m = re.min()
                if m > 0:
                    arg //= m
            return arg

        def PostVisit(self, re: Regexp, parent_arg: Int, pre_arg: Int, child_args: Int, nchild_args: Int) -> Int:
            var arg: Int = pre_arg
            var i: Int = 0
            while i < nchild_args:
                if child_args[i] < arg:
                    arg = child_args[i]
                i += 1
            return arg

        def ShortVisit(self, re: Regexp, parent_arg: Int) -> Int:
            # ifndef FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
            LOG(DFATAL, "RepetitionWalker::ShortVisit called")
            # endif
            return 0

    def Regexp.LeadingRegexp(re: Regexp) -> Regexp:
        if re.op() == kRegexpEmptyMatch:
            return None
        if re.op() == kRegexpConcat and re.nsub() >= 2:
            var sub: Regexp = re.sub()
            if sub[0].op() == kRegexpEmptyMatch:
                return None
            return sub[0]
        return re

    def Regexp.RemoveLeadingRegexp(re: Regexp) -> Regexp:
        if re.op() == kRegexpEmptyMatch:
            return re
        if re.op() == kRegexpConcat and re.nsub() >= 2:
            var sub: Regexp = re.sub()
            if sub[0].op() == kRegexpEmptyMatch:
                return re
            sub[0].Decref()
            sub[0] = None
            if re.nsub() == 2:
                var nre: Regexp = sub[1]
                sub[1] = None
                re.Decref()
                return nre
            re.nsub_ -= 1
            memmove(sub, sub + 1, re.nsub_ * sizeof sub[0])
            return re
        var pf: Regexp.ParseFlags = re.parse_flags()
        re.Decref()
        return Regexp(kRegexpEmptyMatch, pf)

    def Regexp.LeadingString(re: Regexp, nrune: Int, flags: Regexp.ParseFlags) -> Rune:
        while re.op() == kRegexpConcat and re.nsub() > 0:
            re = re.sub()[0]
        flags = Regexp.ParseFlags(re.parse_flags_ & Regexp.FoldCase)
        if re.op() == kRegexpLiteral:
            nrune = 1
            return re.rune_
        if re.op() == kRegexpLiteralString:
            nrune = re.nrunes_
            return re.runes_
        nrune = 0
        return None

    def Regexp.RemoveLeadingString(re: Regexp, n: Int):
        var stk: Regexp[4]
        var d: Int = 0
        while re.op() == kRegexpConcat:
            if d < arraysize(stk):
                stk[d] = re
                d += 1
            re = re.sub()[0]
        if re.op() == kRegexpLiteral:
            re.rune_ = 0
            re.op_ = kRegexpEmptyMatch
        elif re.op() == kRegexpLiteralString:
            if n >= re.nrunes_:
                delete[] re.runes_
                re.runes_ = None
                re.nrunes_ = 0
                re.op_ = kRegexpEmptyMatch
            elif n == re.nrunes_ - 1:
                var rune: Rune = re.runes_[re.nrunes_ - 1]
                delete[] re.runes_
                re.runes_ = None
                re.nrunes_ = 0
                re.rune_ = rune
                re.op_ = kRegexpLiteral
            else:
                re.nrunes_ -= n
                memmove(re.runes_, re.runes_ + n, re.nrunes_ * sizeof re.runes_[0])
        while d > 0:
            d -= 1
            re = stk[d]
            var sub: Regexp = re.sub()
            if sub[0].op() == kRegexpEmptyMatch:
                sub[0].Decref()
                sub[0] = None
                if re.nsub() == 0 or re.nsub() == 1:
                    LOG(DFATAL, "Concat of ", re.nsub())
                    re.submany_ = None
                    re.op_ = kRegexpEmptyMatch
                elif re.nsub() == 2:
                    var old: Regexp = sub[1]
                    sub[1] = None
                    re.Swap(old)
                    old.Decref()
                else:
                    re.nsub_ -= 1
                    memmove(sub, sub + 1, re.nsub_ * sizeof sub[0])

    @value
    struct Splice:
        var prefix: Regexp
        var sub: Regexp
        var nsub: Int
        var nsuffix: Int

        def __init__(inout self, prefix: Regexp, sub: Regexp, nsub: Int):
            self.prefix = prefix
            self.sub = sub
            self.nsub = nsub
            self.nsuffix = -1

    @value
    struct Frame:
        var sub: Regexp
        var nsub: Int
        var round: Int
        var splices: List[Splice]
        var spliceidx: Int

        def __init__(inout self, sub: Regexp, nsub: Int):
            self.sub = sub
            self.nsub = nsub
            self.round = 0
            self.splices = List[Splice]()
            self.spliceidx = 0

    @value
    struct FactorAlternationImpl:
        @staticmethod
        def Round1(sub: Regexp, nsub: Int, flags: Regexp.ParseFlags, splices: List[Splice]):
            var start: Int = 0
            var rune: Rune = None
            var nrune: Int = 0
            var runeflags: Regexp.ParseFlags = Regexp.NoParseFlags
            var i: Int = 0
            while i <= nsub:
                var rune_i: Rune = None
                var nrune_i: Int = 0
                var runeflags_i: Regexp.ParseFlags = Regexp.NoParseFlags
                if i < nsub:
                    rune_i = Regexp.LeadingString(sub[i], nrune_i, runeflags_i)
                    if runeflags_i == runeflags:
                        var same: Int = 0
                        while same < nrune and same < nrune_i and rune[same] == rune_i[same]:
                            same += 1
                        if same > 0:
                            nrune = same
                            i += 1
                            continue
                if i == start:

                elif i == start + 1:

                else:
                    var prefix: Regexp = Regexp.LiteralString(rune, nrune, runeflags)
                    var j: Int = start
                    while j < i:
                        Regexp.RemoveLeadingString(sub[j], nrune)
                        j += 1
                    splices.append(Splice(prefix, sub + start, i - start))
                if i < nsub:
                    start = i
                    rune = rune_i
                    nrune = nrune_i
                    runeflags = runeflags_i
                i += 1

        @staticmethod
        def Round2(sub: Regexp, nsub: Int, flags: Regexp.ParseFlags, splices: List[Splice]):
            var start: Int = 0
            var first: Regexp = None
            var i: Int = 0
            while i <= nsub:
                var first_i: Regexp = None
                if i < nsub:
                    first_i = Regexp.LeadingRegexp(sub[i])
                    if first is not None and (first.op() == kRegexpBeginLine or first.op() == kRegexpEndLine or first.op() == kRegexpWordBoundary or first.op() == kRegexpNoWordBoundary or first.op() == kRegexpBeginText or first.op() == kRegexpEndText or first.op() == kRegexpCharClass or first.op() == kRegexpAnyChar or first.op() == kRegexpAnyByte or (first.op() == kRegexpRepeat and first.min() == first.max() and (first.sub()[0].op() == kRegexpLiteral or first.sub()[0].op() == kRegexpCharClass or first.sub()[0].op() == kRegexpAnyChar or first.sub()[0].op() == kRegexpAnyByte))) and Regexp.Equal(first, first_i):
                        i += 1
                        continue
                if i == start:

                elif i == start + 1:

                else:
                    var prefix: Regexp = first.Incref()
                    var j: Int = start
                    while j < i:
                        sub[j] = Regexp.RemoveLeadingRegexp(sub[j])
                        j += 1
                    splices.append(Splice(prefix, sub + start, i - start))
                if i < nsub:
                    start = i
                    first = first_i
                i += 1

        @staticmethod
        def Round3(sub: Regexp, nsub: Int, flags: Regexp.ParseFlags, splices: List[Splice]):
            var start: Int = 0
            var first: Regexp = None
            var i: Int = 0
            while i <= nsub:
                var first_i: Regexp = None
                if i < nsub:
                    first_i = sub[i]
                    if first is not None and (first.op() == kRegexpLiteral or first.op() == kRegexpCharClass) and (first_i.op() == kRegexpLiteral or first_i.op() == kRegexpCharClass):
                        i += 1
                        continue
                if i == start:

                elif i == start + 1:

                else:
                    var ccb: CharClassBuilder = CharClassBuilder()
                    var j: Int = start
                    while j < i:
                        var re: Regexp = sub[j]
                        if re.op() == kRegexpCharClass:
                            var cc: CharClass = re.cc()
                            var it: CharClass.iterator = cc.begin()
                            while it != cc.end():
                                ccb.AddRange(it.lo, it.hi)
                                it += 1
                        elif re.op() == kRegexpLiteral:
                            ccb.AddRangeFlags(re.rune(), re.rune(), re.parse_flags())
                        else:
                            LOG(DFATAL, "RE2: unexpected op: ", re.op(), " ", re.ToString())
                        re.Decref()
                        j += 1
                    var re: Regexp = Regexp.NewCharClass(ccb.GetCharClass(), flags)
                    splices.append(Splice(re, sub + start, i - start))
                if i < nsub:
                    start = i
                    first = first_i
                i += 1

    def Regexp.FactorAlternation(sub: Regexp, nsub: Int, flags: ParseFlags) -> Int:
        var stk: List[Frame] = List[Frame]()
        stk.append(Frame(sub, nsub))
        while True:
            var sub_ref: Regexp = stk[-1].sub
            var nsub_ref: Int = stk[-1].nsub
            var round_ref: Int = stk[-1].round
            var splices_ref: List[Splice] = stk[-1].splices
            var spliceidx_ref: Int = stk[-1].spliceidx
            if splices_ref.empty():
                round_ref += 1
            elif spliceidx_ref < splices_ref.size():
                stk.append(Frame(splices_ref[spliceidx_ref].sub, splices_ref[spliceidx_ref].nsub))
                continue
            else:
                var iter: Int = 0
                var out: Int = 0
                var i: Int = 0
                while i < nsub_ref:
                    while sub_ref + i < splices_ref[iter].sub:
                        sub_ref[out] = sub_ref[i]
                        out += 1
                        i += 1
                    if round_ref == 1 or round_ref == 2:
                        var re_arr: Regexp[2]
                        re_arr[0] = splices_ref[iter].prefix
                        re_arr[1] = Regexp.AlternateNoFactor(splices_ref[iter].sub, splices_ref[iter].nsuffix, flags)
                        sub_ref[out] = Regexp.Concat(re_arr, 2, flags)
                        out += 1
                        i += splices_ref[iter].nsub
                    elif round_ref == 3:
                        sub_ref[out] = splices_ref[iter].prefix
                        out += 1
                        i += splices_ref[iter].nsub
                    else:
                        LOG(DFATAL, "unknown round: ", round_ref)
                    iter += 1
                    if iter == splices_ref.size():
                        while i < nsub_ref:
                            sub_ref[out] = sub_ref[i]
                            out += 1
                            i += 1
                splices_ref.clear()
                nsub_ref = out
                round_ref += 1
            if round_ref == 1:
                FactorAlternationImpl.Round1(sub_ref, nsub_ref, flags, splices_ref)
            elif round_ref == 2:
                FactorAlternationImpl.Round2(sub_ref, nsub_ref, flags, splices_ref)
            elif round_ref == 3:
                FactorAlternationImpl.Round3(sub_ref, nsub_ref, flags, splices_ref)
            elif round_ref == 4:
                if stk.size() == 1:
                    return nsub_ref
                else:
                    var nsuffix: Int = nsub_ref
                    stk.pop_back()
                    stk[-1].splices[stk[-1].spliceidx].nsuffix = nsuffix
                    stk[-1].spliceidx += 1
                    continue
            else:
                LOG(DFATAL, "unknown round: ", round_ref)
            if splices_ref.empty() or round_ref == 3:
                spliceidx_ref = splices_ref.size()
            else:
                spliceidx_ref = 0

    def CharClassBuilder.AddRangeFlags(inout self, lo: Rune, hi: Rune, parse_flags: Regexp.ParseFlags):
        var cutnl: Bool = not (parse_flags & Regexp.ClassNL) or (parse_flags & Regexp.NeverNL)
        if cutnl and lo <= '\n' and '\n' <= hi:
            if lo < '\n':
                self.AddRangeFlags(lo, '\n' - 1, parse_flags)
            if hi > '\n':
                self.AddRangeFlags('\n' + 1, hi, parse_flags)
            return
        if parse_flags & Regexp.FoldCase:
            AddFoldedRange(self, lo, hi, 0)
        else:
            self.AddRange(lo, hi)

    def LookupGroup(name: StringPiece, groups: UGroup, ngroups: Int) -> UGroup:
        var i: Int = 0
        while i < ngroups:
            if StringPiece(groups[i].name) == name:
                return groups[i]
            i += 1
        return None

    def LookupPosixGroup(name: StringPiece) -> UGroup:
        return LookupGroup(name, posix_groups, num_posix_groups)

    def LookupPerlGroup(name: StringPiece) -> UGroup:
        return LookupGroup(name, perl_groups, num_perl_groups)

    # if !defined(RE2_USE_ICU)
    var any16: URange16[1] = [URange16(0, 65535)]
    var any32: URange32[1] = [URange32(65536, Runemax)]
    var anygroup: UGroup = UGroup("Any", +1, any16, 1, any32, 1)

    def LookupUnicodeGroup(name: StringPiece) -> UGroup:
        if name == StringPiece("Any"):
            return anygroup
        return LookupGroup(name, unicode_groups, num_unicode_groups)
    # endif

    def AddUGroup(cc: CharClassBuilder, g: UGroup, sign: Int, parse_flags: Regexp.ParseFlags):
        if sign == +1:
            var i: Int = 0
            while i < g.nr16:
                cc.AddRangeFlags(g.r16[i].lo, g.r16[i].hi, parse_flags)
                i += 1
            i = 0
            while i < g.nr32:
                cc.AddRangeFlags(g.r32[i].lo, g.r32[i].hi, parse_flags)
                i += 1
        else:
            if parse_flags & Regexp.FoldCase:
                var ccb1: CharClassBuilder = CharClassBuilder()
                AddUGroup(ccb1, g, +1, parse_flags)
                var cutnl: Bool = not (parse_flags & Regexp.ClassNL) or (parse_flags & Regexp.NeverNL)
                if cutnl:
                    ccb1.AddRange('\n', '\n')
                ccb1.Negate()
                cc.AddCharClass(ccb1)
                return
            var next: Int = 0
            var i: Int = 0
            while i < g.nr16:
                if next < g.r16[i].lo:
                    cc.AddRangeFlags(next, g.r16[i].lo - 1, parse_flags)
                next = g.r16[i].hi + 1
                i += 1
            i = 0
            while i < g.nr32:
                if next < g.r32[i].lo:
                    cc.AddRangeFlags(next, g.r32[i].lo - 1, parse_flags)
                next = g.r32[i].hi + 1
                i += 1
            if next <= Runemax:
                cc.AddRangeFlags(next, Runemax, parse_flags)

    def MaybeParsePerlCCEscape(s: StringPiece, parse_flags: Regexp.ParseFlags) -> UGroup:
        if not (parse_flags & Regexp.PerlClasses):
            return None
        if s.size() < 2 or s[0] != '\\':
            return None
        var name: StringPiece = StringPiece(s.data(), 2)
        var g: UGroup = LookupPerlGroup(name)
        if g is None:
            return None
        s.remove_prefix(name.size())
        return g

    enum ParseStatus:
        kParseOk
        kParseError
        kParseNothing

    def ParseUnicodeGroup(s: StringPiece, parse_flags: Regexp.ParseFlags, cc: CharClassBuilder, status: RegexpStatus) -> ParseStatus:
        if not (parse_flags & Regexp.UnicodeGroups):
            return ParseStatus.kParseNothing
        if s.size() < 2 or s[0] != '\\':
            return ParseStatus.kParseNothing
        var c: Rune = s[1]
        if c != 'p' and c != 'P':
            return ParseStatus.kParseNothing
        var sign: Int = +1
        if c == 'P':
            sign = -sign
        var seq: StringPiece = s
        var name: StringPiece
        s.remove_prefix(2)
        if not StringPieceToRune(c, s, status):
            return ParseStatus.kParseError
        if c != '{':
            var p: StringPiece = StringPiece(seq.data() + 2, s.data() - (seq.data() + 2))
            name = p
        else:
            var end: Int = s.find('}', 0)
            if end == StringPiece.npos:
                if not IsValidUTF8(seq, status):
                    return ParseStatus.kParseError
                status.set_code(kRegexpBadCharRange)
                status.set_error_arg(seq)
                return ParseStatus.kParseError
            name = StringPiece(s.data(), end)
            s.remove_prefix(end + 1)
            if not IsValidUTF8(name, status):
                return ParseStatus.kParseError
        seq = StringPiece(seq.data(), s.data() - seq.data())
        if not name.empty() and name[0] == '^':
            sign = -sign
            name.remove_prefix(1)
        # if !defined(RE2_USE_ICU)
        var g: UGroup = LookupUnicodeGroup(name)
        if g is None:
            status.set_code(kRegexpBadCharRange)
            status.set_error_arg(seq)
            return ParseStatus.kParseError
        AddUGroup(cc, g, sign, parse_flags)
        # else
        #   ::icu::UnicodeString ustr = ::icu::UnicodeString::fromUTF8(
        #       string("\\p{") + string(name) + string("}"));
        #   UErrorCode uerr = U_ZERO_ERROR;
        #   ::icu::UnicodeSet uset(ustr, uerr);
        #   if (U_FAILURE(uerr)) {
        #     status->set_code(kRegexpBadCharRange);
        #     status->set_error_arg(seq);
        #     return kParseError;
        #   }
        #   int nr = uset.getRangeCount();
        #   PODArray<URange32> r(nr);
        #   for (int i = 0; i < nr; i++) {
        #     r[i].lo = uset.getRangeStart(i);
        #     r[i].hi = uset.getRangeEnd(i);
        #   }
        #   UGroup g = {"", +1, 0, 0, r.data(), nr};
        #   AddUGroup(cc, &g, sign, parse_flags);
        # endif
        return ParseStatus.kParseOk

    def ParseCCName(s: StringPiece, parse_flags: Regexp.ParseFlags, cc: CharClassBuilder, status: RegexpStatus) -> ParseStatus:
        var p: StringPiece = s.data()
        var ep: StringPiece = s.data() + s.size()
        if ep - p < 2 or p[0] != '[' or p[1] != ':':
            return ParseStatus.kParseNothing
        var q: StringPiece
        q = p + 2
        while q <= ep - 2 and (q[0] != ':' or q[1] != ']'):
            q += 1
        if q > ep - 2:
            return ParseStatus.kParseNothing
        q += 2
        var name: StringPiece = StringPiece(p, q - p)
        var g: UGroup = LookupPosixGroup(name)
        if g is None:
            status.set_code(kRegexpBadCharRange)
            status.set_error_arg(name)
            return ParseStatus.kParseError
        s.remove_prefix(name.size())
        AddUGroup(cc, g, g.sign, parse_flags)
        return ParseStatus.kParseOk

    def ParseInteger(s: StringPiece, np: Int) -> Bool:
        if s.empty() or not isdigit(s[0] & 0xFF):
            return False
        if s.size() >= 2 and s[0] == '0' and isdigit(s[1] & 0xFF):
            return False
        var n: Int = 0
        var c: Int
        while not s.empty() and isdigit(c = s[0] & 0xFF):
            if n >= 100000000:
                return False
            n = n * 10 + c - '0'
            s.remove_prefix(1)
        np = n
        return True

    def MaybeParseRepetition(sp: StringPiece, lo: Int, hi: Int) -> Bool:
        var s: StringPiece = sp
        if s.empty() or s[0] != '{':
            return False
        s.remove_prefix(1)
        if not ParseInteger(s, lo):
            return False
        if s.empty():
            return False
        if s[0] == ',':
            s.remove_prefix(1)
            if s.empty():
                return False
            if s[0] == '}':
                hi = -1
            else:
                if not ParseInteger(s, hi):
                    return False
        else:
            hi = lo
        if s.empty() or s[0] != '}':
            return False
        s.remove_prefix(1)
        sp = s
        return True

    def StringPieceToRune(r: Rune, sp: StringPiece, status: RegexpStatus) -> Int:
        if fullrune(sp.data(), min(4, sp.size())):
            var n: Int = chartorune(r, sp.data())
            if r > Runemax:
                n = 1
                r = Runeerror
            if not (n == 1 and r == Runeerror):
                sp.remove_prefix(n)
                return n
        if status is not None:
            status.set_code(kRegexpBadUTF8)
            status.set_error_arg(StringPiece())
        return -1

    def IsValidUTF8(s: StringPiece, status: RegexpStatus) -> Bool:
        var t: StringPiece = s
        var r: Rune
        while not t.empty():
            if StringPieceToRune(r, t, status) < 0:
                return False
        return True

    def IsHex(c: Int) -> Int:
        return ('0' <= c and c <= '9') or ('A' <= c and c <= 'F') or ('a' <= c and c <= 'f')

    def UnHex(c: Int) -> Int:
        if '0' <= c and c <= '9':
            return c - '0'
        if 'A' <= c and c <= 'F':
            return c - 'A' + 10
        if 'a' <= c and c <= 'f':
            return c - 'a' + 10
        LOG(DFATAL, "Bad hex digit ", c)
        return 0

    def ParseEscape(s: StringPiece, rp: Rune, status: RegexpStatus, rune_max: Int) -> Bool:
        var begin: StringPiece = s.data()
        if s.empty() or s[0] != '\\':
            status.set_code(kRegexpInternalError)
            status.set_error_arg(StringPiece())
            return False
        if s.size() == 1:
            status.set_code(kRegexpTrailingBackslash)
            status.set_error_arg(StringPiece())
            return False
        var c: Rune
        var c1: Rune
        s.remove_prefix(1)
        if StringPieceToRune(c, s, status) < 0:
            return False
        var code: Int
        if c == '1' or c == '2' or c == '3' or c == '4' or c == '5' or c == '6' or c == '7':
            if s.empty() or s[0] < '0' or s[0] > '7':
                goto BadEscape
            # FALLTHROUGH_INTENDED
            code = c - '0'
            if not s.empty() and '0' <= (c = s[0]) and c <= '7':
                code = code * 8 + c - '0'
                s.remove_prefix(1)
                if not s.empty():
                    c = s[0]
                    if '0' <= c and c <= '7':
                        code = code * 8 + c - '0'
                        s.remove_prefix(1)
            if code > rune_max:
                goto BadEscape
            rp = code
            return True
        elif c == '0':
            code = c - '0'
            if not s.empty() and '0' <= (c = s[0]) and c <= '7':
                code = code * 8 + c - '0'
                s.remove_prefix(1)
                if not s.empty():
                    c = s[0]
                    if '0' <= c and c <= '7':
                        code = code * 8 + c - '0'
                        s.remove_prefix(1)
            if code > rune_max:
                goto BadEscape
            rp = code
            return True
        elif c == 'x':
            if s.empty():
                goto BadEscape
            if StringPieceToRune(c, s, status) < 0:
                return False
            if c == '{':
                if StringPieceToRune(c, s, status) < 0:
                    return False
                var nhex: Int = 0
                code = 0
                while IsHex(c):
                    nhex += 1
                    code = code * 16 + UnHex(c)
                    if code > rune_max:
                        goto BadEscape
                    if s.empty():
                        goto BadEscape
                    if StringPieceToRune(c, s, status) < 0:
                        return False
                if c != '}' or nhex == 0:
                    goto BadEscape
                rp = code
                return True
            if s.empty():
                goto BadEscape
            if StringPieceToRune(c1, s, status) < 0:
                return False
            if not IsHex(c) or not IsHex(c1):
                goto BadEscape
            rp = UnHex(c) * 16 + UnHex(c1)
            return True
        elif c == 'n':
            rp = '\n'
            return True
        elif c == 'r':
            rp = '\r'
            return True
        elif c == 't':
            rp = '\t'
            return True
        elif c == 'a':
            rp = '\a'
            return True
        elif c == 'f':
            rp = '\f'
            return True
        elif c == 'v':
            rp = '\v'
            return True
        else:
            if c < Runeself and not isalpha(c) and not isdigit(c):
                rp = c
                return True
            goto BadEscape
        LOG(DFATAL, "Not reached in ParseEscape.")
    BadEscape:
        status.set_code(kRegexpBadEscape)
        status.set_error_arg(StringPiece(begin, s.data() - begin))
        return False

    def ConvertLatin1ToUTF8(latin1: StringPiece, utf: String):
        var buf: UInt8[UTFmax]
        utf.clear()
        var i: Int = 0
        while i < latin1.size():
            var r: Rune = latin1[i] & 0xFF
            var n: Int = runetochar(buf, r)
            utf.append(String(buf, n))
            i += 1

    def IsValidCaptureName(name: StringPiece) -> Bool:
        if name.empty():
            return False
        var cc: CharClass = (fn() -> CharClass:
            var ccb: CharClassBuilder = CharClassBuilder()
            for group in ["Lu", "Ll", "Lt", "Lm", "Lo", "Nl", "Mn", "Mc", "Nd", "Pc"]:
                AddUGroup(ccb, LookupGroup(StringPiece(group), unicode_groups, num_unicode_groups), +1, Regexp.NoParseFlags)
            return ccb.GetCharClass()
        )()
        var t: StringPiece = name
        var r: Rune
        while not t.empty():
            if StringPieceToRune(r, t, None) < 0:
                return False
            if cc.Contains(r):
                continue
            return False
        return True

    def Regexp.Parse(s: StringPiece, global_flags: ParseFlags, status: RegexpStatus) -> Regexp:
        var xstatus: RegexpStatus = RegexpStatus()
        if status is None:
            status = xstatus
        var ps: ParseState = ParseState(global_flags, s, status)
        var t: StringPiece = s
        if global_flags & Latin1:
            var tmp: String = String()
            ConvertLatin1ToUTF8(t, tmp)
            status.set_tmp(tmp)
            t = tmp
        if global_flags & Literal:
            while not t.empty():
                var r: Rune
                if StringPieceToRune(r, t, status) < 0:
                    return None
                if not ps.PushLiteral(r):
                    return None
            return ps.DoFinish()
        var lastunary: StringPiece = StringPiece()
        while not t.empty():
            var isunary: StringPiece = StringPiece()
            if t[0] == '(':
                if (ps.flags() & PerlX) and (t.size() >= 2 and t[1] == '?'):
                    if not ps.ParsePerlFlags(t):
                        return None
                else:
                    if ps.flags() & NeverCapture:
                        if not ps.DoLeftParenNoCapture():
                            return None
                    else:
                        if not ps.DoLeftParen(StringPiece()):
                            return None
                    t.remove_prefix(1)
            elif t[0] == '|':
                if not ps.DoVerticalBar():
                    return None
                t.remove_prefix(1)
            elif t[0] == ')':
                if not ps.DoRightParen():
                    return None
                t.remove_prefix(1)
            elif t[0] == '^':
                if not ps.PushCaret():
                    return None
                t.remove_prefix(1)
            elif t[0] == '$':
                if not ps.PushDollar():
                    return None
                t.remove_prefix(1)
            elif t[0] == '.':
                if not ps.PushDot():
                    return None
                t.remove_prefix(1)
            elif t[0] == '[':
                var re: Regexp
                if not ps.ParseCharClass(t, re, status):
                    return None
                if not ps.PushRegexp(re):
                    return None
            elif t[0] == '*':
                var op: RegexpOp = kRegexpStar
                var opstr: StringPiece = t
                var nongreedy: Bool = False
                t.remove_prefix(1)
                if ps.flags() & PerlX:
                    if not t.empty() and t[0] == '?':
                        nongreedy = True
                        t.remove_prefix(1)
                    if not lastunary.empty():
                        status.set_code(kRegexpRepeatOp)
                        status.set_error_arg(StringPiece(lastunary.data(), t.data() - lastunary.data()))
                        return None
                opstr = StringPiece(opstr.data(), t.data() - opstr.data())
                if not ps.PushRepeatOp(op, opstr, nongreedy):
                    return None
                isunary = opstr
            elif t[0] == '+':
                var op: RegexpOp = kRegexpPlus
                var opstr: StringPiece = t
                var nongreedy: Bool = False
                t.remove_prefix(1)
                if ps.flags() & PerlX:
                    if not t.empty() and t[0] == '?':
                        nongreedy = True
                        t.remove_prefix(1)
                    if not lastunary.empty():
                        status.set_code(kRegexpRepeatOp)
                        status.set_error_arg(StringPiece(lastunary.data(), t.data() - lastunary.data()))
                        return None
                opstr = StringPiece(opstr.data(), t.data() - opstr.data())
                if not ps.PushRepeatOp(op, opstr, nongreedy):
                    return None
                isunary = opstr
            elif t[0] == '?':
                var op: RegexpOp = kRegexpQuest
                var opstr: StringPiece = t
                var nongreedy: Bool = False
                t.remove_prefix(1)
                if ps.flags() & PerlX:
                    if not t.empty() and t[0] == '?':
                        nongreedy = True
                        t.remove_prefix(1)
                    if not lastunary.empty():
                        status.set_code(kRegexpRepeatOp)
                        status.set_error_arg(StringPiece(lastunary.data(), t.data() - lastunary.data()))
                        return None
                opstr = StringPiece(opstr.data(), t.data() - opstr.data())
                if not ps.PushRepeatOp(op, opstr, nongreedy):
                    return None
                isunary = opstr
            elif t[0] == '{':
                var lo: Int
                var hi: Int
                var opstr: StringPiece = t
                if not MaybeParseRepetition(t, lo, hi):
                    if not ps.PushLiteral('{'):
                        return None
                    t.remove_prefix(1)
                else:
                    var nongreedy: Bool = False
                    if ps.flags() & PerlX:
                        if not t.empty() and t[0] == '?':
                            nongreedy = True
                            t.remove_prefix(1)
                        if not lastunary.empty():
                            status.set_code(kRegexpRepeatOp)
                            status.set_error_arg(StringPiece(lastunary.data(), t.data() - lastunary.data()))
                            return None
                    opstr = StringPiece(opstr.data(), t.data() - opstr.data())
                    if not ps.PushRepetition(lo, hi, opstr, nongreedy):
                        return None
                    isunary = opstr
            elif t[0] == '\\':
                if (ps.flags() & Regexp.PerlB) and t.size() >= 2 and (t[1] == 'b' or t[1] == 'B'):
                    if not ps.PushWordBoundary(t[1] == 'b'):
                        return None
                    t.remove_prefix(2)
                elif (ps.flags() & Regexp.PerlX) and t.size() >= 2:
                    if t[1] == 'A':
                        if not ps.PushSimpleOp(kRegexpBeginText):
                            return None
                        t.remove_prefix(2)
                    elif t[1] == 'z':
                        if not ps.PushSimpleOp(kRegexpEndText):
                            return None
                        t.remove_prefix(2)
                    elif t[1] == 'C':
                        if not ps.PushSimpleOp(kRegexpAnyByte):
                            return None
                        t.remove_prefix(2)
                    elif t[1] == 'Q':
                        t.remove_prefix(2)
                        while not t.empty():
                            if t.size() >= 2 and t[0] == '\\' and t[1] == 'E':
                                t.remove_prefix(2)
                                break
                            var r: Rune
                            if StringPieceToRune(r, t, status) < 0:
                                return None
                            if not ps.PushLiteral(r):
                                return None
                    else:
                        if t.size() >= 2 and (t[1] == 'p' or t[1] == 'P'):
                            var re: Regexp = Regexp(kRegexpCharClass, ps.flags() & ~FoldCase)
                            re.ccb_ = CharClassBuilder()
                            var parse_result: ParseStatus = ParseUnicodeGroup(t, ps.flags(), re.ccb_, status)
                            if parse_result == kParseOk:
                                if not ps.PushRegexp(re):
                                    return None
                                goto Break2
                            elif parse_result == kParseError:
                                re.Decref()
                                return None
                            else:
                                re.Decref()
                        var g: UGroup = MaybeParsePerlCCEscape(t, ps.flags())
                        if g is not None:
                            var re: Regexp = Regexp(kRegexpCharClass, ps.flags() & ~FoldCase)
                            re.ccb_ = CharClassBuilder()
                            AddUGroup(re.ccb_, g, g.sign, ps.flags())
                            if not ps.PushRegexp(re):
                                return None
                        else:
                            var r: Rune
                            if not ParseEscape(t, r, status, ps.rune_max()):
                                return None
                            if not ps.PushLiteral(r):
                                return None
                else:
                    if t.size() >= 2 and (t[1] == 'p' or t[1] == 'P'):
                        var re: Regexp = Regexp(kRegexpCharClass, ps.flags() & ~FoldCase)
                        re.ccb_ = CharClassBuilder()
                        var parse_result: ParseStatus = ParseUnicodeGroup(t, ps.flags(), re.ccb_, status)
                        if parse_result == kParseOk:
                            if not ps.PushRegexp(re):
                                return None
                            goto Break2
                        elif parse_result == kParseError:
                            re.Decref()
                            return None
                        else:
                            re.Decref()
                    var g: UGroup = MaybeParsePerlCCEscape(t, ps.flags())
                    if g is not None:
                        var re: Regexp = Regexp(kRegexpCharClass, ps.flags() & ~FoldCase)
                        re.ccb_ = CharClassBuilder()
                        AddUGroup(re.ccb_, g, g.sign, ps.flags())
                        if not ps.PushRegexp(re):
                            return None
                    else:
                        var r: Rune
                        if not ParseEscape(t, r, status, ps.rune_max()):
                            return None
                        if not ps.PushLiteral(r):
                            return None
            else:
                var r: Rune
                if StringPieceToRune(r, t, status) < 0:
                    return None
                if not ps.PushLiteral(r):
                    return None
        Break2:
            lastunary = isunary
        return ps.DoFinish()