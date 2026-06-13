# Copyright (C) 2012 The Android Open Source Project
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from time import monotonic_clock
from regex import Regex, RegexError
from sys import exit, stdout, stderr
from builtins import print

static var g_flops_processed: Int64 = 0
static var g_benchmark_total_time_ns: Int64 = 0
static var g_benchmark_start_time_ns: Int64 = 0

# typedef map<string, ::testing::Benchmark*> BenchmarkMap;
# typedef BenchmarkMap::iterator BenchmarkMapIt;

# BenchmarkMap& gBenchmarks() {
#   static BenchmarkMap g_benchmarks;
#   return g_benchmarks;
# }
static def gBenchmarks() -> Dict[String, Benchmark]:
    static var g_benchmarks: Dict[String, Benchmark] = Dict[String, Benchmark]()
    return g_benchmarks
# }

static var g_name_column_width: Int = 20

static def Round(n: Int) -> Int:
    var base: Int = 1
    while base * 10 < n:
        base *= 10
    # }
    if n < 2 * base:
        return 2 * base
    # }
    if n < 5 * base:
        return 5 * base
    # }
    return 10 * base
# }

# #ifdef __APPLE__
#   #include <mach/mach_time.h>
#   static mach_timebase_info_data_t g_time_info;
#   static void __attribute__((constructor)) init_info() {
#     mach_timebase_info(&g_time_info);
#   }
# #endif

static def NanoTime() -> Int64:
# #if defined(__APPLE__)
#   uint64_t t = mach_absolute_time();
#   return t * g_time_info.numer / g_time_info.denom;
# #else
#   struct timespec t;
#   t.tv_sec = t.tv_nsec = 0;
#   clock_gettime(CLOCK_MONOTONIC, &t);
    return monotonic_clock()
#   #endif
# }

# namespace testing {
struct Benchmark:
    var name_: String
    var fn_: Optional[fn(Int) -> None]
    var fn_range_: Optional[fn(Int, Int) -> None]
    var args_: List[Int]

    # Benchmark* Arg(int arg) {
    def Arg[mut self](arg: Int) -> Self:
        self.args_.append(arg)
        return self
    # }

    # Benchmark* Range(int lo, int hi) {
    def Range[mut self](lo: Int, hi: Int) -> Self:
        var kRangeMultiplier: Int = 8
        var lo_mut: Int = lo
        var hi_mut: Int = hi
        if hi_mut < lo_mut:
            var temp: Int = hi_mut
            hi_mut = lo_mut
            lo_mut = temp
        # }
        while lo_mut < hi_mut:
            self.args_.append(lo_mut)
            lo_mut *= kRangeMultiplier
        # }
        self.args_.append(hi_mut)
        return self
    # }

    # const char* Name() {
    def Name(self) -> String:
        return self.name_
    # }

    # bool ShouldRun(int argc, char* argv[]) {
    def ShouldRun(self, argc: Int, argv: List[String]) -> Bool:
        if argc == 1:
            return True  # With no arguments, we run all benchmarks.
        # }
        for i in range(1, argc):
            var re: Regex
            try:
                re = Regex(argv[i])
            except e:
                print("couldn't compile \"", argv[i], "\" as a regular expression!", file=stderr)
                exit(1)
            # }
            var match: Bool = re.match(self.name_) is not None
            if match:
                return True
            # }
        # }
        return False
    # }

    # void Register(char* name , void (*fn)(int), void (*fn_range)(int, int)) {
    def Register[mut self](name: String, fn_: Optional[fn(Int) -> None], fn_range_: Optional[fn(Int, Int) -> None]):
        self.name_ = name
        self.fn_ = fn_
        self.fn_range_ = fn_range_
        if (self.fn_ is None) and (self.fn_range_ is None):
            print(self.name_, ": missing function", file=stderr)
            exit(1)
        # }
        gBenchmarks()[name] = self
    # }

    # void Run() {
    def Run[mut self]():
        if self.fn_ is not None:
            self.RunWithArg(0)
        else:
            if self.args_.size() == 0:
                print(self.name_, ": no args!", file=stderr)
                exit(1)
            # }
            for i in range(self.args_.size()):
                self.RunWithArg(self.args_[i])
            # }
        # }
    # }

    # void RunRepeatedlyWithArg(int iterations, int arg) {
    def RunRepeatedlyWithArg[mut self](iterations: Int, arg: Int):
        g_flops_processed = 0
        g_benchmark_total_time_ns = 0
        g_benchmark_start_time_ns = NanoTime()
        if self.fn_ is not None:
            # fn_(iterations)
            (self.fn_.value())(iterations)
        else:
            # fn_range_(iterations, arg)
            (self.fn_range_.value())(iterations, arg)
        # }
        if g_benchmark_start_time_ns != 0:
            g_benchmark_total_time_ns += NanoTime() - g_benchmark_start_time_ns
        # }
    # }

    # void RunWithArg(int arg) {
    def RunWithArg[mut self](arg: Int):
        var iterations: Int = 1
        self.RunRepeatedlyWithArg(iterations, arg)
        while (g_benchmark_total_time_ns < 1e9) and (iterations < 1e9):
            var last: Int = iterations
            if g_benchmark_total_time_ns / iterations == 0:
                iterations = 1e9
            else:
                iterations = 1e9 / (g_benchmark_total_time_ns / iterations)
            # }
            iterations = max(last + 1, min(iterations + iterations / 2, 100 * last))
            iterations = Round(iterations)
            self.RunRepeatedlyWithArg(iterations, arg)
        # }
        var throughput: String = String()
        if (g_benchmark_total_time_ns > 0) and (g_flops_processed > 0):
            var mflops_processed: Float64 = Float64(g_flops_processed) / 1e6
            var seconds: Float64 = Float64(g_benchmark_total_time_ns) / 1e9
            # snprintf(throughput, sizeof(throughput), " %8.2f MFlops/s", mflops_processed/seconds);
            throughput = " " + format("{:8.2f} MFlops/s", mflops_processed / seconds)
        # }
        var full_name: String = String()
        if self.fn_range_ is not None:
            if arg >= (1 << 20):
                full_name = self.name_ + "/" + str(arg / (1 << 20)) + "M"
            elif arg >= (1 << 10):
                full_name = self.name_ + "/" + str(arg / (1 << 10)) + "K"
            else:
                full_name = self.name_ + "/" + str(arg)
            # }
        else:
            full_name = self.name_
        # }
        print(format("{:<{}} {:>10} {:>10}{}", full_name, g_name_column_width,
                    iterations, g_benchmark_total_time_ns / iterations, throughput))
        stdout.flush()
    # }
# }  // namespace testing

# void SetBenchmarkFlopsProcessed(int64_t x) {
def SetBenchmarkFlopsProcessed(x: Int64):
    g_flops_processed = x
# }

# void StopBenchmarkTiming() {
def StopBenchmarkTiming():
    if g_benchmark_start_time_ns != 0:
        g_benchmark_total_time_ns += NanoTime() - g_benchmark_start_time_ns
    # }
    g_benchmark_start_time_ns = 0
# }

# void StartBenchmarkTiming() {
def StartBenchmarkTiming():
    if g_benchmark_start_time_ns == 0:
        g_benchmark_start_time_ns = NanoTime()
    # }
# }

# int main(int argc, char* argv[]) {
def main():
    var argc: Int = len(sys.argv())
    var argv: List[String] = sys.argv()
    if gBenchmarks().size() == 0:
        print("No benchmarks registered!", file=stderr)
        exit(1)
    # }
    # for (BenchmarkMapIt it = gBenchmarks().begin(); it != gBenchmarks().end(); ++it) {
    for it in gBenchmarks().items():
        var name_width: Int = len(it.value().Name())
        g_name_column_width = max(g_name_column_width, name_width)
    # }
    var need_header: Bool = True
    # for (BenchmarkMapIt it = gBenchmarks().begin(); it != gBenchmarks().end(); ++it) {
    for it in gBenchmarks().items():
        var b: Benchmark = it.value()
        if b.ShouldRun(argc, argv):
            if need_header:
                print(format("{:<{}} {:>10} {:>10}", "", g_name_column_width, "iterations", "ns/op"))
                stdout.flush()
                need_header = False
            # }
            b.Run()
        # }
    # }
    if need_header:
        print("No matching benchmarks!", file=stderr)
        print("Available benchmarks:", file=stderr)
        # for (BenchmarkMapIt it = gBenchmarks().begin(); it != gBenchmarks().end(); ++it) {
        for it in gBenchmarks().items():
            print("  ", it.value().Name(), file=stderr)
        # }
        exit(1)
    # }
    return
# }