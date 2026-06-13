# EIGEN_INTERNAL_DEBUG_CACHE_QUERY is defined (no effect in Mojo)
from ...Eigen.Core import internal
from ...Eigen.Core import EIGEN_CPUID  # Assumed function
from memory import Pointer
from lang import print

# DUMP_CPUID macro converted to function
def DUMP_CPUID[CODE: Int]():
    var abcd: Pointer[Int32] = Pointer[Int32].alloc(4)
    abcd[0] = 0
    abcd[1] = 0
    abcd[2] = 0
    abcd[3] = 0
    EIGEN_CPUID(abcd, CODE, 0)
    print("The code ", CODE, " gives ",
          Pointer[Int32](address=abcd[0]), " ",
          Pointer[Int32](address=abcd[1]), " ",
          Pointer[Int32](address=abcd[2]), " ",
          Pointer[Int32](address=abcd[3]), " ")
    abcd.free()

def main():
    print("Eigen's L1    = ", internal.queryL1CacheSize())
    print("Eigen's L2/L3 = ", internal.queryTopLevelCacheSize())
    var l1: Int32 = 0
    var l2: Int32 = 0
    var l3: Int32 = 0
    internal.queryCacheSizes(l1, l2, l3)
    print("Eigen's L1, L2, L3       = ", l1, " ", l2, " ", l3)
    # ifdef EIGEN_CPUID (assumed always defined in Mojo context)
    var abcd: Pointer[Int32] = Pointer[Int32].alloc(4)
    var string: Pointer[Int32] = Pointer[Int32].alloc(8)
    var string_char = Pointer[Int8](string)  # reinterpret cast
    EIGEN_CPUID(abcd, 0x0, 0)
    string[0] = abcd[1]
    string[1] = abcd[3]
    string[2] = abcd[2]
    string[3] = 0
    print()
    print("vendor id = ", string_char)
    print()
    var max_funcs: Int32 = abcd[0]
    internal.queryCacheSizes_intel_codes(l1, l2, l3)
    print("Eigen's intel codes L1, L2, L3 = ", l1, " ", l2, " ", l3)
    if max_funcs >= 4:
        internal.queryCacheSizes_intel_direct(l1, l2, l3)
        print("Eigen's intel direct L1, L2, L3 = ", l1, " ", l2, " ", l3)
    internal.queryCacheSizes_amd(l1, l2, l3)
    print("Eigen's amd L1, L2, L3         = ", l1, " ", l2, " ", l3)
    print()
    if max_funcs >= 4:
        l1 = 0
        l2 = 0
        l3 = 0
        var cache_id: Int32 = 0
        var cache_type: Int32 = 0
        do:
            abcd[0] = 0
            abcd[1] = 0
            abcd[2] = 0
            abcd[3] = 0
            EIGEN_CPUID(abcd, 0x4, cache_id)
            cache_type = (abcd[0] & 0x0F) >> 0
            var cache_level: Int32 = (abcd[0] & 0xE0) >> 5
            var ways: Int32 = (abcd[1] & 0xFFC00000) >> 22
            var partitions: Int32 = (abcd[1] & 0x003FF000) >> 12
            var line_size: Int32 = (abcd[1] & 0x00000FFF) >> 0
            var sets: Int32 = abcd[2]
            var cache_size: Int32 = (ways + 1) * (partitions + 1) * (line_size + 1) * (sets + 1)
            print("cache[", cache_id, "].type       = ", cache_type)
            print("cache[", cache_id, "].level      = ", cache_level)
            print("cache[", cache_id, "].ways       = ", ways)
            print("cache[", cache_id, "].partitions = ", partitions)
            print("cache[", cache_id, "].line_size  = ", line_size)
            print("cache[", cache_id, "].sets       = ", sets)
            print("cache[", cache_id, "].size       = ", cache_size)
            cache_id += 1
        while cache_type > 0 and cache_id < 16
    print()
    print("Raw dump:")
    for i in range(max_funcs):
        DUMP_CPUID[i]()
    DUMP_CPUID[0x80000000]()
    DUMP_CPUID[0x80000001]()
    DUMP_CPUID[0x80000002]()
    DUMP_CPUID[0x80000003]()
    DUMP_CPUID[0x80000004]()
    DUMP_CPUID[0x80000005]()
    DUMP_CPUID[0x80000006]()
    DUMP_CPUID[0x80000007]()
    DUMP_CPUID[0x80000008]()
    # else branch not needed (defined)
    abcd.free()
    string.free()