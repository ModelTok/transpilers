from main import main, CALL_SUBTEST, test_precision, VERIFY
from unsupported.Eigen.FFT import FFT
from math import acos, exp, sqrt
from complex import Complex, complex
from random import random
from memory import Pointer
from utils import Vector, Matrix, numext

def RandomCpx[T: DType]() -> Complex[scalar_of[T]]:
    return Complex[scalar_of[T]](
        (scalar_of[T])(random() / (scalar_of[T])(RAND_MAX) - 0.5),
        (scalar_of[T])(random() / (scalar_of[T])(RAND_MAX) - 0.5)
    )

def promote[T: DType](x: Complex[scalar_of[T]]) -> Complex[float64]:
    return Complex[float64]((float64)(x.real()), (float64)(x.imag()))

def promote(x: float32) -> Complex[float64]:
    return Complex[float64]((float64)(x))

def promote(x: float64) -> Complex[float64]:
    return Complex[float64]((float64)(x))

def promote(x: float128) -> Complex[float64]:
    return Complex[float64]((float64)(x))

def fft_rmse[VT1: Collection, VT2: Collection](fftbuf: VT1, timebuf: VT2) -> float64:
    var totalpower: float64 = 0.0
    var difpower: float64 = 0.0
    var pi: float64 = acos((float64)(-1))
    for k0 in range(fftbuf.size):
        var acc: Complex[float64] = 0
        var phinc: float64 = (float64)(-2.0) * k0 * pi / timebuf.size
        for k1 in range(timebuf.size):
            acc += promote(timebuf[k1]) * exp(Complex[float64](0, k1 * phinc))
        totalpower += numext.abs2(acc)
        var x: Complex[float64] = promote(fftbuf[k0])
        var dif: Complex[float64] = acc - x
        difpower += numext.abs2(dif)
    print("rmse:", sqrt(difpower / totalpower))
    return sqrt(difpower / totalpower)

def dif_rmse[VT1: Collection, VT2: Collection](buf1: VT1, buf2: VT2) -> float64:
    var totalpower: float64 = 0.0
    var difpower: float64 = 0.0
    var n: Int = min(buf1.size, buf2.size)
    for k in range(n):
        totalpower += (float64)((numext.abs2(buf1[k]) + numext.abs2(buf2[k])) / 2)
        difpower += (float64)(numext.abs2(buf1[k] - buf2[k]))
    return sqrt(difpower / totalpower)

enum Container:
    StdVectorContainer = 0
    EigenVectorContainer = 1

@value
struct VectorType[Container: Int, Scalar: DType]:

@value
struct VectorType[Container: Int, Scalar: DType] where Container == 0:
    type = Vector[Scalar]

@value
struct VectorType[Container: Int, Scalar: DType] where Container == 1:
    type = Matrix[Scalar, Dynamic, 1]

def test_scalar_generic[Container: Int, T: DType](nfft: Int):
    alias Complex = FFT[T].Complex
    alias Scalar = FFT[T].Scalar
    alias ScalarVector = VectorType[Container, Scalar].type
    alias ComplexVector = VectorType[Container, Complex].type
    var fft: FFT[T] = FFT[T]()
    var tbuf: ScalarVector = ScalarVector(nfft)
    var freqBuf: ComplexVector = ComplexVector()
    for k in range(nfft):
        tbuf[k] = (T)(random() / (float64)(RAND_MAX) - 0.5)
    fft.SetFlag(fft.HalfSpectrum)
    fft.fwd(freqBuf, tbuf)
    VERIFY(freqBuf.size == ((nfft >> 1) + 1))
    VERIFY(T(fft_rmse(freqBuf, tbuf)) < test_precision[T]())
    fft.ClearFlag(fft.HalfSpectrum)
    fft.fwd(freqBuf, tbuf)
    VERIFY(freqBuf.size == nfft)
    VERIFY(T(fft_rmse(freqBuf, tbuf)) < test_precision[T]())
    if nfft & 1:
        return
    var tbuf2: ScalarVector = ScalarVector()
    fft.inv(tbuf2, freqBuf)
    VERIFY(T(dif_rmse(tbuf, tbuf2)) < test_precision[T]())
    var tbuf3: ScalarVector = ScalarVector()
    fft.SetFlag(fft.Unscaled)
    fft.inv(tbuf3, freqBuf)
    for k in range(nfft):
        tbuf3[k] *= T(1.0 / nfft)
    VERIFY(T(dif_rmse(tbuf, tbuf3)) < test_precision[T]())
    fft.ClearFlag(fft.Unscaled)
    fft.inv(tbuf2, freqBuf)
    VERIFY(T(dif_rmse(tbuf, tbuf2)) < test_precision[T]())

def test_scalar[T: DType](nfft: Int):
    test_scalar_generic[Container.StdVectorContainer, T](nfft)

def test_complex_generic[Container: Int, T: DType](nfft: Int):
    alias Complex = FFT[T].Complex
    alias ComplexVector = VectorType[Container, Complex].type
    var fft: FFT[T] = FFT[T]()
    var inbuf: ComplexVector = ComplexVector(nfft)
    var outbuf: ComplexVector = ComplexVector()
    var buf3: ComplexVector = ComplexVector()
    for k in range(nfft):
        inbuf[k] = Complex((T)(random() / (float64)(RAND_MAX) - 0.5), (T)(random() / (float64)(RAND_MAX) - 0.5))
    fft.fwd(outbuf, inbuf)
    VERIFY(T(fft_rmse(outbuf, inbuf)) < test_precision[T]())
    fft.inv(buf3, outbuf)
    VERIFY(T(dif_rmse(inbuf, buf3)) < test_precision[T]())
    var buf4: ComplexVector = ComplexVector()
    fft.SetFlag(fft.Unscaled)
    fft.inv(buf4, outbuf)
    for k in range(nfft):
        buf4[k] *= T(1.0 / nfft)
    VERIFY(T(dif_rmse(inbuf, buf4)) < test_precision[T]())
    fft.ClearFlag(fft.Unscaled)
    fft.inv(buf3, outbuf)
    VERIFY(T(dif_rmse(inbuf, buf3)) < test_precision[T]())

def test_complex[T: DType](nfft: Int):
    test_complex_generic[Container.StdVectorContainer, T](nfft)
    test_complex_generic[Container.EigenVectorContainer, T](nfft)

def test_return_by_value(len: Int):
    var in_: VectorXf = VectorXf()
    var in1: VectorXf = VectorXf()
    in_.setRandom(len)
    var out1: VectorXcf = VectorXcf()
    var out2: VectorXcf = VectorXcf()
    var fft: FFT[float32] = FFT[float32]()
    fft.SetFlag(fft.HalfSpectrum)
    fft.fwd(out1, in_)
    out2 = fft.fwd(in_)
    VERIFY((out1 - out2).norm() < test_precision[float32]())
    in1 = fft.inv(out1)
    VERIFY((in1 - in_).norm() < test_precision[float32]())

def test_FFTW():
    CALL_SUBTEST(test_return_by_value(32))
    CALL_SUBTEST(test_complex[float32](32))
    CALL_SUBTEST(test_complex[float64](32))
    CALL_SUBTEST(test_complex[float32](256))
    CALL_SUBTEST(test_complex[float64](256))
    CALL_SUBTEST(test_complex[float32](3 * 8))
    CALL_SUBTEST(test_complex[float64](3 * 8))
    CALL_SUBTEST(test_complex[float32](5 * 32))
    CALL_SUBTEST(test_complex[float64](5 * 32))
    CALL_SUBTEST(test_complex[float32](2 * 3 * 4))
    CALL_SUBTEST(test_complex[float64](2 * 3 * 4))
    CALL_SUBTEST(test_complex[float32](2 * 3 * 4 * 5))
    CALL_SUBTEST(test_complex[float64](2 * 3 * 4 * 5))
    CALL_SUBTEST(test_complex[float32](2 * 3 * 4 * 5 * 7))
    CALL_SUBTEST(test_complex[float64](2 * 3 * 4 * 5 * 7))
    CALL_SUBTEST(test_scalar[float32](32))
    CALL_SUBTEST(test_scalar[float64](32))
    CALL_SUBTEST(test_scalar[float32](45))
    CALL_SUBTEST(test_scalar[float64](45))
    CALL_SUBTEST(test_scalar[float32](50))
    CALL_SUBTEST(test_scalar[float64](50))
    CALL_SUBTEST(test_scalar[float32](256))
    CALL_SUBTEST(test_scalar[float64](256))
    CALL_SUBTEST(test_scalar[float32](2 * 3 * 4 * 5 * 7))
    CALL_SUBTEST(test_scalar[float64](2 * 3 * 4 * 5 * 7))
    #ifdef EIGEN_HAS_FFTWL
    CALL_SUBTEST(test_complex[float128](32))
    CALL_SUBTEST(test_complex[float128](256))
    CALL_SUBTEST(test_complex[float128](3 * 8))
    CALL_SUBTEST(test_complex[float128](5 * 32))
    CALL_SUBTEST(test_complex[float128](2 * 3 * 4))
    CALL_SUBTEST(test_complex[float128](2 * 3 * 4 * 5))
    CALL_SUBTEST(test_complex[float128](2 * 3 * 4 * 5 * 7))
    CALL_SUBTEST(test_scalar[float128](32))
    CALL_SUBTEST(test_scalar[float128](45))
    CALL_SUBTEST(test_scalar[float128](50))
    CALL_SUBTEST(test_scalar[float128](256))
    CALL_SUBTEST(test_scalar[float128](2 * 3 * 4 * 5 * 7))
    #endif