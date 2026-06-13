from util.logging import *
from util.mix import HashMix
from util.mutex import Mutex
from util.strutil import StringPrintf, PrefixSuccessor
from re2.pod_array import PODArray
from re2.prog import Prog
from re2.re2 import *
from re2.sparse_set import SparseSet
from re2.stringpiece import StringPiece
from memory import alloc, free
from sys import int_size
from threading import Lock
from atomic import Atomic
from math import min, max

# Forward declarations
class DFA:

# Global variables
var dfa_should_bail_when_slow: Bool = True

def TESTING_ONLY_set_dfa_should_bail_when_slow(b: Bool):
    dfa_should_bail_when_slow = b

var ExtraDebug: Bool = False

# Constants
alias Mark: Int = -1
alias MatchSep: Int = -2
alias DeadState: DFA.State = DFA.State(1)
alias FullMatchState: DFA.State = DFA.State(2)
alias SpecialStateMax: DFA.State = FullMatchState

struct DFA:
    # Nested types
    struct State:
        var inst_: Pointer[Int]
        var ninst_: Int
        var flag_: UInt32
        var next_: Pointer[Atomic[Pointer[State]]]  # Flexible array member simulation

        def IsMatch(self) -> Bool:
            return (self.flag_ & kFlagMatch) != 0

    struct StateHash:
        def __call__(self, a: Pointer[State]) -> Int:
            DCHECK(a != None)
            var mix = HashMix(a[].flag_)
            for i in range(a[].ninst_):
                mix.Mix(a[].inst_[i])
            mix.Mix(0)
            return mix.get()

    struct StateEqual:
        def __call__(self, a: Pointer[State], b: Pointer[State]) -> Bool:
            DCHECK(a != None)
            DCHECK(b != None)
            if a == b:
                return True
            if a[].flag_ != b[].flag_:
                return False
            if a[].ninst_ != b[].ninst_:
                return False
            for i in range(a[].ninst_):
                if a[].inst_[i] != b[].inst_[i]:
                    return False
            return True

    alias StateSet = Dict[Pointer[State], None]  # Using dict as set

    enum:
        kByteEndText = 256
        kFlagEmptyMask = 0xFF
        kFlagMatch = 0x0100
        kFlagLastWord = 0x0200
        kFlagNeedShift = 16

    enum:
        kStartBeginText = 0
        kStartBeginLine = 2
        kStartAfterWordChar = 4
        kStartAfterNonWordChar = 6
        kMaxStart = 8
        kStartAnchored = 1

    # Workq class
    struct Workq:
        var sparse_set: SparseSet
        var n_: Int
        var maxmark_: Int
        var nextmark_: Int
        var last_was_mark_: Bool

        def __init__(self, n: Int, maxmark: Int):
            self.sparse_set = SparseSet(n + maxmark)
            self.n_ = n
            self.maxmark_ = maxmark
            self.nextmark_ = n
            self.last_was_mark_ = True

        def is_mark(self, i: Int) -> Bool:
            return i >= self.n_

        def maxmark(self) -> Int:
            return self.maxmark_

        def clear(self):
            self.sparse_set.clear()
            self.nextmark_ = self.n_

        def mark(self):
            if self.last_was_mark_:
                return
            self.last_was_mark_ = False
            self.sparse_set.insert_new(self.nextmark_)
            self.nextmark_ += 1

        def size(self) -> Int:
            return self.n_ + self.maxmark_

        def insert(self, id: Int):
            if self.sparse_set.contains(id):
                return
            self.insert_new(id)

        def insert_new(self, id: Int):
            self.last_was_mark_ = False
            self.sparse_set.insert_new(id)

        def begin(self) -> SparseSet.Iterator:
            return self.sparse_set.begin()

        def end(self) -> SparseSet.Iterator:
            return self.sparse_set.end()

    # RWLocker class
    struct RWLocker:
        var mu_: Pointer[Mutex]
        var writing_: Bool

        def __init__(self, mu: Pointer[Mutex]):
            self.mu_ = mu
            self.writing_ = False
            self.mu_[].ReaderLock()

        def LockForWriting(self):
            if not self.writing_:
                self.mu_[].ReaderUnlock()
                self.mu_[].WriterLock()
                self.writing_ = True

        def __del__(self):
            if not self.writing_:
                self.mu_[].ReaderUnlock()
            else:
                self.mu_[].WriterUnlock()

    # StateSaver class
    struct StateSaver:
        var dfa_: Pointer[DFA]
        var inst_: Pointer[Int]
        var ninst_: Int
        var flag_: UInt32
        var is_special_: Bool
        var special_: Pointer[State]

        def __init__(self, dfa: Pointer[DFA], state: Pointer[State]):
            self.dfa_ = dfa
            if state <= SpecialStateMax:
                self.inst_ = None
                self.ninst_ = 0
                self.flag_ = 0
                self.is_special_ = True
                self.special_ = state
                return
            self.is_special_ = False
            self.special_ = None
            self.flag_ = state[].flag_
            self.ninst_ = state[].ninst_
            self.inst_ = alloc[Int](self.ninst_)
            memmove(self.inst_, state[].inst_, self.ninst_ * sizeof[Int]())

        def __del__(self):
            if not self.is_special_:
                free(self.inst_)

        def Restore(self) -> Pointer[State]:
            if self.is_special_:
                return self.special_
            var l = MutexLock(self.dfa_[].mutex_)
            var s = self.dfa_[].CachedState(self.inst_, self.ninst_, self.flag_)
            if s == None:
                LOG(DFATAL, "StateSaver failed to restore state.")
            return s

    # SearchParams struct
    struct SearchParams:
        var text: StringPiece
        var context: StringPiece
        var anchored: Bool
        var can_prefix_accel: Bool
        var want_earliest_match: Bool
        var run_forward: Bool
        var start: Pointer[State]
        var cache_lock: Pointer[RWLocker]
        var failed: Bool
        var ep: Pointer[UInt8]
        var matches: Pointer[SparseSet]

        def __init__(self, text: StringPiece, context: StringPiece, cache_lock: Pointer[RWLocker]):
            self.text = text
            self.context = context
            self.anchored = False
            self.can_prefix_accel = False
            self.want_earliest_match = False
            self.run_forward = False
            self.start = None
            self.cache_lock = cache_lock
            self.failed = False
            self.ep = None
            self.matches = None

    # StartInfo struct
    struct StartInfo:
        var start: Atomic[Pointer[State]]

        def __init__(self):
            self.start = Atomic[Pointer[State]](None)

    # Member variables
    var prog_: Pointer[Prog]
    var kind_: Prog.MatchKind
    var init_failed_: Bool
    var mutex_: Mutex
    var q0_: Pointer[Workq]
    var q1_: Pointer[Workq]
    var stack_: PODArray[Int]
    var cache_mutex_: Mutex
    var mem_budget_: Int64
    var state_budget_: Int64
    var state_cache_: StateSet
    var start_: StaticArray[StartInfo, 8]

    def __init__(self, prog: Pointer[Prog], kind: Prog.MatchKind, max_mem: Int64):
        self.prog_ = prog
        self.kind_ = kind
        self.init_failed_ = False
        self.q0_ = None
        self.q1_ = None
        self.mem_budget_ = max_mem

        if ExtraDebug:
            fprintf(stderr, "\nkind %d\n%s\n", kind_, prog_[].DumpUnanchored().c_str())

        var nmark: Int = 0
        if kind_ == Prog.kLongestMatch:
            nmark = prog_[].size()

        var nstack: Int = prog_[].inst_count(kInstCapture) + \
                          prog_[].inst_count(kInstEmptyWidth) + \
                          prog_[].inst_count(kInstNop) + \
                          nmark + 1

        self.mem_budget_ -= sizeof[DFA]()
        self.mem_budget_ -= (prog_[].size() + nmark) * (sizeof[Int]() + sizeof[Int]()) * 2
        self.mem_budget_ -= nstack * sizeof[Int]()

        if self.mem_budget_ < 0:
            self.init_failed_ = True
            return

        self.state_budget_ = self.mem_budget_

        var nnext: Int = prog_[].bytemap_range() + 1
        var one_state: Int64 = sizeof[State]() + nnext * sizeof[Atomic[Pointer[State]]]() + \
                               (prog_[].list_count() + nmark) * sizeof[Int]()

        if self.state_budget_ < 20 * one_state:
            self.init_failed_ = True
            return

        self.q0_ = alloc[Workq](1)
        self.q0_[0] = Workq(prog_[].size(), nmark)
        self.q1_ = alloc[Workq](1)
        self.q1_[0] = Workq(prog_[].size(), nmark)
        self.stack_ = PODArray[Int](nstack)

    def __del__(self):
        if self.q0_:
            free(self.q0_)
        if self.q1_:
            free(self.q1_)
        self.ClearCache()

    def ok(self) -> Bool:
        return not self.init_failed_

    def kind(self) -> Prog.MatchKind:
        return self.kind_

    def Search(self, text: StringPiece, context: StringPiece,
              anchored: Bool, want_earliest_match: Bool, run_forward: Bool,
              failed: Pointer[Bool], ep: Pointer[Pointer[UInt8]], matches: Pointer[SparseSet]) -> Bool:
        ep[0] = None
        if not self.ok():
            failed[0] = True
            return False

        failed[0] = False
        if ExtraDebug:
            fprintf(stderr, "\nprogram:\n%s\n", self.prog_[].DumpUnanchored().c_str())
            fprintf(stderr, "text %s anchored=%d earliest=%d fwd=%d kind %d\n",
                    str(text).c_str(), anchored, want_earliest_match, run_forward, kind_)

        var l = RWLocker(self.cache_mutex_)
        var params = SearchParams(text, context, l)
        params.anchored = anchored
        params.want_earliest_match = want_earliest_match
        params.run_forward = run_forward
        params.matches = matches

        if not self.AnalyzeSearch(params):
            failed[0] = True
            return False

        if params.start == DeadState:
            return False

        if params.start == FullMatchState:
            if run_forward == want_earliest_match:
                ep[0] = text.data()
            else:
                ep[0] = text.data() + text.size()
            return True

        if ExtraDebug:
            fprintf(stderr, "start %s\n", DumpState(params.start).c_str())

        var ret = self.FastSearchLoop(params)
        if params.failed:
            failed[0] = True
            return False

        ep[0] = params.ep
        return ret

    def BuildAllStates(self, cb: Prog.DFAStateCallback) -> Int:
        if not self.ok():
            return 0

        var l = RWLocker(self.cache_mutex_)
        var params = SearchParams(StringPiece(), StringPiece(), l)
        params.anchored = False

        if not self.AnalyzeSearch(params) or \
           params.start == None or \
           params.start == DeadState:
            return 0

        var m = Dict[Pointer[State], Int]()
        var q = deque[Pointer[State]]()
        m[params.start] = len(m)
        q.append(params.start)

        var nnext: Int = self.prog_[].bytemap_range() + 1
        var input = List[Int](nnext)
        for c in range(256):
            var b = self.prog_[].bytemap()[c]
            while c < 255 and self.prog_[].bytemap()[c+1] == b:
                c += 1
            input[b] = c
        input[self.prog_[].bytemap_range()] = kByteEndText

        var output = List[Int](nnext)
        var oom: Bool = False

        while len(q) > 0:
            var s = q.popleft()
            for c in input:
                var ns = self.RunStateOnByteUnlocked(s, c)
                if ns == None:
                    oom = True
                    break
                if ns == DeadState:
                    output[self.ByteMap(c)] = -1
                    continue
                if ns not in m:
                    m[ns] = len(m)
                    q.append(ns)
                output[self.ByteMap(c)] = m[ns]

            if cb:
                cb(output.data() if not oom else None,
                   s == FullMatchState or s[].IsMatch())
            if oom:
                break

        return len(m)

    def PossibleMatchRange(self, min: Pointer[String], max: Pointer[String], maxlen: Int) -> Bool:
        if not self.ok():
            return False

        var kMaxEltRepetitions: Int = 0
        var previously_visited_states = Dict[Pointer[State], Int]()

        var l = RWLocker(self.cache_mutex_)
        var params = SearchParams(StringPiece(), StringPiece(), l)
        params.anchored = True

        if not self.AnalyzeSearch(params):
            return False

        if params.start == DeadState:
            min[0] = ""
            max[0] = ""
            return True

        if params.start == FullMatchState:
            return False

        var s = params.start
        min[0].clear()

        var lock = MutexLock(self.mutex_)
        for i in range(maxlen):
            if s in previously_visited_states and previously_visited_states[s] > kMaxEltRepetitions:
                break
            previously_visited_states[s] = previously_visited_states.get(s, 0) + 1

            var ns = self.RunStateOnByte(s, kByteEndText)
            if ns == None:
                return False
            if ns != DeadState and (ns == FullMatchState or ns[].IsMatch()):
                break

            var extended: Bool = False
            for j in range(256):
                ns = self.RunStateOnByte(s, j)
                if ns == None:
                    return False
                if ns == FullMatchState or (ns > SpecialStateMax and ns[].ninst_ > 0):
                    extended = True
                    min[0] += chr(j)
                    s = ns
                    break
            if not extended:
                break

        previously_visited_states.clear()
        s = params.start
        max[0].clear()

        for i in range(maxlen):
            if s in previously_visited_states and previously_visited_states[s] > kMaxEltRepetitions:
                break
            previously_visited_states[s] = previously_visited_states.get(s, 0) + 1

            var extended: Bool = False
            for j in range(255, -1, -1):
                var ns = self.RunStateOnByte(s, j)
                if ns == None:
                    return False
                if ns == FullMatchState or (ns > SpecialStateMax and ns[].ninst_ > 0):
                    extended = True
                    max[0] += chr(j)
                    s = ns
                    break
            if not extended:
                return True

        PrefixSuccessor(max)
        if max[0].empty():
            return False
        return True

    # Private methods
    def ResetCache(self, cache_lock: Pointer[RWLocker]):
        cache_lock[].LockForWriting()
        hooks.GetDFAStateCacheResetHook()({
            "state_budget": self.state_budget_,
            "state_cache_size": len(self.state_cache_),
        })
        for i in range(kMaxStart):
            self.start_[i].start.store(None, memory_order_relaxed)
        self.ClearCache()
        self.mem_budget_ = self.state_budget_

    def WorkqToCachedState(self, q: Pointer[Workq], mq: Pointer[Workq], flag: UInt32) -> Pointer[State]:
        var inst = PODArray[Int](q[].size())
        var n: Int = 0
        var needflags: UInt32 = 0
        var sawmatch: Bool = False
        var sawmark: Bool = False

        if ExtraDebug:
            fprintf(stderr, "WorkqToCachedState %s [%#x]", DumpWorkq(q).c_str(), flag)

        for it in q[].begin() to q[].end():
            var id = it[]
            if sawmatch and (self.kind_ == Prog.kFirstMatch or q[].is_mark(id)):
                break
            if q[].is_mark(id):
                if n > 0 and inst[n-1] != Mark:
                    sawmark = True
                    inst[n] = Mark
                    n += 1
                continue

            var ip = self.prog_[].inst(id)
            if ip.opcode() == kInstAltMatch:
                if self.kind_ != Prog.kManyMatch and \
                   (self.kind_ != Prog.kFirstMatch or \
                    (it == q[].begin() and ip.greedy(self.prog_))) and \
                   (self.kind_ != Prog.kLongestMatch or not sawmark) and \
                   (flag & kFlagMatch):
                    if ExtraDebug:
                        fprintf(stderr, " -> FullMatchState\n")
                    return FullMatchState
                # FALLTHROUGH
            else:
                if self.prog_[].inst(id-1)[].last():
                    inst[n] = it[]
                    n += 1
                if ip.opcode() == kInstEmptyWidth:
                    needflags |= ip.empty()
                if ip.opcode() == kInstMatch and not self.prog_[].anchor_end():
                    sawmatch = True

        DCHECK_LE(n, q[].size())
        if n > 0 and inst[n-1] == Mark:
            n -= 1

        if needflags == 0:
            flag &= kFlagMatch

        if n == 0 and flag == 0:
            if ExtraDebug:
                fprintf(stderr, " -> DeadState\n")
            return DeadState

        if self.kind_ == Prog.kLongestMatch:
            var ip = inst.data()
            var ep = ip + n
            while ip < ep:
                var markp = ip
                while markp < ep and markp[0] != Mark:
                    markp += 1
                sort(ip, markp)
                if markp < ep:
                    markp += 1
                ip = markp

        if self.kind_ == Prog.kManyMatch:
            var ip = inst.data()
            var ep = ip + n
            sort(ip, ep)

        if mq != None:
            inst[n] = MatchSep
            n += 1
            for i in mq[].begin() to mq[].end():
                var id = i[]
                var ip = self.prog_[].inst(id)
                if ip.opcode() == kInstMatch:
                    inst[n] = ip.match_id()
                    n += 1

        flag |= needflags << kFlagNeedShift
        var state = self.CachedState(inst.data(), n, flag)
        return state

    def CachedState(self, inst: Pointer[Int], ninst: Int, flag: UInt32) -> Pointer[State]:
        var state = State()
        state.inst_ = inst
        state.ninst_ = ninst
        state.flag_ = flag

        # Check if state already exists in cache
        for key in self.state_cache_.keys():
            if StateEqual().__call__(key, state):
                if ExtraDebug:
                    fprintf(stderr, " -cached-> %s\n", DumpState(key).c_str())
                return key

        var kStateCacheOverhead: Int = 40
        var nnext: Int = self.prog_[].bytemap_range() + 1
        var mem: Int = sizeof[State]() + nnext * sizeof[Atomic[Pointer[State]]]() + \
                       ninst * sizeof[Int]()

        if self.mem_budget_ < mem + kStateCacheOverhead:
            self.mem_budget_ = -1
            return None

        self.mem_budget_ -= mem + kStateCacheOverhead

        var space = alloc[UInt8](mem)
        var s = Pointer[State](space)
        s[].next_ = Pointer[Atomic[Pointer[State]]](space + sizeof[State]())
        s[].inst_ = Pointer[Int](space + sizeof[State]() + nnext * sizeof[Atomic[Pointer[State]]]())

        for i in range(nnext):
            s[].next_[i] = Atomic[Pointer[State]](None)

        memmove(s[].inst_, inst, ninst * sizeof[Int]())
        s[].ninst_ = ninst
        s[].flag_ = flag

        if ExtraDebug:
            fprintf(stderr, " -> %s\n", DumpState(s).c_str())

        self.state_cache_[s] = None
        return s

    def ClearCache(self):
        for key in self.state_cache_.keys():
            var ninst = key[].ninst_
            var nnext = self.prog_[].bytemap_range() + 1
            var mem = sizeof[State]() + nnext * sizeof[Atomic[Pointer[State]]]() + \
                      ninst * sizeof[Int]()
            free(Pointer[UInt8](key))
        self.state_cache_.clear()

    def StateToWorkq(self, s: Pointer[State], q: Pointer[Workq]):
        q[].clear()
        for i in range(s[].ninst_):
            if s[].inst_[i] == Mark:
                q[].mark()
            elif s[].inst_[i] == MatchSep:
                break
            else:
                self.AddToQueue(q, s[].inst_[i], s[].flag_ & kFlagEmptyMask)

    def AddToQueue(self, q: Pointer[Workq], id: Int, flag: UInt32):
        var stk = self.stack_.data()
        var nstk: Int = 0
        stk[nstk] = id
        nstk += 1

        while nstk > 0:
            DCHECK_LE(nstk, self.stack_.size())
            nstk -= 1
            id = stk[nstk]

            while True:
                if id == Mark:
                    q[].mark()
                    break
                if id == 0:
                    break
                if q[].sparse_set.contains(id):
                    break

                q[].insert_new(id)
                var ip = self.prog_[].inst(id)

                if ip.opcode() == kInstByteRange or ip.opcode() == kInstMatch:
                    if ip.last():
                        break
                    id = id + 1
                    continue
                elif ip.opcode() == kInstCapture or ip.opcode() == kInstNop:
                    if not ip.last():
                        stk[nstk] = id + 1
                        nstk += 1
                    if ip.opcode() == kInstNop and q[].maxmark() > 0 and \
                       id == self.prog_[].start_unanchored() and id != self.prog_[].start():
                        stk[nstk] = Mark
                        nstk += 1
                    id = ip.out()
                    continue
                elif ip.opcode() == kInstAltMatch:
                    DCHECK(not ip.last())
                    id = id + 1
                    continue
                elif ip.opcode() == kInstEmptyWidth:
                    if not ip.last():
                        stk[nstk] = id + 1
                        nstk += 1
                    if ip.empty() & ~flag:
                        break
                    id = ip.out()
                    continue
                else:
                    LOG(DFATAL, "unhandled opcode: " + str(ip.opcode()))
                    break

    def RunWorkqOnEmptyString(self, oldq: Pointer[Workq], newq: Pointer[Workq], flag: UInt32):
        newq[].clear()
        for i in oldq[].begin() to oldq[].end():
            if oldq[].is_mark(i[]):
                self.AddToQueue(newq, Mark, flag)
            else:
                self.AddToQueue(newq, i[], flag)

    def RunWorkqOnByte(self, oldq: Pointer[Workq], newq: Pointer[Workq],
                      c: Int, flag: UInt32, ismatch: Pointer[Bool]):
        newq[].clear()
        for i in oldq[].begin() to oldq[].end():
            if oldq[].is_mark(i[]):
                if ismatch[0]:
                    return
                newq[].mark()
                continue

            var id = i[]
            var ip = self.prog_[].inst(id)

            if ip.opcode() == kInstFail or ip.opcode() == kInstCapture or \
               ip.opcode() == kInstNop or ip.opcode() == kInstAltMatch or \
               ip.opcode() == kInstEmptyWidth:

            elif ip.opcode() == kInstByteRange:
                if not ip.Matches(c):
                    continue
                self.AddToQueue(newq, ip.out(), flag)
                if ip.hint() != 0:
                    i += ip.hint() - 1
                else:
                    var ip0 = ip
                    while not ip.last():
                        ip += 1
                    i += ip - ip0
            elif ip.opcode() == kInstMatch:
                if self.prog_[].anchor_end() and c != kByteEndText and \
                   self.kind_ != Prog.kManyMatch:
                    continue
                ismatch[0] = True
                if self.kind_ == Prog.kFirstMatch:
                    return

        if ExtraDebug:
            fprintf(stderr, "%s on %d[%#x] -> %s [%d]\n",
                    DumpWorkq(oldq).c_str(), c, flag, DumpWorkq(newq).c_str(), ismatch[0])

    def RunStateOnByteUnlocked(self, state: Pointer[State], c: Int) -> Pointer[State]:
        var l = MutexLock(self.mutex_)
        return self.RunStateOnByte(state, c)

    def RunStateOnByte(self, state: Pointer[State], c: Int) -> Pointer[State]:
        if state <= SpecialStateMax:
            if state == FullMatchState:
                return FullMatchState
            if state == DeadState:
                LOG(DFATAL, "DeadState in RunStateOnByte")
                return None
            if state == None:
                LOG(DFATAL, "NULL state in RunStateOnByte")
                return None
            LOG(DFATAL, "Unexpected special state in RunStateOnByte")
            return None

        var ns = state[].next_[self.ByteMap(c)].load(memory_order_relaxed)
        if ns != None:
            return ns

        self.StateToWorkq(state, self.q0_)
        var needflag = state[].flag_ >> kFlagNeedShift
        var beforeflag = state[].flag_ & kFlagEmptyMask
        var oldbeforeflag = beforeflag
        var afterflag: UInt32 = 0

        if c == ord('\n'):
            beforeflag |= kEmptyEndLine
            afterflag |= kEmptyBeginLine

        if c == kByteEndText:
            beforeflag |= kEmptyEndLine | kEmptyEndText

        var islastword = (state[].flag_ & kFlagLastWord) != 0
        var isword = c != kByteEndText and Prog.IsWordChar(UInt8(c))

        if isword == islastword:
            beforeflag |= kEmptyNonWordBoundary
        else:
            beforeflag |= kEmptyWordBoundary

        if beforeflag & ~oldbeforeflag & needflag:
            self.RunWorkqOnEmptyString(self.q0_, self.q1_, beforeflag)
            swap(self.q0_, self.q1_)

        var ismatch: Bool = False
        self.RunWorkqOnByte(self.q0_, self.q1_, c, afterflag, ismatch)
        swap(self.q0_, self.q1_)

        var flag = afterflag
        if ismatch:
            flag |= kFlagMatch
        if isword:
            flag |= kFlagLastWord

        if ismatch and self.kind_ == Prog.kManyMatch:
            ns = self.WorkqToCachedState(self.q0_, self.q1_, flag)
        else:
            ns = self.WorkqToCachedState(self.q0_, None, flag)

        state[].next_[self.ByteMap(c)].store(ns, memory_order_release)
        return ns

    def ByteMap(self, c: Int) -> Int:
        if c == kByteEndText:
            return self.prog_[].bytemap_range()
        return self.prog_[].bytemap()[c]

    def DumpWorkq(self, q: Pointer[Workq]) -> String:
        var s = String()
        var sep = ""
        for it in q[].begin() to q[].end():
            if q[].is_mark(it[]):
                s += "|"
                sep = ""
            else:
                s += StringPrintf("%s%d", sep, it[])
                sep = ","
        return s

    def DumpState(self, state: Pointer[State]) -> String:
        if state == None:
            return "_"
        if state == DeadState:
            return "X"
        if state == FullMatchState:
            return "*"

        var s = String()
        var sep = ""
        s += StringPrintf("(%p)", state)
        for i in range(state[].ninst_):
            if state[].inst_[i] == Mark:
                s += "|"
                sep = ""
            elif state[].inst_[i] == MatchSep:
                s += "||"
                sep = ""
            else:
                s += StringPrintf("%s%d", sep, state[].inst_[i])
                sep = ","
        s += StringPrintf(" flag=%#x", state[].flag_)
        return s

    # Template-like functions for InlinedSearchLoop
    def InlinedSearchLoop_FFF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[False, False, False](params)

    def InlinedSearchLoop_FFT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[False, False, True](params)

    def InlinedSearchLoop_FTF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[False, True, False](params)

    def InlinedSearchLoop_FTT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[False, True, True](params)

    def InlinedSearchLoop_TFF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[True, False, False](params)

    def InlinedSearchLoop_TFT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[True, False, True](params)

    def InlinedSearchLoop_TTF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[True, True, False](params)

    def InlinedSearchLoop_TTT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop[True, True, True](params)

    def InlinedSearchLoop[can_prefix_accel: Bool, want_earliest_match: Bool, run_forward: Bool](self, params: Pointer[SearchParams]) -> Bool:
        var start = params[].start
        var bp = BytePtr(params[].text.data())
        var p = bp
        var ep = BytePtr(params[].text.data() + params[].text.size())
        var resetp: Pointer[UInt8] = None

        if not run_forward:
            swap(p, ep)

        var bytemap = self.prog_[].bytemap()
        var lastmatch: Pointer[UInt8] = None
        var matched: Bool = False
        var s = start

        if ExtraDebug:
            fprintf(stderr, "@stx: %s\n", DumpState(s).c_str())

        if s[].IsMatch():
            matched = True
            lastmatch = p
            if ExtraDebug:
                fprintf(stderr, "match @stx! [%s]\n", DumpState(s).c_str())
            if params[].matches != None and self.kind_ == Prog.kManyMatch:
                for i in range(s[].ninst_ - 1, -1, -1):
                    var id = s[].inst_[i]
                    if id == MatchSep:
                        break
                    params[].matches[].insert(id)
            if want_earliest_match:
                params[].ep = lastmatch
                return True

        while p != ep:
            if ExtraDebug:
                fprintf(stderr, "@%td: %s\n", p - bp, DumpState(s).c_str())

            if can_prefix_accel and s == start:
                p = BytePtr(self.prog_[].PrefixAccel(p, ep - p))
                if p == None:
                    p = ep
                    break

            var c: Int
            if run_forward:
                c = p[0]
                p += 1
            else:
                p -= 1
                c = p[0]

            var ns = s[].next_[bytemap[c]].load(memory_order_acquire)
            if ns == None:
                ns = self.RunStateOnByteUnlocked(s, c)
                if ns == None:
                    if dfa_should_bail_when_slow and resetp != None and \
                       (p - resetp) < 10 * len(self.state_cache_) and \
                       self.kind_ != Prog.kManyMatch:
                        params[].failed = True
                        return False
                    resetp = p
                    var save_start = StateSaver(self, start)
                    var save_s = StateSaver(self, s)
                    self.ResetCache(params[].cache_lock)
                    start = save_start.Restore()
                    s = save_s.Restore()
                    if start == None or s == None:
                        params[].failed = True
                        return False
                    ns = self.RunStateOnByteUnlocked(s, c)
                    if ns == None:
                        LOG(DFATAL, "RunStateOnByteUnlocked failed after ResetCache")
                        params[].failed = True
                        return False

            if ns <= SpecialStateMax:
                if ns == DeadState:
                    params[].ep = lastmatch
                    return matched
                params[].ep = ep
                return True

            s = ns
            if s[].IsMatch():
                matched = True
                if run_forward:
                    lastmatch = p - 1
                else:
                    lastmatch = p + 1
                if ExtraDebug:
                    fprintf(stderr, "match @%td! [%s]\n", lastmatch - bp, DumpState(s).c_str())
                if params[].matches != None and self.kind_ == Prog.kManyMatch:
                    for i in range(s[].ninst_ - 1, -1, -1):
                        var id = s[].inst_[i]
                        if id == MatchSep:
                            break
                        params[].matches[].insert(id)
                if want_earliest_match:
                    params[].ep = lastmatch
                    return True

        if ExtraDebug:
            fprintf(stderr, "@etx: %s\n", DumpState(s).c_str())

        var lastbyte: Int
        if run_forward:
            if EndPtr(params[].text) == EndPtr(params[].context):
                lastbyte = kByteEndText
            else:
                lastbyte = EndPtr(params[].text)[0] & 0xFF
        else:
            if BeginPtr(params[].text) == BeginPtr(params[].context):
                lastbyte = kByteEndText
            else:
                lastbyte = BeginPtr(params[].text)[-1] & 0xFF

        var ns = s[].next_[self.ByteMap(lastbyte)].load(memory_order_acquire)
        if ns == None:
            ns = self.RunStateOnByteUnlocked(s, lastbyte)
            if ns == None:
                var save_s = StateSaver(self, s)
                self.ResetCache(params[].cache_lock)
                s = save_s.Restore()
                if s == None:
                    params[].failed = True
                    return False
                ns = self.RunStateOnByteUnlocked(s, lastbyte)
                if ns == None:
                    LOG(DFATAL, "RunStateOnByteUnlocked failed after Reset")
                    params[].failed = True
                    return False

        if ns <= SpecialStateMax:
            if ns == DeadState:
                params[].ep = lastmatch
                return matched
            params[].ep = ep
            return True

        s = ns
        if s[].IsMatch():
            matched = True
            lastmatch = p
            if ExtraDebug:
                fprintf(stderr, "match @etx! [%s]\n", DumpState(s).c_str())
            if params[].matches != None and self.kind_ == Prog.kManyMatch:
                for i in range(s[].ninst_ - 1, -1, -1):
                    var id = s[].inst_[i]
                    if id == MatchSep:
                        break
                    params[].matches[].insert(id)

        params[].ep = lastmatch
        return matched

    def SearchFFF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_FFF(params)

    def SearchFFT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_FFT(params)

    def SearchFTF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_FTF(params)

    def SearchFTT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_FTT(params)

    def SearchTFF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_TFF(params)

    def SearchTFT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_TFT(params)

    def SearchTTF(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_TTF(params)

    def SearchTTT(self, params: Pointer[SearchParams]) -> Bool:
        return self.InlinedSearchLoop_TTT(params)

    def FastSearchLoop(self, params: Pointer[SearchParams]) -> Bool:
        var Searches: StaticArray[fn(Pointer[SearchParams]) -> Bool, 8] = [
            self.SearchFFF,
            self.SearchFFT,
            self.SearchFTF,
            self.SearchFTT,
            self.SearchTFF,
            self.SearchTFT,
            self.SearchTTF,
            self.SearchTTT,
        ]
        var index = 4 * params[].can_prefix_accel + \
                    2 * params[].want_earliest_match + \
                    1 * params[].run_forward
        return Searches[index](params)

    def AnalyzeSearch(self, params: Pointer[SearchParams]) -> Bool:
        var text = params[].text
        var context = params[].context

        if BeginPtr(text) < BeginPtr(context) or EndPtr(text) > EndPtr(context):
            LOG(DFATAL, "context does not contain text")
            params[].start = DeadState
            return True

        var start: Int
        var flags: UInt32

        if params[].run_forward:
            if BeginPtr(text) == BeginPtr(context):
                start = kStartBeginText
                flags = kEmptyBeginText | kEmptyBeginLine
            elif BeginPtr(text)[-1] == ord('\n'):
                start = kStartBeginLine
                flags = kEmptyBeginLine
            elif Prog.IsWordChar(BeginPtr(text)[-1] & 0xFF):
                start = kStartAfterWordChar
                flags = kFlagLastWord
            else:
                start = kStartAfterNonWordChar
                flags = 0
        else:
            if EndPtr(text) == EndPtr(context):
                start = kStartBeginText
                flags = kEmptyBeginText | kEmptyBeginLine
            elif EndPtr(text)[0] == ord('\n'):
                start = kStartBeginLine
                flags = kEmptyBeginLine
            elif Prog.IsWordChar(EndPtr(text)[0] & 0xFF):
                start = kStartAfterWordChar
                flags = kFlagLastWord
            else:
                start = kStartAfterNonWordChar
                flags = 0

        if params[].anchored:
            start |= kStartAnchored

        var info = self.start_[start]
        if not self.AnalyzeSearchHelper(params, info, flags):
            self.ResetCache(params[].cache_lock)
            if not self.AnalyzeSearchHelper(params, info, flags):
                LOG(DFATAL, "Failed to analyze start state.")
                params[].failed = True
                return False

        params[].start = info.start.load(memory_order_acquire)

        if self.prog_[].can_prefix_accel() and \
           not params[].anchored and \
           params[].start > SpecialStateMax and \
           params[].start[].flag_ >> kFlagNeedShift == 0:
            params[].can_prefix_accel = True

        if ExtraDebug:
            fprintf(stderr, "anchored=%d fwd=%d flags=%#x state=%s can_prefix_accel=%d\n",
                    params[].anchored, params[].run_forward, flags,
                    DumpState(params[].start).c_str(), params[].can_prefix_accel)

        return True

    def AnalyzeSearchHelper(self, params: Pointer[SearchParams], info: Pointer[StartInfo],
                           flags: UInt32) -> Bool:
        var start = info[].start.load(memory_order_acquire)
        if start != None:
            return True

        var l = MutexLock(self.mutex_)
        start = info[].start.load(memory_order_relaxed)
        if start != None:
            return True

        self.q0_[].clear()
        self.AddToQueue(self.q0_,
                        params[].anchored ? self.prog_[].start() : self.prog_[].start_unanchored(),
                        flags)
        start = self.WorkqToCachedState(self.q0_, None, flags)
        if start == None:
            return False

        info[].start.store(start, memory_order_release)
        return True

# Helper functions
def BytePtr(v: Pointer[UInt8]) -> Pointer[UInt8]:
    return v

def BeginPtr(sp: StringPiece) -> Pointer[UInt8]:
    return sp.data()

def EndPtr(sp: StringPiece) -> Pointer[UInt8]:
    return sp.data() + sp.size()

# Prog methods that use DFA
def Prog_GetDFA(self: Pointer[Prog], kind: Prog.MatchKind) -> Pointer[DFA]:
    if kind == kFirstMatch:
        # Simplified: using a simple flag instead of call_once
        if self[].dfa_first_ == None:
            self[].dfa_first_ = alloc[DFA](1)
            self[].dfa_first_[0] = DFA(self, kFirstMatch, self[].dfa_mem_ / 2)
        return self[].dfa_first_
    elif kind == kManyMatch:
        if self[].dfa_first_ == None:
            self[].dfa_first_ = alloc[DFA](1)
            self[].dfa_first_[0] = DFA(self, kManyMatch, self[].dfa_mem_)
        return self[].dfa_first_
    else:
        if self[].dfa_longest_ == None:
            if not self[].reversed_:
                self[].dfa_longest_ = alloc[DFA](1)
                self[].dfa_longest_[0] = DFA(self, kLongestMatch, self[].dfa_mem_ / 2)
            else:
                self[].dfa_longest_ = alloc[DFA](1)
                self[].dfa_longest_[0] = DFA(self, kLongestMatch, self[].dfa_mem_)
        return self[].dfa_longest_

def Prog_DeleteDFA(self: Pointer[Prog], dfa: Pointer[DFA]):
    free(dfa)

def Prog_SearchDFA(self: Pointer[Prog], text: StringPiece, const_context: StringPiece,
                  anchor: Anchor, kind: Prog.MatchKind, match0: Pointer[StringPiece],
                  failed: Pointer[Bool], matches: Pointer[SparseSet]) -> Bool:
    failed[0] = False
    var context = const_context
    if context.data() == None:
        context = text

    var caret = self[].anchor_start()
    var dollar = self[].anchor_end()

    if self[].reversed_:
        swap(caret, dollar)

    if caret and BeginPtr(context) != BeginPtr(text):
        return False
    if dollar and EndPtr(context) != EndPtr(text):
        return False

    var anchored = anchor == kAnchored or self[].anchor_start() or kind == kFullMatch
    var endmatch = False

    if kind == kManyMatch:

    elif kind == kFullMatch or self[].anchor_end():
        endmatch = True
        kind = kLongestMatch

    var want_earliest_match = False
    if kind == kManyMatch:
        if matches == None:
            want_earliest_match = True
    elif match0 == None and not endmatch:
        want_earliest_match = True
        kind = kLongestMatch

    var dfa = self[].GetDFA(kind)
    var ep: Pointer[UInt8]
    var matched = dfa[].Search(text, context, anchored,
                               want_earliest_match, not self[].reversed_,
                               failed, ep, matches)

    if failed[0]:
        hooks.GetDFASearchFailureHook()({})
        return False

    if not matched:
        return False

    if endmatch and ep != (self[].reversed_ ? text.data() : text.data() + text.size()):
        return False

    if match0:
        if self[].reversed_:
            match0[0] = StringPiece(ep, text.data() + text.size() - ep)
        else:
            match0[0] = StringPiece(text.data(), ep - text.data())

    return True

def Prog_BuildEntireDFA(self: Pointer[Prog], kind: Prog.MatchKind, cb: Prog.DFAStateCallback) -> Int:
    return self[].GetDFA(kind)[].BuildAllStates(cb)

def Prog_PossibleMatchRange(self: Pointer[Prog], min: Pointer[String], max: Pointer[String], maxlen: Int) -> Bool:
    return self[].GetDFA(kLongestMatch)[].PossibleMatchRange(min, max, maxlen)