from time import monotonic_ns
from util.logging import CHECK
from util.util import ATTRIBUTE_UNUSED
from util.flags import *
from re2.re2 import RE2

from sys import stdout

# Declaration of global functions and classes from util/benchmark.h

def StartBenchmarkTiming():
    if t0 == 0:
        t0 = nsec()

def StopBenchmarkTiming():
    if t0 != 0:
        ns += nsec() - t0
        t0 = 0

def SetBenchmarkBytesProcessed(b: Int64):
    bytes = b

def SetBenchmarkItemsProcessed(i: Int64):
    items = i

@value
struct State:
    var iters_: Int64
    var arg_: Int64
    var has_arg_: Bool

    @value
    struct Iterator:
        struct Value:

        var iters_: Int64

        def __ne__(self, that: Self) -> Bool:
            if self.iters_ != that.iters_:
                return True
            else:
                StopBenchmarkTiming()
                return False

        def __getitem__(self) -> Value:
            return Value()

        def __add__(self) -> Self:
            self.iters_ -= 1
            return self

    def __init__(self, iters: Int64):
        self.iters_ = iters
        self.arg_ = 0
        self.has_arg_ = False

    def __init__(self, iters: Int64, arg: Int64):
        self.iters_ = iters
        self.arg_ = arg
        self.has_arg_ = True

    def begin(self) -> Iterator:
        StartBenchmarkTiming()
        return Iterator(self.iters_)

    def end(self) -> Iterator:
        return Iterator(0)

    def SetBytesProcessed(self, b: Int64):
        SetBenchmarkBytesProcessed(b)

    def SetItemsProcessed(self, i: Int64):
        SetBenchmarkItemsProcessed(i)

    def iterations(self) -> Int64:
        return self.iters_

    def range(self, pos: Int) -> Int64:
        CHECK(self.has_arg_)
        return self.arg_

@value
struct Benchmark:
    var name_: String
    var func_: fn(Int, Int) -> None
    var lo_: Int
    var hi_: Int
    var has_arg_: Bool

    def __init__(self, name: String, func: fn(State ref)):
        self.name_ = name
        self.func_ = fn(iters: Int, arg: Int) {
            var state = State(iters)
            func(state)
        }
        self.lo_ = 0
        self.hi_ = 0
        self.has_arg_ = False
        self.Register()

    def __init__(self, name: String, func: fn(State ref), lo: Int, hi: Int):
        self.name_ = name
        self.func_ = fn(iters: Int, arg: Int) {
            var state = State(iters, arg)
            func(state)
        }
        self.lo_ = lo
        self.hi_ = hi
        self.has_arg_ = True
        self.Register()

    def ThreadRange(self, lo: Int, hi: Int) -> Self:
        return self

    def name(self) -> String:
        return self.name_

    def func(self) -> fn(Int, Int) -> None:
        return self.func_

    def lo(self) -> Int:
        return self.lo_

    def hi(self) -> Int:
        return self.hi_

    def has_arg(self) -> Bool:
        return self.has_arg_

    def Register(self):
        self.lo_ = max(1, self.lo_)
        self.hi_ = max(self.lo_, self.hi_)
        benchmarks.append(Pointer.address_of(self))

# Macro definitions (not used directly in this file, but kept for compatibility)
# BENCHMARK(f) ::testing::Benchmark* _benchmark_##f = (new ::testing::Benchmark(#f, f))
# BENCHMARK_RANGE(f, lo, hi) ::testing::Benchmark* _benchmark_##f = (new ::testing::Benchmark(#f, f, lo, hi))

# Global variables from benchmark.cc
var benchmarks = List[Pointer[Benchmark]]()
var nbenchmarks: Int = 0

var t0: Int64 = 0
var ns: Int64 = 0
var bytes: Int64 = 0
var items: Int64 = 0

def nsec() -> Int64:
    return monotonic_ns()

def RunFunc(b: Pointer[Benchmark], iters: Int, arg: Int):
    t0 = nsec()
    ns = 0
    bytes = 0
    items = 0
    (b[]).func()(iters, arg)
    StopBenchmarkTiming()

def round(n: Int) -> Int:
    var base = 1
    while base * 10 < n:
        base *= 10
    if n < 2 * base:
        return 2 * base
    if n < 5 * base:
        return 5 * base
    return 10 * base

def RunBench(b: Pointer[Benchmark], arg: Int):
    var iters: Int, last: Int
    iters = 1
    RunFunc(b, iters, arg)
    while ns < 1000000000 and iters < 1000000000:
        last = iters
        if ns / iters == 0:
            iters = 1000000000
        else:
            iters = 1000000000 / Int(ns / iters)
        iters = max(last + 1, min(iters + iters / 2, 100 * last))
        iters = round(iters)
        RunFunc(b, iters, arg)
    var mb = String("")
    var suf = String("")
    if ns > 0 and bytes > 0:
        mb = f"\t{((Float64(bytes) / 1e6) / (Float64(ns) / 1e9)):7.2f} MB/s"
    if (b[]).has_arg():
        if arg >= (1 << 20):
            suf = f"/{arg / (1 << 20)}M"
        elif arg >= (1 << 10):
            suf = f"/{arg / (1 << 10)}K"
        else:
            suf = f"/{arg}"
    print(f"{ (b[]).name() }{suf}\t{iters:8d}\t{Int64(ns / iters):10lld} ns/op{mb}")
    stdout.flush()

def WantBench(name: String, argc: Int, argv: Pointer[Pointer[UInt8]]) -> Bool:
    if argc == 1:
        return True
    for i in range(1, argc):
        if RE2.PartialMatch(name, argv[i]):
            return True
    return False

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    for i in range(nbenchmarks):
        var b = benchmarks[i]
        if not WantBench((b[]).name(), argc, argv):
            continue
        var arg = (b[]).lo()
        while arg <= (b[]).hi():
            RunBench(b, arg)
            arg <<= 1
    return 0