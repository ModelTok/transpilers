from Eigen.Core import *
from BenchTimer import BenchTimer

using Eigen
using std

@parameter
def EIGEN_DONT_INLINE[T: AnyType]() -> Bool:  # placeholder for the macro
    return True

# template<T>
# EIGEN_DONT_INLINE T::Scalar sqsumNorm(T& v)
def sqsumNorm[T: AnyType](v: T) -> T.Scalar:
    return v.norm()

# template<T>
# EIGEN_DONT_INLINE T::Scalar stableNorm(T& v)
def stableNorm[T: AnyType](v: T) -> T.Scalar:
    return v.stableNorm()

# template<T>
# EIGEN_DONT_INLINE T::Scalar hypotNorm(T& v)
def hypotNorm[T: AnyType](v: T) -> T.Scalar:
    return v.hypotNorm()

# template<T>
# EIGEN_DONT_INLINE T::Scalar blueNorm(T& v)
def blueNorm[T: AnyType](v: T) -> T.Scalar:
    return v.blueNorm()

# template<T>
# EIGEN_DONT_INLINE T::Scalar lapackNorm(T& v)
def lapackNorm[T: AnyType](v: T) -> T.Scalar:
    alias Scalar = T.Scalar
    var n: Int = v.size()
    var scale: Scalar = 0
    var ssq: Scalar = 1
    for i in range(n):
        var ax: Scalar = abs(v.coeff(i))
        if scale >= ax:
            ssq += numext.abs2(ax/scale)
        else:
            ssq = Scalar(1) + ssq * numext.abs2(scale/ax)
            scale = ax
    return scale * sqrt(ssq)

# template<T>
# EIGEN_DONT_INLINE T::Scalar twopassNorm(T& v)
def twopassNorm[T: AnyType](v: T) -> T.Scalar:
    alias Scalar = T.Scalar
    var s: Scalar = v.array().abs().maxCoeff()
    return s * (v/s).norm()

# template<T>
# EIGEN_DONT_INLINE T::Scalar bl2passNorm(T& v)
def bl2passNorm[T: AnyType](v: T) -> T.Scalar:
    return v.stableNorm()

# template<T>
# EIGEN_DONT_INLINE T::Scalar divacNorm(T& v)
def divacNorm[T: AnyType](v: T) -> T.Scalar:
    var n: Int = v.size() / 2
    for i in range(n):
        v(i) = v(2*i) * v(2*i) + v(2*i+1) * v(2*i+1)
    n = n / 2
    while n > 0:
        for i in range(n):
            v(i) = v(2*i) + v(2*i+1)
        n = n / 2
    return sqrt(v(0))

# namespace Eigen {
# namespace internal {
# #ifdef EIGEN_VECTORIZE
# Packet4f plt(Packet4f& a , Packet4f& b) { return _mm_cmplt_ps(a,b); }
# Packet2d plt(Packet2d& a , Packet2d& b) { return _mm_cmplt_pd(a,b); }
# Packet4f pandnot(Packet4f& a , Packet4f& b) { return _mm_andnot_ps(a,b); }
# Packet2d pandnot(Packet2d& a , Packet2d& b) { return _mm_andnot_pd(a,b); }
# #endif
# }
# }

# The above intrinsics are platform-specific; we keep the definitions as placeholders.
# In Mojo, we cannot directly call _mm intrinsics, so we define them as stubs.
@parameter
def EIGEN_VECTORIZE() -> Bool:
    return True  # assume vectorization enabled

alias Packet4f = any_type
alias Packet2d = any_type

def plt(a: Packet4f, b: Packet4f) -> Packet4f:
    return _mm_cmplt_ps(a, b)  # kept for faithful translation, will fail if not available

def plt(a: Packet2d, b: Packet2d) -> Packet2d:
    return _mm_cmplt_pd(a, b)

def pandnot(a: Packet4f, b: Packet4f) -> Packet4f:
    return _mm_andnot_ps(a, b)

def pandnot(a: Packet2d, b: Packet2d) -> Packet2d:
    return _mm_andnot_pd(a, b)

# template<T>
# EIGEN_DONT_INLINE T::Scalar pblueNorm(T& v )
def pblueNorm[T: AnyType](v: T) -> T.Scalar:
    alias Scalar = T.Scalar
    if not EIGEN_VECTORIZE():
        return v.blueNorm()
    else:
        @parameter
        var nmax: Int = 0
        var b1: Scalar = 0
        var b2: Scalar = 0
        var s1m: Scalar = 0
        var s2m: Scalar = 0
        var overfl: Scalar = 0
        var rbig: Scalar = 0
        var relerr: Scalar = 0

        if nmax <= 0:
            var nbig: Int = sys.int.max  # largest integer
            var ibeta: Int = Scalar.radix  # base
            var it: Int = Scalar.digits  # mantissa digits
            var iemin: Int = Scalar.min_exponent
            var iemax: Int = Scalar.max_exponent
            rbig = Scalar.max  # largest finite

            if (iemin > 1 - 2*it) or (1+it > iemax) or (it==2 and ibeta<5) or (it<=4 and ibeta<=3) or it<2:
                # eigen_assert(false && "the algorithm cannot be guaranteed on this computer");
                print("the algorithm cannot be guaranteed on this computer")
            var iexp: Int = -((1-iemin)/2)
            b1 = pow(Scalar(ibeta), iexp)
            iexp = (iemax + 1 - it)/2
            b2 = pow(Scalar(ibeta), iexp)
            iexp = (2-iemin)/2
            s1m = pow(Scalar(ibeta), iexp)
            iexp = - ((iemax+it)/2)
            s2m = pow(Scalar(ibeta), iexp)
            overfl = rbig * s2m
            var eps: Scalar = pow(Scalar(ibeta), 1-it)
            relerr = sqrt(eps)
            var abig: Scalar = 1.0/eps - 1.0
            if Scalar(nbig) > abig:
                nmax = abig
            else:
                nmax = nbig

        alias Packet = internal.packet_traits[Scalar].type
        var ps: Int = internal.packet_traits[Scalar].size
        var pasml: Packet = internal.pset1[Packet](Scalar(0))
        var pamed: Packet = internal.pset1[Packet](Scalar(0))
        var pabig: Packet = internal.pset1[Packet](Scalar(0))
        var ps2m: Packet = internal.pset1[Packet](s2m)
        var ps1m: Packet = internal.pset1[Packet](s1m)
        var pb2: Packet = internal.pset1[Packet](b2)
        var pb1: Packet = internal.pset1[Packet](b1)

        for j in range(0, v.size(), ps):
            var ax: Packet = internal.pabs(v.template packet[Aligned](j))
            var ax_s2m: Packet = internal.pmul(ax, ps2m)
            var ax_s1m: Packet = internal.pmul(ax, ps1m)
            var maskBig: Packet = internal.plt(pb2, ax)
            var maskSml: Packet = internal.plt(ax, pb1)
            pabig = internal.padd(pabig, internal.pand(maskBig, internal.pmul(ax_s2m, ax_s2m)))
            pasml = internal.padd(pasml, internal.pand(maskSml, internal.pmul(ax_s1m, ax_s1m)))
            pamed = internal.padd(pamed, internal.pandnot(internal.pmul(ax, ax), internal.pand(maskSml, maskBig)))

        var abig: Scalar = internal.predux(pabig)
        var asml: Scalar = internal.predux(pasml)
        var amed: Scalar = internal.predux(pamed)

        if abig > Scalar(0):
            abig = sqrt(abig)
            if abig > overfl:
                # eigen_assert(false && "overflow");
                print("overflow")
                return rbig
            if amed > Scalar(0):
                abig = abig / s2m
                amed = sqrt(amed)
            else:
                return abig / s2m
        elif asml > Scalar(0):
            if amed > Scalar(0):
                abig = sqrt(amed)
                amed = sqrt(asml) / s1m
            else:
                return sqrt(asml) / s1m
        else:
            return sqrt(amed)

        asml = min(abig, amed)
        abig = max(abig, amed)
        if asml <= abig * relerr:
            return abig
        else:
            return abig * sqrt(Scalar(1) + numext.abs2(asml / abig))
        # endif

# Note: The macro BENCH_PERF is translated as a function-like macro. In Mojo we use a function.
# Since C++ macro passes NRM as a token, we keep it as a string and then call the function.
# However, to keep faithful, we define a helper that uses the macro expansion pattern.
# We'll define a function bench_perf that takes a string name and a function.
# But the original uses the macro to print results. We'll replicate the logic inline.

# #define BENCH_PERF(NRM) { ... }
def bench_perf(nrm: fn(VectorXf) -> float, vf: VectorXf, vd: VectorXd, vcf: VectorXcf, tries: Int, iters: Int):
    var af: float = 0
    var ad: float = 0
    var ac: complex[float] = 0
    var tf = BenchTimer()
    var td = BenchTimer()
    var tcf = BenchTimer()
    tf.reset()
    td.reset()
    tcf.reset()
    for k in range(tries):
        tf.start()
        for i in range(iters):
            af += nrm(vf)
        tf.stop()
    for k in range(tries):
        td.start()
        for i in range(iters):
            ad += nrm(vd)
        td.stop()
    # for (int k=0; k<max(1,tries/3); ++k) { ... }
    # commented out in original
    # We'll skip tcf
    print(nrm.__name__ + "\t" + str(tf.value()) + "   " + str(td.value()) + "    " + str(tcf.value()))

def check_accuracy(basef: float, based: float, s: Int):
    var yf: double = basef * abs(internal.random[double]())
    var yd: double = based * abs(internal.random[double]())
    var vf = VectorXf.Ones(s) * yf
    var vd = VectorXd.Ones(s) * yd
    print("reference\t" + str(sqrt(double(s))*yf) + "\t" + str(sqrt(double(s))*yd))
    print("sqsumNorm\t" + str(sqsumNorm(vf)) + "\t" + str(sqsumNorm(vd)))
    print("hypotNorm\t" + str(hypotNorm(vf)) + "\t" + str(hypotNorm(vd)))
    print("blueNorm\t" + str(blueNorm(vf)) + "\t" + str(blueNorm(vd)))
    print("pblueNorm\t" + str(pblueNorm(vf)) + "\t" + str(pblueNorm(vd)))
    print("lapackNorm\t" + str(lapackNorm(vf)) + "\t" + str(lapackNorm(vd)))
    print("twopassNorm\t" + str(twopassNorm(vf)) + "\t" + str(twopassNorm(vd)))
    print("bl2passNorm\t" + str(bl2passNorm(vf)) + "\t" + str(bl2passNorm(vd)))

def check_accuracy_var(ef0: Int, ef1: Int, ed0: Int, ed1: Int, s: Int):
    var vf = VectorXf(s)
    var vd = VectorXd(s)
    for i in range(s):
        vf[i] = abs(internal.random[double]()) * pow(double(10), internal.random[Int](ef0, ef1))
        vd[i] = abs(internal.random[double]()) * pow(double(10), internal.random[Int](ed0, ed1))
    print("sqsumNorm\t" + str(sqsumNorm(vf)) + "\t" + str(sqsumNorm(vd)) + "\t" + str(sqsumNorm(vf.cast[long double]())) + "\t" + str(sqsumNorm(vd.cast[long double]())))
    print("hypotNorm\t" + str(hypotNorm(vf)) + "\t" + str(hypotNorm(vd)) + "\t" + str(hypotNorm(vf.cast[long double]())) + "\t" + str(hypotNorm(vd.cast[long double]())))
    print("blueNorm\t" + str(blueNorm(vf)) + "\t" + str(blueNorm(vd)) + "\t" + str(blueNorm(vf.cast[long double]())) + "\t" + str(blueNorm(vd.cast[long double]())))
    print("pblueNorm\t" + str(pblueNorm(vf)) + "\t" + str(pblueNorm(vd)) + "\t" + str(blueNorm(vf.cast[long double]())) + "\t" + str(blueNorm(vd.cast[long double]())))
    print("lapackNorm\t" + str(lapackNorm(vf)) + "\t" + str(lapackNorm(vd)) + "\t" + str(lapackNorm(vf.cast[long double]())) + "\t" + str(lapackNorm(vd.cast[long double]())))
    print("twopassNorm\t" + str(twopassNorm(vf)) + "\t" + str(twopassNorm(vd)) + "\t" + str(twopassNorm(vf.cast[long double]())) + "\t" + str(twopassNorm(vd.cast[long double]())))

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    var tries: Int = 10
    var iters: Int = 100000
    var y: double = 1.1345743233455785456788e12 * internal.random[double]()
    var v = VectorXf.Ones(1024) * y
    var s: Int = 10000
    var basef_ok: double = 1.1345743233455785456788e15
    var based_ok: double = 1.1345743233455785456788e95
    var basef_under: double = 1.1345743233455785456788e-27
    var based_under: double = 1.1345743233455785456788e-303
    var basef_over: double = 1.1345743233455785456788e+27
    var based_over: double = 1.1345743233455785456788e+302
    print.precision(20)
    print("\nNo under/overflow:", file=stderr)
    check_accuracy(basef_ok, based_ok, s)
    print("\nUnderflow:", file=stderr)
    check_accuracy(basef_under, based_under, s)
    print("\nOverflow:", file=stderr)
    check_accuracy(basef_over, based_over, s)
    print("\nVarying (over):", file=stderr)
    for k in range(1):
        check_accuracy_var(20,27,190,302,s)
        print("\n")
    print("\nVarying (under):", file=stderr)
    for k in range(1):
        check_accuracy_var(-27,20,-302,-190,s)
        print("\n")
    y = 1
    print.precision(4)
    var s1: Int = 1024*1024*32
    print("Performance (out of cache, " + str(s1) + "):", file=stderr)
    var iters1: Int = 1
    var vf = VectorXf.Random(s1) * y
    var vd = VectorXd.Random(s1) * y
    var vcf = VectorXcf.Random(s1) * y
    bench_perf(sqsumNorm, vf, vd, vcf, tries, iters1)
    bench_perf(stableNorm, vf, vd, vcf, tries, iters1)
    bench_perf(blueNorm, vf, vd, vcf, tries, iters1)
    bench_perf(pblueNorm, vf, vd, vcf, tries, iters1)
    bench_perf(lapackNorm, vf, vd, vcf, tries, iters1)
    bench_perf(hypotNorm, vf, vd, vcf, tries, iters1)
    bench_perf(twopassNorm, vf, vd, vcf, tries, iters1)
    bench_perf(bl2passNorm, vf, vd, vcf, tries, iters1)
    print("\nPerformance (in cache, 512):", file=stderr)
    var iters2: Int = 100000
    vf = VectorXf.Random(512) * y
    vd = VectorXd.Random(512) * y
    vcf = VectorXcf.Random(512) * y
    bench_perf(sqsumNorm, vf, vd, vcf, tries, iters2)
    bench_perf(stableNorm, vf, vd, vcf, tries, iters2)
    bench_perf(blueNorm, vf, vd, vcf, tries, iters2)
    bench_perf(pblueNorm, vf, vd, vcf, tries, iters2)
    bench_perf(lapackNorm, vf, vd, vcf, tries, iters2)
    bench_perf(hypotNorm, vf, vd, vcf, tries, iters2)
    bench_perf(twopassNorm, vf, vd, vcf, tries, iters2)
    bench_perf(bl2passNorm, vf, vd, vcf, tries, iters2)