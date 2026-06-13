from Eigen.Geometry import Quaternion, dummy_precision, epsilon, internal
from bench.BenchTimer import BenchTimer
from math import acos, sin, asin
from random import seed, random
from time import time
from io import print

def nlerp[Q: AnyType](a: Q, b: Q, t: Q.Scalar) -> Q:
    return Q((a.coeffs() * (1.0 - t) + b.coeffs() * t).normalized())

def slerp_eigen[Q: AnyType](a: Q, b: Q, t: Q.Scalar) -> Q:
    return a.slerp(t, b)

def slerp_legacy[Q: AnyType](a: Q, b: Q, t: Q.Scalar) -> Q:
    type Scalar = Q.Scalar
    static const one = Scalar(1) - dummy_precision[Scalar]()
    var d = a.dot(b)
    var absD = internal.abs(d)
    if absD >= one:
        return a
    var theta = acos(absD)
    var sinTheta = internal.sin(theta)
    var scale0 = internal.sin((Scalar(1) - t) * theta) / sinTheta
    var scale1 = internal.sin((t * theta)) / sinTheta
    if d < 0:
        scale1 = -scale1
    return Q(scale0 * a.coeffs() + scale1 * b.coeffs())

def slerp_legacy_nlerp[Q: AnyType](a: Q, b: Q, t: Q.Scalar) -> Q:
    type Scalar = Q.Scalar
    static const one = Scalar(1) - epsilon[Scalar]()
    var d = a.dot(b)
    var absD = internal.abs(d)
    var scale0: Scalar
    var scale1: Scalar
    if absD >= one:
        scale0 = Scalar(1) - t
        scale1 = t
    else:
        var theta = acos(absD)
        var sinTheta = internal.sin(theta)
        scale0 = internal.sin((Scalar(1) - t) * theta) / sinTheta
        scale1 = internal.sin((t * theta)) / sinTheta
        if d < 0:
            scale1 = -scale1
    return Q(scale0 * a.coeffs() + scale1 * b.coeffs())

def sin_over_x[T: AnyType](x: T) -> T:
    if T(1) + x * x == T(1):
        return T(1)
    else:
        return sin(x) / x

def slerp_rw[Q: AnyType](a: Q, b: Q, t: Q.Scalar) -> Q:
    type Scalar = Q.Scalar
    var d = a.dot(b)
    var theta: Scalar
    if d < 0.0:
        theta = Scalar(2) * asin((a.coeffs() + b.coeffs()).norm() / 2)
    else:
        theta = Scalar(2) * asin((a.coeffs() - b.coeffs()).norm() / 2)
    var sinOverTheta = sin_over_x(theta)
    var scale0 = (Scalar(1) - t) * sin_over_x((Scalar(1) - t) * theta) / sinOverTheta
    var scale1 = t * sin_over_x((t * theta)) / sinOverTheta
    if d < 0:
        scale1 = -scale1
    return Quaternion[Scalar](scale0 * a.coeffs() + scale1 * b.coeffs())

def slerp_gael[Q: AnyType](a: Q, b: Q, t: Q.Scalar) -> Q:
    type Scalar = Q.Scalar
    var d = a.dot(b)
    var theta: Scalar
    if d < 0.0:
        theta = Scalar(2) * asin((-a.coeffs() - b.coeffs()).norm() / 2)
    else:
        theta = Scalar(2) * asin((a.coeffs() - b.coeffs()).norm() / 2)
    var scale0: Scalar
    var scale1: Scalar
    if theta * theta - Scalar(6) == -Scalar(6):
        scale0 = Scalar(1) - t
        scale1 = t
    else:
        var sinTheta = sin(theta)
        scale0 = internal.sin((Scalar(1) - t) * theta) / sinTheta
        scale1 = internal.sin((t * theta)) / sinTheta
        if d < 0:
            scale1 = -scale1
    return Quaternion[Scalar](scale0 * a.coeffs() + scale1 * b.coeffs())

def main():
    type RefScalar = Float64
    type TestScalar = Float32
    type Qd = Quaternion[RefScalar]
    type Qf = Quaternion[TestScalar]
    var g_seed = UInt32(time(None))
    print(g_seed)
    seed(g_seed)
    var maxerr = Matrix[RefScalar, Dynamic, 1](7)
    maxerr.setZero()
    var avgerr = Matrix[RefScalar, Dynamic, 1](7)
    avgerr.setZero()
    print("double=>float=>double       nlerp        eigen        legacy(snap)         legacy(nlerp)        rightway         gael's criteria")
    var rep = 100
    var iters = 40
    for w in range(rep):
        var a: Qf
        var b: Qf
        a.coeffs().setRandom()
        a.normalize()
        b.coeffs().setRandom()
        b.normalize()
        var c: StaticArray[Qf, 6]
        var ar = Qd(a.cast[RefScalar]())
        var br = Qd(b.cast[RefScalar]())
        var cr: Qd
        print.precision = 8
        print.scientific = True
        for i in range(iters):
            var t: RefScalar = 0.65
            cr = slerp_rw(ar, br, t)
            var refc = Qf(cr.cast[TestScalar]())
            c[0] = nlerp(a, b, t)
            c[1] = slerp_eigen(a, b, t)
            c[2] = slerp_legacy(a, b, t)
            c[3] = slerp_legacy_nlerp(a, b, t)
            c[4] = slerp_rw(a, b, t)
            c[5] = slerp_gael(a, b, t)
            var err = VectorXd(7)
            err[0] = (cr.coeffs() - refc.cast[RefScalar]().coeffs()).norm()
            for k in range(6):
                err[k + 1] = (c[k].coeffs() - refc.coeffs()).norm()
            maxerr = maxerr.cwise().max(err)
            avgerr += err
            b = Qf(cr.cast[TestScalar]())
            br = cr
    avgerr /= RefScalar(rep * iters)
    print("\n\nAccuracy:")
    print("  max: ", maxerr.transpose())
    print("  avg: ", avgerr.transpose())
    var a: Quaternionf
    var b: Quaternionf
    a.coeffs().setRandom()
    a.normalize()
    b.coeffs().setRandom()
    b.normalize()
    var s: Float32 = 0.65
    #define BENCH(FUNC) {
    #    var t: BenchTimer
    #    for k in range(2):
    #        t.start()
    #        for i in range(1000000):
    #            FUNC(a, b, s)
    #        t.stop()
    #    print("  " + #FUNC + " => \t " + str(t.value()) + "s")
    #}
    print("\nSpeed:")
    print.fixed = True
    #BENCH(nlerp)
    #BENCH(slerp_eigen)
    #BENCH(slerp_legacy)
    #BENCH(slerp_legacy_nlerp)
    #BENCH(slerp_rw)
    #BENCH(slerp_gael)