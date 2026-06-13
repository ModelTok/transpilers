from util.benchmark import benchmark, BENCHMARK_RANGE, BENCHMARK
from util.test import Test, CHECK, CHECK_EQ
from util.flags import GetFlag, DEFINE_FLAG
from util.logging import LOG
from util.malloc_counter import MallocCounter
from util.strutil import StringPiece
from ..prog import Prog
from ..re2 import RE2
from ..regexp import Regexp
from util.mutex import Mutex, MutexLock
from util.pcre import PCRE
from stdlib.random import rand
from stdlib.thread import hardware_concurrency
from stdlib.string import String
from stdlib.dict import Dict
from stdlib.algorithm import swap

def Test():
    var re = Regexp.Parse("(\\d+)-(\\d+)-(\\d+)", Regexp.LikePerl, None)
    CHECK(re)
    var prog = re.CompileToProg(0)
    CHECK(prog)
    CHECK(prog.IsOnePass())
    CHECK(prog.CanBitState())
    var text = "650-253-0001"
    var sp = StringPiece(4)
    CHECK(prog.SearchOnePass(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))
    CHECK_EQ(sp[0], "650-253-0001")
    CHECK_EQ(sp[1], "650")
    CHECK_EQ(sp[2], "253")
    CHECK_EQ(sp[3], "0001")
    delete prog
    re.Decref()
    LOG(INFO).log("test passed\n")

def MemoryUsage():
    var regexp = "(\\d+)-(\\d+)-(\\d+)"
    var text = "650-253-0001"
    {
        var mc = MallocCounter(MallocCounter.THIS_THREAD_ONLY)
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        fprintf(stderr, "Regexp: %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        mc.Reset()
        var prog = re.CompileToProg(0)
        CHECK(prog)
        CHECK(prog.IsOnePass())
        CHECK(prog.CanBitState())
        fprintf(stderr, "Prog:   %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        mc.Reset()
        var sp = StringPiece(4)
        CHECK(prog.SearchOnePass(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))
        fprintf(stderr, "Search: %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        delete prog
        re.Decref()
    }
    {
        var mc = MallocCounter(MallocCounter.THIS_THREAD_ONLY)
        var re = PCRE(regexp, PCRE.UTF8)
        fprintf(stderr, "RE:     %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        PCRE.FullMatch(text, re)
        fprintf(stderr, "RE:     %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
    }
    {
        var mc = MallocCounter(MallocCounter.THIS_THREAD_ONLY)
        var re = PCRE(regexp, PCRE.UTF8)
        fprintf(stderr, "PCRE*:  %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        PCRE.FullMatch(text, *re)
        fprintf(stderr, "PCRE*:  %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        delete re
    }
    {
        var mc = MallocCounter(MallocCounter.THIS_THREAD_ONLY)
        var re = RE2(regexp)
        fprintf(stderr, "RE2:    %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
        RE2.FullMatch(text, re)
        fprintf(stderr, "RE2:    %7lld bytes (peak=%lld)\n",
                mc.HeapGrowth, mc.PeakHeapGrowth)
    }
    fprintf(stderr, "sizeof: PCRE=%zd RE2=%zd Prog=%zd Inst=%zd\n",
            sizeof[PCRE], sizeof[RE2], sizeof[Prog], sizeof[Prog.Inst])

def NumCPUs() -> Int32:
    return hardware_concurrency()

typealias SearchImpl = fn(benchmark.State&, String, StringPiece&, Prog.Anchor, Bool) -> Void
var SearchDFA: SearchImpl
var SearchNFA: SearchImpl
var SearchOnePass: SearchImpl
var SearchBitState: SearchImpl
var SearchPCRE: SearchImpl
var SearchRE2: SearchImpl
var SearchCachedDFA: SearchImpl
var SearchCachedNFA: SearchImpl
var SearchCachedOnePass: SearchImpl
var SearchCachedBitState: SearchImpl
var SearchCachedPCRE: SearchImpl
var SearchCachedRE2: SearchImpl

typealias ParseImpl = fn(benchmark.State&, String, StringPiece&) -> Void
var Parse1NFA: ParseImpl
var Parse1OnePass: ParseImpl
var Parse1BitState: ParseImpl
var Parse1PCRE: ParseImpl
var Parse1RE2: ParseImpl
var Parse1Backtrack: ParseImpl
var Parse1CachedNFA: ParseImpl
var Parse1CachedOnePass: ParseImpl
var Parse1CachedBitState: ParseImpl
var Parse1CachedPCRE: ParseImpl
var Parse1CachedRE2: ParseImpl
var Parse1CachedBacktrack: ParseImpl
var Parse3NFA: ParseImpl
var Parse3OnePass: ParseImpl
var Parse3BitState: ParseImpl
var Parse3PCRE: ParseImpl
var Parse3RE2: ParseImpl
var Parse3Backtrack: ParseImpl
var Parse3CachedNFA: ParseImpl
var Parse3CachedOnePass: ParseImpl
var Parse3CachedBitState: ParseImpl
var Parse3CachedPCRE: ParseImpl
var Parse3CachedRE2: ParseImpl
var Parse3CachedBacktrack: ParseImpl
var SearchParse2CachedPCRE: ParseImpl
var SearchParse2CachedRE2: ParseImpl
var SearchParse1CachedPCRE: ParseImpl
var SearchParse1CachedRE2: ParseImpl

def RandomText(nbytes: Int64) -> String:
    @staticmethod
    def inner() -> String:
        var text = String()
        srand(1)
        text.reserve(16 << 20)
        for i in range(0, 16 << 20):
            var byte = rand() & 0x7F
            if byte < 0x20:
                byte = 0x20
            text[i] = byte
        return text
    var text = inner()
    CHECK_LE(nbytes, 16 << 20)
    return text.substr(0, nbytes)

def Search(state: benchmark.State&, regexp: String, search: SearchImpl):
    var s = RandomText(state.range(0))
    search(state, regexp, s, Prog.kUnanchored, False)
    state.SetBytesProcessed(state.iterations() * state.range(0))

var EASY0 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
var EASY1 = "A[AB]B[BC]C[CD]D[DE]E[EF]F[FG]G[GH]H[HI]I[IJ]J$"
var EASY2 = "(?i)" + EASY0
var MEDIUM = "[XYZ]ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
var HARD = "[ -~]*ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
var FANOUT = "(?:[\\x{80}-\\x{10FFFF}]?){100}[\\x{80}-\\x{10FFFF}]"
var PARENS = "([ -~])*(A)(B)(C)(D)(E)(F)(G)(H)(I)(J)(K)(L)(M)" \
             "(N)(O)(P)(Q)(R)(S)(T)(U)(V)(W)(X)(Y)(Z)$"

def Search_Easy0_CachedDFA(state: benchmark.State&):
    Search(state, EASY0, SearchCachedDFA)
def Search_Easy0_CachedNFA(state: benchmark.State&):
    Search(state, EASY0, SearchCachedNFA)
def Search_Easy0_CachedPCRE(state: benchmark.State&):
    Search(state, EASY0, SearchCachedPCRE)
def Search_Easy0_CachedRE2(state: benchmark.State&):
    Search(state, EASY0, SearchCachedRE2)
BENCHMARK_RANGE(Search_Easy0_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Easy0_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Easy0_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Easy0_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_Easy1_CachedDFA(state: benchmark.State&):
    Search(state, EASY1, SearchCachedDFA)
def Search_Easy1_CachedNFA(state: benchmark.State&):
    Search(state, EASY1, SearchCachedNFA)
def Search_Easy1_CachedPCRE(state: benchmark.State&):
    Search(state, EASY1, SearchCachedPCRE)
def Search_Easy1_CachedRE2(state: benchmark.State&):
    Search(state, EASY1, SearchCachedRE2)
BENCHMARK_RANGE(Search_Easy1_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Easy1_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Easy1_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Easy1_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_Easy2_CachedDFA(state: benchmark.State&):
    Search(state, EASY2, SearchCachedDFA)
def Search_Easy2_CachedNFA(state: benchmark.State&):
    Search(state, EASY2, SearchCachedNFA)
def Search_Easy2_CachedPCRE(state: benchmark.State&):
    Search(state, EASY2, SearchCachedPCRE)
def Search_Easy2_CachedRE2(state: benchmark.State&):
    Search(state, EASY2, SearchCachedRE2)
BENCHMARK_RANGE(Search_Easy2_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Easy2_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Easy2_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Easy2_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_Medium_CachedDFA(state: benchmark.State&):
    Search(state, MEDIUM, SearchCachedDFA)
def Search_Medium_CachedNFA(state: benchmark.State&):
    Search(state, MEDIUM, SearchCachedNFA)
def Search_Medium_CachedPCRE(state: benchmark.State&):
    Search(state, MEDIUM, SearchCachedPCRE)
def Search_Medium_CachedRE2(state: benchmark.State&):
    Search(state, MEDIUM, SearchCachedRE2)
BENCHMARK_RANGE(Search_Medium_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Medium_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Medium_CachedPCRE, 8, 256 << 10).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Medium_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_Hard_CachedDFA(state: benchmark.State&):
    Search(state, HARD, SearchCachedDFA)
def Search_Hard_CachedNFA(state: benchmark.State&):
    Search(state, HARD, SearchCachedNFA)
def Search_Hard_CachedPCRE(state: benchmark.State&):
    Search(state, HARD, SearchCachedPCRE)
def Search_Hard_CachedRE2(state: benchmark.State&):
    Search(state, HARD, SearchCachedRE2)
BENCHMARK_RANGE(Search_Hard_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Hard_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Hard_CachedPCRE, 8, 4 << 10).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Hard_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_Fanout_CachedDFA(state: benchmark.State&):
    Search(state, FANOUT, SearchCachedDFA)
def Search_Fanout_CachedNFA(state: benchmark.State&):
    Search(state, FANOUT, SearchCachedNFA)
def Search_Fanout_CachedPCRE(state: benchmark.State&):
    Search(state, FANOUT, SearchCachedPCRE)
def Search_Fanout_CachedRE2(state: benchmark.State&):
    Search(state, FANOUT, SearchCachedRE2)
BENCHMARK_RANGE(Search_Fanout_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Fanout_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Fanout_CachedPCRE, 8, 4 << 10).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Fanout_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_Parens_CachedDFA(state: benchmark.State&):
    Search(state, PARENS, SearchCachedDFA)
def Search_Parens_CachedNFA(state: benchmark.State&):
    Search(state, PARENS, SearchCachedNFA)
def Search_Parens_CachedPCRE(state: benchmark.State&):
    Search(state, PARENS, SearchCachedPCRE)
def Search_Parens_CachedRE2(state: benchmark.State&):
    Search(state, PARENS, SearchCachedRE2)
BENCHMARK_RANGE(Search_Parens_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Parens_CachedNFA, 8, 256 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Parens_CachedPCRE, 8, 8).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Parens_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def SearchBigFixed(state: benchmark.State&, search: SearchImpl):
    var s: String = ""
    s.append(state.range(0) / 2, 'x')
    var regexp = "^" + s + ".*$"
    var t = RandomText(state.range(0) / 2)
    s += t
    search(state, regexp, s, Prog.kUnanchored, True)
    state.SetBytesProcessed(state.iterations() * state.range(0))

def Search_BigFixed_CachedDFA(state: benchmark.State&):
    SearchBigFixed(state, SearchCachedDFA)
def Search_BigFixed_CachedNFA(state: benchmark.State&):
    SearchBigFixed(state, SearchCachedNFA)
def Search_BigFixed_CachedPCRE(state: benchmark.State&):
    SearchBigFixed(state, SearchCachedPCRE)
def Search_BigFixed_CachedRE2(state: benchmark.State&):
    SearchBigFixed(state, SearchCachedRE2)
BENCHMARK_RANGE(Search_BigFixed_CachedDFA, 8, 1 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_BigFixed_CachedNFA, 8, 32 << 10).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_BigFixed_CachedPCRE, 8, 32 << 10).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_BigFixed_CachedRE2, 8, 1 << 20).ThreadRange(1, NumCPUs())

def FindAndConsume(state: benchmark.State&):
    var s = RandomText(state.range(0))
    s.append("Hello World")
    var re = RE2("((Hello World))")
    for _ in state:
        var t = StringPiece(s)
        var u = StringPiece()
        CHECK(RE2.FindAndConsume(&t, re, &u))
        CHECK_EQ(u, "Hello World")
    state.SetBytesProcessed(state.iterations() * state.range(0))

BENCHMARK_RANGE(FindAndConsume, 8, 16 << 20).ThreadRange(1, NumCPUs())

def SearchSuccess(state: benchmark.State&, regexp: String, search: SearchImpl):
    var s = RandomText(state.range(0))
    search(state, regexp, s, Prog.kAnchored, True)
    state.SetBytesProcessed(state.iterations() * state.range(0))

def Search_Success_DFA(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchDFA)
def Search_Success_NFA(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchNFA)
def Search_Success_PCRE(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchPCRE)
def Search_Success_RE2(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchRE2)
def Search_Success_OnePass(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchOnePass)
BENCHMARK_RANGE(Search_Success_DFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success_NFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success_PCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Success_RE2, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success_OnePass, 8, 2 << 20).ThreadRange(1, NumCPUs())

def Search_Success_CachedDFA(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchCachedDFA)
def Search_Success_CachedNFA(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchCachedNFA)
def Search_Success_CachedPCRE(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchCachedPCRE)
def Search_Success_CachedRE2(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchCachedRE2)
def Search_Success_CachedOnePass(state: benchmark.State&):
    SearchSuccess(state, ".*$", SearchCachedOnePass)
BENCHMARK_RANGE(Search_Success_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success_CachedNFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Success_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success_CachedOnePass, 8, 2 << 20).ThreadRange(1, NumCPUs())

def Search_Success1_DFA(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchDFA)
def Search_Success1_NFA(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchNFA)
def Search_Success1_PCRE(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchPCRE)
def Search_Success1_RE2(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchRE2)
def Search_Success1_BitState(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchBitState)
BENCHMARK_RANGE(Search_Success1_DFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success1_NFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success1_PCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Success1_RE2, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success1_BitState, 8, 2 << 20).ThreadRange(1, NumCPUs())

def Search_Success1_CachedDFA(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchCachedDFA)
def Search_Success1_CachedNFA(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchCachedNFA)
def Search_Success1_CachedPCRE(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchCachedPCRE)
def Search_Success1_CachedRE2(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchCachedRE2)
def Search_Success1_CachedBitState(state: benchmark.State&):
    SearchSuccess(state, ".*\\C$", SearchCachedBitState)
BENCHMARK_RANGE(Search_Success1_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success1_CachedNFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success1_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_Success1_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_Success1_CachedBitState, 8, 2 << 20).ThreadRange(1, NumCPUs())

def SearchAltMatch(state: benchmark.State&, search: SearchImpl):
    var s = RandomText(state.range(0))
    search(state, "\\C*", s, Prog.kAnchored, True)
    state.SetBytesProcessed(state.iterations() * state.range(0))

def Search_AltMatch_DFA(state: benchmark.State&):
    SearchAltMatch(state, SearchDFA)
def Search_AltMatch_NFA(state: benchmark.State&):
    SearchAltMatch(state, SearchNFA)
def Search_AltMatch_OnePass(state: benchmark.State&):
    SearchAltMatch(state, SearchOnePass)
def Search_AltMatch_BitState(state: benchmark.State&):
    SearchAltMatch(state, SearchBitState)
def Search_AltMatch_PCRE(state: benchmark.State&):
    SearchAltMatch(state, SearchPCRE)
def Search_AltMatch_RE2(state: benchmark.State&):
    SearchAltMatch(state, SearchRE2)
BENCHMARK_RANGE(Search_AltMatch_DFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_AltMatch_NFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_AltMatch_OnePass, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_AltMatch_BitState, 8, 16 << 20).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_AltMatch_PCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_AltMatch_RE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def Search_AltMatch_CachedDFA(state: benchmark.State&):
    SearchAltMatch(state, SearchCachedDFA)
def Search_AltMatch_CachedNFA(state: benchmark.State&):
    SearchAltMatch(state, SearchCachedNFA)
def Search_AltMatch_CachedOnePass(state: benchmark.State&):
    SearchAltMatch(state, SearchCachedOnePass)
def Search_AltMatch_CachedBitState(state: benchmark.State&):
    SearchAltMatch(state, SearchCachedBitState)
def Search_AltMatch_CachedPCRE(state: benchmark.State&):
    SearchAltMatch(state, SearchCachedPCRE)
def Search_AltMatch_CachedRE2(state: benchmark.State&):
    SearchAltMatch(state, SearchCachedRE2)
BENCHMARK_RANGE(Search_AltMatch_CachedDFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_AltMatch_CachedNFA, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_AltMatch_CachedOnePass, 8, 16 << 20).ThreadRange(1, NumCPUs())
BENCHMARK_RANGE(Search_AltMatch_CachedBitState, 8, 16 << 20).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK_RANGE(Search_AltMatch_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(Search_AltMatch_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

def SearchDigits(state: benchmark.State&, search: SearchImpl):
    var s = StringPiece("650-253-0001")
    search(state, "([0-9]+)-([0-9]+)-([0-9]+)", s, Prog.kAnchored, True)
    state.SetItemsProcessed(state.iterations())

def Search_Digits_DFA(state: benchmark.State&):
    SearchDigits(state, SearchDFA)
def Search_Digits_NFA(state: benchmark.State&):
    SearchDigits(state, SearchNFA)
def Search_Digits_OnePass(state: benchmark.State&):
    SearchDigits(state, SearchOnePass)
def Search_Digits_PCRE(state: benchmark.State&):
    SearchDigits(state, SearchPCRE)
def Search_Digits_RE2(state: benchmark.State&):
    SearchDigits(state, SearchRE2)
def Search_Digits_BitState(state: benchmark.State&):
    SearchDigits(state, SearchBitState)
BENCHMARK(Search_Digits_DFA).ThreadRange(1, NumCPUs())
BENCHMARK(Search_Digits_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Search_Digits_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Search_Digits_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Search_Digits_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Search_Digits_BitState).ThreadRange(1, NumCPUs())

def Parse3Digits(state: benchmark.State&, parse3: ParseImpl):
    parse3(state, "([0-9]+)-([0-9]+)-([0-9]+)", "650-253-0001")
    state.SetItemsProcessed(state.iterations())

def Parse_Digits_NFA(state: benchmark.State&):
    Parse3Digits(state, Parse3NFA)
def Parse_Digits_OnePass(state: benchmark.State&):
    Parse3Digits(state, Parse3OnePass)
def Parse_Digits_PCRE(state: benchmark.State&):
    Parse3Digits(state, Parse3PCRE)
def Parse_Digits_RE2(state: benchmark.State&):
    Parse3Digits(state, Parse3RE2)
def Parse_Digits_Backtrack(state: benchmark.State&):
    Parse3Digits(state, Parse3Backtrack)
def Parse_Digits_BitState(state: benchmark.State&):
    Parse3Digits(state, Parse3BitState)
BENCHMARK(Parse_Digits_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_Digits_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Parse_Digits_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_Digits_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_Digits_Backtrack).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_Digits_BitState).ThreadRange(1, NumCPUs())

def Parse_CachedDigits_NFA(state: benchmark.State&):
    Parse3Digits(state, Parse3CachedNFA)
def Parse_CachedDigits_OnePass(state: benchmark.State&):
    Parse3Digits(state, Parse3CachedOnePass)
def Parse_CachedDigits_PCRE(state: benchmark.State&):
    Parse3Digits(state, Parse3CachedPCRE)
def Parse_CachedDigits_RE2(state: benchmark.State&):
    Parse3Digits(state, Parse3CachedRE2)
def Parse_CachedDigits_Backtrack(state: benchmark.State&):
    Parse3Digits(state, Parse3CachedBacktrack)
def Parse_CachedDigits_BitState(state: benchmark.State&):
    Parse3Digits(state, Parse3CachedBitState)
BENCHMARK(Parse_CachedDigits_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedDigits_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Parse_CachedDigits_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_CachedDigits_Backtrack).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedDigits_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedDigits_BitState).ThreadRange(1, NumCPUs())

def Parse3DigitDs(state: benchmark.State&, parse3: ParseImpl):
    parse3(state, "(\\d+)-(\\d+)-(\\d+)", "650-253-0001")
    state.SetItemsProcessed(state.iterations())

def Parse_DigitDs_NFA(state: benchmark.State&):
    Parse3DigitDs(state, Parse3NFA)
def Parse_DigitDs_OnePass(state: benchmark.State&):
    Parse3DigitDs(state, Parse3OnePass)
def Parse_DigitDs_PCRE(state: benchmark.State&):
    Parse3DigitDs(state, Parse3PCRE)
def Parse_DigitDs_RE2(state: benchmark.State&):
    Parse3DigitDs(state, Parse3RE2)
def Parse_DigitDs_Backtrack(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedBacktrack)
def Parse_DigitDs_BitState(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedBitState)
BENCHMARK(Parse_DigitDs_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_DigitDs_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Parse_DigitDs_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_DigitDs_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_DigitDs_Backtrack).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_DigitDs_BitState).ThreadRange(1, NumCPUs())

def Parse_CachedDigitDs_NFA(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedNFA)
def Parse_CachedDigitDs_OnePass(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedOnePass)
def Parse_CachedDigitDs_PCRE(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedPCRE)
def Parse_CachedDigitDs_RE2(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedRE2)
def Parse_CachedDigitDs_Backtrack(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedBacktrack)
def Parse_CachedDigitDs_BitState(state: benchmark.State&):
    Parse3DigitDs(state, Parse3CachedBitState)
BENCHMARK(Parse_CachedDigitDs_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedDigitDs_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Parse_CachedDigitDs_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_CachedDigitDs_Backtrack).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedDigitDs_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedDigitDs_BitState).ThreadRange(1, NumCPUs())

def Parse1Split(state: benchmark.State&, parse1: ParseImpl):
    parse1(state, "[0-9]+-(.*)", "650-253-0001")
    state.SetItemsProcessed(state.iterations())

def Parse_Split_NFA(state: benchmark.State&):
    Parse1Split(state, Parse1NFA)
def Parse_Split_OnePass(state: benchmark.State&):
    Parse1Split(state, Parse1OnePass)
def Parse_Split_PCRE(state: benchmark.State&):
    Parse1Split(state, Parse1PCRE)
def Parse_Split_RE2(state: benchmark.State&):
    Parse1Split(state, Parse1RE2)
def Parse_Split_BitState(state: benchmark.State&):
    Parse1Split(state, Parse1BitState)
BENCHMARK(Parse_Split_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_Split_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Parse_Split_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_Split_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_Split_BitState).ThreadRange(1, NumCPUs())

def Parse_CachedSplit_NFA(state: benchmark.State&):
    Parse1Split(state, Parse1CachedNFA)
def Parse_CachedSplit_OnePass(state: benchmark.State&):
    Parse1Split(state, Parse1CachedOnePass)
def Parse_CachedSplit_PCRE(state: benchmark.State&):
    Parse1Split(state, Parse1CachedPCRE)
def Parse_CachedSplit_RE2(state: benchmark.State&):
    Parse1Split(state, Parse1CachedRE2)
def Parse_CachedSplit_BitState(state: benchmark.State&):
    Parse1Split(state, Parse1CachedBitState)
BENCHMARK(Parse_CachedSplit_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedSplit_OnePass).ThreadRange(1, NumCPUs())
#ifdef USEPCRE
BENCHMARK(Parse_CachedSplit_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_CachedSplit_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedSplit_BitState).ThreadRange(1, NumCPUs())

def Parse1SplitHard(state: benchmark.State&, run: ParseImpl):
    run(state, "[0-9]+.(.*)", "650-253-0001")
    state.SetItemsProcessed(state.iterations())

def Parse_SplitHard_NFA(state: benchmark.State&):
    Parse1SplitHard(state, Parse1NFA)
def Parse_SplitHard_PCRE(state: benchmark.State&):
    Parse1SplitHard(state, Parse1PCRE)
def Parse_SplitHard_RE2(state: benchmark.State&):
    Parse1SplitHard(state, Parse1RE2)
def Parse_SplitHard_BitState(state: benchmark.State&):
    Parse1SplitHard(state, Parse1BitState)
#ifdef USEPCRE
BENCHMARK(Parse_SplitHard_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_SplitHard_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_SplitHard_BitState).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_SplitHard_NFA).ThreadRange(1, NumCPUs())

def Parse_CachedSplitHard_NFA(state: benchmark.State&):
    Parse1SplitHard(state, Parse1CachedNFA)
def Parse_CachedSplitHard_PCRE(state: benchmark.State&):
    Parse1SplitHard(state, Parse1CachedPCRE)
def Parse_CachedSplitHard_RE2(state: benchmark.State&):
    Parse1SplitHard(state, Parse1CachedRE2)
def Parse_CachedSplitHard_BitState(state: benchmark.State&):
    Parse1SplitHard(state, Parse1CachedBitState)
def Parse_CachedSplitHard_Backtrack(state: benchmark.State&):
    Parse1SplitHard(state, Parse1CachedBacktrack)
#ifdef USEPCRE
BENCHMARK(Parse_CachedSplitHard_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_CachedSplitHard_RE2).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedSplitHard_BitState).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedSplitHard_NFA).ThreadRange(1, NumCPUs())
BENCHMARK(Parse_CachedSplitHard_Backtrack).ThreadRange(1, NumCPUs())

def Parse1SplitBig1(state: benchmark.State&, run: ParseImpl):
    var s: String = ""
    s.append(100000, 'x')
    s.append("650-253-0001")
    run(state, "[0-9]+.(.*)", s)
    state.SetItemsProcessed(state.iterations())

def Parse_CachedSplitBig1_PCRE(state: benchmark.State&):
    Parse1SplitBig1(state, SearchParse1CachedPCRE)
def Parse_CachedSplitBig1_RE2(state: benchmark.State&):
    Parse1SplitBig1(state, SearchParse1CachedRE2)
#ifdef USEPCRE
BENCHMARK(Parse_CachedSplitBig1_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_CachedSplitBig1_RE2).ThreadRange(1, NumCPUs())

def Parse1SplitBig2(state: benchmark.State&, run: ParseImpl):
    var s: String = ""
    s.append("650-253-")
    s.append(100000, '0')
    run(state, "[0-9]+.(.*)", s)
    state.SetItemsProcessed(state.iterations())

def Parse_CachedSplitBig2_PCRE(state: benchmark.State&):
    Parse1SplitBig2(state, SearchParse1CachedPCRE)
def Parse_CachedSplitBig2_RE2(state: benchmark.State&):
    Parse1SplitBig2(state, SearchParse1CachedRE2)
#ifdef USEPCRE
BENCHMARK(Parse_CachedSplitBig2_PCRE).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(Parse_CachedSplitBig2_RE2).ThreadRange(1, NumCPUs())

def ParseRegexp(state: benchmark.State&, regexp: String):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        re.Decref()

def SimplifyRegexp(state: benchmark.State&, regexp: String):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var sre = re.Simplify()
        CHECK(sre)
        sre.Decref()
        re.Decref()

def NullWalkRegexp(state: benchmark.State&, regexp: String):
    var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
    CHECK(re)
    for _ in state:
        re.NullWalk()
    re.Decref()

def SimplifyCompileRegexp(state: benchmark.State&, regexp: String):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var sre = re.Simplify()
        CHECK(sre)
        var prog = sre.CompileToProg(0)
        CHECK(prog)
        delete prog
        sre.Decref()
        re.Decref()

def CompileRegexp(state: benchmark.State&, regexp: String):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        delete prog
        re.Decref()

def CompileToProg(state: benchmark.State&, regexp: String):
    var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
    CHECK(re)
    for _ in state:
        var prog = re.CompileToProg(0)
        CHECK(prog)
        delete prog
    re.Decref()

def CompileByteMap(state: benchmark.State&, regexp: String):
    var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
    CHECK(re)
    var prog = re.CompileToProg(0)
    CHECK(prog)
    for _ in state:
        prog.ComputeByteMap()
    delete prog
    re.Decref()

def CompilePCRE(state: benchmark.State&, regexp: String):
    for _ in state:
        var re = PCRE(regexp, PCRE.UTF8)
        CHECK_EQ(re.error(), "")

def CompileRE2(state: benchmark.State&, regexp: String):
    for _ in state:
        var re = RE2(regexp)
        CHECK_EQ(re.error(), "")

def RunBuild(state: benchmark.State&, regexp: String, run: fn(benchmark.State&, String)):
    run(state, regexp)
    state.SetItemsProcessed(state.iterations())

DEFINE_FLAG(String, "compile_regexp", "(.*)-(\\d+)-of-(\\d+)", "regexp for compile benchmarks")

def BM_PCRE_Compile(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), CompilePCRE)
def BM_Regexp_Parse(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), ParseRegexp)
def BM_Regexp_Simplify(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), SimplifyRegexp)
def BM_CompileToProg(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), CompileToProg)
def BM_CompileByteMap(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), CompileByteMap)
def BM_Regexp_Compile(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), CompileRegexp)
def BM_Regexp_SimplifyCompile(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), SimplifyCompileRegexp)
def BM_Regexp_NullWalk(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), NullWalkRegexp)
def BM_RE2_Compile(state: benchmark.State&):
    RunBuild(state, GetFlag(FLAGS_compile_regexp), CompileRE2)
#ifdef USEPCRE
BENCHMARK(BM_PCRE_Compile).ThreadRange(1, NumCPUs())
#endif
BENCHMARK(BM_Regexp_Parse).ThreadRange(1, NumCPUs())
BENCHMARK(BM_Regexp_Simplify).ThreadRange(1, NumCPUs())
BENCHMARK(BM_CompileToProg).ThreadRange(1, NumCPUs())
BENCHMARK(BM_CompileByteMap).ThreadRange(1, NumCPUs())
BENCHMARK(BM_Regexp_Compile).ThreadRange(1, NumCPUs())
BENCHMARK(BM_Regexp_SimplifyCompile).ThreadRange(1, NumCPUs())
BENCHMARK(BM_Regexp_NullWalk).ThreadRange(1, NumCPUs())
BENCHMARK(BM_RE2_Compile).ThreadRange(1, NumCPUs())

def SearchPhone(state: benchmark.State&, search: ParseImpl):
    var s = RandomText(state.range(0))
    s.append("(650) 253-0001")
    search(state, "(\\d{3}-|\\(\\d{3}\\)\\s+)(\\d{3}-\\d{4})", s)
    state.SetBytesProcessed(state.iterations() * state.range(0))

def SearchPhone_CachedPCRE(state: benchmark.State&):
    SearchPhone(state, SearchParse2CachedPCRE)

def SearchPhone_CachedRE2(state: benchmark.State&):
    SearchPhone(state, SearchParse2CachedRE2)

#ifdef USEPCRE
BENCHMARK_RANGE(SearchPhone_CachedPCRE, 8, 16 << 20).ThreadRange(1, NumCPUs())
#endif
BENCHMARK_RANGE(SearchPhone_CachedRE2, 8, 16 << 20).ThreadRange(1, NumCPUs())

/*
TODO(rsc): Make this work again.
void CacheFill(int iters, int n, SearchImpl *srch) {
  string s = DeBruijnString(n+1);
  string t;
  for (int i = n+1; i < 20; i++) {
    t = s + s;
    using swap;
    swap(s, t);
  }
  srch(iters, StringPrintf("0[01]{%d}$", n).c_str(), s,
       Prog::kUnanchored, true);
  SetBenchmarkBytesProcessed(static_cast<int64_t>(iters)*s.size());
}
void CacheFillPCRE(int i, int n) { CacheFill(i, n, SearchCachedPCRE); }
void CacheFillRE2(int i, int n)  { CacheFill(i, n, SearchCachedRE2); }
void CacheFillNFA(int i, int n)  { CacheFill(i, n, SearchCachedNFA); }
void CacheFillDFA(int i, int n)  { CacheFill(i, n, SearchCachedDFA); }
#define MY_BENCHMARK_WITH_ARG(n, a) \
  bool __benchmark_ ## n ## a =     \
    (new ::testing::Benchmark(#n, NewPermanentCallback(&n)))->ThreadRange(1, NumCPUs());
#define DO24(A, B) \
  A(B, 1);    A(B, 2);    A(B, 3);    A(B, 4);    A(B, 5);    A(B, 6);  \
  A(B, 7);    A(B, 8);    A(B, 9);    A(B, 10);   A(B, 11);   A(B, 12); \
  A(B, 13);   A(B, 14);   A(B, 15);   A(B, 16);   A(B, 17);   A(B, 18); \
  A(B, 19);   A(B, 20);   A(B, 21);   A(B, 22);   A(B, 23);   A(B, 24);
DO24(MY_BENCHMARK_WITH_ARG, CacheFillPCRE)
DO24(MY_BENCHMARK_WITH_ARG, CacheFillNFA)
DO24(MY_BENCHMARK_WITH_ARG, CacheFillRE2)
DO24(MY_BENCHMARK_WITH_ARG, CacheFillDFA)
#undef DO24
#undef MY_BENCHMARK_WITH_ARG
*/

def SearchDFA(state: benchmark.State&, regexp: String, text: StringPiece&,
             anchor: Prog.Anchor, expect_match: Bool):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        var failed: Bool = False
        CHECK_EQ(prog.SearchDFA(text, StringPiece(), anchor, Prog.kFirstMatch,
                               None, &failed, None),
                expect_match)
        CHECK(!failed)
        delete prog
        re.Decref()

def SearchNFA(state: benchmark.State&, regexp: String, text: StringPiece&,
             anchor: Prog.Anchor, expect_match: Bool):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        CHECK_EQ(prog.SearchNFA(text, StringPiece(), anchor, Prog.kFirstMatch,
                               None, 0),
                expect_match)
        delete prog
        re.Decref()

def SearchOnePass(state: benchmark.State&, regexp: String, text: StringPiece&,
                 anchor: Prog.Anchor, expect_match: Bool):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        CHECK(prog.IsOnePass())
        CHECK_EQ(prog.SearchOnePass(text, text, anchor, Prog.kFirstMatch, None, 0),
                expect_match)
        delete prog
        re.Decref()

def SearchBitState(state: benchmark.State&, regexp: String, text: StringPiece&,
                  anchor: Prog.Anchor, expect_match: Bool):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        CHECK(prog.CanBitState())
        CHECK_EQ(prog.SearchBitState(text, text, anchor, Prog.kFirstMatch, None, 0),
                expect_match)
        delete prog
        re.Decref()

def SearchPCRE(state: benchmark.State&, regexp: String, text: StringPiece&,
              anchor: Prog.Anchor, expect_match: Bool):
    for _ in state:
        var re = PCRE(regexp, PCRE.UTF8)
        CHECK_EQ(re.error(), "")
        if anchor == Prog.kAnchored:
            CHECK_EQ(PCRE.FullMatch(text, re), expect_match)
        else:
            CHECK_EQ(PCRE.PartialMatch(text, re), expect_match)

def SearchRE2(state: benchmark.State&, regexp: String, text: StringPiece&,
             anchor: Prog.Anchor, expect_match: Bool):
    for _ in state:
        var re = RE2(regexp)
        CHECK_EQ(re.error(), "")
        if anchor == Prog.kAnchored:
            CHECK_EQ(RE2.FullMatch(text, re), expect_match)
        else:
            CHECK_EQ(RE2.PartialMatch(text, re), expect_match)

def GetCachedProg(regexp: String) -> Prog:
    var mutex = Mutex()
    MutexLock(&mutex)
    var cache = Dict[String, Prog]()
    var prog = cache.get(regexp, None)
    if prog is None:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        prog = re.CompileToProg(Int64(1) << 31)  # mostly for the DFA
        CHECK(prog)
        cache[regexp] = prog
        re.Decref()
        prog.IsOnePass()
    return prog

def GetCachedPCRE(regexp: String) -> PCRE:
    var mutex = Mutex()
    MutexLock(&mutex)
    var cache = Dict[String, PCRE]()
    var re = cache.get(regexp, None)
    if re is None:
        re = PCRE(regexp, PCRE.UTF8)
        CHECK_EQ(re.error(), "")
        cache[regexp] = re
    return re

def GetCachedRE2(regexp: String) -> RE2:
    var mutex = Mutex()
    MutexLock(&mutex)
    var cache = Dict[String, RE2]()
    var re = cache.get(regexp, None)
    if re is None:
        re = RE2(regexp)
        CHECK_EQ(re.error(), "")
        cache[regexp] = re
    return re

def SearchCachedDFA(state: benchmark.State&, regexp: String, text: StringPiece&,
                   anchor: Prog.Anchor, expect_match: Bool):
    var prog = GetCachedProg(regexp)
    for _ in state:
        var failed: Bool = False
        CHECK_EQ(prog.SearchDFA(text, StringPiece(), anchor, Prog.kFirstMatch,
                               None, &failed, None),
                expect_match)
        CHECK(!failed)

def SearchCachedNFA(state: benchmark.State&, regexp: String, text: StringPiece&,
                   anchor: Prog.Anchor, expect_match: Bool):
    var prog = GetCachedProg(regexp)
    for _ in state:
        CHECK_EQ(prog.SearchNFA(text, StringPiece(), anchor, Prog.kFirstMatch,
                               None, 0),
                expect_match)

def SearchCachedOnePass(state: benchmark.State&, regexp: String, text: StringPiece&,
                       anchor: Prog.Anchor, expect_match: Bool):
    var prog = GetCachedProg(regexp)
    CHECK(prog.IsOnePass())
    for _ in state:
        CHECK_EQ(prog.SearchOnePass(text, text, anchor, Prog.kFirstMatch, None, 0),
                expect_match)

def SearchCachedBitState(state: benchmark.State&, regexp: String, text: StringPiece&,
                        anchor: Prog.Anchor, expect_match: Bool):
    var prog = GetCachedProg(regexp)
    CHECK(prog.CanBitState())
    for _ in state:
        CHECK_EQ(prog.SearchBitState(text, text, anchor, Prog.kFirstMatch, None, 0),
                expect_match)

def SearchCachedPCRE(state: benchmark.State&, regexp: String, text: StringPiece&,
                    anchor: Prog.Anchor, expect_match: Bool):
    var re = GetCachedPCRE(regexp)
    for _ in state:
        if anchor == Prog.kAnchored:
            CHECK_EQ(PCRE.FullMatch(text, re), expect_match)
        else:
            CHECK_EQ(PCRE.PartialMatch(text, re), expect_match)

def SearchCachedRE2(state: benchmark.State&, regexp: String, text: StringPiece&,
                   anchor: Prog.Anchor, expect_match: Bool):
    var re = GetCachedRE2(regexp)
    for _ in state:
        if anchor == Prog.kAnchored:
            CHECK_EQ(RE2.FullMatch(text, re), expect_match)
        else:
            CHECK_EQ(RE2.PartialMatch(text, re), expect_match)

def Parse3NFA(state: benchmark.State&, regexp: String, text: StringPiece&):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        var sp = StringPiece(4)  # 4 because sp[0] is whole match.
        CHECK(prog.SearchNFA(text, StringPiece(), Prog.kAnchored,
                            Prog.kFullMatch, sp, 4))
        delete prog
        re.Decref()

def Parse3OnePass(state: benchmark.State&, regexp: String, text: StringPiece&):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        CHECK(prog.IsOnePass())
        var sp = StringPiece(4)  # 4 because sp[0] is whole match.
        CHECK(prog.SearchOnePass(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))
        delete prog
        re.Decref()

def Parse3BitState(state: benchmark.State&, regexp: String, text: StringPiece&):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        CHECK(prog.CanBitState())
        var sp = StringPiece(4)  # 4 because sp[0] is whole match.
        CHECK(prog.SearchBitState(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))
        delete prog
        re.Decref()

def Parse3Backtrack(state: benchmark.State&, regexp: String, text: StringPiece&):
    for _ in state:
        var re = Regexp.Parse(regexp, Regexp.LikePerl, None)
        CHECK(re)
        var prog = re.CompileToProg(0)
        CHECK(prog)
        var sp = StringPiece(4)  # 4 because sp[0] is whole match.
        CHECK(prog.UnsafeSearchBacktrack(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))
        delete prog
        re.Decref()

def Parse3PCRE(state: benchmark.State&, regexp: String, text: StringPiece&):
    for _ in state:
        var re = PCRE(regexp, PCRE.UTF8)
        CHECK_EQ(re.error(), "")
        var sp1 = StringPiece()
        var sp2 = StringPiece()
        var sp3 = StringPiece()
        CHECK(PCRE.FullMatch(text, re, &sp1, &sp2, &sp3))

def Parse3RE2(state: benchmark.State&, regexp: String, text: StringPiece&):
    for _ in state:
        var re = RE2(regexp)
        CHECK_EQ(re.error(), "")
        var sp1 = StringPiece()
        var sp2 = StringPiece()
        var sp3 = StringPiece()
        CHECK(RE2.FullMatch(text, re, &sp1, &sp2, &sp3))

def Parse3CachedNFA(state: benchmark.State&, regexp: String, text: StringPiece&):
    var prog = GetCachedProg(regexp)
    var sp = StringPiece(4)  # 4 because sp[0] is whole match.
    for _ in state:
        CHECK(prog.SearchNFA(text, StringPiece(), Prog.kAnchored,
                            Prog.kFullMatch, sp, 4))

def Parse3CachedOnePass(state: benchmark.State&, regexp: String, text: StringPiece&):
    var prog = GetCachedProg(regexp)
    CHECK(prog.IsOnePass())
    var sp = StringPiece(4)  # 4 because sp[0] is whole match.
    for _ in state:
        CHECK(prog.SearchOnePass(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))

def Parse3CachedBitState(state: benchmark.State&, regexp: String, text: StringPiece&):
    var prog = GetCachedProg(regexp)
    CHECK(prog.CanBitState())
    var sp = StringPiece(4)  # 4 because sp[0] is whole match.
    for _ in state:
        CHECK(prog.SearchBitState(text, text, Prog.kAnchored, Prog.kFullMatch, sp, 4))

def Parse3CachedBacktrack(state: benchmark.State&, regexp: String, text: StringPiece&):
    var prog = GetCachedProg(regexp)
   