from util.util import *
from util.logging import *
from re2.pod_array import PODArray
from re2.prog import Prog
from re2.regexp import *

@value
struct Backtracker:
    var prog_: Prog
    var text_: StringPiece
    var context_: StringPiece
    var anchored_: Bool
    var longest_: Bool
    var endmatch_: Bool
    var submatch_: Pointer[StringPiece]
    var nsubmatch_: Int
    var cap_: InlineArray[Pointer[UInt8], 64]
    var visited_: PODArray[UInt32]

    def __init__(inout self, prog: Prog):
        self.prog_ = prog
        self.anchored_ = False
        self.longest_ = False
        self.endmatch_ = False
        self.submatch_ = Pointer[StringPiece]()
        self.nsubmatch_ = 0

    def Search(inout self, text: StringPiece, context: StringPiece, anchored: Bool, longest: Bool, submatch: Pointer[StringPiece], nsubmatch: Int) -> Bool:
        self.text_ = text
        self.context_ = context
        if self.context_.data() == None:
            self.context_ = text
        if self.prog_.anchor_start() and BeginPtr(text) > BeginPtr(self.context_):
            return False
        if self.prog_.anchor_end() and EndPtr(text) < EndPtr(self.context_):
            return False
        self.anchored_ = anchored or self.prog_.anchor_start()
        self.longest_ = longest or self.prog_.anchor_end()
        self.endmatch_ = self.prog_.anchor_end()
        self.submatch_ = submatch
        self.nsubmatch_ = nsubmatch
        # CHECK_LT(2*nsubmatch_, static_cast<int>(arraysize(cap_)));
        memset(self.cap_.data, 0, sizeof(self.cap_))
        var sp0 = StringPiece()
        if nsubmatch < 1:
            self.submatch_ = Pointer[StringPiece].address_of(sp0)
            self.nsubmatch_ = 1
        self.submatch_[0] = StringPiece()
        var nvisited = self.prog_.size() * (text.size() + 1)
        nvisited = (nvisited + 31) // 32
        self.visited_ = PODArray[UInt32](nvisited)
        memset(self.visited_.data(), 0, nvisited * sizeof(self.visited_[0]))
        if self.anchored_:
            self.cap_[0] = text.data()
            return self.Visit(self.prog_.start(), text.data())
        var p = text.data()
        while p <= text.data() + text.size():
            self.cap_[0] = p
            if self.Visit(self.prog_.start(), p):
                return True
            if p == None:
                break
            p += 1
        return False

    def Visit(inout self, id: Int, p: Pointer[UInt8]) -> Bool:
        # CHECK(p <= text_.data() + text_.size());
        var n = id * (self.text_.size() + 1) + (p - self.text_.data())
        # CHECK_LT(n/32, visited_.size());
        if self.visited_[n // 32] & (1 << (n & 31)):
            return False
        self.visited_[n // 32] |= 1 << (n & 31)
        var ip = self.prog_.inst(id)
        if self.Try(id, p):
            if self.longest_ and not ip.last():
                self.Visit(id + 1, p)
            return True
        if not ip.last():
            return self.Visit(id + 1, p)
        return False

    def Try(inout self, id: Int, p: Pointer[UInt8]) -> Bool:
        var c = -1
        if p < self.text_.data() + self.text_.size():
            c = p[0] & 0xFF
        var ip = self.prog_.inst(id)
        if ip.opcode() == kInstAltMatch:
            return False
        elif ip.opcode() == kInstByteRange:
            if ip.Matches(c):
                return self.Visit(ip.out(), p + 1)
            return False
        elif ip.opcode() == kInstCapture:
            if 0 <= ip.cap() and ip.cap() < 64:
                var q = self.cap_[ip.cap()]
                self.cap_[ip.cap()] = p
                var ret = self.Visit(ip.out(), p)
                self.cap_[ip.cap()] = q
                return ret
            return self.Visit(ip.out(), p)
        elif ip.opcode() == kInstEmptyWidth:
            if ip.empty() & ~Prog.EmptyFlags(self.context_, p):
                return False
            return self.Visit(ip.out(), p)
        elif ip.opcode() == kInstNop:
            return self.Visit(ip.out(), p)
        elif ip.opcode() == kInstMatch:
            if self.endmatch_ and p != self.context_.data() + self.context_.size():
                return False
            self.cap_[1] = p
            if self.submatch_[0].data() == None or (self.longest_ and p > self.submatch_[0].data() + self.submatch_[0].size()):
                for i in range(self.nsubmatch_):
                    self.submatch_[i] = StringPiece(self.cap_[2 * i], self.cap_[2 * i + 1] - self.cap_[2 * i])
            return True
        elif ip.opcode() == kInstFail:
            return False
        else:
            # LOG(FATAL) << "Unexpected opcode: " << (int)ip->opcode();
            return False

def UnsafeSearchBacktrack(prog: Prog, text: StringPiece, context: StringPiece, anchor: Anchor, kind: MatchKind, match: Pointer[StringPiece], nmatch: Int) -> Bool:
    var sp0 = StringPiece()
    if kind == kFullMatch:
        anchor = kAnchored
        if nmatch < 1:
            match = Pointer[StringPiece].address_of(sp0)
            nmatch = 1
    var b = Backtracker(prog)
    var anchored = anchor == kAnchored
    var longest = kind != kFirstMatch
    if not b.Search(text, context, anchored, longest, match, nmatch):
        return False
    if kind == kFullMatch and EndPtr(match[0]) != EndPtr(text):
        return False
    return True