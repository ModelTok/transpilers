from Eigen.Core import *
from bench.BenchTimer import BenchTimer
from memory import aligned_alloc
from sys import print

const SIZE: Int = 50
const REPEAT: Int = 10000

type Scalar = Float32

@noinline
def benchVec(a: Pointer[Scalar], b: Pointer[Scalar], c: Pointer[Scalar], size: Int):

@noinline
def benchVec(a: MatrixXf, b: MatrixXf, c: MatrixXf):

@noinline
def benchVec(a: VectorXf, b: VectorXf, c: VectorXf):

def main() raises:
    var size: Int = SIZE * 8
    var size2: Int = size * size
    var a: Pointer[Scalar] = internal.aligned_new[Scalar](size2)
    var b: Pointer[Scalar] = internal.aligned_new[Scalar](size2 + 4) + 1
    var c: Pointer[Scalar] = internal.aligned_new[Scalar](size2)
    for i in range(size):
        a[i] = 0
        b[i] = 0
        c[i] = 0
    var timer: BenchTimer = BenchTimer()
    timer.reset()
    for k in range(10):
        timer.start()
        benchVec(a, b, c, size2)
        timer.stop()
    print(timer.value(), "s  ", (Float64(size2 * REPEAT) / timer.value()) / (1024.0 * 1024.0 * 1024.0), " GFlops")
    # unreachable code below (original C++ has return 0 before the loops)
    # we keep the dead code for faithfulness
    for innersize in range(size, 2, -1):
        if size2 % innersize == 0:
            var outersize: Int = size2 // innersize
            var ma: MatrixXf = Map[MatrixXf](a, innersize, outersize)
            var mb: MatrixXf = Map[MatrixXf](b, innersize, outersize)
            var mc: MatrixXf = Map[MatrixXf](c, innersize, outersize)
            timer.reset()
            for k in range(3):
                timer.start()
                benchVec(ma, mb, mc)
                timer.stop()
            print(innersize, " x ", outersize, "  ", timer.value(), "s   ", (Float64(size2 * REPEAT) / timer.value()) / (1024.0 * 1024.0 * 1024.0), " GFlops")
    var va: VectorXf = Map[VectorXf](a, size2)
    var vb: VectorXf = Map[VectorXf](b, size2)
    var vc: VectorXf = Map[VectorXf](c, size2)
    timer.reset()
    for k in range(3):
        timer.start()
        benchVec(va, vb, vc)
        timer.stop()
    print(timer.value(), "s   ", (Float64(size2 * REPEAT) / timer.value()) / (1024.0 * 1024.0 * 1024.0), " GFlops")
    # return 0 implicitly

def benchVec(a: MatrixXf, b: MatrixXf, c: MatrixXf):
    for k in range(REPEAT):
        a = a + b

def benchVec(a: VectorXf, b: VectorXf, c: VectorXf):
    for k in range(REPEAT):
        a = a + b

def benchVec(a: Pointer[Scalar], b: Pointer[Scalar], c: Pointer[Scalar], size: Int):
    alias PacketType = internal.packet_traits[Scalar].type
    alias PacketSize = internal.packet_traits[Scalar].size
    var a0: PacketType
    var a1: PacketType
    var a2: PacketType
    var a3: PacketType
    var b0: PacketType
    var b1: PacketType
    var b2: PacketType
    var b3: PacketType
    for k in range(REPEAT):
        for i in range(0, size, PacketSize * 8):
            internal.pstore[Pointer[Scalar]](&a[i + 2 * PacketSize], internal.padd(internal.ploadu[Pointer[Scalar]](&a[i + 2 * PacketSize]), internal.ploadu[Pointer[Scalar]](&b[i + 2 * PacketSize])))
            internal.pstore[Pointer[Scalar]](&a[i + 3 * PacketSize], internal.padd(internal.ploadu[Pointer[Scalar]](&a[i + 3 * PacketSize]), internal.ploadu[Pointer[Scalar]](&b[i + 3 * PacketSize])))
            internal.pstore[Pointer[Scalar]](&a[i + 4 * PacketSize], internal.padd(internal.ploadu[Pointer[Scalar]](&a[i + 4 * PacketSize]), internal.ploadu[Pointer[Scalar]](&b[i + 4 * PacketSize])))
            internal.pstore[Pointer[Scalar]](&a[i + 5 * PacketSize], internal.padd(internal.ploadu[Pointer[Scalar]](&a[i + 5 * PacketSize]), internal.ploadu[Pointer[Scalar]](&b[i + 5 * PacketSize])))
            internal.pstore[Pointer[Scalar]](&a[i + 6 * PacketSize], internal.padd(internal.ploadu[Pointer[Scalar]](&a[i + 6 * PacketSize]), internal.ploadu[Pointer[Scalar]](&b[i + 6 * PacketSize])))
            internal.pstore[Pointer[Scalar]](&a[i + 7 * PacketSize], internal.padd(internal.ploadu[Pointer[Scalar]](&a[i + 7 * PacketSize]), internal.ploadu[Pointer[Scalar]](&b[i + 7 * PacketSize])))