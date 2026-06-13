# Mojo translation of prog.cc (with prog.h) - faithful 1:1
# Note: unions are represented as struct with all fields (non-overlapping).
# switch statements converted to if/elif/else chains.
# goto's converted to while loops with continue.

from util.util import StringPrintf
from util.logging import LOG, DCHECK, CHECK_EQ, FALLTHROUGH_INTENDED
from util.strutil import *
from .bitmap256 import Bitmap256
from stringpiece import StringPiece
from .pod_array import PODArray
from .sparse_array import SparseArray
from .sparse_set import SparseSet
from  import RE2
from memory import memmove, memcpy, memset, memchr
from builtin import min, max, sort, find, unique

# Conditional AVX2 support (disabled)
alias __AVX2__ = False

# --- Enums ---
enum InstOp(UInt32):
    kInstAlt = 0
    kInstAltMatch
    kInstByteRange
    kInstCapture
    kInstEmptyWidth
    kInstMatch
    kInstNop
    kInstFail
    kNumInst

enum EmptyOp(UInt32):
    kEmptyBeginLine = 1<<0
    kEmptyEndLine = 1<<1
    kEmptyBeginText = 1<<2
    kEmptyEndText = 1<<3
    kEmptyWordBoundary = 1<<4
    kEmptyNonWordBoundary = 1<<5
    kEmptyAllFlags = (1<<6)-1

# --- Prog class (forward decl needed) ---
# Inst nested class defined inside Prog

struct Prog:
    # enum Anchor, MatchKind
    enum Anchor:
        kUnanchored
        kAnchored

    enum MatchKind:
        kFirstMatch
        kLongestMatch
        kFullMatch
        kManyMatch

    # --- Nested class Inst ---
    struct Inst:
        var out_opcode_: UInt32
        # union fields (all stored separately for Mojo)
        var out1_: UInt32
        var cap_: Int32
        var match_id_: Int32
        var lo_: UInt8
        var hi_: UInt8
        var hint_foldcase_: UInt16
        var empty_: EmptyOp

        def __init__(inout self):
            self.out_opcode_ = 0
            self.out1_ = 0
            self.cap_ = 0
            self.match_id_ = 0
            self.lo_ = 0
            self.hi_ = 0
            self.hint_foldcase_ = 0
            self.empty_ = EmptyOp(0)

        def InitAlt(inout self, out: UInt32, out1: UInt32):
            DCHECK(self.out_opcode_ == 0)
            self.set_out_opcode(out, InstOp.kInstAlt)
            self.out1_ = out1

        def InitByteRange(inout self, lo: Int, hi: Int, foldcase: Int, out: UInt32):
            DCHECK(self.out_opcode_ == 0)
            self.set_out_opcode(out, InstOp.kInstByteRange)
            self.lo_ = UInt8(lo & 0xFF)
            self.hi_ = UInt8(hi & 0xFF)
            self.hint_foldcase_ = UInt16(foldcase & 1)

        def InitCapture(inout self, cap: Int, out: UInt32):
            DCHECK(self.out_opcode_ == 0)
            self.set_out_opcode(out, InstOp.kInstCapture)
            self.cap_ = Int32(cap)

        def InitEmptyWidth(inout self, empty: EmptyOp, out: UInt32):
            DCHECK(self.out_opcode_ == 0)
            self.set_out_opcode(out, InstOp.kInstEmptyWidth)
            self.empty_ = empty

        def InitMatch(inout self, id: Int32):
            DCHECK(self.out_opcode_ == 0)
            self.set_opcode(InstOp.kInstMatch)
            self.match_id_ = id

        def InitNop(inout self, out: UInt32):
            DCHECK(self.out_opcode_ == 0)
            self.set_opcode(InstOp.kInstNop)

        def InitFail(inout self):
            DCHECK(self.out_opcode_ == 0)
            self.set_opcode(InstOp.kInstFail)

        def id(self, p: Prog) -> Int:
            return Int(self.address - p.inst_.data().address)  # adjusted for Mojo pointer arithmetic (simplified)

        def opcode(self) -> InstOp:
            return InstOp(self.out_opcode_ & 7)

        def last(self) -> Int:
            return Int((self.out_opcode_ >> 3) & 1)

        def out(self) -> Int:
            return Int(self.out_opcode_ >> 4)

        def out1(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstAlt or self.opcode() == InstOp.kInstAltMatch)
            return Int(self.out1_)

        def cap(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstCapture)
            return Int(self.cap_)

        def lo(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstByteRange)
            return Int(self.lo_)

        def hi(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstByteRange)
            return Int(self.hi_)

        def foldcase(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstByteRange)
            return Int(self.hint_foldcase_ & 1)

        def hint(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstByteRange)
            return Int(self.hint_foldcase_ >> 1)

        def match_id(self) -> Int:
            DCHECK(self.opcode() == InstOp.kInstMatch)
            return Int(self.match_id_)

        def empty(self) -> EmptyOp:
            DCHECK(self.opcode() == InstOp.kInstEmptyWidth)
            return self.empty_

        def greedy(self, p: Prog) -> Bool:
            DCHECK(self.opcode() == InstOp.kInstAltMatch)
            var ip = p.inst(self.out())
            if ip.opcode() == InstOp.kInstByteRange:
                return True
            if ip.opcode() == InstOp.kInstNop:
                var ip2 = p.inst(ip.out())
                if ip2.opcode() == InstOp.kInstByteRange:
                    return True
            return False

        def Matches(self, c: Int) -> Bool:
            DCHECK(self.opcode() == InstOp.kInstByteRange)
            var c2 = c
            if self.foldcase() and 'A' <= c and c <= 'Z':
                c2 += 'a' - 'A'
            return self.lo_ <= c2 and c2 <= self.hi_

        def Dump(self) -> String:
            if self.opcode() == InstOp.kInstAlt:
                return StringPrintf("alt -> %d | %d", self.out(), self.out1())
            elif self.opcode() == InstOp.kInstAltMatch:
                return StringPrintf("altmatch -> %d | %d", self.out(), self.out1())
            elif self.opcode() == InstOp.kInstByteRange:
                return StringPrintf("byte%s [%02x-%02x] %d -> %d",
                                    "/i" if self.foldcase() else "",
                                    self.lo_, self.hi_, self.hint(), self.out())
            elif self.opcode() == InstOp.kInstCapture:
                return StringPrintf("capture %d -> %d", self.cap(), self.out())
            elif self.opcode() == InstOp.kInstEmptyWidth:
                return StringPrintf("emptywidth %#x -> %d", Int(self.empty_), self.out())
            elif self.opcode() == InstOp.kInstMatch:
                return StringPrintf("match! %d", self.match_id())
            elif self.opcode() == InstOp.kInstNop:
                return StringPrintf("nop -> %d", self.out())
            elif self.opcode() == InstOp.kInstFail:
                return StringPrintf("fail")
            else:
                return StringPrintf("opcode %d", Int(self.opcode()))

        # private helpers in C++ (made public for translation)
        def set_opcode(inout self, opcode: InstOp):
            self.out_opcode_ = (UInt32(self.out()) << 4) | (UInt32(self.last()) << 3) | UInt32(opcode)

        def set_last(inout self):
            self.out_opcode_ = (UInt32(self.out()) << 4) | (1 << 3) | UInt32(self.opcode())

        def set_out(inout self, out: Int):
            self.out_opcode_ = (UInt32(out) << 4) | (UInt32(self.last()) << 3) | UInt32(self.opcode())

        def set_out_opcode(inout self, out: Int, opcode: InstOp):
            self.out_opcode_ = (UInt32(out) << 4) | (UInt32(self.last()) << 3) | UInt32(opcode)

        # constant
        alias kMaxInst = (1 << 28) - 1

    # --- Prog members ---
    var anchor_start_: Bool
    var anchor_end_: Bool
    var reversed_: Bool
    var did_flatten_: Bool
    var did_onepass_: Bool
    var start_: Int
    var start_unanchored_: Int
    var size_: Int
    var bytemap_range_: Int
    var prefix_foldcase_: Bool
    var prefix_size_: Int
    var prefix_front_: Int
    var prefix_back_: Int
    var prefix_dfa_: Pointer[UInt64]
    var list_count_: Int
    var inst_count_: List[Int]  # size kNumInst
    var list_heads_: PODArray[UInt16]
    var bit_state_text_max_size_: Int
    var inst_: PODArray[Inst]
    var onepass_nodes_: PODArray[UInt8]
    var dfa_mem_: Int64
    var dfa_first_: DFA
    var dfa_longest_: DFA
    var bytemap_: List[UInt8]  # size 256
    var dfa_first_once_: Bool
    var dfa_longest_once_: Bool

    def __init__(inout self):
        self.anchor_start_ = False
        self.anchor_end_ = False
        self.reversed_ = False
        self.did_flatten_ = False
        self.did_onepass_ = False
        self.start_ = 0
        self.start_unanchored_ = 0
        self.size_ = 0
        self.bytemap_range_ = 0
        self.prefix_foldcase_ = False
        self.prefix_size_ = 0
        self.list_count_ = 0
        self.bit_state_text_max_size_ = 0
        self.dfa_mem_ = 0
        self.dfa_first_ = DFA()
        self.dfa_longest_ = DFA()
        self.bytemap_ = List[UInt8](256, 0)
        self.inst_count_ = List[Int](Int(InstOp.kNumInst), 0)
        self.dfa_first_once_ = False
        self.dfa_longest_once_ = False

    def __del__(inout self):
        self.DeleteDFA(self.dfa_longest_)
        self.DeleteDFA(self.dfa_first_)
        if self.prefix_foldcase_:
            del self.prefix_dfa_

    def inst(self, id: Int) -> Inst:
        return self.inst_[id]

    def start(self) -> Int:
        return self.start_

    def set_start(inout self, start: Int):
        self.start_ = start

    def start_unanchored(self) -> Int:
        return self.start_unanchored_

    def set_start_unanchored(inout self, start: Int):
        self.start_unanchored_ = start

    def size(self) -> Int:
        return self.size_

    def reversed(self) -> Bool:
        return self.reversed_

    def set_reversed(inout self, reversed: Bool):
        self.reversed_ = reversed

    def list_count(self) -> Int:
        return self.list_count_

    def inst_count(self, op: InstOp) -> Int:
        return self.inst_count_[Int(op)]

    def list_heads(self) -> Pointer[UInt16]:
        return self.list_heads_.data()

    def bit_state_text_max_size(self) -> Int:
        return self.bit_state_text_max_size_

    def dfa_mem(self) -> Int64:
        return self.dfa_mem_

    def set_dfa_mem(inout self, dfa_mem: Int64):
        self.dfa_mem_ = dfa_mem

    def anchor_start(self) -> Bool:
        return self.anchor_start_

    def set_anchor_start(inout self, b: Bool):
        self.anchor_start_ = b

    def anchor_end(self) -> Bool:
        return self.anchor_end_

    def set_anchor_end(inout self, b: Bool):
        self.anchor_end_ = b

    def bytemap_range(self) -> Int:
        return self.bytemap_range_

    def bytemap(self) -> Pointer[UInt8]:
        return self.bytemap_.data()

    def can_prefix_accel(self) -> Bool:
        return self.prefix_size_ != 0

    def PrefixAccel(self, data: Pointer[UInt8], size: Int) -> Pointer[UInt8]:
        DCHECK(self.can_prefix_accel())
        if self.prefix_foldcase_:
            return self.PrefixAccel_ShiftDFA(data, size)
        elif self.prefix_size_ != 1:
            return self.PrefixAccel_FrontAndBack(data, size)
        else:
            return memchr(data, self.prefix_front_, size)

    def ConfigurePrefixAccel(inout self, prefix: String, prefix_foldcase: Bool):
        self.prefix_foldcase_ = prefix_foldcase
        self.prefix_size_ = prefix.size()
        if prefix_foldcase_:
            self.prefix_size_ = min(self.prefix_size_, kShiftDFAFinal)
            self.prefix_dfa_ = BuildShiftDFA(prefix.substr(0, self.prefix_size_))
        elif self.prefix_size_ != 1:
            self.prefix_front_ = Int(prefix.front())
            self.prefix_back_ = Int(prefix.back())
        else:
            self.prefix_front_ = Int(prefix.front())

    def PrefixAccel_ShiftDFA(self, data: Pointer[UInt8], size: Int) -> Pointer[UInt8]:
        if size < self.prefix_size_:
            return Pointer[UInt8]()
        var curr: UInt64 = 0
        var p = data
        if size >= 8:
            var endp = p + (size & ~7)
            while p != endp:
                var b0 = p[0]
                var b1 = p[1]
                var b2 = p[2]
                var b3 = p[3]
                var b4 = p[4]
                var b5 = p[5]
                var b6 = p[6]
                var b7 = p[7]
                var next0 = self.prefix_dfa_[b0]
                var next1 = self.prefix_dfa_[b1]
                var next2 = self.prefix_dfa_[b2]
                var next3 = self.prefix_dfa_[b3]
                var next4 = self.prefix_dfa_[b4]
                var next5 = self.prefix_dfa_[b5]
                var next6 = self.prefix_dfa_[b6]
                var next7 = self.prefix_dfa_[b7]
                var curr0 = next0 >> (curr & 63)
                var curr1 = next1 >> (curr0 & 63)
                var curr2 = next2 >> (curr1 & 63)
                var curr3 = next3 >> (curr2 & 63)
                var curr4 = next4 >> (curr3 & 63)
                var curr5 = next5 >> (curr4 & 63)
                var curr6 = next6 >> (curr5 & 63)
                var curr7 = next7 >> (curr6 & 63)
                if (curr7 & 63) == kShiftDFAFinal * 6:
                    if ((curr7 - curr0) & 63) == 0: return p + 1 - self.prefix_size_
                    if ((curr7 - curr1) & 63) == 0: return p + 2 - self.prefix_size_
                    if ((curr7 - curr2) & 63) == 0: return p + 3 - self.prefix_size_
                    if ((curr7 - curr3) & 63) == 0: return p + 4 - self.prefix_size_
                    if ((curr7 - curr4) & 63) == 0: return p + 5 - self.prefix_size_
                    if ((curr7 - curr5) & 63) == 0: return p + 6 - self.prefix_size_
                    if ((curr7 - curr6) & 63) == 0: return p + 7 - self.prefix_size_
                    if ((curr7 - curr7) & 63) == 0: return p + 8 - self.prefix_size_
                curr = curr7
                p += 8
            data = p
            size = size & 7
        p = data
        var endp_small = p + size
        while p != endp_small:
            var b = p[0]
            p += 1
            var next = self.prefix_dfa_[b]
            curr = next >> (curr & 63)
            if (curr & 63) == kShiftDFAFinal * 6:
                return p - self.prefix_size_
        return Pointer[UInt8]()

    @parameter
    if __AVX2__:
        def FindLSBSet(n: UInt32) -> Int:
            DCHECK(n != 0)
            # Use builtin ctz if available, else loop
            # In Mojo we can use Int.ctz()? Not sure, fallback loop
            var c: Int = 31
            var shift: Int = 1 << 4
            while shift != 0:
                var word = n << shift
                if word != 0:
                    n = word
                    c -= shift
                shift >>= 1
            return c

    def PrefixAccel_FrontAndBack(self, data: Pointer[UInt8], size: Int) -> Pointer[UInt8]:
        DCHECK(self.prefix_size_ >= 2)
        if size < self.prefix_size_:
            return Pointer[UInt8]()
        var size2 = size - (self.prefix_size_ - 1)
        @parameter
        if __AVX2__:
            if size2 >= sizeof(__m256i):
                var fp = Pointer[__m256i](data)
                var bp = Pointer[__m256i](data + (self.prefix_size_ - 1))
                var endfp = fp + (size2 / sizeof(__m256i))
                var f_set1 = _mm256_set1_epi8(self.prefix_front_)
                var b_set1 = _mm256_set1_epi8(self.prefix_back_)
                while fp != endfp:
                    var f_loadu = _mm256_loadu_si256(fp)
                    fp += 1
                    var b_loadu = _mm256_loadu_si256(bp)
                    bp += 1
                    var f_cmpeq = _mm256_cmpeq_epi8(f_set1, f_loadu)
                    var b_cmpeq = _mm256_cmpeq_epi8(b_set1, b_loadu)
                    var fb_testz = _mm256_testz_si256(f_cmpeq, b_cmpeq)
                    if fb_testz == 0:
                        var fb_and = _mm256_and_si256(f_cmpeq, b_cmpeq)
                        var fb_movemask = _mm256_movemask_epi8(fb_and)
                        var fb_ctz = FindLSBSet(fb_movemask)
                        return Pointer[UInt8](fp - 1) + fb_ctz
                data = Pointer[UInt8](fp)
                size2 = size2 % sizeof(__m256i)
        var p0 = Pointer[UInt8](data)
        var p = p0
        loop:
            p = memchr(p, self.prefix_front_, size2 - Int(p - p0))
            if p is None or p[self.prefix_size_ - 1] == self.prefix_back_:
                return p
        return Pointer[UInt8]()

    def Dump(self) -> String:
        if self.did_flatten_:
            return FlattenedProgToString(self, self.start_)
        var q = Workq(self.size_)
        AddToQueue(&q, self.start_)
        return ProgToString(self, &q)

    def DumpUnanchored(self) -> String:
        if self.did_flatten_:
            return FlattenedProgToString(self, self.start_unanchored_)
        var q = Workq(self.size_)
        AddToQueue(&q, self.start_unanchored_)
        return ProgToString(self, &q)

    def DumpByteMap(self) -> String:
        var map = String
        for c in range(256):
            var b = self.bytemap_[c]
            var lo = c
            while c < 255 and self.bytemap_[c + 1] == b:
                c += 1
            var hi = c
            map += StringPrintf("[%02x-%02x] -> %d\n", lo, hi, b)
        return map

    def Optimize(inout self):
        var q = Workq(self.size_)
        q.clear()
        AddToQueue(&q, self.start_)
        for i in q:
            var id = i
            var ip = self.inst(id)
            var j = ip.out()
            var jp: Self.Inst
            while j != 0 and (jp = self.inst(j), jp.opcode() == InstOp.kInstNop):
                j = jp.out()
            ip.set_out(j)
            AddToQueue(&q, ip.out())
            if ip.opcode() == InstOp.kInstAlt:
                j = ip.out1()
                while j != 0 and (jp = self.inst(j), jp.opcode() == InstOp.kInstNop):
                    j = jp.out()
                ip.out1_ = UInt32(j)
                AddToQueue(&q, ip.out1())
        q.clear()
        AddToQueue(&q, self.start_)
        for i in q:
            var id = i
            var ip = self.inst(id)
            AddToQueue(&q, ip.out())
            if ip.opcode() == InstOp.kInstAlt:
                AddToQueue(&q, ip.out1())
                var j = self.inst(ip.out())
                var k = self.inst(ip.out1())
                if j.opcode() == InstOp.kInstByteRange and j.out() == id and j.lo() == 0x00 and j.hi() == 0xFF and IsMatch(self, k):
                    ip.set_opcode(InstOp.kInstAltMatch)
                elif IsMatch(self, j) and k.opcode() == InstOp.kInstByteRange and k.out() == id and k.lo() == 0x00 and k.hi() == 0xFF:
                    ip.set_opcode(InstOp.kInstAltMatch)

    def EmptyFlags(text: StringPiece, p: Pointer[UInt8]) -> UInt32:
        var flags: UInt32 = 0
        if p == text.data():
            flags |= kEmptyBeginText | kEmptyBeginLine
        elif p[-1] == '\n':
            flags |= kEmptyBeginLine
        if p == text.data() + text.size():
            flags |= kEmptyEndText | kEmptyEndLine
        elif p < text.data() + text.size() and p[0] == '\n':
            flags |= kEmptyEndLine
        if p == text.data() and p == text.data() + text.size():

        elif p == text.data():
            if IsWordChar(p[0]):
                flags |= kEmptyWordBoundary
        elif p == text.data() + text.size():
            if IsWordChar(p[-1]):
                flags |= kEmptyWordBoundary
        else:
            if IsWordChar(p[-1]) != IsWordChar(p[0]):
                flags |= kEmptyWordBoundary
        if not (flags & kEmptyWordBoundary):
            flags |= kEmptyNonWordBoundary
        return flags

    def IsWordChar(c: UInt8) -> Bool:
        return ('A' <= c and c <= 'Z') or ('a' <= c and c <= 'z') or ('0' <= c and c <= '9') or c == '_'

    def ComputeByteMap(inout self):
        var builder = ByteMapBuilder()
        var marked_line_boundaries = False
        var marked_word_boundaries = False
        for id in range(self.size()):
            var ip = self.inst(id)
            if ip.opcode() == InstOp.kInstByteRange:
                var lo = ip.lo()
                var hi = ip.hi()
                builder.Mark(lo, hi)
                if ip.foldcase() and lo <= 'z' and hi >= 'a':
                    var foldlo = lo
                    var foldhi = hi
                    if foldlo < 'a':
                        foldlo = 'a'
                    if foldhi > 'z':
                        foldhi = 'z'
                    if foldlo <= foldhi:
                        foldlo += 'A' - 'a'
                        foldhi += 'A' - 'a'
                        builder.Mark(foldlo, foldhi)
                if not ip.last() and self.inst(id + 1).opcode() == InstOp.kInstByteRange and ip.out() == self.inst(id + 1).out():
                    continue
                builder.Merge()
            elif ip.opcode() == InstOp.kInstEmptyWidth:
                if ip.empty() & (kEmptyBeginLine | kEmptyEndLine) and not marked_line_boundaries:
                    builder.Mark('\n', '\n')
                    builder.Merge()
                    marked_line_boundaries = True
                if ip.empty() & (kEmptyWordBoundary | kEmptyNonWordBoundary) and not marked_word_boundaries:
                    for isword in [True, False]:
                        var i: Int = 0
                        while i < 256:
                            var j = i + 1
                            while j < 256 and Prog.IsWordChar(UInt8(i)) == Prog.IsWordChar(UInt8(j)):
                                j += 1
                            if Prog.IsWordChar(UInt8(i)) == isword:
                                builder.Mark(i, j - 1)
                            i = j
                        builder.Merge()
                    marked_word_boundaries = True
        builder.Build(self.bytemap_.data(), &self.bytemap_range_)
        if False:  # For debugging
            LOG(ERROR) << "Using trivial bytemap."
            for i in range(256):
                self.bytemap_[i] = UInt8(i)
            self.bytemap_range_ = 256

    def Flatten(inout self):
        if self.did_flatten_:
            return
        self.did_flatten_ = True
        var reachable = SparseSet(self.size())
        var stk = List[Int]()
        stk.reserve(self.size())
        var rootmap = SparseArray[Int](self.size())
        var predmap = SparseArray[Int](self.size())
        var predvec = List[List[Int]]()
        self.MarkSuccessors(&rootmap, &predmap, &predvec, &reachable, &stk)
        var sorted = SparseArray[Int](rootmap)
        sort(sorted.begin(), sorted.end(), sorted.less)
        var i = sorted.end() - 1
        while i != sorted.begin():
            if i.index() != self.start_unanchored() and i.index() != self.start():
                self.MarkDominator(i.index(), &rootmap, &predmap, &predvec, &reachable, &stk)
            i -= 1
        var flatmap = List[Int](rootmap.size())
        var flat = List[Inst]()
        flat.reserve(self.size())
        for i in rootmap:
            flatmap[i.value()] = Int(flat.size())
            self.EmitList(i.index(), &rootmap, &flat, &reachable, &stk)
            flat.back().set_last()
            self.ComputeHints(&flat, flatmap[i.value()], Int(flat.size()))
        self.list_count_ = Int(flatmap.size())
        for i in range(Int(InstOp.kNumInst)):
            self.inst_count_[i] = 0
        for id in range(Int(flat.size())):
            var ip = &flat[id]
            if ip.opcode() != InstOp.kInstAltMatch:
                ip.set_out(flatmap[ip.out()])
            self.inst_count_[Int(ip.opcode())] += 1
        # debug check
        if False:
            var total: Int = 0
            for i in range(Int(InstOp.kNumInst)):
                total += self.inst_count_[i]
            CHECK_EQ(total, flat.size())
        if self.start_unanchored() == 0:
            DCHECK(self.start() == 0)
        elif self.start_unanchored() == self.start():
            self.set_start_unanchored(flatmap[1])
            self.set_start(flatmap[1])
        else:
            self.set_start_unanchored(flatmap[1])
            self.set_start(flatmap[2])
        self.size_ = Int(flat.size())
        self.inst_ = PODArray[Inst](self.size_)
        memmove(self.inst_.data(), flat.data(), self.size_ * sizeof[Self.Inst])
        if self.size_ <= 512:
            self.list_heads_ = PODArray[UInt16](self.size_)
            memset(self.list_heads_.data(), 0xFF, self.size_ * sizeof[UInt16])
            for i in range(self.list_count_):
                self.list_heads_[flatmap[i]] = UInt16(i)
        alias kBitStateBitmapMaxSize = 256 * 1024  # max size in bits
        self.bit_state_text_max_size_ = Int(kBitStateBitmapMaxSize / self.list_count_) - 1

    def MarkSuccessors(inout self, rootmap: Pointer[SparseArray[Int]], predmap: Pointer[SparseArray[Int]], predvec: Pointer[List[List[Int]]], reachable: Pointer[SparseSet], stk: Pointer[List[Int]]):
        rootmap.set_new(0, rootmap.size())
        if not rootmap.has_index(self.start_unanchored()):
            rootmap.set_new(self.start_unanchored(), rootmap.size())
        if not rootmap.has_index(self.start()):
            rootmap.set_new(self.start(), rootmap.size())
        reachable.clear()
        stk.clear()
        stk.push_back(self.start_unanchored())
        while not stk.empty():
            var id = stk.back()
            stk.pop_back()
            while True:
                if reachable.contains(id):
                    break
                reachable.insert_new(id)
                var ip = self.inst(id)
                if ip.opcode() == InstOp.kInstAltMatch or ip.opcode() == InstOp.kInstAlt:
                    for out in [ip.out(), ip.out1()]:
                        if not predmap.has_index(out):
                            predmap.set_new(out, Int(predvec.size()))
                            predvec.emplace_back()
                        predvec[predmap.get_existing(out)].emplace_back(id)
                    stk.push_back(ip.out1())
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstByteRange or ip.opcode() == InstOp.kInstCapture or ip.opcode() == InstOp.kInstEmptyWidth:
                    if not rootmap.has_index(ip.out()):
                        rootmap.set_new(ip.out(), rootmap.size())
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstNop:
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstMatch or ip.opcode() == InstOp.kInstFail:
                    break
                else:
                    LOG(DFATAL) << "unhandled opcode: " << ip.opcode()
                    break
                break  # exit while true

    def MarkDominator(inout self, root: Int, rootmap: Pointer[SparseArray[Int]], predmap: Pointer[SparseArray[Int]], predvec: Pointer[List[List[Int]]], reachable: Pointer[SparseSet], stk: Pointer[List[Int]]):
        reachable.clear()
        stk.clear()
        stk.push_back(root)
        while not stk.empty():
            var id = stk.back()
            stk.pop_back()
            while True:
                if reachable.contains(id):
                    break
                reachable.insert_new(id)
                if id != root and rootmap.has_index(id):
                    continue
                var ip = self.inst(id)
                if ip.opcode() == InstOp.kInstAltMatch or ip.opcode() == InstOp.kInstAlt:
                    stk.push_back(ip.out1())
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstByteRange or ip.opcode() == InstOp.kInstCapture or ip.opcode() == InstOp.kInstEmptyWidth:
                    break
                elif ip.opcode() == InstOp.kInstNop:
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstMatch or ip.opcode() == InstOp.kInstFail:
                    break
                else:
                    LOG(DFATAL) << "unhandled opcode: " << ip.opcode()
                    break
                break
        for i in reachable:
            var id = i
            if predmap.has_index(id):
                for pred in predvec[predmap.get_existing(id)]:
                    if not reachable.contains(pred):
                        if not rootmap.has_index(id):
                            rootmap.set_new(id, rootmap.size())

    def EmitList(inout self, root: Int, rootmap: Pointer[SparseArray[Int]], flat: Pointer[List[Inst]], reachable: Pointer[SparseSet], stk: Pointer[List[Int]]):
        reachable.clear()
        stk.clear()
        stk.push_back(root)
        while not stk.empty():
            var id = stk.back()
            stk.pop_back()
            while True:
                if reachable.contains(id):
                    break
                reachable.insert_new(id)
                if id != root and rootmap.has_index(id):
                    flat.emplace_back()
                    flat.back().set_opcode(InstOp.kInstNop)
                    flat.back().set_out(rootmap.get_existing(id))
                    continue
                var ip = self.inst(id)
                if ip.opcode() == InstOp.kInstAltMatch:
                    flat.emplace_back()
                    flat.back().set_opcode(InstOp.kInstAltMatch)
                    flat.back().set_out(Int(flat.size()))
                    flat.back().out1_ = UInt32(Int(flat.size()) + 1)
                    # FALLTHROUGH_INTENDED
                    # fall through to kInstAlt
                    # In Mojo we'll handle Alt after fallthrough
                if ip.opcode() == InstOp.kInstAlt or ip.opcode() == InstOp.kInstAltMatch:
                    stk.push_back(ip.out1())
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstByteRange or ip.opcode() == InstOp.kInstCapture or ip.opcode() == InstOp.kInstEmptyWidth:
                    flat.emplace_back()
                    memmove(&flat.back(), ip, sizeof[Self.Inst])
                    flat.back().set_out(rootmap.get_existing(ip.out()))
                    break
                elif ip.opcode() == InstOp.kInstNop:
                    id = ip.out()
                    continue
                elif ip.opcode() == InstOp.kInstMatch or ip.opcode() == InstOp.kInstFail:
                    flat.emplace_back()
                    memmove(&flat.back(), ip, sizeof[Self.Inst])
                    break
                else:
                    LOG(DFATAL) << "unhandled opcode: " << ip.opcode()
                    break
                break

    def ComputeHints(inout self, flat: Pointer[List[Inst]], begin: Int, end: Int):
        var splits = Bitmap256()
        var colors = List[Int](256, 0)
        var dirty = False
        for id in range(end, begin - 1, -1):
            if id == end or flat[id].opcode() != InstOp.kInstByteRange:
                if dirty:
                    dirty = False
                    splits.Clear()
                splits.Set(255)
                colors[255] = id
                continue
            dirty = True
            var first = end
            # Recolor lambda
            def Recolor(lo: Int, hi: Int):
                var lo2 = lo
                var hi2 = hi
                lo2 -= 1
                if 0 <= lo2 and not splits.Test(lo2):
                    splits.Set(lo2)
                    var next = splits.FindNextSetBit(lo2 + 1)
                    colors[lo2] = colors[next]
                if not splits.Test(hi2):
                    splits.Set(hi2)
                    var next = splits.FindNextSetBit(hi2 + 1)
                    colors[hi2] = colors[next]
                var c = lo2 + 1
                while c < 256:
                    var next = splits.FindNextSetBit(c)
                    first = min(first, colors[next])
                    colors[next] = id
                    if next == hi2:
                        break
                    c = next + 1
            var ip = &flat[id]
            var lo = ip.lo()
            var hi = ip.hi()
            Recolor(lo, hi)
            if ip.foldcase() and lo <= 'z' and hi >= 'a':
                var foldlo = lo
                var foldhi = hi
                if foldlo < 'a':
                    foldlo = 'a'
                if foldhi > 'z':
                    foldhi = 'z'
                if foldlo <= foldhi:
                    foldlo += 'A' - 'a'
                    foldhi += 'A' - 'a'
                    Recolor(foldlo, foldhi)
            if first != end:
                var hint = UInt16(min(first - id, 32767))
                ip.hint_foldcase_ |= hint << 1

    def GetDFA(inout self, kind: MatchKind) -> DFA:
        # placeholder - no implementation in C++ (only declaration)
        return DFA()

    def DeleteDFA(inout self, dfa: DFA):

    # Static methods
    def CompileSet(re: Regexp, anchor: RE2.Anchor, max_mem: Int64) -> Prog:
        # placeholder - not implemented in this file
        return Prog()

    # Other methods (SearchNFA, SearchDFA, etc.) - declared but not implemented in this file
    # They remain as stubs (will be added if needed, but not in source)

# --- Free functions ---
alias Workq = SparseSet

def AddToQueue(q: Pointer[Workq], id: Int):
    if id != 0:
        q.insert(id)

def ProgToString(prog: Prog, q: Pointer[Workq]) -> String:
    var s = String
    for i in q:
        var id = i
        var ip = prog.inst(id)
        s += StringPrintf("%d. %s\n", id, ip.Dump())
        AddToQueue(q, ip.out())
        if ip.opcode() == InstOp.kInstAlt or ip.opcode() == InstOp.kInstAltMatch:
            AddToQueue(q, ip.out1())
    return s

def FlattenedProgToString(prog: Prog, start: Int) -> String:
    var s = String
    for id in range(start, prog.size()):
        var ip = prog.inst(id)
        if ip.last():
            s += StringPrintf("%d. %s\n", id, ip.Dump())
        else:
            s += StringPrintf("%d+ %s\n", id, ip.Dump())
    return s

def IsMatch(prog: Prog, ip: Prog.Inst) -> Bool:
    var ip2 = ip
    while True:
        if ip2.opcode() == InstOp.kInstCapture or ip2.opcode() == InstOp.kInstNop:
            ip2 = prog.inst(ip2.out())
            continue
        elif ip2.opcode() == InstOp.kInstMatch:
            return True
        else:
            LOG(DFATAL) << "Unexpected opcode in IsMatch: " << ip2.opcode()
            return False

# --- ByteMapBuilder class ---
struct ByteMapBuilder:
    var splits_: Bitmap256
    var colors_: List[Int]  # size 256
    var nextcolor_: Int
    var colormap_: List[Tuple[Int, Int]]  # pair of ints
    var ranges_: List[Tuple[Int, Int]]

    def __init__(inout self):
        self.splits_ = Bitmap256()
        self.splits_.Set(255)
        self.colors_ = List[Int](256, 0)
        self.colors_[255] = 256
        self.nextcolor_ = 257
        self.colormap_ = List[Tuple[Int, Int]]()
        self.ranges_ = List[Tuple[Int, Int]]()

    def Mark(inout self, lo: Int, hi: Int):
        DCHECK_GE(lo, 0)
        DCHECK_GE(hi, 0)
        DCHECK_LE(lo, 255)
        DCHECK_LE(hi, 255)
        DCHECK_LE(lo, hi)
        if lo == 0 and hi == 255:
            return
        self.ranges_.emplace_back(lo, hi)

    def Merge(inout self):
        for it in self.ranges_:
            var lo = it[0] - 1
            var hi = it[1]
            if 0 <= lo and not self.splits_.Test(lo):
                self.splits_.Set(lo)
                var next = self.splits_.FindNextSetBit(lo + 1)
                self.colors_[lo] = self.colors_[next]
            if not self.splits_.Test(hi):
                self.splits_.Set(hi)
                var next = self.splits_.FindNextSetBit(hi + 1)
                self.colors_[hi] = self.colors_[next]
            var c = lo + 1
            while c < 256:
                var next = self.splits_.FindNextSetBit(c)
                self.colors_[next] = self.Recolor(self.colors_[next])
                if next == hi:
                    break
                c = next + 1
        self.colormap_.clear()
        self.ranges_.clear()

    def Build(inout self, bytemap: Pointer[UInt8], bytemap_range: Pointer[Int]):
        self.nextcolor_ = 0
        var c = 0
        while c < 256:
            var next = self.splits_.FindNextSetBit(c)
            var b = UInt8(self.Recolor(self.colors_[next]))
            while c <= next:
                bytemap[c] = b
                c += 1
        bytemap_range[0] = self.nextcolor_

    def Recolor(inout self, oldcolor: Int) -> Int:
        var it = find_if(self.colormap_, fn(kv: Tuple[Int, Int]) -> Bool:
            return kv[0] == oldcolor or kv[1] == oldcolor
        )
        if it != self.colormap_.end():
            return it[1]
        var newcolor = self.nextcolor_
        self.nextcolor_ += 1
        self.colormap_.emplace_back(oldcolor, newcolor)
        return newcolor

# --- BuildShiftDFA ---
alias kShiftDFAFinal: Int = 9

def BuildShiftDFA(prefix: String) -> Pointer[UInt64]:
    var size = prefix.size()
    var nfa = List[UInt16](256, 0)
    for i in range(size):
        var b = UInt8(prefix[i])
        nfa[b] |= UInt16(1 << (i + 1))
    for b in range(256):
        nfa[b] |= 1
    var states = List[UInt16](kShiftDFAFinal + 1, 0)
    states[0] = 1
    for dcurr in range(size):
        var b = UInt8(prefix[dcurr])
        var ncurr = states[dcurr]
        var nnext = nfa[b] & ((ncurr << 1) | 1)
        var dnext = dcurr + 1
        if dnext == size:
            dnext = kShiftDFAFinal
        states[dnext] = nnext
    # sort unique
    var prefix_sorted = prefix
    sort(prefix_sorted.begin(), prefix_sorted.end())
    prefix_sorted.erase(unique(prefix_sorted.begin(), prefix_sorted.end()), prefix_sorted.end())
    var dfa = List[UInt64](256, 0)
    for dcurr in range(size):
        for b in prefix_sorted:
            var ncurr = states[dcurr]
            var nnext = nfa[UInt8(b)] & ((ncurr << 1) | 1)
            var dnext: Int = 0
            while states[dnext] != nnext:
                dnext += 1
            dfa[UInt8(b)] |= UInt64(dnext * 6) << (dcurr * 6)
            if 'a' <= b and b <= 'z':
                var b_up = b - ('a' - 'A')
                dfa[UInt8(b_up)] |= UInt64(dnext * 6) << (dcurr * 6)
    for b in range(256):
        dfa[b] |= UInt64(kShiftDFAFinal * 6) << (kShiftDFAFinal * 6)
    # Transfer to allocated pointer (simulate new[] with Pointer)
    var dfa_ptr = Pointer[UInt64].alloc(256)
    for i in range(256):
        dfa_ptr[i] = dfa[i]
    return dfa_ptr

# --- End of file ---