from util.logging import LOG, DFATAL
from .pod_array import PODArray
from prog import Prog, Inst, Anchor, MatchKind, kInstFail, kInstAltMatch, kInstByteRange, kInstCapture, kInstEmptyWidth, kInstNop, kInstMatch
from regexp import StringPiece, BeginPtr, EndPtr
from memory import memmove, memset
from sys import int_type
from builtins import int

struct Job:
    var id: Int
    var rle: Int  # run length encoding
    var p: Pointer[UInt8]

class BitState:
    var prog_: Prog
    var text_: StringPiece
    var context_: StringPiece
    var anchored_: Bool
    var longest_: Bool
    var endmatch_: Bool
    var submatch_: Pointer[StringPiece]
    var nsubmatch_: Int
    var visited_: PODArray[UInt64]
    var cap_: PODArray[Pointer[UInt8]]
    var job_: PODArray[Job]
    var njob_: Int

    def __init__(self, prog: Prog):
        self.prog_ = prog
        self.anchored_ = False
        self.longest_ = False
        self.endmatch_ = False
        self.submatch_ = Pointer[StringPiece]()
        self.nsubmatch_ = 0
        self.njob_ = 0

    def ShouldVisit(self, id: Int, p: Pointer[UInt8]) -> Bool:
        let n: Int = self.prog_.list_heads()[id] * (self.text_.size() + 1) + (p - self.text_.data())
        if self.visited_[n // 64] & (UInt64(1) << (n & 63)):
            return False
        self.visited_[n // 64] |= UInt64(1) << (n & 63)
        return True

    def GrowStack(self):
        let tmp = PODArray[Job](2 * self.job_.size())
        memmove(tmp.data().bitcast[UInt8](), self.job_.data().bitcast[UInt8](), self.njob_ * sizeof[Job]())
        self.job_ = tmp

    def Push(self, id: Int, p: Pointer[UInt8]):
        if self.njob_ >= self.job_.size():
            self.GrowStack()
            if self.njob_ >= self.job_.size():
                LOG(DFATAL, "GrowStack() failed: njob_ = ", self.njob_, ", job_.size() = ", self.job_.size())
                return
        if id >= 0 and self.njob_ > 0:
            let top = self.job_.data() + (self.njob_ - 1)
            if id == top[].id and p == top[].p + top[].rle + 1 and top[].rle < int_type.max():
                top[].rle = top[].rle + 1
                return
        let top = self.job_.data() + self.njob_
        self.njob_ = self.njob_ + 1
        top[].id = id
        top[].rle = 0
        top[].p = p

    def TrySearch(self, id0: Int, p0: Pointer[UInt8]) -> Bool:
        var matched: Bool = False
        let end = self.text_.data() + self.text_.size()
        self.njob_ = 0
        if self.ShouldVisit(id0, p0):
            self.Push(id0, p0)
        while self.njob_ > 0:
            self.njob_ = self.njob_ - 1
            let id = self.job_[self.njob_].id
            var rle = self.job_[self.njob_].rle
            let p = self.job_[self.njob_].p
            if id < 0:
                self.cap_[self.prog_.inst(-id).cap()] = p
                continue
            if rle > 0:
                p += rle
                rle = rle - 1
                self.njob_ = self.njob_ + 1
            Loop:
                let ip = self.prog_.inst(id)
                if ip.opcode() == kInstFail:

                elif ip.opcode() == kInstAltMatch:
                    if ip.greedy(self.prog_):
                        id = ip.out1()
                        p = end
                        Loop
                    if self.longest_:
                        id = ip.out()
                        p = end
                        Loop
                    goto Next
                elif ip.opcode() == kInstByteRange:
                    var c: Int = -1
                    if p < end:
                        c = p[0] & 0xFF
                    if not ip.Matches(c):
                        goto Next
                    if ip.hint() != 0:
                        self.Push(id + ip.hint(), p)
                    id = ip.out()
                    p = p + 1
                    goto CheckAndLoop
                elif ip.opcode() == kInstCapture:
                    if not ip.last():
                        self.Push(id + 1, p)
                    if 0 <= ip.cap() and ip.cap() < self.cap_.size():
                        self.Push(-id, self.cap_[ip.cap()])
                        self.cap_[ip.cap()] = p
                    id = ip.out()
                    goto CheckAndLoop
                elif ip.opcode() == kInstEmptyWidth:
                    if ip.empty() & ~Prog.EmptyFlags(self.context_, p):
                        goto Next
                    if not ip.last():
                        self.Push(id + 1, p)
                    id = ip.out()
                    goto CheckAndLoop
                elif ip.opcode() == kInstNop:
                    if not ip.last():
                        self.Push(id + 1, p)
                    id = ip.out()
                    CheckAndLoop:
                        if ShouldVisit(id, p):
                            goto Loop

                elif ip.opcode() == kInstMatch:
                    if self.endmatch_ and p != end:
                        goto Next
                    if self.nsubmatch_ == 0:
                        return True
                    matched = True
                    self.cap_[1] = p
                    if self.submatch_[0].data() == Pointer[UInt8]() or (self.longest_ and p > self.submatch_[0].data() + self.submatch_[0].size()):
                        for i in range(self.nsubmatch_):
                            self.submatch_[i] = StringPiece(self.cap_[2 * i], (self.cap_[2 * i + 1] - self.cap_[2 * i]).__index__())
                    if not self.longest_:
                        return True
                    if p == end:
                        return True
                    Next:
                        if not ip.last():
                            id = id + 1
                            goto Loop

                else:
                    LOG(DFATAL, "Unexpected opcode: ", ip.opcode())
                    return False
        return matched

    def Search(self, text: StringPiece, context: StringPiece, anchored: Bool, longest: Bool, submatch: Pointer[StringPiece], nsubmatch: Int) -> Bool:
        self.text_ = text
        self.context_ = context
        if self.context_.data() == Pointer[UInt8]():
            self.context_ = text
        if self.prog_.anchor_start() and BeginPtr(self.context_) != BeginPtr(self.text):
            return False
        if self.prog_.anchor_end() and EndPtr(self.context_) != EndPtr(self.text):
            return False
        self.anchored_ = anchored or self.prog_.anchor_start()
        self.longest_ = longest or self.prog_.anchor_end()
        self.endmatch_ = self.prog_.anchor_end()
        self.submatch_ = submatch
        self.nsubmatch_ = nsubmatch
        for i in range(self.nsubmatch_):
            self.submatch_[i] = StringPiece()
        var nvisited: Int = self.prog_.list_count() * (text.size() + 1)
        nvisited = (nvisited + 63) // 64
        self.visited_ = PODArray[UInt64](nvisited)
        memset(self.visited_.data().bitcast[UInt8](), 0, nvisited * sizeof[UInt64]())
        var ncap: Int = 2 * nsubmatch
        if ncap < 2:
            ncap = 2
        self.cap_ = PODArray[Pointer[UInt8]](ncap)
        memset(self.cap_.data().bitcast[UInt8](), 0, ncap * sizeof[Pointer[UInt8]]())
        self.job_ = PODArray[Job](64)
        if self.anchored_:
            self.cap_[0] = text.data()
            return self.TrySearch(self.prog_.start(), text.data())
        let etext = text.data() + text.size()
        var p = text.data()
        while p <= etext:
            if p < etext and self.prog_.can_prefix_accel():
                p = self.prog_.PrefixAccel(p, (etext - p).__index__())
                if p == Pointer[UInt8]():
                    p = etext
            self.cap_[0] = p
            if self.TrySearch(self.prog_.start(), p):
                return True
            if p == Pointer[UInt8]():
                break
            p = p + 1
        return False

def Prog_SearchBitState(self: Prog, text: StringPiece, context: StringPiece, anchor: Anchor, kind: MatchKind, match: Pointer[StringPiece], nmatch: Int) -> Bool:
    var sp0 = StringPiece()
    if kind == kFullMatch:
        anchor = kAnchored
        if nmatch < 1:
            match = sp0.__ptr__()
            nmatch = 1
    let b = BitState(self)
    let anchored = anchor == kAnchored
    let longest = kind != kFirstMatch
    if not b.Search(text, context, anchored, longest, match, nmatch):
        return False
    if kind == kFullMatch and EndPtr(match[0]) != EndPtr(text):
        return False
    return True