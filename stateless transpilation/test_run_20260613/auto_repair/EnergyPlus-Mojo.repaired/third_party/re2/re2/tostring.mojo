from util.util import *
from util.logging import LOG
from util.strutil import *
from util.utf import *
from re2.regexp import Regexp
from re2.walker-inl import Walker

enum Prec:
    PrecAtom = 0
    PrecUnary = 1
    PrecConcat = 2
    PrecAlternate = 3
    PrecEmpty = 4
    PrecParen = 5
    PrecToplevel = 6

def AppendCCRange(t: Pointer[String], lo: Rune, hi: Rune):

class ToStringWalker(Walker[Int32]):
    var t_: Pointer[String]  # The string the walker appends to.

    def __init__(inout self, t: Pointer[String]):
        self.t_ = t

    def PreVisit(inout self, re: Regexp, parent_arg: Int32, stop: Pointer[Bool]) -> Int32:
        var prec = parent_arg
        var nprec = Prec.PrecAtom
        if re.op() == RegexpOp.kRegexpNoMatch:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpEmptyMatch:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpLiteral:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpAnyChar:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpAnyByte:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpBeginLine:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpEndLine:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpBeginText:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpEndText:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpWordBoundary:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpNoWordBoundary:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpCharClass:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpHaveMatch:
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpConcat:
            if prec < Prec.PrecConcat:
                self.t_[].append("(?:")
            nprec = Prec.PrecConcat
        elif re.op() == RegexpOp.kRegexpLiteralString:
            if prec < Prec.PrecConcat:
                self.t_[].append("(?:")
            nprec = Prec.PrecConcat
        elif re.op() == RegexpOp.kRegexpAlternate:
            if prec < Prec.PrecAlternate:
                self.t_[].append("(?:")
            nprec = Prec.PrecAlternate
        elif re.op() == RegexpOp.kRegexpCapture:
            self.t_[].append("(")
            if re.cap() == 0:
                LOG(LogLevel.DFATAL, "kRegexpCapture cap() == 0")
            if re.name():
                self.t_[].append("?P<")
                self.t_[].append(re.name()[])
                self.t_[].append(">")
            nprec = Prec.PrecParen
        elif re.op() == RegexpOp.kRegexpStar:
            if prec < Prec.PrecUnary:
                self.t_[].append("(?:")
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpPlus:
            if prec < Prec.PrecUnary:
                self.t_[].append("(?:")
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpQuest:
            if prec < Prec.PrecUnary:
                self.t_[].append("(?:")
            nprec = Prec.PrecAtom
        elif re.op() == RegexpOp.kRegexpRepeat:
            if prec < Prec.PrecUnary:
                self.t_[].append("(?:")
            nprec = Prec.PrecAtom
        return nprec

    def PostVisit(inout self, re: Regexp, parent_arg: Int32, pre_arg: Int32,
                 child_args: Pointer[Int32], nchild_args: Int32) -> Int32:
        var prec = parent_arg
        if re.op() == RegexpOp.kRegexpNoMatch:
            self.t_[].append("[^\\x00-\\x{10ffff}]")
        elif re.op() == RegexpOp.kRegexpEmptyMatch:
            if prec < Prec.PrecEmpty:
                self.t_[].append("(?:)")
        elif re.op() == RegexpOp.kRegexpLiteral:
            AppendLiteral(self.t_, re.rune(),
                          (re.parse_flags() & RegexpFlags.FoldCase) != 0)
        elif re.op() == RegexpOp.kRegexpLiteralString:
            for i in range(re.nrunes()):
                AppendLiteral(self.t_, re.runes()[i],
                              (re.parse_flags() & RegexpFlags.FoldCase) != 0)
            if prec < Prec.PrecConcat:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpConcat:
            if prec < Prec.PrecConcat:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpAlternate:
            if self.t_[][self.t_[].size()-1] == '|':
                self.t_[].erase(self.t_[].size()-1)
            else:
                LOG(LogLevel.DFATAL, "Bad final char: " + self.t_[].str())
            if prec < Prec.PrecAlternate:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpStar:
            self.t_[].append("*")
            if re.parse_flags() & RegexpFlags.NonGreedy:
                self.t_[].append("?")
            if prec < Prec.PrecUnary:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpPlus:
            self.t_[].append("+")
            if re.parse_flags() & RegexpFlags.NonGreedy:
                self.t_[].append("?")
            if prec < Prec.PrecUnary:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpQuest:
            self.t_[].append("?")
            if re.parse_flags() & RegexpFlags.NonGreedy:
                self.t_[].append("?")
            if prec < Prec.PrecUnary:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpRepeat:
            if re.max() == -1:
                self.t_[].append(StringPrintf("{%d,}", re.min()))
            elif re.min() == re.max():
                self.t_[].append(StringPrintf("{%d}", re.min()))
            else:
                self.t_[].append(StringPrintf("{%d,%d}", re.min(), re.max()))
            if re.parse_flags() & RegexpFlags.NonGreedy:
                self.t_[].append("?")
            if prec < Prec.PrecUnary:
                self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpAnyChar:
            self.t_[].append(".")
        elif re.op() == RegexpOp.kRegexpAnyByte:
            self.t_[].append("\\C")
        elif re.op() == RegexpOp.kRegexpBeginLine:
            self.t_[].append("^")
        elif re.op() == RegexpOp.kRegexpEndLine:
            self.t_[].append("$")
        elif re.op() == RegexpOp.kRegexpBeginText:
            self.t_[].append("(?-m:^)")
        elif re.op() == RegexpOp.kRegexpEndText:
            if re.parse_flags() & RegexpFlags.WasDollar:
                self.t_[].append("(?-m:$)")
            else:
                self.t_[].append("\\z")
        elif re.op() == RegexpOp.kRegexpWordBoundary:
            self.t_[].append("\\b")
        elif re.op() == RegexpOp.kRegexpNoWordBoundary:
            self.t_[].append("\\B")
        elif re.op() == RegexpOp.kRegexpCharClass:
            if re.cc().size() == 0:
                self.t_[].append("[^\\x00-\\x{10ffff}]")
            else:
                self.t_[].append("[")
                var cc = re.cc()
                if cc.Contains(0xFFFE) and not cc.full():
                    cc = cc.Negate()
                    self.t_[].append("^")
                for i in cc.begin().__iter__():
                    AppendCCRange(self.t_, i.lo, i.hi)
                if cc != re.cc():
                    cc.Delete()
                self.t_[].append("]")
        elif re.op() == RegexpOp.kRegexpCapture:
            self.t_[].append(")")
        elif re.op() == RegexpOp.kRegexpHaveMatch:
            self.t_[].append(StringPrintf("(?HaveMatch:%d)", re.match_id()))
        if prec == Prec.PrecAlternate:
            self.t_[].append("|")
        return 0

    def ShortVisit(inout self, re: Regexp, parent_arg: Int32) -> Int32:
        return 0

def AppendLiteral(t: Pointer[String], r: Rune, foldcase: Bool):
    if r != 0 and r < 0x80 and strchr("(){}[]*+?|.^$\\", r):
        t[].append(1, '\\')
        t[].append(1, static_cast[Char](r))
    elif foldcase and 'a' <= r and r <= 'z':
        r -= 'a' - 'A'
        t[].append(1, '[')
        t[].append(1, static_cast[Char](r))
        t[].append(1, static_cast[Char](r) + 'a' - 'A')
        t[].append(1, ']')
    else:
        AppendCCRange(t, r, r)

def AppendCCChar(t: Pointer[String], r: Rune):
    if 0x20 <= r and r <= 0x7E:
        if strchr("[]^-\\", r):
            t[].append("\\")
        t[].append(1, static_cast[Char](r))
        return
    if r == '\r':
        t[].append("\\r")
        return
    elif r == '\t':
        t[].append("\\t")
        return
    elif r == '\n':
        t[].append("\\n")
        return
    elif r == '\f':
        t[].append("\\f")
        return
    else:

    if r < 0x100:
        t[] += StringPrintf("\\x%02x", static_cast[Int32](r))
        return
    t[] += StringPrintf("\\x{%x}", static_cast[Int32](r))

def AppendCCRange(t: Pointer[String], lo: Rune, hi: Rune):
    if lo > hi:
        return
    AppendCCChar(t, lo)
    if lo < hi:
        t[].append("-")
        AppendCCChar(t, hi)

def ToString(self: Regexp) -> String:
    var t = String()
    var w = ToStringWalker(Pointer[String].address_of(t))
    w.WalkExponential(self, Prec.PrecToplevel, 100000)
    if w.stopped_early():
        t += " [truncated]"
    return t

# define ToString DontCallToString  # Avoid accidental recursion.