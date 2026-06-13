from memory import memset_zero
from os import system
from math import log2
from time import sleep
from sys import argv, exit
from utils import StringRef
from io import FileHandle
from random import shuffle
from algorithm import sort
from vector import DynamicVector
from string import String
from os.path import exists, unlink

# Simulate Eigen types and functions
struct MatrixXf:
    var rows: Int
    var cols: Int
    var data: DynamicVector[Float32]
    
    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = DynamicVector[Float32](size=rows*cols)
        memset_zero(self.data.data, rows*cols)
    
    @staticmethod
    def Zero(rows: Int, cols: Int) -> MatrixXf:
        return MatrixXf(rows, cols)
    
    def __getitem__(self, i: Int, j: Int) -> Float32:
        return self.data[i * self.cols + j]
    
    def __setitem__(inout self, i: Int, j: Int, val: Float32):
        self.data[i * self.cols + j] = val
    
    def noalias(self) -> Self:
        return self

def operator*(a: MatrixXf, b: MatrixXf) -> MatrixXf:
    # Simplified matrix multiplication for benchmarking
    var result = MatrixXf(a.rows, b.cols)
    for i in range(a.rows):
        for j in range(b.cols):
            var sum: Float32 = 0.0
            for k in range(a.cols):
                sum += a[i, k] * b[k, j]
            result[i, j] = sum
    return result

struct BenchTimer:
    def getCpuTime(self) -> Float64:
        return 0.0  # Simplified
    def getRealTime(self) -> Float64:
        return 0.0  # Simplified

var timer = BenchTimer()
const measurement_repetitions: Int = 3
const min_accurate_time: Float32 = 1e-2
var min_working_set_size: Int = 0
var max_clock_speed: Float32 = 0.0
const maxsize: Int = 2048
const minsize: Int = 16

typealias Scalar = Float32
typealias MatrixType = MatrixXf
typealias Packet = Float32  # Simplified

# Static assertions (compile-time checks in Mojo are limited)
# We'll keep them as comments
# static_assert((maxsize & (maxsize - 1)) == 0, "maxsize must be a power of two")
# static_assert((minsize & (minsize - 1)) == 0, "minsize must be a power of two")
# static_assert(maxsize > minsize, "maxsize must be larger than minsize")
# static_assert(maxsize < (minsize << 16), "maxsize must be less than (minsize<<16)")

struct size_triple_t:
    var k: Int
    var m: Int
    var n: Int
    
    def __init__(inout self):
        self.k = 0
        self.m = 0
        self.n = 0
    
    def __init__(inout self, _k: Int, _m: Int, _n: Int):
        self.k = _k
        self.m = _m
        self.n = _n
    
    def __init__(inout self, o: Self):
        self.k = o.k
        self.m = o.m
        self.n = o.n
    
    def __init__(inout self, compact: UInt16):
        self.k = 1 << ((compact & 0xf00) >> 8)
        self.m = 1 << ((compact & 0x0f0) >> 4)
        self.n = 1 << ((compact & 0x00f) >> 0)

def log2_pot(x: Int) -> UInt8:
    var l: UInt8 = 0
    var temp = x
    while temp >>= 1:
        l += 1
    return l

def compact_size_triple(k: Int, m: Int, n: Int) -> UInt16:
    return (UInt16(log2_pot(k)) << 8) | (UInt16(log2_pot(m)) << 4) | UInt16(log2_pot(n))

def compact_size_triple(t: size_triple_t) -> UInt16:
    return compact_size_triple(t.k, t.m, t.n)

struct benchmark_t:
    var compact_product_size: UInt16
    var compact_block_size: UInt16
    var use_default_block_size: Bool
    var gflops: Float32
    
    def __init__(inout self):
        self.compact_product_size = 0
        self.compact_block_size = 0
        self.use_default_block_size = False
        self.gflops = 0.0
    
    def __init__(inout self, pk: Int, pm: Int, pn: Int, bk: Int, bm: Int, bn: Int):
        self.compact_product_size = compact_size_triple(pk, pm, pn)
        self.compact_block_size = compact_size_triple(bk, bm, bn)
        self.use_default_block_size = False
        self.gflops = 0.0
    
    def __init__(inout self, pk: Int, pm: Int, pn: Int):
        self.compact_product_size = compact_size_triple(pk, pm, pn)
        self.compact_block_size = 0
        self.use_default_block_size = True
        self.gflops = 0.0
    
    def run(inout self):
        var productsizes = size_triple_t(self.compact_product_size)
        if self.use_default_block_size:
            eigen_use_specific_block_size = False
        else:
            eigen_use_specific_block_size = True
            var blocksizes = size_triple_t(self.compact_block_size)
            eigen_block_size_k = blocksizes.k
            eigen_block_size_m = blocksizes.m
            eigen_block_size_n = blocksizes.n
        
        const combined_three_matrices_sizes: Int = sizeof[Scalar]() * (
            productsizes.k * productsizes.m +
            productsizes.k * productsizes.n +
            productsizes.m * productsizes.n)
        const unlikely_large_cache_size: Int = 64 << 20
        const working_set_size: Int = min_working_set_size if min_working_set_size else unlikely_large_cache_size
        const matrix_pool_size: Int = 1 + working_set_size / combined_three_matrices_sizes
        
        var lhs = DynamicVector[MatrixType]()
        var rhs = DynamicVector[MatrixType]()
        var dst = DynamicVector[MatrixType]()
        for i in range(matrix_pool_size):
            lhs.push_back(MatrixType.Zero(productsizes.m, productsizes.k))
            rhs.push_back(MatrixType.Zero(productsizes.k, productsizes.n))
            dst.push_back(MatrixType.Zero(productsizes.m, productsizes.n))
        
        var iters_at_a_time: Int = 1
        var time_per_iter: Float32 = 0.0
        var matrix_index: Int = 0
        while True:
            var starttime = timer.getCpuTime()
            for i in range(iters_at_a_time):
                dst[matrix_index].noalias() = lhs[matrix_index] * rhs[matrix_index]
                matrix_index += 1
                if matrix_index == matrix_pool_size:
                    matrix_index = 0
            var endtime = timer.getCpuTime()
            var timing = Float32(endtime - starttime)
            if timing >= min_accurate_time:
                time_per_iter = timing / iters_at_a_time
                break
            iters_at_a_time *= 2
        
        # Cleanup (Mojo handles memory automatically)
        self.gflops = 2e-9 * productsizes.k * productsizes.m * productsizes.n / time_per_iter

def print_cpuinfo():
    # Simplified - no /proc/cpuinfo in Mojo
    print("CPU info not available in Mojo")

def type_name_float() -> String:
    return "float"

def type_name_double() -> String:
    return "double"

trait action_t:
    def invokation_name(self) -> String:
        return ""
    def run(self):

def show_usage_and_exit(argc: Int, argv: Pointer[String], available_actions: DynamicVector[action_t]):
    print("usage: " + argv[0] + " <action> [options...]", file=stderr)
    print("", file=stderr)
    print("available actions:", file=stderr)
    print("", file=stderr)
    for it in range(available_actions.size):
        print("  " + available_actions[it].invokation_name(), file=stderr)
    print("", file=stderr)
    print("options:", file=stderr)
    print("", file=stderr)
    print("  --min-working-set-size=N:", file=stderr)
    print("       Set the minimum working set size to N bytes.", file=stderr)
    print("       This is rounded up as needed to a multiple of matrix size.", file=stderr)
    print("       A larger working set lowers the chance of a warm cache.", file=stderr)
    print("       The default value 0 means use a large enough working", file=stderr)
    print("       set to likely outsize caches.", file=stderr)
    print("       A value of 1 (that is, 1 byte) would mean don't do anything to", file=stderr)
    print("       avoid warm caches.", file=stderr)
    exit(1)

def measure_clock_speed() -> Float32:
    print("Measuring clock speed...                              ", end="\r", file=stderr)
    var all_gflops = DynamicVector[Float32]()
    for i in range(8):
        var b = benchmark_t(1024, 1024, 1024)
        b.run()
        all_gflops.push_back(b.gflops)
    sort(all_gflops)
    var stable_estimate = all_gflops[2] + all_gflops[3] + all_gflops[4] + all_gflops[5]
    var result = stable_estimate * 123.456
    return result

struct human_duration_t:
    var seconds: Int
    
    def __init__(inout self, s: Int):
        self.seconds = s

def format_human_duration(d: human_duration_t) -> String:
    var result = String("")
    var remainder = d.seconds
    if remainder > 3600:
        var hours = remainder / 3600
        result += str(hours) + " h "
        remainder -= hours * 3600
    if remainder > 60:
        var minutes = remainder / 60
        result += str(minutes) + " min "
        remainder -= minutes * 60
    if d.seconds < 600:
        result += str(remainder) + " s"
    return result

const session_filename: String = "/data/local/tmp/benchmark-blocking-sizes-session.data"

def serialize_benchmarks(filename: String, benchmarks: DynamicVector[benchmark_t], first_benchmark_to_run: Int):
    var file = FileHandle(filename, "w")
    if not file:
        print("Could not open file " + filename + " for writing.", file=stderr)
        print("Do you have write permissions on the current working directory?", file=stderr)
        exit(1)
    var benchmarks_vector_size = benchmarks.size
    file.write(max_clock_speed)
    file.write(benchmarks_vector_size)
    file.write(first_benchmark_to_run)
    for i in range(benchmarks.size):
        file.write(benchmarks[i].compact_product_size)
        file.write(benchmarks[i].compact_block_size)
        file.write(benchmarks[i].use_default_block_size)
        file.write(benchmarks[i].gflops)
    file.close()

def deserialize_benchmarks(filename: String, benchmarks: DynamicVector[benchmark_t], first_benchmark_to_run: Int) -> Bool:
    if not exists(filename):
        return False
    var file = FileHandle(filename, "r")
    if not file:
        return False
    if file.read(max_clock_speed) != 1:
        return False
    var benchmarks_vector_size: Int = 0
    if file.read(benchmarks_vector_size) != 1:
        return False
    if file.read(first_benchmark_to_run) != 1:
        return False
    benchmarks.resize(benchmarks_vector_size)
    for i in range(benchmarks_vector_size):
        var compact_product_size: UInt16 = 0
        var compact_block_size: UInt16 = 0
        var use_default_block_size: Bool = False
        var gflops: Float32 = 0.0
        if file.read(compact_product_size) != 1:
            return False
        if file.read(compact_block_size) != 1:
            return False
        if file.read(use_default_block_size) != 1:
            return False
        if file.read(gflops) != 1:
            return False
        benchmarks[i].compact_product_size = compact_product_size
        benchmarks[i].compact_block_size = compact_block_size
        benchmarks[i].use_default_block_size = use_default_block_size
        benchmarks[i].gflops = gflops
    unlink(filename)
    return True

def try_run_some_benchmarks(benchmarks: DynamicVector[benchmark_t], time_start: Float64, first_benchmark_to_run: Int):
    if first_benchmark_to_run == benchmarks.size:
        return
    var time_last_progress_update: Float64 = 0.0
    var time_last_clock_speed_measurement: Float64 = 0.0
    var time_now: Float64 = 0.0
    var benchmark_index = first_benchmark_to_run
    while True:
        var ratio_done = Float32(benchmark_index) / benchmarks.size
        time_now = timer.getRealTime()
        if benchmark_index == benchmarks.size or time_now > time_last_clock_speed_measurement + 60.0:
            time_last_clock_speed_measurement = time_now
            var current_clock_speed = measure_clock_speed()
            const clock_speed_tolerance: Float32 = 0.02
            if current_clock_speed > (1 + clock_speed_tolerance) * max_clock_speed:
                if benchmark_index:
                    print("Restarting at " + str(100.0 * ratio_done) + " % because clock speed increased.          ", file=stderr)
                max_clock_speed = current_clock_speed
                first_benchmark_to_run = 0
                return
            var rerun_last_tests = False
            if current_clock_speed < (1 - clock_speed_tolerance) * max_clock_speed:
                print("Measurements completed so far: " + str(100.0 * ratio_done) + " %                             ", file=stderr)
                print("Clock speed seems to be only " + str(current_clock_speed/max_clock_speed) + " times what it used to be.", file=stderr)
                var seconds_to_sleep_if_lower_clock_speed: UInt32 = 1
                while current_clock_speed < (1 - clock_speed_tolerance) * max_clock_speed:
                    if seconds_to_sleep_if_lower_clock_speed > 32:
                        print("Sleeping longer probably won't make a difference.", file=stderr)
                        print("Serializing benchmarks to " + session_filename, file=stderr)
                        serialize_benchmarks(session_filename, benchmarks, first_benchmark_to_run)
                        print("Now restart this benchmark, and it should pick up where we left.", file=stderr)
                        exit(2)
                    rerun_last_tests = True
                    print("Sleeping " + str(seconds_to_sleep_if_lower_clock_speed) + " s...                                   \r", file=stderr)
                    sleep(seconds_to_sleep_if_lower_clock_speed)
                    current_clock_speed = measure_clock_speed()
                    seconds_to_sleep_if_lower_clock_speed *= 2
            if rerun_last_tests:
                print("Redoing the last " + str(100.0 * Float32(benchmark_index - first_benchmark_to_run) / benchmarks.size) + " % because clock speed had been low.   ", file=stderr)
                return
            first_benchmark_to_run = benchmark_index
        if benchmark_index == benchmarks.size:
            first_benchmark_to_run = benchmarks.size
            print("                                                            ", file=stderr)
            return
        if time_now > time_last_progress_update + 1.0:
            time_last_progress_update = time_now
            print("Measurements... " + str(100.0 * ratio_done) + " %, ETA " + format_human_duration(human_duration_t(Float32(time_now - time_start) * (1.0 - ratio_done) / ratio_done)) + "                          \r", end="", file=stderr)
        benchmarks[benchmark_index].run()
        benchmark_index += 1

def run_benchmarks(benchmarks: DynamicVector[benchmark_t]):
    var first_benchmark_to_run: Int = 0
    var deserialized_benchmarks = DynamicVector[benchmark_t]()
    var use_deserialized_benchmarks = False
    if deserialize_benchmarks(session_filename, deserialized_benchmarks, first_benchmark_to_run):
        print("Found serialized session with " + str(100.0 * first_benchmark_to_run / deserialized_benchmarks.size) + " % already done", file=stderr)
        if deserialized_benchmarks.size == benchmarks.size and first_benchmark_to_run > 0 and first_benchmark_to_run < benchmarks.size:
            use_deserialized_benchmarks = True
    if use_deserialized_benchmarks:
        benchmarks = deserialized_benchmarks
    else:
        first_benchmark_to_run = 0
        shuffle(benchmarks)
    for i in range(4):
        max_clock_speed = max(max_clock_speed, measure_clock_speed())
    var time_start: Float64 = 0.0
    while first_benchmark_to_run < benchmarks.size:
        if first_benchmark_to_run == 0:
            time_start = timer.getRealTime()
        try_run_some_benchmarks(benchmarks, time_start, first_benchmark_to_run)
    sort(benchmarks)
    var best_benchmarks = DynamicVector[benchmark_t]()
    for it in range(benchmarks.size):
        if best_benchmarks.size == 0 or best_benchmarks.back().compact_product_size != benchmarks[it].compact_product_size or best_benchmarks.back().compact_block_size != benchmarks[it].compact_block_size:
            best_benchmarks.push_back(benchmarks[it])
    benchmarks = best_benchmarks

struct measure_all_pot_sizes_action_t(action_t):
    def invokation_name(self) -> String:
        return "all-pot-sizes"
    def run(self):
        var benchmarks = DynamicVector[benchmark_t]()
        for repetition in range(measurement_repetitions):
            var ksize = minsize
            while ksize <= maxsize:
                var msize = minsize
                while msize <= maxsize:
                    var nsize = minsize
                    while nsize <= maxsize:
                        var kblock = minsize
                        while kblock <= ksize:
                            var mblock = minsize
                            while mblock <= msize:
                                var nblock = minsize
                                while nblock <= nsize:
                                    benchmarks.push_back(benchmark_t(ksize, msize, nsize, kblock, mblock, nblock))
                                    nblock *= 2
                                mblock *= 2
                            kblock *= 2
                        nsize *= 2
                    msize *= 2
                ksize *= 2
        run_benchmarks(benchmarks)
        print("BEGIN MEASUREMENTS ALL POT SIZES")
        for it in range(benchmarks.size):
            print(str(benchmarks[it].compact_product_size) + " " + str(benchmarks[it].compact_block_size) + " " + str(benchmarks[it].gflops))

struct measure_default_sizes_action_t(action_t):
    def invokation_name(self) -> String:
        return "default-sizes"
    def run(self):
        var benchmarks = DynamicVector[benchmark_t]()
        for repetition in range(measurement_repetitions):
            var ksize = minsize
            while ksize <= maxsize:
                var msize = minsize
                while msize <= maxsize:
                    var nsize = minsize
                    while nsize <= maxsize:
                        benchmarks.push_back(benchmark_t(ksize, msize, nsize))
                        nsize *= 2
                    msize *= 2
                ksize *= 2
        run_benchmarks(benchmarks)
        print("BEGIN MEASUREMENTS DEFAULT SIZES")
        for it in range(benchmarks.size):
            print(str(benchmarks[it].compact_product_size) + " " + str(benchmarks[it].gflops))

def main():
    var time_start = timer.getRealTime()
    var available_actions = DynamicVector[action_t]()
    available_actions.push_back(measure_all_pot_sizes_action_t())
    available_actions.push_back(measure_default_sizes_action_t())
    var action: Int = -1
    if len(argv) <= 1:
        show_usage_and_exit(len(argv), argv, available_actions)
    for it in range(available_actions.size):
        if argv[1] == available_actions[it].invokation_name():
            action = it
            break
    if action == -1:
        show_usage_and_exit(len(argv), argv, available_actions)
    for i in range(2, len(argv)):
        if argv[i].find("--min-working-set-size=") == 0:
            var equals_sign = argv[i].find("=")
            min_working_set_size = int(argv[i].substr(equals_sign+1))
        else:
            print("unrecognized option: " + argv[i], file=stderr)
            print("", file=stderr)
            show_usage_and_exit(len(argv), argv, available_actions)
    print_cpuinfo()
    print("benchmark parameters:")
    print("pointer size: " + str(8*sizeof[Pointer[None]]()) + " bits")
    print("scalar type: " + type_name_float())
    print("packet size: " + str(1))  # Simplified
    print("minsize = " + str(minsize))
    print("maxsize = " + str(maxsize))
    print("measurement_repetitions = " + str(measurement_repetitions))
    print("min_accurate_time = " + str(min_accurate_time))
    print("min_working_set_size = " + str(min_working_set_size), end="")
    if min_working_set_size == 0:
        print(" (try to outsize caches)", end="")
    print("")
    print("")
    available_actions[action].run()
    var time_end = timer.getRealTime()
    print("Finished in " + format_human_duration(human_duration_t(Int(time_end - time_start))), file=stderr)