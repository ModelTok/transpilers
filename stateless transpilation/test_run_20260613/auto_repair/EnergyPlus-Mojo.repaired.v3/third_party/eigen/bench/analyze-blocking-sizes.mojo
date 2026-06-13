from memory import memset_zero
from math import isfinite
from os import exit
from sys import argv, stderr, stdout
from utils import StringRef
from vector import DynamicVector, StaticVector

def log2_pot(x: size_t) -> uint8_t:
    var l: size_t = 0
    var x_copy = x
    while x_copy >>= 1:
        l += 1
    return l

def compact_size_triple(k: size_t, m: size_t, n: size_t) -> uint16_t:
    return (log2_pot(k) << 8) | (log2_pot(m) << 4) | log2_pot(n)

struct size_triple_t:
    var k: uint16_t
    var m: uint16_t
    var n: uint16_t

    def __init__(inout self):
        self.k = 0
        self.m = 0
        self.n = 0

    def __init__(inout self, _k: size_t, _m: size_t, _n: size_t):
        self.k = _k
        self.m = _m
        self.n = _n

    def __init__(inout self, o: Self):
        self.k = o.k
        self.m = o.m
        self.n = o.n

    def __init__(inout self, compact: uint16_t):
        self.k = 1 << ((compact & 0xf00) >> 8)
        self.m = 1 << ((compact & 0x0f0) >> 4)
        self.n = 1 << ((compact & 0x00f) >> 0)

    def is_cubic(self) -> bool:
        return self.k == self.m and self.m == self.n

def print_size_triple_t(s: StringRef, t: size_triple_t):
    print(s, "(", t.k, ", ", t.m, ", ", t.n, ")")

struct inputfile_entry_t:
    var product_size: uint16_t
    var pot_block_size: uint16_t
    var nonpot_block_size: size_triple_t
    var gflops: float32

struct inputfile_t:
    enum type_t:
        unknown = 0
        all_pot_sizes = 1
        default_sizes = 2

    var filename: StringRef
    var entries: DynamicVector[inputfile_entry_t]
    var type: type_t

    def __init__(inout self, fname: StringRef):
        self.filename = fname
        self.type = type_t.unknown
        var stream = open(fname, "r")
        if not stream:
            print("couldn't open input file: ", fname, file=stderr)
            exit(1)
        var line: StringRef
        while stream.read_line(line):
            if len(line) == 0:
                continue
            if line.find("BEGIN MEASUREMENTS ALL POT SIZES") == 0:
                if self.type != type_t.unknown:
                    print("Input file ", fname, " contains redundant BEGIN MEASUREMENTS lines", file=stderr)
                    exit(1)
                self.type = type_t.all_pot_sizes
                continue
            if line.find("BEGIN MEASUREMENTS DEFAULT SIZES") == 0:
                if self.type != type_t.unknown:
                    print("Input file ", fname, " contains redundant BEGIN MEASUREMENTS lines", file=stderr)
                    exit(1)
                self.type = type_t.default_sizes
                continue
            if self.type == type_t.unknown:
                continue
            if self.type == type_t.all_pot_sizes:
                var product_size: uint32 = 0
                var block_size: uint32 = 0
                var gflops: float32 = 0.0
                var sscanf_result = sscanf(line, "%x %x %f", product_size, block_size, gflops)
                if sscanf_result != 3 or product_size == 0 or product_size > 0xfff or block_size == 0 or block_size > 0xfff or not isfinite(gflops):
                    print("ill-formed input file: ", fname, file=stderr)
                    print("offending line:", file=stderr)
                    print(line, file=stderr)
                    exit(1)
                if only_cubic_sizes and not size_triple_t(product_size).is_cubic():
                    continue
                var entry = inputfile_entry_t()
                entry.product_size = uint16_t(product_size)
                entry.pot_block_size = uint16_t(block_size)
                entry.gflops = gflops
                self.entries.push_back(entry)
            elif self.type == type_t.default_sizes:
                var product_size: uint32 = 0
                var gflops: float32 = 0.0
                var bk: int32 = 0
                var bm: int32 = 0
                var bn: int32 = 0
                var sscanf_result = sscanf(line, "%x default(%d, %d, %d) %f", product_size, bk, bm, bn, gflops)
                if sscanf_result != 5 or product_size == 0 or product_size > 0xfff or not isfinite(gflops):
                    print("ill-formed input file: ", fname, file=stderr)
                    print("offending line:", file=stderr)
                    print(line, file=stderr)
                    exit(1)
                if only_cubic_sizes and not size_triple_t(product_size).is_cubic():
                    continue
                var entry = inputfile_entry_t()
                entry.product_size = uint16_t(product_size)
                entry.pot_block_size = 0
                entry.nonpot_block_size = size_triple_t(bk, bm, bn)
                entry.gflops = gflops
                self.entries.push_back(entry)
        stream.close()
        if self.type == type_t.unknown:
            print("Unrecognized input file ", fname, file=stderr)
            exit(1)
        if len(self.entries) == 0:
            print("didn't find any measurements in input file: ", fname, file=stderr)
            exit(1)

struct preprocessed_inputfile_entry_t:
    var product_size: uint16_t
    var block_size: uint16_t
    var efficiency: float32

def lower_efficiency(e1: preprocessed_inputfile_entry_t, e2: preprocessed_inputfile_entry_t) -> bool:
    return e1.efficiency < e2.efficiency

struct preprocessed_inputfile_t:
    var filename: StringRef
    var entries: DynamicVector[preprocessed_inputfile_entry_t]

    def __init__(inout self, inputfile: inputfile_t):
        self.filename = inputfile.filename
        if inputfile.type != inputfile_t.type_t.all_pot_sizes:
            abort()
        var it = inputfile.entries.begin()
        var it_first_with_given_product_size = it
        while it != inputfile.entries.end():
            it += 1
            if it == inputfile.entries.end() or it[].product_size != it_first_with_given_product_size[].product_size:
                self.import_input_file_range_one_product_size(it_first_with_given_product_size, it)
                it_first_with_given_product_size = it

    def import_input_file_range_one_product_size(inout self, begin: DynamicVector[inputfile_entry_t].Iterator, end: DynamicVector[inputfile_entry_t].Iterator):
        var product_size = begin[].product_size
        var max_gflops: float32 = 0.0
        var it = begin
        while it != end:
            if it[].product_size != product_size:
                print("Unexpected ordering of entries in ", self.filename, file=stderr)
                print("(Expected all entries for product size ", hex(product_size), dec, " to be grouped)", file=stderr)
                exit(1)
            max_gflops = max(max_gflops, it[].gflops)
            it += 1
        it = begin
        while it != end:
            var entry = preprocessed_inputfile_entry_t()
            entry.product_size = it[].product_size
            entry.block_size = it[].pot_block_size
            entry.efficiency = it[].gflops / max_gflops
            self.entries.push_back(entry)
            it += 1

def check_all_files_in_same_exact_order(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t]):
    if len(preprocessed_inputfiles) == 0:
        return
    var first_file = preprocessed_inputfiles[0]
    var num_entries = len(first_file.entries)
    for i in range(len(preprocessed_inputfiles)):
        if len(preprocessed_inputfiles[i].entries) != num_entries:
            print("these files have different number of entries: ", preprocessed_inputfiles[i].filename, " and ", first_file.filename, file=stderr)
            exit(1)
    for entry_index in range(num_entries):
        var entry_product_size = first_file.entries[entry_index].product_size
        var entry_block_size = first_file.entries[entry_index].block_size
        for file_index in range(len(preprocessed_inputfiles)):
            var cur_file = preprocessed_inputfiles[file_index]
            if cur_file.entries[entry_index].product_size != entry_product_size or cur_file.entries[entry_index].block_size != entry_block_size:
                print("entries not in same order between these files: ", first_file.filename, " and ", cur_file.filename, file=stderr)
                exit(1)

def efficiency_of_subset(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t], subset: DynamicVector[size_t]) -> float32:
    if len(subset) <= 1:
        return 1.0
    var first_file = preprocessed_inputfiles[subset[0]]
    var num_entries = len(first_file.entries)
    var efficiency: float32 = 1.0
    var entry_index: size_t = 0
    var first_entry_index_with_this_product_size: size_t = 0
    var product_size = first_file.entries[0].product_size
    while entry_index < num_entries:
        entry_index += 1
        if entry_index == num_entries or first_file.entries[entry_index].product_size != product_size:
            var efficiency_this_product_size: float32 = 0.0
            for e in range(first_entry_index_with_this_product_size, entry_index):
                var efficiency_this_entry: float32 = 1.0
                for i in range(len(subset)):
                    efficiency_this_entry = min(efficiency_this_entry, preprocessed_inputfiles[subset[i]].entries[e].efficiency)
                efficiency_this_product_size = max(efficiency_this_product_size, efficiency_this_entry)
            efficiency = min(efficiency, efficiency_this_product_size)
            if entry_index < num_entries:
                first_entry_index_with_this_product_size = entry_index
                product_size = first_file.entries[entry_index].product_size
    return efficiency

def dump_table_for_subset(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t], subset: DynamicVector[size_t]):
    var first_file = preprocessed_inputfiles[subset[0]]
    var num_entries = len(first_file.entries)
    var entry_index: size_t = 0
    var first_entry_index_with_this_product_size: size_t = 0
    var product_size = first_file.entries[0].product_size
    var i: size_t = 0
    var min_product_size = size_triple_t(first_file.entries.front().product_size)
    var max_product_size = size_triple_t(first_file.entries.back().product_size)
    if not min_product_size.is_cubic() or not max_product_size.is_cubic():
        abort()
    if only_cubic_sizes:
        print("Can't generate tables with --only-cubic-sizes.", file=stderr)
        abort()
    print("struct LookupTable {")
    print("  static size_t BaseSize = ", min_product_size.k, ";")
    var NumSizes = log2_pot(max_product_size.k / min_product_size.k) + 1
    var TableSize = NumSizes * NumSizes * NumSizes
    print("  static size_t NumSizes = ", NumSizes, ";")
    print("  static const unsigned short* Data() {")
    print("    static const unsigned short data[", TableSize, "] = {")
    while entry_index < num_entries:
        entry_index += 1
        if entry_index == num_entries or first_file.entries[entry_index].product_size != product_size:
            var best_efficiency_this_product_size: float32 = 0.0
            var best_block_size_this_product_size: uint16_t = 0
            for e in range(first_entry_index_with_this_product_size, entry_index):
                var efficiency_this_entry: float32 = 1.0
                for j in range(len(subset)):
                    efficiency_this_entry = min(efficiency_this_entry, preprocessed_inputfiles[subset[j]].entries[e].efficiency)
                if efficiency_this_entry > best_efficiency_this_product_size:
                    best_efficiency_this_product_size = efficiency_this_entry
                    best_block_size_this_product_size = first_file.entries[e].block_size
            if (i % NumSizes) != 0:
                print(" ", end="")
            else:
                print()
                print("      ", end="")
            print("0x", hex(best_block_size_this_product_size), dec, end="")
            if entry_index < num_entries:
                print(",", end="")
                first_entry_index_with_this_product_size = entry_index
                product_size = first_file.entries[entry_index].product_size
            i += 1
    if i != TableSize:
        print()
        print("Wrote ", i, " table entries, expected ", TableSize, file=stderr)
        abort()
    print()
    print("    };")
    print("    return data;")
    print("  }")
    print("};")

def efficiency_of_partition(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t], partition: DynamicVector[DynamicVector[size_t]]) -> float32:
    var efficiency: float32 = 1.0
    for s in range(len(partition)):
        efficiency = min(efficiency, efficiency_of_subset(preprocessed_inputfiles, partition[s]))
    return efficiency

def make_first_subset(subset_size: size_t, out_subset: DynamicVector[size_t], set_size: size_t):
    assert(subset_size >= 1 and subset_size <= set_size)
    out_subset.resize(subset_size)
    for i in range(subset_size):
        out_subset[i] = i

def is_last_subset(subset: DynamicVector[size_t], set_size: size_t) -> bool:
    return subset[0] == set_size - len(subset)

def next_subset(inout_subset: DynamicVector[size_t], set_size: size_t):
    if is_last_subset(inout_subset, set_size):
        print("iterating past the last subset", file=stderr)
        abort()
    var i: size_t = 1
    while inout_subset[len(inout_subset) - i] == set_size - i:
        i += 1
        assert(i <= len(inout_subset))
    var first_index_to_change = len(inout_subset) - i
    inout_subset[first_index_to_change] += 1
    var p = inout_subset[first_index_to_change]
    for j in range(first_index_to_change + 1, len(inout_subset)):
        inout_subset[j] = p + 1
        p += 1

var number_of_subsets_limit: size_t = 100
var always_search_subsets_of_size_at_least: size_t = 2

def is_number_of_subsets_feasible(n: size_t, p: size_t) -> bool:
    assert(n > 0 and p > 0 and p <= n)
    var numerator: uint64 = 1
    var denominator: uint64 = 1
    for i in range(p):
        numerator *= n - i
        denominator *= i + 1
        if numerator > denominator * number_of_subsets_limit:
            return False
    return True

def max_feasible_subset_size(n: size_t) -> size_t:
    assert(n > 0)
    var minresult = min(n - 1, always_search_subsets_of_size_at_least)
    for p in range(1, n):
        if not is_number_of_subsets_feasible(n, p + 1):
            return max(p, minresult)
    return n - 1

def find_subset_with_efficiency_higher_than(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t], required_efficiency_to_beat: float32, inout_remainder: DynamicVector[size_t], out_subset: DynamicVector[size_t]):
    out_subset.resize(0)
    if required_efficiency_to_beat >= 1.0:
        print("can't beat efficiency 1.", file=stderr)
        abort()
    while len(inout_remainder) > 0:
        var candidate_indices = DynamicVector[size_t](len(inout_remainder))
        for i in range(len(candidate_indices)):
            candidate_indices[i] = i
        var candidate_indices_subset_size = max_feasible_subset_size(len(candidate_indices))
        while candidate_indices_subset_size >= 1:
            var candidate_indices_subset = DynamicVector[size_t]()
            make_first_subset(candidate_indices_subset_size, candidate_indices_subset, len(candidate_indices))
            var best_candidate_indices_subset = DynamicVector[size_t]()
            var best_efficiency: float32 = 0.0
            var trial_subset = DynamicVector[size_t](len(out_subset) + candidate_indices_subset_size)
            for k in range(len(out_subset)):
                trial_subset[k] = out_subset[k]
            while True:
                for k in range(candidate_indices_subset_size):
                    trial_subset[len(out_subset) + k] = inout_remainder[candidate_indices_subset[k]]
                var trial_efficiency = efficiency_of_subset(preprocessed_inputfiles, trial_subset)
                if trial_efficiency > best_efficiency:
                    best_efficiency = trial_efficiency
                    best_candidate_indices_subset = DynamicVector[size_t](candidate_indices_subset)
                if is_last_subset(candidate_indices_subset, len(candidate_indices)):
                    break
                next_subset(candidate_indices_subset, len(candidate_indices))
            if best_efficiency > required_efficiency_to_beat:
                var new_candidate_indices = DynamicVector[size_t](len(best_candidate_indices_subset))
                for k in range(len(best_candidate_indices_subset)):
                    new_candidate_indices[k] = candidate_indices[best_candidate_indices_subset[k]]
                candidate_indices = new_candidate_indices
            candidate_indices_subset_size -= 1
        var candidate_index = candidate_indices[0]
        var trial_subset2 = DynamicVector[size_t](len(out_subset) + 1)
        for k in range(len(out_subset)):
            trial_subset2[k] = out_subset[k]
        trial_subset2[len(out_subset)] = inout_remainder[candidate_index]
        var trial_efficiency2 = efficiency_of_subset(preprocessed_inputfiles, trial_subset2)
        if trial_efficiency2 > required_efficiency_to_beat:
            out_subset.push_back(inout_remainder[candidate_index])
            inout_remainder.erase(candidate_index)
        else:
            break

def find_partition_with_efficiency_higher_than(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t], required_efficiency_to_beat: float32, out_partition: DynamicVector[DynamicVector[size_t]]):
    out_partition.resize(0)
    var remainder = DynamicVector[size_t]()
    for i in range(len(preprocessed_inputfiles)):
        remainder.push_back(i)
    while len(remainder) > 0:
        var new_subset = DynamicVector[size_t]()
        find_subset_with_efficiency_higher_than(preprocessed_inputfiles, required_efficiency_to_beat, remainder, new_subset)
        out_partition.push_back(new_subset)

def print_partition(preprocessed_inputfiles: DynamicVector[preprocessed_inputfile_t], partition: DynamicVector[DynamicVector[size_t]]):
    var efficiency = efficiency_of_partition(preprocessed_inputfiles, partition)
    print("Partition into ", len(partition), " subsets for ", efficiency * 100.0, "% efficiency")
    for subset_idx in range(len(partition)):
        print("  Subset ", subset_idx, ", efficiency ", efficiency_of_subset(preprocessed_inputfiles, partition[subset_idx]) * 100.0, "%:")
        for file_idx in range(len(partition[subset_idx])):
            print("    ", preprocessed_inputfiles[partition[subset_idx][file_idx]].filename)
        if dump_tables:
            print("  Table:")
            dump_table_for_subset(preprocessed_inputfiles, partition[subset_idx])
    print()

struct action_t:
    def invokation_name(self) -> StringRef:
        abort()
        return ""
    def run(self, input_filenames: DynamicVector[StringRef]):
        abort()
    def __del__(self):

struct partition_action_t(action_t):
    def invokation_name(self) -> StringRef:
        return "partition"
    def run(self, input_filenames: DynamicVector[StringRef]):
        var preprocessed_inputfiles = DynamicVector[preprocessed_inputfile_t]()
        if len(input_filenames) == 0:
            print("The ", self.invokation_name(), " action needs a list of input files.", file=stderr)
            exit(1)
        for it in range(len(input_filenames)):
            var inputfile = inputfile_t(input_filenames[it])
            if inputfile.type == inputfile_t.type_t.all_pot_sizes:
                preprocessed_inputfiles.push_back(preprocessed_inputfile_t(inputfile))
            elif inputfile.type == inputfile_t.type_t.default_sizes:
                print("The ", self.invokation_name(), " action only uses measurements for all pot sizes, and has no use for ", input_filenames[it], " which contains measurements for default sizes.", file=stderr)
                exit(1)
            else:
                print("Unrecognized input file: ", input_filenames[it], file=stderr)
                exit(1)
        check_all_files_in_same_exact_order(preprocessed_inputfiles)
        var required_efficiency_to_beat: float32 = 0.0
        var partitions = DynamicVector[DynamicVector[DynamicVector[size_t]]]()
        print("searching for partitions...\r", end="", file=stderr)
        while True:
            var partition = DynamicVector[DynamicVector[size_t]]()
            find_partition_with_efficiency_higher_than(preprocessed_inputfiles, required_efficiency_to_beat, partition)
            var actual_efficiency = efficiency_of_partition(preprocessed_inputfiles, partition)
            print("partition ", len(preprocessed_inputfiles), " files into ", len(partition), " subsets for ", 100.0 * actual_efficiency, " % efficiency                  \r", end="", file=stderr)
            partitions.push_back(partition)
            if len(partition) == len(preprocessed_inputfiles) or actual_efficiency == 1.0:
                break
            required_efficiency_to_beat = actual_efficiency
        print("                                                                  ", file=stderr)
        while True:
            var repeat = False
            for i in range(len(partitions) - 1):
                if len(partitions[i]) >= len(partitions[i + 1]):
                    partitions.erase(i)
                    repeat = True
                    break
            if not repeat:
                break
        for it in range(len(partitions)):
            print_partition(preprocessed_inputfiles, partitions[it])

struct evaluate_defaults_action_t(action_t):
    struct results_entry_t:
        var product_size: uint16_t
        var default_block_size: size_triple_t
        var best_pot_block_size: uint16_t
        var default_gflops: float32
        var best_pot_gflops: float32
        var default_efficiency: float32

    def print_results_entry(s: StringRef, entry: results_entry_t):
        print(s, "Product size ", size_triple_t(entry.product_size), ": default block size ", entry.default_block_size, " -> ", entry.default_gflops, " GFlop/s = ", entry.default_efficiency * 100.0, " % of best POT block size ", size_triple_t(entry.best_pot_block_size), " -> ", entry.best_pot_gflops, " GFlop/s")

    def lower_efficiency_static(e1: results_entry_t, e2: results_entry_t) -> bool:
        return e1.default_efficiency < e2.default_efficiency

    def invokation_name(self) -> StringRef:
        return "evaluate-defaults"

    def show_usage_and_exit(self):
        print("usage: ", self.invokation_name(), " default-sizes-data all-pot-sizes-data", file=stderr)
        print("checks how well the performance with default sizes compares to the best performance measured over all POT sizes.", file=stderr)
        exit(1)

    def run(self, input_filenames: DynamicVector[StringRef]):
        if len(input_filenames) != 2:
            self.show_usage_and_exit()
        var inputfile_default_sizes = inputfile_t(input_filenames[0])
        var inputfile_all_pot_sizes = inputfile_t(input_filenames[1])
        if inputfile_default_sizes.type != inputfile_t.type_t.default_sizes:
            print(inputfile_default_sizes.filename, " is not an input file with default sizes.", file=stderr)
            self.show_usage_and_exit()
        if inputfile_all_pot_sizes.type != inputfile_t.type_t.all_pot_sizes:
            print(inputfile_all_pot_sizes.filename, " is not an input file with all POT sizes.", file=stderr)
            self.show_usage_and_exit()
        var results = DynamicVector[results_entry_t]()
        var cubic_results = DynamicVector[results_entry_t]()
        var product_size: uint16_t = 0
        var it_all_pot_sizes = inputfile_all_pot_sizes.entries.begin()
        for it_default_sizes in range(len(inputfile_default_sizes.entries)):
            if inputfile_default_sizes.entries[it_default_sizes].product_size == product_size:
                continue
            product_size = inputfile_default_sizes.entries[it_default_sizes].product_size
            while it_all_pot_sizes != inputfile_all_pot_sizes.entries.end() and it_all_pot_sizes[].product_size != product_size:
                it_all_pot_sizes += 1
            if it_all_pot_sizes == inputfile_all_pot_sizes.entries.end():
                break
            var best_pot_block_size: uint16_t = 0
            var best_pot_gflops: float32 = 0.0
            var it = it_all_pot_sizes
            while it != inputfile_all_pot_sizes.entries.end() and it[].product_size == product_size:
                if it[].gflops > best_pot_gflops:
                    best_pot_gflops = it[].gflops
                    best_pot_block_size = it[].pot_block_size
                it += 1
            var entry = results_entry_t()
            entry.product_size = product_size
            entry.default_block_size = inputfile_default_sizes.entries[it_default_sizes].nonpot_block_size
            entry.best_pot_block_size = best_pot_block_size
            entry.default_gflops = inputfile_default_sizes.entries[it_default_sizes].gflops
            entry.best_pot_gflops = best_pot_gflops
            entry.default_efficiency = entry.default_gflops / entry.best_pot_gflops
            results.push_back(entry)
            var t = size_triple_t(product_size)
            if t.k == t.m and t.m == t.n:
                cubic_results.push_back(entry)
        print("All results:")
        for it in range(len(results)):
            self.print_results_entry("", results[it])
        print()
        sort(results, self.lower_efficiency_static)
        var n = min[uint64](20, len(results))
        print(n, " worst results:")
        for i in range(n):
            self.print_results_entry("", results[i])
        print()
        print("cubic results:")
        for it in range(len(cubic_results)):
            self.print_results_entry("", cubic_results[it])
        print()
        sort(cubic_results, self.lower_efficiency_static)
        print_precision(2)
        var a = DynamicVector[float32]([0.5, 0.20, 0.10, 0.05, 0.02, 0.01])
        for it in range(len(a)):
            var n2 = min(len(results) - 1, uint64(a[it] * len(results)))
            print(100.0 * n2 / (len(results) - 1), " % of product sizes have default efficiency <= ", 100.0 * results[n2].default_efficiency, " %")
        print_precision(default_precision)

def show_usage_and_exit(argc: int32, argv: DynamicVector[StringRef], available_actions: DynamicVector[action_t]):
    print("usage: ", argv[0], " <action> [options...] <input files...>", file=stderr)
    print("available actions:", file=stderr)
    for it in range(len(available_actions)):
        print("  ", available_actions[it].invokation_name(), file=stderr)
    print("the input files should each contain an output of benchmark-blocking-sizes", file=stderr)
    exit(1)

var default_precision: int32 = 4
var only_cubic_sizes: bool = False
var dump_tables: bool = False

def main():
    print_precision(default_precision)
    print_precision(default_precision, file=stderr)
    var available_actions = DynamicVector[action_t]()
    available_actions.push_back(partition_action_t())
    available_actions.push_back(evaluate_defaults_action_t())
    var input_filenames = DynamicVector[StringRef]()
    var action: action_t = None
    if len(argv) < 2:
        show_usage_and_exit(len(argv), argv, available_actions)
    for i in range(1, len(argv)):
        var arg_handled = False
        for it in range(len(available_actions)):
            if argv[i] == available_actions[it].invokation_name():
                if action is None:
                    action = available_actions[it]
                    arg_handled = True
                    break
                else:
                    print("can't specify more than one action!", file=stderr)
                    show_usage_and_exit(len(argv), argv, available_actions)
        if arg_handled:
            continue
        if argv[i][0] == '-':
            if argv[i] == "--only-cubic-sizes":
                only_cubic_sizes = True
                arg_handled = True
            if argv[i] == "--dump-tables":
                dump_tables = True
                arg_handled = True
            if not arg_handled:
                print("Unrecognized option: ", argv[i], file=stderr)
                show_usage_and_exit(len(argv), argv, available_actions)
        if arg_handled:
            continue
        input_filenames.push_back(argv[i])
    if dump_tables and only_cubic_sizes:
        print("Incompatible options: --only-cubic-sizes and --dump-tables.", file=stderr)
        show_usage_and_exit(len(argv), argv, available_actions)
    if action is None:
        show_usage_and_exit(len(argv), argv, available_actions)
    action.run(input_filenames)