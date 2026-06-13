from DType import DType
from Pointer import Pointer
from IO import print
from Math import abs
from Time import perf_counter
from Random import randint
from Memory import memset
from SIMD import SIMD

alias Scalar = Float64

def bench_reverse[MatrixType: AnyType](m: MatrixType):
    let rows = m.rows()
    let cols = m.cols()
    let size = m.size()
    let repeats = (100000 * 1000) // size
    var a = MatrixType.random(rows, cols)
    var b = MatrixType.random(rows, cols)
    var timerB = BenchTimer()
    var timerH = BenchTimer()
    var timerV = BenchTimer()
    var acc: Scalar = 0
    let r = randint(0, rows - 1)
    let c = randint(0, cols - 1)
    for t in range(20):
        timerB.start()
        for k in range(repeats):
            asm("#begin foo")
            b = a.reverse()
            asm("#end foo")
            acc += b.coeff(r, c)
        timerB.stop()
    if MatrixType.RowsAtCompileTime == Dynamic:
        print("dyn   ", end="")
    else:
        print("fixed ", end="")
    print(rows, " x ", cols, " \t", (timerB.value() * 100000) / repeats, "s ", "(", 1e-6 * size * repeats / timerB.value(), " MFLOPS)\t", end="")
    print("\n", end="")
    if acc == 123:
        print(acc)

def main() raises:
    let dynsizes = StaticIntTuple[12](4, 6, 8, 16, 24, 32, 49, 64, 128, 256, 512, 900, 0)
    print("size            no sqrt                           standard")
    print("\n", end="")
    for i in range(12):
        if dynsizes[i] > 0:
            bench_reverse[Matrix[Scalar, Dynamic, Dynamic]](dynsizes[i], dynsizes[i])
            bench_reverse[Matrix[Scalar, Dynamic, 1]](dynsizes[i] * dynsizes[i])
    return 0