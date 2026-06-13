from util.logging import LOG, DCHECK, DCHECK_EQ
from util.utf import runetochar, Runeself, UTFmax, Runemax, Rune
from re2.pod_array import PODArray
from prog import Prog, Prog_Inst, EmptyOp, kInstNop, kInstAlt, kInstByteRange, kInstCapture, kInstEmptyWidth, kInstMatch, kEmptyBeginLine, kEmptyEndLine, kEmptyBeginText, kEmptyEndText, kEmptyWordBoundary, kEmptyNonWordBoundary, kAnchored, kManyMatch
from re2 import RE2, Anchor, StringPiece
from regexp import Regexp, CharClass, kRegexpRepeat, kRegexpNoMatch, kRegexpEmptyMatch, kRegexpHaveMatch, kRegexpConcat, kRegexpAlternate, kRegexpStar, kRegexpPlus, kRegexpQuest, kRegexpLiteral, kRegexpLiteralString, kRegexpAnyChar, kRegexpAnyByte, kRegexpCharClass, kRegexpCapture, kRegexpBeginLine, kRegexpEndLine, kRegexpBeginText, kRegexpEndText, kRegexpWordBoundary, kRegexpNoWordBoundary, Regexp_ParseFlags, Regexp_NonGreedy, Regexp_FoldCase, Regexp_Latin1
from re2.walker-inl import Walker

struct PatchList:
    @staticmethod
    def Mk(p: UInt32) -> PatchList:
        return PatchList(p, p)

    @staticmethod
    def Patch(inst0: Pointer[Prog_Inst], l: PatchList, p: UInt32):
        var head = l.head
        while head != 0:
            var ip = inst0 + (head >> 1)
            if (head & 1) != 0:
                head = ip[].out1()
                ip[].out1_ = p
            else:
                head = ip[].out()
                ip[].set_out(p)

    @staticmethod
    def Append(inst0: Pointer[Prog_Inst], l1: PatchList, l2: PatchList) -> PatchList:
        if l1.head == 0:
            return l2
        if l2.head == 0:
            return l1
        var ip = inst0 + (l1.tail >> 1)
        if (l1.tail & 1) != 0:
            ip[].out1_ = l2.head
        else:
            ip[].set_out(l2.head)
        return PatchList(l1.head, l2.tail)

    var head: UInt32
    var tail: UInt32

var kNullPatchList = PatchList(0, 0)

struct Frag:
    var begin: UInt32
    var end: PatchList
    var nullable: Bool

    def __init__(inout self):
        self.begin = 0
        self.end = kNullPatchList
        self.nullable = False

    def __init__(inout self, begin: UInt32, end: PatchList, nullable: Bool):
        self.begin = begin
        self.end = end
        self.nullable = nullable

@value
enum Encoding:
    kEncodingUTF8 = 1
    kEncodingLatin1 = 2

struct Compiler(Walker[Frag]):
    var prog_: Pointer[Prog]
    var failed_: Bool
    var encoding_: Encoding
    var reversed_: Bool
    var inst_: PODArray[Prog_Inst]
    var ninst_: Int
    var max_ninst_: Int
    var max_mem_: Int64
    var rune_cache_: Dict[UInt64, Int]
    var rune_range_: Frag
    var anchor_: Anchor

    def __init__(inout self):
        self.prog_ = Pointer[Prog].alloc()
        self.prog_[].__init__()
        self.failed_ = False
        self.encoding_ = Encoding.kEncodingUTF8
        self.reversed_ = False
        self.ninst_ = 0
        self.max_ninst_ = 1
        self.max_mem_ = 0
        var fail = self.AllocInst(1)
        self.inst_[fail].InitFail()
        self.max_ninst_ = 0

    def __del__(owned self):
        if self.prog_:
            self.prog_[].__del__()
            free(self.prog_)

    def AllocInst(inout self, n: Int) -> Int:
        if self.failed_ or self.ninst_ + n > self.max_ninst_:
            self.failed_ = True
            return -1
        if self.ninst_ + n > self.inst_.size():
            var cap = self.inst_.size()
            if cap == 0:
                cap = 8
            while self.ninst_ + n > cap:
                cap *= 2
            var inst = PODArray[Prog_Inst](cap)
            if self.inst_.data() != None:
                memmove(inst.data(), self.inst_.data(), self.ninst_ * sizeof[Prog_Inst]())
            memset(inst.data() + self.ninst_, 0, (cap - self.ninst_) * sizeof[Prog_Inst]())
            self.inst_ = inst
        var id = self.ninst_
        self.ninst_ += n
        return id

    def NoMatch(inout self) -> Frag:
        return Frag()

    def Cat(inout self, a: Frag, b: Frag) -> Frag:
        if IsNoMatch(a) or IsNoMatch(b):
            return self.NoMatch()
        var begin = self.inst_.data() + a.begin
        if begin[].opcode() == kInstNop and a.end.head == (a.begin << 1) and begin[].out() == 0:
            PatchList.Patch(self.inst_.data(), a.end, b.begin)
            return b
        if self.reversed_:
            PatchList.Patch(self.inst_.data(), b.end, a.begin)
            return Frag(b.begin, a.end, b.nullable and a.nullable)
        PatchList.Patch(self.inst_.data(), a.end, b.begin)
        return Frag(a.begin, b.end, a.nullable and b.nullable)

    def Alt(inout self, a: Frag, b: Frag) -> Frag:
        if IsNoMatch(a):
            return b
        if IsNoMatch(b):
            return a
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        self.inst_[id].InitAlt(a.begin, b.begin)
        return Frag(id, PatchList.Append(self.inst_.data(), a.end, b.end), a.nullable or b.nullable)

    def Plus(inout self, a: Frag, nongreedy: Bool) -> Frag:
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        var pl: PatchList
        if nongreedy:
            self.inst_[id].InitAlt(0, a.begin)
            pl = PatchList.Mk(id << 1)
        else:
            self.inst_[id].InitAlt(a.begin, 0)
            pl = PatchList.Mk((id << 1) | 1)
        PatchList.Patch(self.inst_.data(), a.end, id)
        return Frag(a.begin, pl, a.nullable)

    def Star(inout self, a: Frag, nongreedy: Bool) -> Frag:
        if a.nullable:
            return self.Quest(self.Plus(a, nongreedy), nongreedy)
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        var pl: PatchList
        if nongreedy:
            self.inst_[id].InitAlt(0, a.begin)
            pl = PatchList.Mk(id << 1)
        else:
            self.inst_[id].InitAlt(a.begin, 0)
            pl = PatchList.Mk((id << 1) | 1)
        PatchList.Patch(self.inst_.data(), a.end, id)
        return Frag(id, pl, True)

    def Quest(inout self, a: Frag, nongreedy: Bool) -> Frag:
        if IsNoMatch(a):
            return self.Nop()
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        var pl: PatchList
        if nongreedy:
            self.inst_[id].InitAlt(0, a.begin)
            pl = PatchList.Mk(id << 1)
        else:
            self.inst_[id].InitAlt(a.begin, 0)
            pl = PatchList.Mk((id << 1) | 1)
        return Frag(id, PatchList.Append(self.inst_.data(), pl, a.end), True)

    def ByteRange(inout self, lo: Int, hi: Int, foldcase: Bool) -> Frag:
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        self.inst_[id].InitByteRange(lo, hi, foldcase, 0)
        return Frag(id, PatchList.Mk(id << 1), False)

    def Nop(inout self) -> Frag:
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        self.inst_[id].InitNop(0)
        return Frag(id, PatchList.Mk(id << 1), True)

    def Match(inout self, match_id: Int32) -> Frag:
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        self.inst_[id].InitMatch(match_id)
        return Frag(id, kNullPatchList, False)

    def EmptyWidth(inout self, empty: EmptyOp) -> Frag:
        var id = self.AllocInst(1)
        if id < 0:
            return self.NoMatch()
        self.inst_[id].InitEmptyWidth(empty, 0)
        return Frag(id, PatchList.Mk(id << 1), True)

    def Capture(inout self, a: Frag, n: Int) -> Frag:
        if IsNoMatch(a):
            return self.NoMatch()
        var id = self.AllocInst(2)
        if id < 0:
            return self.NoMatch()
        self.inst_[id].InitCapture(2 * n, a.begin)
        self.inst_[id + 1].InitCapture(2 * n + 1, 0)
        PatchList.Patch(self.inst_.data(), a.end, id + 1)
        return Frag(id, PatchList.Mk((id + 1) << 1), a.nullable)

    def BeginRange(inout self):
        self.rune_cache_.clear()
        self.rune_range_.begin = 0
        self.rune_range_.end = kNullPatchList

    def UncachedRuneByteSuffix(inout self, lo: UInt8, hi: UInt8, foldcase: Bool, next: Int) -> Int:
        var f = self.ByteRange(lo, hi, foldcase)
        if next != 0:
            PatchList.Patch(self.inst_.data(), f.end, next)
        else:
            self.rune_range_.end = PatchList.Append(self.inst_.data(), self.rune_range_.end, f.end)
        return f.begin

    def CachedRuneByteSuffix(inout self, lo: UInt8, hi: UInt8, foldcase: Bool, next: Int) -> Int:
        var key = MakeRuneCacheKey(lo, hi, foldcase, next)
        if self.rune_cache_.contains(key):
            return self.rune_cache_[key]
        var id = self.UncachedRuneByteSuffix(lo, hi, foldcase, next)
        self.rune_cache_[key] = id
        return id

    def IsCachedRuneByteSuffix(inout self, id: Int) -> Bool:
        var lo = self.inst_[id].lo_
        var hi = self.inst_[id].hi_
        var foldcase = (self.inst_[id].foldcase() != 0)
        var next = self.inst_[id].out()
        var key = MakeRuneCacheKey(lo, hi, foldcase, next)
        return self.rune_cache_.contains(key)

    def AddSuffix(inout self, id: Int):
        if self.failed_:
            return
        if self.rune_range_.begin == 0:
            self.rune_range_.begin = id
            return
        if self.encoding_ == Encoding.kEncodingUTF8:
            self.rune_range_.begin = self.AddSuffixRecursive(self.rune_range_.begin, id)
            return
        var alt = self.AllocInst(1)
        if alt < 0:
            self.rune_range_.begin = 0
            return
        self.inst_[alt].InitAlt(self.rune_range_.begin, id)
        self.rune_range_.begin = alt

    def AddSuffixRecursive(inout self, root: Int, id: Int) -> Int:
        DCHECK(self.inst_[root].opcode() == kInstAlt or self.inst_[root].opcode() == kInstByteRange)
        var f = self.FindByteRange(root, id)
        if IsNoMatch(f):
            var alt = self.AllocInst(1)
            if alt < 0:
                return 0
            self.inst_[alt].InitAlt(root, id)
            return alt
        var br: Int
        if f.end.head == 0:
            br = root
        elif (f.end.head & 1) != 0:
            br = self.inst_[f.begin].out1()
        else:
            br = self.inst_[f.begin].out()
        if self.IsCachedRuneByteSuffix(br):
            var byterange = self.AllocInst(1)
            if byterange < 0:
                return 0
            self.inst_[byterange].InitByteRange(self.inst_[br].lo(), self.inst_[br].hi(), self.inst_[br].foldcase(), self.inst_[br].out())
            br = byterange
            if f.end.head == 0:
                root = br
            elif (f.end.head & 1) != 0:
                self.inst_[f.begin].out1_ = br
            else:
                self.inst_[f.begin].set_out(br)
        var out = self.inst_[id].out()
        if not self.IsCachedRuneByteSuffix(id):
            DCHECK_EQ(id, self.ninst_ - 1)
            self.inst_[id].out_opcode_ = 0
            self.inst_[id].out1_ = 0
            self.ninst_ -= 1
        out = self.AddSuffixRecursive(self.inst_[br].out(), out)
        if out == 0:
            return 0
        self.inst_[br].set_out(out)
        return root

    def ByteRangeEqual(inout self, id1: Int, id2: Int) -> Bool:
        return self.inst_[id1].lo() == self.inst_[id2].lo() and self.inst_[id1].hi() == self.inst_[id2].hi() and self.inst_[id1].foldcase() == self.inst_[id2].foldcase()

    def FindByteRange(inout self, root: Int, id: Int) -> Frag:
        if self.inst_[root].opcode() == kInstByteRange:
            if self.ByteRangeEqual(root, id):
                return Frag(root, kNullPatchList, False)
            else:
                return self.NoMatch()
        while self.inst_[root].opcode() == kInstAlt:
            var out1 = self.inst_[root].out1()
            if self.ByteRangeEqual(out1, id):
                return Frag(root, PatchList.Mk((root << 1) | 1), False)
            if not self.reversed_:
                return self.NoMatch()
            var out = self.inst_[root].out()
            if self.inst_[out].opcode() == kInstAlt:
                root = out
            elif self.ByteRangeEqual(out, id):
                return Frag(root, PatchList.Mk(root << 1), False)
            else:
                return self.NoMatch()
        LOG(DFATAL, "should never happen")
        return self.NoMatch()

    def EndRange(inout self) -> Frag:
        return self.rune_range_

    def AddRuneRange(inout self, lo: Rune, hi: Rune, foldcase: Bool):
        if self.encoding_ == Encoding.kEncodingUTF8:
            self.AddRuneRangeUTF8(lo, hi, foldcase)
        elif self.encoding_ == Encoding.kEncodingLatin1:
            self.AddRuneRangeLatin1(lo, hi, foldcase)
        else:

    def AddRuneRangeLatin1(inout self, lo: Rune, hi: Rune, foldcase: Bool):
        if lo > hi or lo > 0xFF:
            return
        if hi > 0xFF:
            hi = 0xFF
        self.AddSuffix(self.UncachedRuneByteSuffix(UInt8(lo), UInt8(hi), foldcase, 0))

    def Add_80_10ffff(inout self):
        var id: Int
        if self.reversed_:
            id = self.UncachedRuneByteSuffix(0xC2, 0xDF, False, 0)
            id = self.UncachedRuneByteSuffix(0x80, 0xBF, False, id)
            self.AddSuffix(id)
            id = self.UncachedRuneByteSuffix(0xE0, 0xEF, False, 0)
            id = self.UncachedRuneByteSuffix(0x80, 0xBF, False, id)
            id = self.UncachedRuneByteSuffix(0x80, 0xBF, False, id)
            self.AddSuffix(id)
            id = self.UncachedRuneByteSuffix(0xF0, 0xF4, False, 0)
            id = self.UncachedRuneByteSuffix(0x80, 0xBF, False, id)
            id = self.UncachedRuneByteSuffix(0x80, 0xBF, False, id)
            id = self.UncachedRuneByteSuffix(0x80, 0xBF, False, id)
            self.AddSuffix(id)
        else:
            var cont1 = self.UncachedRuneByteSuffix(0x80, 0xBF, False, 0)
            id = self.UncachedRuneByteSuffix(0xC2, 0xDF, False, cont1)
            self.AddSuffix(id)
            var cont2 = self.UncachedRuneByteSuffix(0x80, 0xBF, False, cont1)
            id = self.UncachedRuneByteSuffix(0xE0, 0xEF, False, cont2)
            self.AddSuffix(id)
            var cont3 = self.UncachedRuneByteSuffix(0x80, 0xBF, False, cont2)
            id = self.UncachedRuneByteSuffix(0xF0, 0xF4, False, cont3)
            self.AddSuffix(id)

    def AddRuneRangeUTF8(inout self, lo: Rune, hi: Rune, foldcase: Bool):
        if lo > hi:
            return
        if lo == 0x80 and hi == 0x10ffff:
            self.Add_80_10ffff()
            return
        for i in range(1, UTFmax):
            var max = MaxRune(i)
            if lo <= max and max < hi:
                self.AddRuneRangeUTF8(lo, max, foldcase)
                self.AddRuneRangeUTF8(max + 1, hi, foldcase)
                return
        if hi < Runeself:
            self.AddSuffix(self.UncachedRuneByteSuffix(UInt8(lo), UInt8(hi), foldcase, 0))
            return
        for i in range(1, UTFmax):
            var m = (1 << (6 * i)) - 1
            if (lo & ~m) != (hi & ~m):
                if (lo & m) != 0:
                    self.AddRuneRangeUTF8(lo, lo | m, foldcase)
                    self.AddRuneRangeUTF8((lo | m) + 1, hi, foldcase)
                    return
                if (hi & m) != m:
                    self.AddRuneRangeUTF8(lo, (hi & ~m) - 1, foldcase)
                    self.AddRuneRangeUTF8(hi & ~m, hi, foldcase)
                    return
        var ulo = Pointer[UInt8].alloc(UTFmax)
        var uhi = Pointer[UInt8].alloc(UTFmax)
        var n = runetochar(Pointer[Char](ulo), lo)
        var m = runetochar(Pointer[Char](uhi), hi)
        DCHECK_EQ(n, m)
        var id = 0
        if self.reversed_:
            for i in range(n):
                if i == 0 or (ulo[i] == uhi[i] and i != n - 1):
                    id = self.CachedRuneByteSuffix(ulo[i], uhi[i], False, id)
                else:
                    id = self.UncachedRuneByteSuffix(ulo[i], uhi[i], False, id)
        else:
            for i in range(n - 1, -1, -1):
                if i == n - 1 or (ulo[i] < uhi[i] and i != 0):
                    id = self.CachedRuneByteSuffix(ulo[i], uhi[i], False, id)
                else:
                    id = self.UncachedRuneByteSuffix(ulo[i], uhi[i], False, id)
        self.AddSuffix(id)
        free(ulo)
        free(uhi)

    def Copy(inout self, arg: Frag) -> Frag:
        LOG(DFATAL, "Compiler::Copy called!")
        self.failed_ = True
        return self.NoMatch()

    def ShortVisit(inout self, re: Pointer[Regexp], arg: Frag) -> Frag:
        self.failed_ = True
        return self.NoMatch()

    def PreVisit(inout self, re: Pointer[Regexp], arg: Frag, stop: Pointer[Bool]) -> Frag:
        if self.failed_:
            stop[0] = True
        return Frag()

    def Literal(inout self, r: Rune, foldcase: Bool) -> Frag:
        if self.encoding_ == Encoding.kEncodingLatin1:
            return self.ByteRange(r, r, foldcase)
        elif self.encoding_ == Encoding.kEncodingUTF8:
            if r < Runeself:
                return self.ByteRange(r, r, foldcase)
            var buf = Pointer[UInt8].alloc(UTFmax)
            var n = runetochar(Pointer[Char](buf), r)
            var f = self.ByteRange(UInt8(buf[0]), buf[0], False)
            for i in range(1, n):
                f = self.Cat(f, self.ByteRange(UInt8(buf[i]), buf[i], False))
            free(buf)
            return f
        else:
            return Frag()

    def PostVisit(inout self, re: Pointer[Regexp], arg: Frag, pre_arg: Frag, child_frags: Pointer[Frag], nchild_frags: Int) -> Frag:
        if self.failed_:
            return self.NoMatch()
        if re[].op() == kRegexpRepeat:

        elif re[].op() == kRegexpNoMatch:
            return self.NoMatch()
        elif re[].op() == kRegexpEmptyMatch:
            return self.Nop()
        elif re[].op() == kRegexpHaveMatch:
            var f = self.Match(re[].match_id())
            if self.anchor_ == RE2.ANCHOR_BOTH:
                f = self.Cat(self.EmptyWidth(kEmptyEndText), f)
            return f
        elif re[].op() == kRegexpConcat:
            var f = child_frags[0]
            for i in range(1, nchild_frags):
                f = self.Cat(f, child_frags[i])
            return f
        elif re[].op() == kRegexpAlternate:
            var f = child_frags[0]
            for i in range(1, nchild_frags):
                f = self.Alt(f, child_frags[i])
            return f
        elif re[].op() == kRegexpStar:
            return self.Star(child_frags[0], (re[].parse_flags() & Regexp_NonGreedy) != 0)
        elif re[].op() == kRegexpPlus:
            return self.Plus(child_frags[0], (re[].parse_flags() & Regexp_NonGreedy) != 0)
        elif re[].op() == kRegexpQuest:
            return self.Quest(child_frags[0], (re[].parse_flags() & Regexp_NonGreedy) != 0)
        elif re[].op() == kRegexpLiteral:
            return self.Literal(re[].rune(), (re[].parse_flags() & Regexp_FoldCase) != 0)
        elif re[].op() == kRegexpLiteralString:
            if re[].nrunes() == 0:
                return self.Nop()
            var f: Frag
            for i in range(re[].nrunes()):
                var f1 = self.Literal(re[].runes()[i], (re[].parse_flags() & Regexp_FoldCase) != 0)
                if i == 0:
                    f = f1
                else:
                    f = self.Cat(f, f1)
            return f
        elif re[].op() == kRegexpAnyChar:
            self.BeginRange()
            self.AddRuneRange(0, Runemax, False)
            return self.EndRange()
        elif re[].op() == kRegexpAnyByte:
            return self.ByteRange(0x00, 0xFF, False)
        elif re[].op() == kRegexpCharClass:
            var cc = re[].cc()
            if cc[].empty():
                LOG(DFATAL, "No ranges in char class")
                self.failed_ = True
                return self.NoMatch()
            var foldascii = cc[].FoldsASCII()
            self.BeginRange()
            var it = cc[].begin()
            while it != cc[].end():
                if foldascii and 'A' <= it[].lo and it[].hi <= 'Z':
                    it = it.next()
                    continue
                var fold = foldascii
                if (it[].lo <= 'A' and 'z' <= it[].hi) or it[].hi < 'A' or 'z' < it[].lo or ('Z' < it[].lo and it[].hi < 'a'):
                    fold = False
                self.AddRuneRange(it[].lo, it[].hi, fold)
                it = it.next()
            return self.EndRange()
        elif re[].op() == kRegexpCapture:
            if re[].cap() < 0:
                return child_frags[0]
            return self.Capture(child_frags[0], re[].cap())
        elif re[].op() == kRegexpBeginLine:
            return self.EmptyWidth(kEmptyEndLine if self.reversed_ else kEmptyBeginLine)
        elif re[].op() == kRegexpEndLine:
            return self.EmptyWidth(kEmptyBeginLine if self.reversed_ else kEmptyEndLine)
        elif re[].op() == kRegexpBeginText:
            return self.EmptyWidth(kEmptyEndText if self.reversed_ else kEmptyBeginText)
        elif re[].op() == kRegexpEndText:
            return self.EmptyWidth(kEmptyBeginText if self.reversed_ else kEmptyEndText)
        elif re[].op() == kRegexpWordBoundary:
            return self.EmptyWidth(kEmptyWordBoundary)
        elif re[].op() == kRegexpNoWordBoundary:
            return self.EmptyWidth(kEmptyNonWordBoundary)
        else:
            LOG(DFATAL, "Missing case in Compiler: " + str(re[].op()))
            self.failed_ = True
            return self.NoMatch()
        return self.NoMatch()

    def Setup(inout self, flags: Regexp_ParseFlags, max_mem: Int64, anchor: Anchor):
        if (flags & Regexp_Latin1) != 0:
            self.encoding_ = Encoding.kEncodingLatin1
        self.max_mem_ = max_mem
        if max_mem <= 0:
            self.max_ninst_ = 100000
        elif max_mem <= sizeof[Prog]():
            self.max_ninst_ = 0
        else:
            var m = (max_mem - sizeof[Prog]()) // sizeof[Prog_Inst]()
            if m >= 1 << 24:
                m = 1 << 24
            if m > Prog_Inst.kMaxInst:
                m = Prog_Inst.kMaxInst
            self.max_ninst_ = Int(m)
        self.anchor_ = anchor

    @staticmethod
    def Compile(re: Pointer[Regexp], reversed: Bool, max_mem: Int64) -> Pointer[Prog]:
        var c = Compiler()
        c.Setup(re[].parse_flags(), max_mem, RE2.UNANCHORED)
        c.reversed_ = reversed
        var sre = re[].Simplify()
        if sre == None:
            return None
        var is_anchor_start = IsAnchorStart(sre, 0)
        var is_anchor_end = IsAnchorEnd(sre, 0)
        var all = c.WalkExponential(sre, Frag(), 2 * c.max_ninst_)
        sre[].Decref()
        if c.failed_:
            return None
        c.reversed_ = False
        all = c.Cat(all, c.Match(0))
        c.prog_[].set_reversed(reversed)
        if c.prog_[].reversed():
            c.prog_[].set_anchor_start(is_anchor_end)
            c.prog_[].set_anchor_end(is_anchor_start)
        else:
            c.prog_[].set_anchor_start(is_anchor_start)
            c.prog_[].set_anchor_end(is_anchor_end)
        c.prog_[].set_start(all.begin)
        if not c.prog_[].anchor_start():
            all = c.Cat(c.DotStar(), all)
        c.prog_[].set_start_unanchored(all.begin)
        return c.Finish(re)

    def Finish(inout self, re: Pointer[Regexp]) -> Pointer[Prog]:
        if self.failed_:
            return None
        if self.prog_[].start() == 0 and self.prog_[].start_unanchored() == 0:
            self.ninst_ = 1
        self.prog_[].inst_ = self.inst_
        self.prog_[].size_ = self.ninst_
        self.prog_[].Optimize()
        self.prog_[].Flatten()
        self.prog_[].ComputeByteMap()
        if not self.prog_[].reversed():
            var prefix = String("")
            var prefix_foldcase = False
            if re[].RequiredPrefixForAccel(prefix, prefix_foldcase):
                self.prog_[].ConfigurePrefixAccel(prefix, prefix_foldcase)
        if self.max_mem_ <= 0:
            self.prog_[].set_dfa_mem(1 << 20)
        else:
            var m = self.max_mem_ - sizeof[Prog]()
            m -= self.prog_[].size_ * sizeof[Prog_Inst]()
            if self.prog_[].CanBitState():
                m -= self.prog_[].size_ * sizeof[UInt16]()
            if m < 0:
                m = 0
            self.prog_[].set_dfa_mem(m)
        var p = self.prog_
        self.prog_ = None
        return p

    def DotStar(inout self) -> Frag:
        return self.Star(self.ByteRange(0x00, 0xFF, False), True)

    @staticmethod
    def CompileSet(re: Pointer[Regexp], anchor: Anchor, max_mem: Int64) -> Pointer[Prog]:
        var c = Compiler()
        c.Setup(re[].parse_flags(), max_mem, anchor)
        var sre = re[].Simplify()
        if sre == None:
            return None
        var all = c.WalkExponential(sre, Frag(), 2 * c.max_ninst_)
        sre[].Decref()
        if c.failed_:
            return None
        c.prog_[].set_anchor_start(True)
        c.prog_[].set_anchor_end(True)
        if anchor == RE2.UNANCHORED:
            all = c.Cat(c.DotStar(), all)
        c.prog_[].set_start(all.begin)
        c.prog_[].set_start_unanchored(all.begin)
        var prog = c.Finish(re)
        if prog == None:
            return None
        var dfa_failed = False
        var sp = StringPiece("hello, world")
        prog[].SearchDFA(sp, sp, kAnchored, kManyMatch, None, dfa_failed, None)
        if dfa_failed:
            free(prog)
            return None
        return prog

def IsNoMatch(a: Frag) -> Bool:
    return a.begin == 0

def MaxRune(len: Int) -> Int:
    var b: Int
    if len == 1:
        b = 7
    else:
        b = 8 - (len + 1) + 6 * (len - 1)
    return (1 << b) - 1

def MakeRuneCacheKey(lo: UInt8, hi: UInt8, foldcase: Bool, next: Int) -> UInt64:
    return (UInt64(next) << 17) | (UInt64(lo) << 9) | (UInt64(hi) << 1) | UInt64(foldcase)

def IsAnchorStart(pre: Pointer[Pointer[Regexp]], depth: Int) -> Bool:
    var re = pre[0]
    var sub: Pointer[Regexp]
    if re == None or depth >= 4:
        return False
    if re[].op() == kRegexpConcat:
        if re[].nsub() > 0:
            sub = re[].sub()[0].Incref()
            if IsAnchorStart(sub, depth + 1):
                var subcopy = PODArray[Pointer[Regexp]](re[].nsub())
                subcopy[0] = sub
                for i in range(1, re[].nsub()):
                    subcopy[i] = re[].sub()[i].Incref()
                pre[0] = Regexp.Concat(subcopy.data(), re[].nsub(), re[].parse_flags())
                re[].Decref()
                return True
            sub[].Decref()
    elif re[].op() == kRegexpCapture:
        sub = re[].sub()[0].Incref()
        if IsAnchorStart(sub, depth + 1):
            pre[0] = Regexp.Capture(sub, re[].parse_flags(), re[].cap())
            re[].Decref()
            return True
        sub[].Decref()
    elif re[].op() == kRegexpBeginText:
        pre[0] = Regexp.LiteralString(None, 0, re[].parse_flags())
        re[].Decref()
        return True
    return False

def IsAnchorEnd(pre: Pointer[Pointer[Regexp]], depth: Int) -> Bool:
    var re = pre[0]
    var sub: Pointer[Regexp]
    if re == None or depth >= 4:
        return False
    if re[].op() == kRegexpConcat:
        if re[].nsub() > 0:
            sub = re[].sub()[re[].nsub() - 1].Incref()
            if IsAnchorEnd(sub, depth + 1):
                var subcopy = PODArray[Pointer[Regexp]](re[].nsub())
                subcopy[re[].nsub() - 1] = sub
                for i in range(re[].nsub() - 1):
                    subcopy[i] = re[].sub()[i].Incref()
                pre[0] = Regexp.Concat(subcopy.data(), re[].nsub(), re[].parse_flags())
                re[].Decref()
                return True
            sub[].Decref()
    elif re[].op() == kRegexpCapture:
        sub = re[].sub()[0].Incref()
        if IsAnchorEnd(sub, depth + 1):
            pre[0] = Regexp.Capture(sub, re[].parse_flags(), re[].cap())
            re[].Decref()
            return True
        sub[].Decref()
    elif re[].op() == kRegexpEndText:
        pre[0] = Regexp.LiteralString(None, 0, re[].parse_flags())
        re[].Decref()
        return True
    return False

def Regexp_CompileToProg(self: Pointer[Regexp], max_mem: Int64) -> Pointer[Prog]:
    return Compiler.Compile(self, False, max_mem)

def Regexp_CompileToReverseProg(self: Pointer[Regexp], max_mem: Int64) -> Pointer[Prog]:
    return Compiler.Compile(self, True, max_mem)

def Prog_CompileSet(re: Pointer[Regexp], anchor: Anchor, max_mem: Int64) -> Pointer[Prog]:
    return Compiler.CompileSet(re, anchor, max_mem)