from util.util import StringPiece, ParseFlags, RegexpStatus
from util.logging import LOG, DFATAL, ERROR
from util.utf import Rune
from .pod_array import PODArray
from regexp import Regexp
from re2.walker-inl import Walker

@value
struct CoalesceWalker(Walker[Regexp]):
    var __init__: fn() -> Self = __init__

    def __init__(inout self):

    def PostVisit(inout self, re: Regexp, parent_arg: Regexp, pre_arg: Regexp, child_args: Pointer[Regexp], nchild_args: Int) -> Regexp:
        return CoalesceWalker_PostVisit(self, re, parent_arg, pre_arg, child_args, nchild_args)

    def Copy(inout self, re: Regexp) -> Regexp:
        return CoalesceWalker_Copy(self, re)

    def ShortVisit(inout self, re: Regexp, parent_arg: Regexp) -> Regexp:
        return CoalesceWalker_ShortVisit(self, re, parent_arg)

    @staticmethod
    def CanCoalesce(r1: Regexp, r2: Regexp) -> Bool:
        return CoalesceWalker_CanCoalesce(r1, r2)

    @staticmethod
    def DoCoalesce(r1ptr: Pointer[Regexp], r2ptr: Pointer[Regexp]):
        CoalesceWalker_DoCoalesce(r1ptr, r2ptr)

@value
struct SimplifyWalker(Walker[Regexp]):
    var __init__: fn() -> Self = __init__

    def __init__(inout self):

    def PreVisit(inout self, re: Regexp, parent_arg: Regexp, stop: Pointer[Bool]) -> Regexp:
        return SimplifyWalker_PreVisit(self, re, parent_arg, stop)

    def PostVisit(inout self, re: Regexp, parent_arg: Regexp, pre_arg: Regexp, child_args: Pointer[Regexp], nchild_args: Int) -> Regexp:
        return SimplifyWalker_PostVisit(self, re, parent_arg, pre_arg, child_args, nchild_args)

    def Copy(inout self, re: Regexp) -> Regexp:
        return SimplifyWalker_Copy(self, re)

    def ShortVisit(inout self, re: Regexp, parent_arg: Regexp) -> Regexp:
        return SimplifyWalker_ShortVisit(self, re, parent_arg)

    @staticmethod
    def Concat2(re1: Regexp, re2: Regexp, flags: Regexp.ParseFlags) -> Regexp:
        return SimplifyWalker_Concat2(re1, re2, flags)

    @staticmethod
    def SimplifyRepeat(re: Regexp, min: Int, max: Int, parse_flags: Regexp.ParseFlags) -> Regexp:
        return SimplifyWalker_SimplifyRepeat(re, min, max, parse_flags)

    @staticmethod
    def SimplifyCharClass(re: Regexp) -> Regexp:
        return SimplifyWalker_SimplifyCharClass(re)

def Regexp_SimplifyRegexp(src: StringPiece, flags: ParseFlags, dst: Pointer[String], status: Pointer[RegexpStatus]) -> Bool:
    var re: Regexp = Regexp.Parse(src, flags, status)
    if re == None:
        return False
    var sre: Regexp = re.Simplify()
    re.Decref()
    if sre == None:
        if status:
            status.set_code(kRegexpInternalError)
            status.set_error_arg(src)
        return False
    dst[] = sre.ToString()
    sre.Decref()
    return True

def Regexp_ComputeSimple(self: Regexp) -> Bool:
    var subs: Pointer[Regexp]
    if self.op_ == kRegexpNoMatch:
        return True
    elif self.op_ == kRegexpEmptyMatch:
        return True
    elif self.op_ == kRegexpLiteral:
        return True
    elif self.op_ == kRegexpLiteralString:
        return True
    elif self.op_ == kRegexpBeginLine:
        return True
    elif self.op_ == kRegexpEndLine:
        return True
    elif self.op_ == kRegexpBeginText:
        return True
    elif self.op_ == kRegexpWordBoundary:
        return True
    elif self.op_ == kRegexpNoWordBoundary:
        return True
    elif self.op_ == kRegexpEndText:
        return True
    elif self.op_ == kRegexpAnyChar:
        return True
    elif self.op_ == kRegexpAnyByte:
        return True
    elif self.op_ == kRegexpHaveMatch:
        return True
    elif self.op_ == kRegexpConcat:
        subs = self.sub()
        for i in range(self.nsub_):
            if not subs[i].simple():
                return False
        return True
    elif self.op_ == kRegexpAlternate:
        subs = self.sub()
        for i in range(self.nsub_):
            if not subs[i].simple():
                return False
        return True
    elif self.op_ == kRegexpCharClass:
        if self.ccb_ != None:
            return not self.ccb_.empty() and not self.ccb_.full()
        return not self.cc_.empty() and not self.cc_.full()
    elif self.op_ == kRegexpCapture:
        subs = self.sub()
        return subs[0].simple()
    elif self.op_ == kRegexpStar:
        subs = self.sub()
        if not subs[0].simple():
            return False
        if subs[0].op_ == kRegexpStar:
            return False
        elif subs[0].op_ == kRegexpPlus:
            return False
        elif subs[0].op_ == kRegexpQuest:
            return False
        elif subs[0].op_ == kRegexpEmptyMatch:
            return False
        elif subs[0].op_ == kRegexpNoMatch:
            return False
        else:
            return True
    elif self.op_ == kRegexpPlus:
        subs = self.sub()
        if not subs[0].simple():
            return False
        if subs[0].op_ == kRegexpStar:
            return False
        elif subs[0].op_ == kRegexpPlus:
            return False
        elif subs[0].op_ == kRegexpQuest:
            return False
        elif subs[0].op_ == kRegexpEmptyMatch:
            return False
        elif subs[0].op_ == kRegexpNoMatch:
            return False
        else:
            return True
    elif self.op_ == kRegexpQuest:
        subs = self.sub()
        if not subs[0].simple():
            return False
        if subs[0].op_ == kRegexpStar:
            return False
        elif subs[0].op_ == kRegexpPlus:
            return False
        elif subs[0].op_ == kRegexpQuest:
            return False
        elif subs[0].op_ == kRegexpEmptyMatch:
            return False
        elif subs[0].op_ == kRegexpNoMatch:
            return False
        else:
            return True
    elif self.op_ == kRegexpRepeat:
        return False
    LOG(DFATAL, "Case not handled in ComputeSimple: ", self.op_)
    return False

def Regexp_Simplify(self: Regexp) -> Regexp:
    var cw: CoalesceWalker = CoalesceWalker()
    var cre: Regexp = cw.Walk(self, None)
    if cre == None:
        return None
    if cw.stopped_early():
        cre.Decref()
        return None
    var sw: SimplifyWalker = SimplifyWalker()
    var sre: Regexp = sw.Walk(cre, None)
    cre.Decref()
    if sre == None:
        return None
    if sw.stopped_early():
        sre.Decref()
        return None
    return sre

def ChildArgsChanged(re: Regexp, child_args: Pointer[Regexp]) -> Bool:
    for i in range(re.nsub()):
        var sub: Regexp = re.sub()[i]
        var newsub: Regexp = child_args[i]
        if newsub != sub:
            return True
    for i in range(re.nsub()):
        var newsub: Regexp = child_args[i]
        newsub.Decref()
    return False

def CoalesceWalker_Copy(self: CoalesceWalker, re: Regexp) -> Regexp:
    return re.Incref()

def CoalesceWalker_ShortVisit(self: CoalesceWalker, re: Regexp, parent_arg: Regexp) -> Regexp:
    return re.Incref()

def CoalesceWalker_PostVisit(self: CoalesceWalker, re: Regexp, parent_arg: Regexp, pre_arg: Regexp, child_args: Pointer[Regexp], nchild_args: Int) -> Regexp:
    if re.nsub() == 0:
        return re.Incref()
    if re.op() != kRegexpConcat:
        if not ChildArgsChanged(re, child_args):
            return re.Incref()
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(re.nsub())
        var nre_subs: Pointer[Regexp] = nre.sub()
        for i in range(re.nsub()):
            nre_subs[i] = child_args[i]
        if re.op() == kRegexpRepeat:
            nre.min_ = re.min()
            nre.max_ = re.max()
        elif re.op() == kRegexpCapture:
            nre.cap_ = re.cap()
        return nre
    var can_coalesce: Bool = False
    for i in range(re.nsub()):
        if i + 1 < re.nsub() and CoalesceWalker.CanCoalesce(child_args[i], child_args[i + 1]):
            can_coalesce = True
            break
    if not can_coalesce:
        if not ChildArgsChanged(re, child_args):
            return re.Incref()
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(re.nsub())
        var nre_subs: Pointer[Regexp] = nre.sub()
        for i in range(re.nsub()):
            nre_subs[i] = child_args[i]
        return nre
    for i in range(re.nsub()):
        if i + 1 < re.nsub() and CoalesceWalker.CanCoalesce(child_args[i], child_args[i + 1]):
            CoalesceWalker.DoCoalesce(Pointer[Regexp](address_of(child_args[i])), Pointer[Regexp](address_of(child_args[i + 1])))
    var n: Int = 0
    for i in range(n, re.nsub()):
        if child_args[i].op() == kRegexpEmptyMatch:
            n += 1
    var nre: Regexp = Regexp(re.op(), re.parse_flags())
    nre.AllocSub(re.nsub() - n)
    var nre_subs: Pointer[Regexp] = nre.sub()
    var j: Int = 0
    for i in range(re.nsub()):
        if child_args[i].op() == kRegexpEmptyMatch:
            child_args[i].Decref()
            continue
        nre_subs[j] = child_args[i]
        j += 1
    return nre

def CoalesceWalker_CanCoalesce(r1: Regexp, r2: Regexp) -> Bool:
    if (r1.op() == kRegexpStar or r1.op() == kRegexpPlus or r1.op() == kRegexpQuest or r1.op() == kRegexpRepeat) and (r1.sub()[0].op() == kRegexpLiteral or r1.sub()[0].op() == kRegexpCharClass or r1.sub()[0].op() == kRegexpAnyChar or r1.sub()[0].op() == kRegexpAnyByte):
        if (r2.op() == kRegexpStar or r2.op() == kRegexpPlus or r2.op() == kRegexpQuest or r2.op() == kRegexpRepeat) and Regexp.Equal(r1.sub()[0], r2.sub()[0]) and ((r1.parse_flags() & Regexp.NonGreedy) == (r2.parse_flags() & Regexp.NonGreedy)):
            return True
        if Regexp.Equal(r1.sub()[0], r2):
            return True
        if r1.sub()[0].op() == kRegexpLiteral and r2.op() == kRegexpLiteralString and r2.runes()[0] == r1.sub()[0].rune() and ((r1.sub()[0].parse_flags() & Regexp.FoldCase) == (r2.parse_flags() & Regexp.FoldCase)):
            return True
    return False

def CoalesceWalker_DoCoalesce(r1ptr: Pointer[Regexp], r2ptr: Pointer[Regexp]):
    var r1: Regexp = r1ptr[]
    var r2: Regexp = r2ptr[]
    var nre: Regexp = Regexp.Repeat(r1.sub()[0].Incref(), r1.parse_flags(), 0, 0)
    if r1.op() == kRegexpStar:
        nre.min_ = 0
        nre.max_ = -1
    elif r1.op() == kRegexpPlus:
        nre.min_ = 1
        nre.max_ = -1
    elif r1.op() == kRegexpQuest:
        nre.min_ = 0
        nre.max_ = 1
    elif r1.op() == kRegexpRepeat:
        nre.min_ = r1.min()
        nre.max_ = r1.max()
    else:
        LOG(DFATAL, "DoCoalesce failed: r1->op() is ", r1.op())
        nre.Decref()
        return
    if r2.op() == kRegexpStar:
        nre.max_ = -1
        r1ptr[] = Regexp(kRegexpEmptyMatch, Regexp.NoParseFlags)
        r2ptr[] = nre
    elif r2.op() == kRegexpPlus:
        nre.min_ += 1
        nre.max_ = -1
        r1ptr[] = Regexp(kRegexpEmptyMatch, Regexp.NoParseFlags)
        r2ptr[] = nre
    elif r2.op() == kRegexpQuest:
        if nre.max() != -1:
            nre.max_ += 1
        r1ptr[] = Regexp(kRegexpEmptyMatch, Regexp.NoParseFlags)
        r2ptr[] = nre
    elif r2.op() == kRegexpRepeat:
        nre.min_ += r2.min()
        if r2.max() == -1:
            nre.max_ = -1
        elif nre.max() != -1:
            nre.max_ += r2.max()
        r1ptr[] = Regexp(kRegexpEmptyMatch, Regexp.NoParseFlags)
        r2ptr[] = nre
    elif r2.op() == kRegexpLiteral or r2.op() == kRegexpCharClass or r2.op() == kRegexpAnyChar or r2.op() == kRegexpAnyByte:
        nre.min_ += 1
        if nre.max() != -1:
            nre.max_ += 1
        r1ptr[] = Regexp(kRegexpEmptyMatch, Regexp.NoParseFlags)
        r2ptr[] = nre
    elif r2.op() == kRegexpLiteralString:
        var r: Rune = r1.sub()[0].rune()
        var n: Int = 1
        while n < r2.nrunes() and r2.runes()[n] == r:
            n += 1
        nre.min_ += n
        if nre.max() != -1:
            nre.max_ += n
        if n == r2.nrunes():
            r1ptr[] = Regexp(kRegexpEmptyMatch, Regexp.NoParseFlags)
            r2ptr[] = nre
        else:
            r1ptr[] = nre
            r2ptr[] = Regexp.LiteralString(Pointer[Rune](address_of(r2.runes()[n])), r2.nrunes() - n, r2.parse_flags())
    else:
        LOG(DFATAL, "DoCoalesce failed: r2->op() is ", r2.op())
        nre.Decref()
        return
    r1.Decref()
    r2.Decref()

def SimplifyWalker_Copy(self: SimplifyWalker, re: Regexp) -> Regexp:
    return re.Incref()

def SimplifyWalker_ShortVisit(self: SimplifyWalker, re: Regexp, parent_arg: Regexp) -> Regexp:
    return re.Incref()

def SimplifyWalker_PreVisit(self: SimplifyWalker, re: Regexp, parent_arg: Regexp, stop: Pointer[Bool]) -> Regexp:
    if re.simple():
        stop[] = True
        return re.Incref()
    return None

def SimplifyWalker_PostVisit(self: SimplifyWalker, re: Regexp, parent_arg: Regexp, pre_arg: Regexp, child_args: Pointer[Regexp], nchild_args: Int) -> Regexp:
    if re.op() == kRegexpNoMatch:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpEmptyMatch:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpLiteral:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpLiteralString:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpBeginLine:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpEndLine:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpBeginText:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpWordBoundary:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpNoWordBoundary:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpEndText:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpAnyChar:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpAnyByte:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpHaveMatch:
        re.simple_ = True
        return re.Incref()
    elif re.op() == kRegexpConcat:
        if not ChildArgsChanged(re, child_args):
            re.simple_ = True
            return re.Incref()
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(re.nsub())
        var nre_subs: Pointer[Regexp] = nre.sub()
        for i in range(re.nsub()):
            nre_subs[i] = child_args[i]
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpAlternate:
        if not ChildArgsChanged(re, child_args):
            re.simple_ = True
            return re.Incref()
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(re.nsub())
        var nre_subs: Pointer[Regexp] = nre.sub()
        for i in range(re.nsub()):
            nre_subs[i] = child_args[i]
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpCapture:
        var newsub: Regexp = child_args[0]
        if newsub == re.sub()[0]:
            newsub.Decref()
            re.simple_ = True
            return re.Incref()
        var nre: Regexp = Regexp(kRegexpCapture, re.parse_flags())
        nre.AllocSub(1)
        nre.sub()[0] = newsub
        nre.cap_ = re.cap()
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpStar:
        var newsub: Regexp = child_args[0]
        if newsub.op() == kRegexpEmptyMatch:
            return newsub
        if newsub == re.sub()[0]:
            newsub.Decref()
            re.simple_ = True
            return re.Incref()
        if re.op() == newsub.op() and re.parse_flags() == newsub.parse_flags():
            return newsub
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(1)
        nre.sub()[0] = newsub
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpPlus:
        var newsub: Regexp = child_args[0]
        if newsub.op() == kRegexpEmptyMatch:
            return newsub
        if newsub == re.sub()[0]:
            newsub.Decref()
            re.simple_ = True
            return re.Incref()
        if re.op() == newsub.op() and re.parse_flags() == newsub.parse_flags():
            return newsub
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(1)
        nre.sub()[0] = newsub
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpQuest:
        var newsub: Regexp = child_args[0]
        if newsub.op() == kRegexpEmptyMatch:
            return newsub
        if newsub == re.sub()[0]:
            newsub.Decref()
            re.simple_ = True
            return re.Incref()
        if re.op() == newsub.op() and re.parse_flags() == newsub.parse_flags():
            return newsub
        var nre: Regexp = Regexp(re.op(), re.parse_flags())
        nre.AllocSub(1)
        nre.sub()[0] = newsub
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpRepeat:
        var newsub: Regexp = child_args[0]
        if newsub.op() == kRegexpEmptyMatch:
            return newsub
        var nre: Regexp = SimplifyWalker.SimplifyRepeat(newsub, re.min_, re.max_, re.parse_flags())
        newsub.Decref()
        nre.simple_ = True
        return nre
    elif re.op() == kRegexpCharClass:
        var nre: Regexp = SimplifyWalker.SimplifyCharClass(re)
        nre.simple_ = True
        return nre
    LOG(ERROR, "Simplify case not handled: ", re.op())
    return re.Incref()

def SimplifyWalker_Concat2(re1: Regexp, re2: Regexp, parse_flags: Regexp.ParseFlags) -> Regexp:
    var re: Regexp = Regexp(kRegexpConcat, parse_flags)
    re.AllocSub(2)
    var subs: Pointer[Regexp] = re.sub()
    subs[0] = re1
    subs[1] = re2
    return re

def SimplifyWalker_SimplifyRepeat(re: Regexp, min: Int, max: Int, f: Regexp.ParseFlags) -> Regexp:
    if max == -1:
        if min == 0:
            return Regexp.Star(re.Incref(), f)
        if min == 1:
            return Regexp.Plus(re.Incref(), f)
        var nre_subs: PODArray[Regexp] = PODArray[Regexp](min)
        for i in range(min - 1):
            nre_subs[i] = re.Incref()
        nre_subs[min - 1] = Regexp.Plus(re.Incref(), f)
        return Regexp.Concat(nre_subs.data(), min, f)
    if min == 0 and max == 0:
        return Regexp(kRegexpEmptyMatch, f)
    if min == 1 and max == 1:
        return re.Incref()
    var nre: Regexp = None
    if min > 0:
        var nre_subs: PODArray[Regexp] = PODArray[Regexp](min)
        for i in range(min):
            nre_subs[i] = re.Incref()
        nre = Regexp.Concat(nre_subs.data(), min, f)
    if max > min:
        var suf: Regexp = Regexp.Quest(re.Incref(), f)
        for i in range(min + 1, max):
            suf = Regexp.Quest(SimplifyWalker_Concat2(re.Incref(), suf, f), f)
        if nre == None:
            nre = suf
        else:
            nre = SimplifyWalker_Concat2(nre, suf, f)
    if nre == None:
        LOG(DFATAL, "Malformed repeat ", re.ToString(), " ", min, " ", max)
        return Regexp(kRegexpNoMatch, f)
    return nre

def SimplifyWalker_SimplifyCharClass(re: Regexp) -> Regexp:
    var cc: CharClass = re.cc()
    if cc.empty():
        return Regexp(kRegexpNoMatch, re.parse_flags())
    if cc.full():
        return Regexp(kRegexpAnyChar, re.parse_flags())
    return re.Incref()