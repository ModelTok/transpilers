from python import print
from math import log2
from bench.BenchUtil import BenchTimer
from complex import Complex
from vector import DynamicVector
from Eigen.Core import NumTraits
from unsupported.Eigen.FFT import FFT

alias TYPE = Float32
alias NFFT = 1024
alias NDATA = 1000000
alias LongDouble = Float64

def nameof[T: AnyType]() -> String:
    @parameter
    if T == Float32:
        return "float"
    elif T == Float64:
        return "double"
    elif T == LongDouble:
        return "long double"
    else:
        return "unknown"

def bench[T: AnyType](nfft: Int, fwd: Bool, unscaled: Bool = False, halfspec: Bool = False):
    alias Scalar = NumTraits[T].Real
    alias ComplexType = Complex[Scalar]
    var nits = NDATA // nfft
    var inbuf = DynamicVector[T](nfft)
    var outbuf = DynamicVector[ComplexType](nfft)
    var fft = FFT[Scalar]()
    if unscaled:
        fft.SetFlag(fft.Unscaled)
        print("unscaled ", end="")
    if halfspec:
        fft.SetFlag(fft.HalfSpectrum)
        print("halfspec ", end="")
    inbuf.fill(0)
    fft.fwd(outbuf, inbuf)
    var timer = BenchTimer()
    timer.reset()
    for k in range(8):
        timer.start()
        if fwd:
            for i in range(nits):
                fft.fwd(outbuf, inbuf)
        else:
            for i in range(nits):
                fft.inv(inbuf, outbuf)
        timer.stop()
    var out_str = nameof[Scalar]() + " "
    var mflops = 5.0 * Float64(nfft) * log2(Float64(nfft)) / (1e6 * timer.value() / Float64(nits))
    if NumTraits[T].IsComplex:
        out_str += "complex"
    else:
        out_str += "real   "
        mflops /= 2.0
    if fwd:
        out_str += " fwd"
    else:
        out_str += " inv"
    out_str += " NFFT=" + str(nfft) + "  " + str(Float64(1e-6 * nfft * nits) / timer.value()) + " MS/s  " + str(mflops) + "MFLOPS"
    print(out_str)

def main():
    bench[Complex[Float32]](NFFT, True)
    bench[Complex[Float32]](NFFT, False)
    bench[Float32](NFFT, True)
    bench[Float32](NFFT, False)
    bench[Float32](NFFT, False, True)
    bench[Float32](NFFT, False, True, True)
    bench[Complex[Float64]](NFFT, True)
    bench[Complex[Float64]](NFFT, False)
    bench[Float64](NFFT, True)
    bench[Float64](NFFT, False)
    bench[Complex[LongDouble]](NFFT, True)
    bench[Complex[LongDouble]](NFFT, False)
    bench[LongDouble](NFFT, True)
    bench[LongDouble](NFFT, False)