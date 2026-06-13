from util.logging import LOG, DCHECK, DCHECK_EQ, DCHECK_LE
from util.strutil import StringPrintf
from re2.pod_array import PODArray
from prog import Prog
from regexp import Regexp
from re2.sparse_array import SparseArray
from re2.sparse_set import SparseSet

from memory import memset, memmove
from sys import stderr

@value
struct StringPiece:
    var data: Pointer[UInt8]
    var size: Int

    def __init__(inout self, data: Pointer[UInt8], size: Int):
        self.data = data
        self.size = size

    def __init__(inout self):
        self.data = Pointer[UInt8]()
        self.size = 0

    def data(self) -> Pointer[UInt8]:
        return self.data

    def size(self) -> Int:
        return self.size

def BeginPtr(sp: StringPiece) -> Pointer[UInt8]:
    return sp.data()

def EndPtr(sp: StringPiece) -> Pointer[UInt8]:
    return sp.data() + sp.size()

def swap(inout a: StringPiece, inout b: StringPiece):
    var tmp = a
    a = b
    b = tmp

static var ExtraDebug: Bool = False

@value
struct NFA:
    var prog_: Prog
    var start_: Int
    var ncapture_: Int
    var longest_: Bool
    var endmatch_: Bool
    var btext_: Pointer[UInt8]
    var etext_: Pointer[UInt8]
    var q0_: Threadq
    var q1_: Threadq
    var stack_: PODArray[AddState]
    var arena_: Deque[Thread]
    var freelist_: Thread
    var match_: Pointer[Pointer[UInt8]]
    var matched_: Bool

    @value
    struct Thread:
        var ref_or_next: Int  # union: ref or next pointer as int
        var capture: Pointer[Pointer[UInt8]]

    @value
    struct AddState:
        var id: Int
        var t: Thread

    alias Threadq = SparseArray[Thread]

    def __init__(inout self, prog: Prog):
        self.prog_ = prog
        self.start_ = prog.start()
        self.ncapture_ = 0
        self.longest_ = False
        self.endmatch_ = False
        self.btext_ = Pointer[UInt8]()
        self.etext_ = Pointer[UInt8]()
        self.q0_.resize(prog.size())
        self.q1_.resize(prog.size())
        var nstack: Int = 2 * prog.inst_count(kInstCapture) + prog.inst_count(kInstEmptyWidth) + prog.inst_count(kInstNop) + 1
        self.stack_ = PODArray[AddState](nstack)
        self.freelist_ = Thread()
        self.match_ = Pointer[Pointer[UInt8]]()
        self.matched_ = False

    def __del__(owned self):
        if self.match_:
            del self.match_
        for t in self.arena_:
            if t.capture:
                del t.capture

    def AllocThread(inout self) -> Thread:
        var t: Thread = self.freelist_
        if t.ref_or_next != 0:
            self.freelist_ = Thread(ref_or_next=t.ref_or_next, capture=Pointer[Pointer[UInt8]]())
            t.ref_or_next = 1
            return t
        self.arena_.emplace_back()
        t = self.arena_.back()
        t.ref_or_next = 1
        t.capture = Pointer[Pointer[UInt8]](alloc[UInt8](self.ncapture_ * sizeof[Pointer[UInt8]]()))
        return t

    def Incref(inout self, t: Thread) -> Thread:
        DCHECK(t.ref_or_next != 0)
        t.ref_or_next += 1
        return t

    def Decref(inout self, t: Thread):
        DCHECK(t.ref_or_next != 0)
        t.ref_or_next -= 1
        if t.ref_or_next > 0:
            return
        DCHECK_EQ(t.ref_or_next, 0)
        t.ref_or_next = self.freelist_.ref_or_next
        self.freelist_ = t

    def AddToThreadq(inout self, q: Threadq, id0: Int, c: Int, context: StringPiece, p: Pointer[UInt8], t0: Thread):
        if id0 == 0:
            return
        var stk: Pointer[AddState] = self.stack_.data()
        var nstk: Int = 0
        stk[nstk] = AddState(id0, Thread())
        nstk += 1
        while nstk > 0:
            DCHECK_LE(nstk, self.stack_.size())
            nstk -= 1
            var a: AddState = stk[nstk]
            loop:
                if a.t.ref_or_next != 0:
                    self.Decref(t0)
                    t0 = a.t
                var id: Int = a.id
                if id == 0:
                    continue
                if q.has_index(id):
                    if ExtraDebug:
                        stderr.printf("  [%d%s]\n", id, self.FormatCapture(t0.capture).c_str())
                    continue
                q.set_new(id, Thread())
                var tp: Pointer[Thread] = q.get_existing(id)
                var j: Int
                var t: Thread
                var ip: Prog.Inst = self.prog_.inst(id)
                match ip.opcode():
                    case _:
                        LOG(DFATAL, "unhandled " + str(ip.opcode()) + " in AddToThreadq")
                    case kInstFail:

                    case kInstAltMatch:
                        t = self.Incref(t0)
                        tp[] = t
                        DCHECK(!ip.last())
                        a = AddState(id + 1, Thread())
                        loop()
                    case kInstNop:
                        if !ip.last():
                            stk[nstk] = AddState(id + 1, Thread())
                            nstk += 1
                        a = AddState(ip.out(), Thread())
                        loop()
                    case kInstCapture:
                        if !ip.last():
                            stk[nstk] = AddState(id + 1, Thread())
                            nstk += 1
                        j = ip.cap()
                        if j < self.ncapture_:
                            stk[nstk] = AddState(0, t0)
                            nstk += 1
                            t = self.AllocThread()
                            self.CopyCapture(t.capture, t0.capture)
                            t.capture[j] = p
                            t0 = t
                        a = AddState(ip.out(), Thread())
                        loop()
                    case kInstByteRange:
                        if !ip.Matches(c):
                            goto Next
                        t = self.Incref(t0)
                        tp[] = t
                        if ExtraDebug:
                            stderr.printf(" + %d%s\n", id, self.FormatCapture(t0.capture).c_str())
                        if ip.hint() == 0:
                            break
                        a = AddState(id + ip.hint(), Thread())
                        loop()
                    case kInstMatch:
                        t = self.Incref(t0)
                        tp[] = t
                        if ExtraDebug:
                            stderr.printf(" ! %d%s\n", id, self.FormatCapture(t0.capture).c_str())
                        Next:
                            if ip.last():
                                break
                            a = AddState(id + 1, Thread())
                            loop()
                    case kInstEmptyWidth:
                        if !ip.last():
                            stk[nstk] = AddState(id + 1, Thread())
                            nstk += 1
                        if ip.empty() & ~Prog.EmptyFlags(context, p):
                            break
                        a = AddState(ip.out(), Thread())
                        loop()

    def Step(inout self, runq: Threadq, nextq: Threadq, c: Int, context: StringPiece, p: Pointer[UInt8]) -> Int:
        nextq.clear()
        var i: Threadq.Iterator = runq.begin()
        while i != runq.end():
            var t: Thread = i.value()
            if t.ref_or_next != 0:
                if self.longest_:
                    if self.matched_ and self.match_[0] < t.capture[0]:
                        self.Decref(t)
                        i += 1
                        continue
                var id: Int = i.index()
                var ip: Prog.Inst = self.prog_.inst(id)
                match ip.opcode():
                    case _:
                        LOG(DFATAL, "Unhandled " + str(ip.opcode()) + " in step")
                    case kInstByteRange:
                        self.AddToThreadq(nextq, ip.out(), c, context, p, t)
                    case kInstAltMatch:
                        if i != runq.begin():
                            break
                        if ip.greedy(self.prog_) or self.longest_:
                            self.CopyCapture(self.match_, t.capture)
                            self.matched_ = True
                            self.Decref(t)
                            i += 1
                            while i != runq.end():
                                if i.value().ref_or_next != 0:
                                    self.Decref(i.value())
                                i += 1
                            runq.clear()
                            if ip.greedy(self.prog_):
                                return ip.out1()
                            return ip.out()
                    case kInstMatch:
                        if p.is_null():
                            self.CopyCapture(self.match_, t.capture)
                            self.match_[1] = p
                            self.matched_ = True
                            break
                        if self.endmatch_ and (p - 1) != self.etext_:
                            break
                        if self.longest_:
                            if !self.matched_ or t.capture[0] < self.match_[0] or (t.capture[0] == self.match_[0] and (p - 1) > self.match_[1]):
                                self.CopyCapture(self.match_, t.capture)
                                self.match_[1] = p - 1
                                self.matched_ = True
                        else:
                            self.CopyCapture(self.match_, t.capture)
                            self.match_[1] = p - 1
                            self.matched_ = True
                            self.Decref(t)
                            i += 1
                            while i != runq.end():
                                if i.value().ref_or_next != 0:
                                    self.Decref(i.value())
                                i += 1
                            runq.clear()
                            return 0
                self.Decref(t)
            i += 1
        runq.clear()
        return 0

    def FormatCapture(self, capture: Pointer[Pointer[UInt8]]) -> String:
        var s: String = ""
        var i: Int = 0
        while i < self.ncapture_:
            if capture[i].is_null():
                s += "(?,?)"
            elif capture[i + 1].is_null():
                s += StringPrintf("(%td,?)", capture[i] - self.btext_)
            else:
                s += StringPrintf("(%td,%td)", capture[i] - self.btext_, capture[i + 1] - self.btext_)
            i += 2
        return s

    def CopyCapture(self, dst: Pointer[Pointer[UInt8]], src: Pointer[Pointer[UInt8]]):
        memmove(dst, src, self.ncapture_ * sizeof[Pointer[UInt8]]())

    def Search(inout self, text: StringPiece, const_context: StringPiece, anchored: Bool, longest: Bool, submatch: Pointer[StringPiece], nsubmatch: Int) -> Bool:
        if self.start_ == 0:
            return False
        var context: StringPiece = const_context
        if context.data().is_null():
            context = text
        if BeginPtr(text) < BeginPtr(context) or EndPtr(text) > EndPtr(context):
            LOG(DFATAL, "context does not contain text")
            return False
        if self.prog_.anchor_start() and BeginPtr(context) != BeginPtr(text):
            return False
        if self.prog_.anchor_end() and EndPtr(context) != EndPtr(text):
            return False
        anchored = anchored or self.prog_.anchor_start()
        if self.prog_.anchor_end():
            longest = True
            self.endmatch_ = True
        if nsubmatch < 0:
            LOG(DFATAL, "Bad args: nsubmatch=" + str(nsubmatch))
            return False
        self.ncapture_ = 2 * nsubmatch
        self.longest_ = longest
        if nsubmatch == 0:
            self.ncapture_ = 2
        self.match_ = Pointer[Pointer[UInt8]](alloc[UInt8](self.ncapture_ * sizeof[Pointer[UInt8]]()))
        memset(self.match_, 0, self.ncapture_ * sizeof[Pointer[UInt8]]())
        self.matched_ = False
        self.btext_ = context.data()
        self.etext_ = text.data() + text.size()
        if ExtraDebug:
            stderr.printf("NFA::Search %s (context: %s) anchored=%d longest=%d\n", str(text).c_str(), str(context).c_str(), anchored, longest)
        var runq: Threadq = self.q0_
        var nextq: Threadq = self.q1_
        runq.clear()
        nextq.clear()
        var p: Pointer[UInt8] = text.data()
        while True:
            if ExtraDebug:
                var c: Int = 0
                if p == self.btext_:
                    c = ord('^')
                elif p > self.etext_:
                    c = ord('$')
                elif p < self.etext_:
                    c = p[0] & 0xFF
                stderr.printf("%c:", c)
                var i: Threadq.Iterator = runq.begin()
                while i != runq.end():
                    var t: Thread = i.value()
                    if t.ref_or_next != 0:
                        stderr.printf(" %d%s", i.index(), self.FormatCapture(t.capture).c_str())
                    i += 1
                stderr.printf("\n")
            var id: Int = self.Step(runq, nextq, (p < self.etext_) ? (p[0] & 0xFF) : -1, context, p)
            DCHECK_EQ(runq.size(), 0)
            swap(nextq, runq)
            nextq.clear()
            if id != 0:
                p = self.etext_
                while True:
                    var ip: Prog.Inst = self.prog_.inst(id)
                    match ip.opcode():
                        case _:
                            LOG(DFATAL, "Unexpected opcode in short circuit: " + str(ip.opcode()))
                        case kInstCapture:
                            if ip.cap() < self.ncapture_:
                                self.match_[ip.cap()] = p
                            id = ip.out()
                            continue
                        case kInstNop:
                            id = ip.out()
                            continue
                        case kInstMatch:
                            self.match_[1] = p
                            self.matched_ = True
                    break
                break
            if p > self.etext_:
                break
            if !self.matched_ and (!anchored or p == text.data()):
                if !anchored and runq.size() == 0 and p < self.etext_ and self.prog_.can_prefix_accel():
                    p = self.prog_.PrefixAccel(p, self.etext_ - p)
                    if p.is_null():
                        p = self.etext_
                var t: Thread = self.AllocThread()
                self.CopyCapture(t.capture, self.match_)
                t.capture[0] = p
                self.AddToThreadq(runq, self.start_, (p < self.etext_) ? (p[0] & 0xFF) : -1, context, p, t)
                self.Decref(t)
            if runq.size() == 0:
                if ExtraDebug:
                    stderr.printf("dead\n")
                break
            if p.is_null():
                self.Step(runq, nextq, -1, context, p)
                DCHECK_EQ(runq.size(), 0)
                swap(nextq, runq)
                nextq.clear()
                break
            p += 1
        var i: Threadq.Iterator = runq.begin()
        while i != runq.end():
            if i.value().ref_or_next != 0:
                self.Decref(i.value())
            i += 1
        if self.matched_:
            var i2: Int = 0
            while i2 < nsubmatch:
                submatch[i2] = StringPiece(self.match_[2 * i2], static_cast[Int](self.match_[2 * i2 + 1] - self.match_[2 * i2]))
                i2 += 1
            if ExtraDebug:
                stderr.printf("match (%td,%td)\n", self.match_[0] - self.btext_, self.match_[1] - self.btext_)
            return True
        return False

def Prog_SearchNFA(prog: Prog, text: StringPiece, context: StringPiece, anchor: Anchor, kind: MatchKind, match: Pointer[StringPiece], nmatch: Int) -> Bool:
    if ExtraDebug:
        prog.Dump()
    var nfa: NFA = NFA(prog)
    var sp: StringPiece = StringPiece()
    if kind == kFullMatch:
        anchor = kAnchored
        if nmatch == 0:
            match = sp
            nmatch = 1
    if !nfa.Search(text, context, anchor == kAnchored, kind != kFirstMatch, match, nmatch):
        return False
    if kind == kFullMatch and EndPtr(match[0]) != EndPtr(text):
        return False
    return True

def Prog_Fanout(prog: Prog, fanout: SparseArray[Int]):
    DCHECK_EQ(fanout.max_size(), prog.size())
    var reachable: SparseSet = SparseSet(prog.size())
    fanout.clear()
    fanout.set_new(prog.start(), 0)
    var i: SparseArray[Int].Iterator = fanout.begin()
    while i != fanout.end():
        var count: Pointer[Int] = i.value_ptr()
        reachable.clear()
        reachable.insert(i.index())
        var j: SparseSet.Iterator = reachable.begin()
        while j != reachable.end():
            var id: Int = j[]
            var ip: Prog.Inst = prog.inst(id)
            match ip.opcode():
                case _:
                    LOG(DFATAL, "unhandled " + str(ip.opcode()) + " in Prog::Fanout()")
                case kInstByteRange:
                    if !ip.last():
                        reachable.insert(id + 1)
                    count[] += 1
                    if !fanout.has_index(ip.out()):
                        fanout.set_new(ip.out(), 0)
                case kInstAltMatch:
                    DCHECK(!ip.last())
                    reachable.insert(id + 1)
                case kInstCapture:
                case kInstEmptyWidth:
                case kInstNop:
                    if !ip.last():
                        reachable.insert(id + 1)
                    reachable.insert(ip.out())
                case kInstMatch:
                    if !ip.last():
                        reachable.insert(id + 1)
                case kInstFail:

            j += 1
        i += 1