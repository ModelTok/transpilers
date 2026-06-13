from util.util import *
from util.logging import *
from util.strutil import *
from util.utf import *
from  import *
from unicode_casefold import *
from re2.walker-inl import *

@value
struct Prefilter:
    enum Op:
        ALL = 0
        NONE = 1
        ATOM = 2
        AND = 3
        OR = 4

    var op_: Op
    var subs_: Pointer[Pointer[Int8]]  # Will use List[Prefilter*] via Pointer
    var atom_: String
    var unique_id_: Int32

    def __init__(inout self, op: Op):
        self.op_ = op
        self.subs_ = Pointer[Pointer[Int8]].null()
        if self.op_ == Op.AND or self.op_ == Op.OR:
            # In Mojo we would use a List[Pointer[Prefilter]] but keeping 1:1 we store as raw pointer
            self.subs_ = Pointer[Pointer[Int8]].alloc(1)
            self.subs_[0] = Pointer[Int8].null()  # placeholder

    def __del__(owned self):
        if self.subs_:
            for i in range(self.subs_.size()):
                if self.subs_[i]:
                    # delete the Prefilter object if we had it

            self.subs_.free()
            self.subs_ = Pointer[Pointer[Int8]].null()

    def op(self) -> Op:
        return self.op_

    def atom(self) -> String:
        return self.atom_

    def set_unique_id(inout self, id: Int32):
        self.unique_id_ = id

    def unique_id(self) -> Int32:
        return self.unique_id_

    def subs(self) -> Pointer[Pointer[Int8]]:
        DCHECK(self.op_ == Op.AND or self.op_ == Op.OR)
        return self.subs_

    def set_subs(inout self, subs: Pointer[Pointer[Int8]]):
        self.subs_ = subs

    @staticmethod
    def FromRE2(re2: Pointer[RE2]) -> Pointer[Prefilter]:
        if not re2:
            return Pointer[Prefilter].null()
        regexp = re2[0].Regexp()
        if not regexp:
            return Pointer[Prefilter].null()
        return FromRegexp(regexp)

    def DebugString(self) -> String:
        if self.op_ == Op.NONE:
            return "*no-matches*"
        elif self.op_ == Op.ATOM:
            return self.atom_
        elif self.op_ == Op.ALL:
            return ""
        elif self.op_ == Op.AND:
            var s = String("")
            for i in range(self.subs_.size()):
                if i > 0:
                    s += " "
                sub = self.subs_[i]
                if sub:
                    s += sub.DebugString()
                else:
                    s += "<nil>"
            return s
        elif self.op_ == Op.OR:
            var s = String("(")
            for i in range(self.subs_.size()):
                if i > 0:
                    s += "|"
                sub = self.subs_[i]
                if sub:
                    s += sub.DebugString()
                else:
                    s += "<nil>"
            s += ")"
            return s
        else:
            LOG(DFATAL) << "Bad op in Prefilter::DebugString: " << self.op_
            return StringPrintf("op%d", self.op_)
        return String("")

    @staticmethod
    def And(a: Pointer[Prefilter], b: Pointer[Prefilter]) -> Pointer[Prefilter]:
        return AndOr(Op.AND, a, b)

    @staticmethod
    def Or(a: Pointer[Prefilter], b: Pointer[Prefilter]) -> Pointer[Prefilter]:
        return AndOr(Op.OR, a, b)

    @staticmethod
    def AndOr(op: Op, a: Pointer[Prefilter], b: Pointer[Prefilter]) -> Pointer[Prefilter]:
        a = a.Simplify()
        b = b.Simplify()
        if a.op() > b.op():
            t = a
            a = b
            b = t
        if a.op() == Op.ALL or a.op() == Op.NONE:
            if (a.op() == Op.ALL and op == Op.AND) or (a.op() == Op.NONE and op == Op.OR):
                delete a
                return b
            else:
                delete b
                return a
        if a.op() == op and b.op() == op:
            for i in range(b.subs().size()):
                bb = b.subs()[i]
                a.subs().push_back(bb)
            b.subs().clear()
            delete b
            return a
        if b.op() == op:
            t = a
            a = b
            b = t
        if a.op() == op:
            a.subs().push_back(b)
            return a
        c = Pointer[Prefilter].alloc(1)
        c[0] = Prefilter(op)
        c[0].subs_.push_back(a)
        c[0].subs_.push_back(b)
        return c

    @staticmethod
    def FromRegexp(re: Pointer[Regexp]) -> Pointer[Prefilter]:
        if not re:
            return Pointer[Prefilter].null()
        simple = re.Simplify()
        if not simple:
            return Pointer[Prefilter].null()
        info = BuildInfo(simple)
        simple.Decref()
        if not info:
            return Pointer[Prefilter].null()
        m = info.TakeMatch()
        delete info
        return m

    @staticmethod
    def FromString(str: String) -> Pointer[Prefilter]:
        m = Pointer[Prefilter].alloc(1)
        m[0] = Prefilter(Op.ATOM)
        m[0].atom_ = str
        return m

    @staticmethod
    def OrStrings(ss: Set[String]) -> Pointer[Prefilter]:
        or_prefilter = Pointer[Prefilter].alloc(1)
        or_prefilter[0] = Prefilter(Op.NONE)
        SimplifyStringSet(ss)
        for i in ss.iter():
            or_prefilter = Or(or_prefilter, FromString(i))
        return or_prefilter

    def Simplify(inout self) -> Pointer[Prefilter]:
        if self.op_ != Op.AND and self.op_ != Op.OR:
            return Pointer[Prefilter].address_of(self)
        if self.subs_.empty():
            if self.op_ == Op.AND:
                self.op_ = Op.ALL
            else:
                self.op_ = Op.NONE
            return Pointer[Prefilter].address_of(self)
        if self.subs_.size() == 1:
            a = self.subs_[0]
            self.subs_.clear()
            delete Pointer[Prefilter].address_of(self)
            return a.Simplify()
        return Pointer[Prefilter].address_of(self)

    # Info struct forward declaration needed; we embed it struct Info:
        var exact_: Set[String]
        var is_exact_: Bool
        var match_: Pointer[Prefilter]

        def __init__(inout self):
            self.is_exact_ = False
            self.match_ = Pointer[Prefilter].null()

        def __del__(owned self):
            if self.match_:
                delete self.match_

        def TakeMatch(inout self) -> Pointer[Prefilter]:
            if self.is_exact_:
                self.match_ = Prefilter.OrStrings(self.exact_)
                self.is_exact_ = False
            m = self.match_
            self.match_ = Pointer[Prefilter].null()
            return m

        def ToString(self) -> String:
            if self.is_exact_:
                n = 0
                s = String("")
                for i in self.exact_.iter():
                    if n > 0:
                        s += ","
                    s += i
                n += 1
                return s
            if self.match_:
                return self.match_.DebugString()
            return String("")

        @staticmethod
        def Alt(a: Pointer[Info], b: Pointer[Info]) -> Pointer[Info]:
            ab = Pointer[Info].alloc(1)
            ab[0] = Info()
            if a[0].is_exact_ and b[0].is_exact_:
                CopyIn(a[0].exact_, ab[0].exact_)
                CopyIn(b[0].exact_, ab[0].exact_)
                ab[0].is_exact_ = True
            else:
                ab[0].match_ = Prefilter.Or(a[0].TakeMatch(), b[0].TakeMatch())
                ab[0].is_exact_ = False
            delete a
            delete b
            return ab

        @staticmethod
        def Concat(a: Pointer[Info], b: Pointer[Info]) -> Pointer[Info]:
            if not a:
                return b
            DCHECK(a[0].is_exact_)
            DCHECK(b and b[0].is_exact_)
            ab = Pointer[Info].alloc(1)
            ab[0] = Info()
            CrossProduct(a[0].exact_, b[0].exact_, ab[0].exact_)
            ab[0].is_exact_ = True
            delete a
            delete b
            return ab

        @staticmethod
        def And(a: Pointer[Info], b: Pointer[Info]) -> Pointer[Info]:
            if not a:
                return b
            if not b:
                return a
            ab = Pointer[Info].alloc(1)
            ab[0] = Info()
            ab[0].match_ = Prefilter.And(a[0].TakeMatch(), b[0].TakeMatch())
            ab[0].is_exact_ = False
            delete a
            delete b
            return ab

        @staticmethod
        def Star(a: Pointer[Info]) -> Pointer[Info]:
            return Quest(a)

        @staticmethod
        def Plus(a: Pointer[Info]) -> Pointer[Info]:
            ab = Pointer[Info].alloc(1)
            ab[0] = Info()
            ab[0].match_ = a[0].TakeMatch()
            ab[0].is_exact_ = False
            delete a
            return ab

        @staticmethod
        def Quest(a: Pointer[Info]) -> Pointer[Info]:
            ab = Pointer[Info].alloc(1)
            ab[0] = Info()
            ab[0].is_exact_ = False
            ab[0].match_ = Pointer[Prefilter].alloc(1)
            ab[0].match_[0] = Prefilter(Op.ALL)
            delete a
            return ab

        @staticmethod
        def EmptyString() -> Pointer[Info]:
            info = Pointer[Info].alloc(1)
            info[0] = Info()
            info[0].is_exact_ = True
            info[0].exact_.insert(String(""))
            return info

        @staticmethod
        def NoMatch() -> Pointer[Info]:
            info = Pointer[Info].alloc(1)
            info[0] = Info()
            info[0].match_ = Pointer[Prefilter].alloc(1)
            info[0].match_[0] = Prefilter(Op.NONE)
            return info

        @staticmethod
        def AnyCharOrAnyByte() -> Pointer[Info]:
            info = Pointer[Info].alloc(1)
            info[0] = Info()
            info[0].match_ = Pointer[Prefilter].alloc(1)
            info[0].match_[0] = Prefilter(Op.ALL)
            return info

        @staticmethod
        def CClass(cc: Pointer[CharClass], latin1: Bool) -> Pointer[Info]:
            if ExtraDebug:
                LOG(ERROR) << "CharClassInfo:"
                for i in cc[0].begin():
                    pass  # simplified: iterate cc
                for i in cc[0].begin():
                    LOG(ERROR) << "  " << i.lo << "-" << i.hi
            if cc[0].size() > 10:
                return AnyCharOrAnyByte()
            a = Pointer[Info].alloc(1)
            a[0] = Info()
            for i in cc[0].begin():
                for r in range(i.lo, i.hi + 1):
                    if latin1:
                        a[0].exact_.insert(RuneToStringLatin1(ToLowerRuneLatin1(r)))
                    else:
                        a[0].exact_.insert(RuneToString(ToLowerRune(r)))
            a[0].is_exact_ = True
            if ExtraDebug:
                LOG(ERROR) << " = " << a[0].ToString()
            return a

        @staticmethod
        def Literal(r: Rune) -> Pointer[Info]:
            info = Pointer[Info].alloc(1)
            info[0] = Info()
            info[0].exact_.insert(RuneToString(ToLowerRune(r)))
            info[0].is_exact_ = True
            return info

        @staticmethod
        def LiteralLatin1(r: Rune) -> Pointer[Info]:
            info = Pointer[Info].alloc(1)
            info[0] = Info()
            info[0].exact_.insert(RuneToStringLatin1(ToLowerRuneLatin1(r)))
            info[0].is_exact_ = True
            return info

        @staticmethod
        def AnyMatch() -> Pointer[Info]:
            info = Pointer[Info].alloc(1)
            info[0] = Info()
            info[0].match_ = Pointer[Prefilter].alloc(1)
            info[0].match_[0] = Prefilter(Op.ALL)
            return info

        def exact(inout self) -> Set[String]:
            return self.exact_

        def is_exact(self) -> Bool:
            return self.is_exact_

        struct Walker(Regexp.Walker[Pointer[Info]]):
            var latin1_: Bool

            def __init__(inout self, latin1: Bool):
                self.latin1_ = latin1

            def PostVisit(self, re: Pointer[Regexp], parent_arg: Pointer[Info], pre_arg: Pointer[Info], child_args: Pointer[Pointer[Info]], nchild_args: Int32) -> Pointer[Info]:
                var info: Pointer[Info]
                if re[0].op() == kRegexpRepeat:
                    LOG(DFATAL) << "Bad regexp op " << re[0].op()
                    info = EmptyString()
                elif re[0].op() == kRegexpNoMatch:
                    info = NoMatch()
                elif re[0].op() == kRegexpEmptyMatch or re[0].op() == kRegexpBeginLine or re[0].op() == kRegexpEndLine or re[0].op() == kRegexpBeginText or re[0].op() == kRegexpEndText or re[0].op() == kRegexpWordBoundary or re[0].op() == kRegexpNoWordBoundary:
                    info = EmptyString()
                elif re[0].op() == kRegexpLiteral:
                    if self.latin1():
                        info = LiteralLatin1(re[0].rune())
                    else:
                        info = Literal(re[0].rune())
                elif re[0].op() == kRegexpLiteralString:
                    if re[0].nrunes() == 0:
                        info = NoMatch()
                    else:
                        if self.latin1():
                            info = LiteralLatin1(re[0].runes()[0])
                            for i in range(1, re[0].nrunes()):
                                info = Concat(info, LiteralLatin1(re[0].runes()[i]))
                        else:
                            info = Literal(re[0].runes()[0])
                            for i in range(1, re[0].nrunes()):
                                info = Concat(info, Literal(re[0].runes()[i]))
                elif re[0].op() == kRegexpConcat:
                    info = Pointer[Info].null()
                    exact = Pointer[Info].null()
                    for i in range(nchild_args):
                        ci = child_args[i]
                        if not ci[0].is_exact() or (exact and ci[0].exact().size() * exact[0].exact().size() > 16):
                            info = And(info, exact)
                            exact = Pointer[Info].null()
                            info = And(info, ci)
                        else:
                            exact = Concat(exact, ci)
                    info = And(info, exact)
                elif re[0].op() == kRegexpAlternate:
                    info = child_args[0]
                    for i in range(1, nchild_args):
                        info = Alt(info, child_args[i])
                elif re[0].op() == kRegexpStar:
                    info = Star(child_args[0])
                elif re[0].op() == kRegexpQuest:
                    info = Quest(child_args[0])
                elif re[0].op() == kRegexpPlus:
                    info = Plus(child_args[0])
                elif re[0].op() == kRegexpAnyChar or re[0].op() == kRegexpAnyByte:
                    info = AnyCharOrAnyByte()
                elif re[0].op() == kRegexpCharClass:
                    info = CClass(re[0].cc(), self.latin1())
                elif re[0].op() == kRegexpCapture:
                    info = child_args[0]
                else:
                    info = EmptyString()
                if ExtraDebug:
                    LOG(ERROR) << "BuildInfo " << re[0].ToString() << ": " << (info[0].ToString() if info else "")
                return info

            def ShortVisit(self, re: Pointer[Regexp], parent_arg: Pointer[Info]) -> Pointer[Info]:
                return AnyMatch()

            def latin1(self) -> Bool:
                return self.latin1_

    @staticmethod
    def BuildInfo(re: Pointer[Regexp]) -> Pointer[Info]:
        if ExtraDebug:
            LOG(ERROR) << "BuildPrefilter::Info: " << re[0].ToString()
        latin1 = (re[0].parse_flags() & Regexp.Latin1) != 0
        w = Info.Walker(latin1)
        info = w.WalkExponential(re, Pointer[Info].null(), 100000)
        if w.stopped_early():
            delete info
            return Pointer[Info].null()
        return info


var ExtraDebug = False
type SSIter = Int  # simplified
type ConstSSIter = Int  # simplified

def SimplifyStringSet(ss: Set[String]):
    for i in ss.iter():
        if i.empty():
            continue
        # need mutable iteration; use while
        var j = ss.find_next(i)
        while j:
            if j.find(i) != -1:
                ss.erase(j)
                continue
            j = ss.find_next(j)

def ToLowerRune(r: Rune) -> Rune:
    if r < Runeself:
        if 'A' <= r and r <= 'Z':
            r += 'a' - 'A'
        return r
    f = LookupCaseFold(unicode_tolower, num_unicode_tolower, r)
    if not f or r < f.lo:
        return r
    return ApplyFold(f, r)

def ToLowerRuneLatin1(r: Rune) -> Rune:
    if 'A' <= r and r <= 'Z':
        r += 'a' - 'A'
    return r

def CopyIn(src: Set[String], dst: Set[String]):
    for i in src.iter():
        dst.insert(i)

def CrossProduct(a: Set[String], b: Set[String], dst: Set[String]):
    for i in a.iter():
        for j in b.iter():
            dst.insert(i + j)

def RuneToString(r: Rune) -> String:
    buf = List[Int8](size=UTFmax)
    n = runetochar(buf, r)
    return String(buf.slice(0, n))

def RuneToStringLatin1(r: Rune) -> String:
    c = r & 0xff
    return String(List[Int8](c), 1)

def Prefilter_FromRE2(re2: Pointer[RE2]) -> Pointer[Prefilter]:
    return Prefilter.FromRE2(re2)