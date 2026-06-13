from prog import (
    Prog, Anchor, MatchKind,
    kInstByteRange, kInstCapture, kInstEmptyWidth, kInstNop,
    kInstMatch, kInstFail, kInstAltMatch,
    Inst,
    kEmptyAllFlags, kEmptyWordBoundary, kEmptyNonWordBoundary,
)
from .pod_array import PODArray
from .sparse_set import SparseSet
from stringpiece import StringPiece
from util.logging import LOG  # assume LOG(level, msg) function

alias ExtraDebug = False

struct OneState:
    var _ptr: Pointer[UInt8]
    
    def __init__(inout self, ptr: Pointer[UInt8]):
        self._ptr = ptr
    
    def matchcond(self) -> UInt32:
        return self._ptr.load[UInt32](0)
    
    def set_matchcond(inout self, val: UInt32):
        self._ptr.store[UInt32](0, val)
    
    def action(self, b: Int) -> UInt32:
        return self._ptr.load[UInt32](4 + b * 4)
    
    def set_action(inout self, b: Int, val: UInt32):
        self._ptr.store[UInt32](4 + b * 4, val)

alias kIndexShift = 16
alias kEmptyShift = 6
alias kRealCapShift = kEmptyShift + 1
alias kRealMaxCap = ((kIndexShift - kRealCapShift) // 2) * 2
alias kCapShift = kRealCapShift - 2
alias kMaxCap = kRealMaxCap + 2
alias kMatchWins = UInt32(1) << kEmptyShift
alias kCapMask = ((UInt32(1) << kRealMaxCap) - 1) << kRealCapShift
alias kImpossible = UInt32(kEmptyWordBoundary | kEmptyNonWordBoundary)

def OnePass_Checks():
    # static_assert((1<<kEmptyShift)-1 == kEmptyAllFlags,
    #               "kEmptyShift disagrees with kEmptyAllFlags")
    # static_assert(kMaxCap == Prog.kMaxOnePassCapture*2,
    #               "kMaxCap disagrees with kMaxOnePassCapture")

def Satisfy(cond: UInt32, context: StringPiece, p: Pointer[UInt8]) -> Bool:
    var satisfied = Prog.EmptyFlags(context, p)
    if cond & kEmptyAllFlags & ~satisfied:
        return False
    return True

def ApplyCaptures(cond: UInt32, p: Pointer[UInt8], cap: Pointer[Pointer[UInt8]], ncap: Int):
    for i in range(2, ncap):
        if cond & (1 << kCapShift << i):
            cap[i] = p

def IndexToNode(nodes: Pointer[UInt8], statesize: Int, nodeindex: Int) -> OneState:
    return OneState(nodes + statesize * nodeindex)

# Extend Prog with methods
def Prog.SearchOnePass(
    inout self,
    text: StringPiece,
    const_context: StringPiece,
    anchor: Anchor,
    kind: MatchKind,
    match: Pointer[StringPiece],
    nmatch: Int,
) -> Bool:
    if anchor != kAnchored and kind != kFullMatch:
        LOG("DFATAL", "Cannot use SearchOnePass for unanchored matches.")
        return False
    var ncap = 2 * nmatch
    if ncap < 2:
        ncap = 2
    var cap = Pointer[Pointer[UInt8]].alloc(kMaxCap)
    for i in range(ncap):
        cap[i] = Pointer[UInt8]()
    var matchcap = Pointer[Pointer[UInt8]].alloc(kMaxCap)
    for i in range(ncap):
        matchcap[i] = Pointer[UInt8]()
    var context = const_context
    if context.data() == Pointer[UInt8]():
        context = text
    if self.anchor_start() and BeginPtr(context) != BeginPtr(text):
        return False
    if self.anchor_end() and EndPtr(context) != EndPtr(text):
        return False
    if self.anchor_end():
        kind = kFullMatch
    var nodes = self.onepass_nodes_.data()
    var statesize = sizeof[OneState]() + self.bytemap_range() * sizeof[UInt32]()
    var state = IndexToNode(nodes, statesize, 0)
    var bytemap = self.bytemap_
    var bp = text.data()
    var ep = text.data() + text.size()
    var p: Pointer[UInt8]
    var matched = False
    matchcap[0] = bp
    cap[0] = bp
    var nextmatchcond = state.matchcond()
    p = bp
    while p < ep:
        var c = bytemap[UInt8(p.load())]
        var matchcond = nextmatchcond
        var cond = state.action(c)
        if (cond & kEmptyAllFlags) == 0 or Satisfy(cond, context, p):
            var nextindex = cond >> kIndexShift
            state = IndexToNode(nodes, statesize, nextindex)
            nextmatchcond = state.matchcond()
        else:
            state = OneState(Pointer[UInt8]())
            nextmatchcond = kImpossible
        if kind == kFullMatch:
            goto skipmatch
        if matchcond == kImpossible:
            goto skipmatch
        if (cond & kMatchWins) == 0 and (nextmatchcond & kEmptyAllFlags) == 0:
            goto skipmatch
        if (matchcond & kEmptyAllFlags) == 0 or Satisfy(matchcond, context, p):
            for i in range(2, 2 * nmatch):
                matchcap[i] = cap[i]
            if nmatch > 1 and (matchcond & kCapMask):
                ApplyCaptures(matchcond, p, matchcap, ncap)
            matchcap[1] = p
            matched = True
            if kind == kFirstMatch and (cond & kMatchWins):
                goto done
    label skipmatch:
        if state._ptr == Pointer[UInt8]():
            goto done
        if (cond & kCapMask) and nmatch > 1:
            ApplyCaptures(cond, p, cap, ncap)
        p += 1
    # after loop
    var matchcond2 = state.matchcond()
    if matchcond2 != kImpossible and ((matchcond2 & kEmptyAllFlags) == 0 or Satisfy(matchcond2, context, p)):
        if nmatch > 1 and (matchcond2 & kCapMask):
            ApplyCaptures(matchcond2, p, cap, ncap)
        for i in range(2, ncap):
            matchcap[i] = cap[i]
        matchcap[1] = p
        matched = True
label done:
    if not matched:
        return False
    for i in range(nmatch):
        match[i] = StringPiece(
            matchcap[2 * i],
            (matchcap[2 * i + 1] - matchcap[2 * i]).to_index()
        )
    return True

alias Instq = SparseSet

def AddQ(q: Instq, id: Int) -> Bool:
    if id == 0:
        return True
    if q.contains(id):
        return False
    q.insert(id)
    return True

struct InstCond:
    var id: Int
    var cond: UInt32

def Prog.IsOnePass(inout self) -> Bool:
    if self.did_onepass_:
        return self.onepass_nodes_.data() != Pointer[UInt8]()
    self.did_onepass_ = True
    if self.start() == 0:
        return False
    var maxnodes = 2 + self.inst_count(kInstByteRange)
    var statesize = sizeof[OneState]() + self.bytemap_range() * sizeof[UInt32]()
    if maxnodes >= 65000 or self.dfa_mem_ // 4 // statesize < maxnodes:
        return False
    var stacksize = self.inst_count(kInstCapture) + self.inst_count(kInstEmptyWidth) + self.inst_count(kInstNop) + 1
    var stack = PODArray[InstCond](stacksize)
    var size = self.size()
    var nodebyid = PODArray[Int](size)
    for i in range(size):
        nodebyid[i] = -1
    var nodes = List[UInt8]()
    var tovisit = SparseSet(size)
    var workq = SparseSet(size)
    AddQ(tovisit, self.start())
    nodebyid[self.start()] = 0
    var nalloc = 1
    for _ in range(statesize):
        nodes.append(0)
    for it in tovisit:
        var id = it
        var nodeindex = nodebyid[id]
        var node = IndexToNode(nodes.data().bitcast[UInt8](), statesize, nodeindex)
        for b in range(self.bytemap_range_):
            node.set_action(b, kImpossible)
        node.set_matchcond(kImpossible)
        workq.clear()
        var matched = False
        var nstack = 0
        stack[nstack].id = id
        stack[nstack].cond = 0
        nstack += 1
        while nstack > 0:
            nstack -= 1
            var id2 = stack[nstack].id
            var cond = stack[nstack].cond
            label Loop:
            var ip = self.inst(id2)
            if ip.opcode() == kInstAltMatch:
                # DCHECK(!ip.last())
                if not AddQ(workq, id2 + 1):
                    goto fail
                id2 = id2 + 1
                goto Loop
            elif ip.opcode() == kInstByteRange:
                var nextindex = nodebyid[ip.out()]
                if nextindex == -1:
                    if nalloc >= maxnodes:
                        if ExtraDebug:
                            LOG("ERROR", StringPrintf("Not OnePass: hit node limit %d >= %d", nalloc, maxnodes))
                        goto fail
                    nextindex = nalloc
                    AddQ(tovisit, ip.out())
                    nodebyid[ip.out()] = nalloc
                    nalloc += 1
                    for _ in range(statesize):
                        nodes.append(0)
                    node = IndexToNode(nodes.data().bitcast[UInt8](), statesize, nodeindex)
                var lo = ip.lo()
                var hi = ip.hi()
                var c = lo
                while c <= hi:
                    var b = self.bytemap_[c]
                    while c < 255 and self.bytemap_[c + 1] == b:
                        c += 1
                    var act = node.action(b)
                    var newact = (nextindex << kIndexShift) | cond
                    if matched:
                        newact |= kMatchWins
                    if (act & kImpossible) == kImpossible:
                        node.set_action(b, newact)
                    elif act != newact:
                        if ExtraDebug:
                            LOG("ERROR", StringPrintf("Not OnePass: conflict on byte %#x at state %d", c, it))
                        goto fail
                    c += 1
                if ip.foldcase():
                    var lo2 = max(ip.lo(), ord('a')) + (ord('A') - ord('a'))
                    var hi2 = min(ip.hi(), ord('z')) + (ord('A') - ord('a'))
                    c = lo2
                    while c <= hi2:
                        var b = self.bytemap_[c]
                        while c < 255 and self.bytemap_[c + 1] == b:
                            c += 1
                        var act = node.action(b)
                        var newact = (nextindex << kIndexShift) | cond
                        if matched:
                            newact |= kMatchWins
                        if (act & kImpossible) == kImpossible:
                            node.set_action(b, newact)
                        elif act != newact:
                            if ExtraDebug:
                                LOG("ERROR", StringPrintf("Not OnePass: conflict on byte %#x at state %d", c, it))
                            goto fail
                        c += 1
                if ip.last():
                    break
                if not AddQ(workq, id2 + 1):
                    goto fail
                id2 = id2 + 1
                goto Loop
            elif ip.opcode() in (kInstCapture, kInstEmptyWidth, kInstNop):
                if not ip.last():
                    if not AddQ(workq, id2 + 1):
                        goto fail
                    stack[nstack].id = id2 + 1
                    stack[nstack].cond = cond
                    nstack += 1
                if ip.opcode() == kInstCapture and ip.cap() < kMaxCap:
                    cond |= (1 << kCapShift) << ip.cap()
                if ip.opcode() == kInstEmptyWidth:
                    cond |= ip.empty()
                if not AddQ(workq, ip.out()):
                    if ExtraDebug:
                        LOG("ERROR", StringPrintf("Not OnePass: multiple paths %d -> %d", it, ip.out()))
                    goto fail
                id2 = ip.out()
                goto Loop
            elif ip.opcode() == kInstMatch:
                if matched:
                    if ExtraDebug:
                        LOG("ERROR", StringPrintf("Not OnePass: multiple matches from %d", it))
                    goto fail
                matched = True
                node.set_matchcond(cond)
                if ip.last():
                    break
                if not AddQ(workq, id2 + 1):
                    goto fail
                id2 = id2 + 1
                goto Loop
            elif ip.opcode() == kInstFail:
                break
            else:
                LOG("DFATAL", StringPrintf("unhandled opcode: %d", ip.opcode()))
                break
    if ExtraDebug:
        LOG("ERROR", "bytemap:\n" + self.DumpByteMap())
        LOG("ERROR", "prog:\n" + self.Dump())
        var idmap = Dict[Int, Int]()
        for i in range(size):
            if nodebyid[i] != -1:
                idmap[nodebyid[i]] = i
        var dump_str = ""
        for it in tovisit:
            var id = it
            var nodeindex = nodebyid[id]
            if nodeindex == -1:
                continue
            var node = IndexToNode(nodes.data().bitcast[UInt8](), statesize, nodeindex)
            dump_str += StringPrintf("node %d id=%d: matchcond=%#x\n", nodeindex, id, node.matchcond())
            for i in range(self.bytemap_range_):
                if (node.action(i) & kImpossible) == kImpossible:
                    continue
                dump_str += StringPrintf("  %d cond %#x -> %d id=%d\n",
                                         i, node.action(i) & 0xFFFF,
                                         node.action(i) >> kIndexShift,
                                         idmap[node.action(i) >> kIndexShift])
        LOG("ERROR", "nodes:\n" + dump_str)
    self.dfa_mem_ -= nalloc * statesize
    self.onepass_nodes_ = PODArray[UInt8](nalloc * statesize)
    memmove(self.onepass_nodes_.data(), nodes.data().bitcast[UInt8](), nalloc * statesize)
    return True
label fail:
    return False