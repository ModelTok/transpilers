// #define NOGMM
// #define NOMTL
// #include <map>
// #include <ext/hash_map>
// #include <google/dense_hash_map>
// #include <google/sparse_hash_map>
#ifndef SIZE
alias SIZE = 10000
#endif
#ifndef DENSITY
alias DENSITY = 0.01
#endif
#ifndef REPEAT
alias REPEAT = 1
#endif
// #include "BenchSparseUtil.h"
from BenchSparseUtil import EigenSparseMatrix, RandomSetter, StdMapTraits, GnuHashMapTraits, GoogleDenseHashMapTraits, GoogleSparseHashMapTraits, BenchTimer
import internal
#ifndef MINDENSITY
alias MINDENSITY = 0.0004
#endif
#ifndef NBTRIES
alias NBTRIES = 10
#endif
// #define BENCH(X) \
//   timer.reset(); \
//   for (int _j=0; _j<NBTRIES; ++_j) { \
//     timer.start(); \
//     for (int _k=0; _k<REPEAT; ++_k) { \
//         X  \
//   } timer.stop(); }
def BENCH(X: fn()):
    var timer = BenchTimer()
    timer.reset()
    for _j in range(NBTRIES):
        timer.start()
        for _k in range(REPEAT):
            X()
        timer.stop()
var rtime: Float64
var nentries: Float64

def dostuff[SetterType: AnyType](name: String, inout sm1: EigenSparseMatrix):
    var rows = sm1.rows()
    var cols = sm1.cols()
    sm1.setZero()
    var t = BenchTimer()
    var set1 = new SetterType(sm1)
    t.reset()
    t.start()
    for k in range(int(nentries)):
        (*set1)(internal.random[int](0, rows-1), internal.random[int](0, cols-1)) += 1
    t.stop()
    print(f"map =>      \t{t.value() - rtime} nnz={set1.nonZeros()}", end='', flush=True)
    t.reset()
    t.start()
    delete set1
    t.stop()
    print(f"  back: \t{t.value()}")

def main() -> Int32:
    var rows = SIZE
    var cols = SIZE
    var density = DENSITY
    var sm1 = EigenSparseMatrix(rows, cols)
    var sm2 = EigenSparseMatrix(rows, cols)
    nentries = Float64(rows) * Float64(cols) * density
    print("n = ", nentries)
    var dummy: Int32
    var t = BenchTimer()
    t.reset()
    t.start()
    for k in range(int(nentries)):
        dummy = internal.random[int](0, rows-1) + internal.random[int](0, cols-1)
    t.stop()
    rtime = t.value()
    print(f"rtime = {rtime} ({dummy})")
    print()
    const Bits = 6
    while True:
        dostuff[RandomSetter[EigenSparseMatrix, StdMapTraits, Bits]]("map     ", sm1)
        dostuff[RandomSetter[EigenSparseMatrix, GnuHashMapTraits, Bits]]("gnu::hash_map", sm1)
        dostuff[RandomSetter[EigenSparseMatrix, GoogleDenseHashMapTraits, Bits]]("google::dense", sm1)
        dostuff[RandomSetter[EigenSparseMatrix, GoogleSparseHashMapTraits, Bits]]("google::sparse", sm1)
        print()
        print()
    return 0