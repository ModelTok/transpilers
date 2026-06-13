from main import (
    VERIFY,
    VERIFY_IS_APPROX,
    VERIFY_IS_MUCH_SMALLER_THAN,
    VERIFY_IS_NOT_APPROX,
    isPlusInf,
    CALL_SUBTEST_1,
    CALL_SUBTEST_2,
    CALL_SUBTEST_3,
    CALL_SUBTEST_4,
    CALL_SUBTEST_5,
    g_repeat,
)
from eigen import (
    Matrix,
    Vector4d,
    VectorXd,
    VectorXf,
    VectorXcd,
    Index,
    internal,
    numext,
)
from math import sqrt, abs, isnan, isfinite, limits, inf, nan

var first: Bool = True

def copy[T](x: T) -> T:
    return x

def stable_norm[MatrixType: AnyType](m: MatrixType):
    /* this test covers the following files:
       StableNorm.h
    */
    using sqrt
    using abs
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    var complex_real_product_ok: Bool = True
    {
        var ibeta: Int32
        var it: Int32
        var iemin: Int32
        var iemax: Int32
        let lim = limits[RealScalar]()
        ibeta = lim.radix         # base for floating-point numbers
        it    = lim.digits        # number of base-beta digits in mantissa
        iemin = lim.min_exponent  # minimum exponent
        iemax = lim.max_exponent  # maximum exponent
        VERIFY(
            (!(iemin > 1 - 2 * it or 1 + it > iemax or (it == 2 and ibeta < 5) or (it <= 4 and ibeta <= 3) or it < 2))
            and "the stable norm algorithm cannot be guaranteed on this computer"
        )
        let inf = limits[RealScalar]().inf
        if NumTraits[Scalar].IsComplex and isnan(inf * RealScalar(1)):
            complex_real_product_ok = False
            global first
            if first:
                print(
                    "WARNING: compiler mess up complex*real product, ",
                    inf,
                    " * ",
                    1.0,
                    " = ",
                    inf * RealScalar(1),
                )
                first = False
    }
    var rows = m.rows()
    var cols = m.cols()
    var factor = internal.random[Scalar]()
    while numext.abs2(factor) < RealScalar(1e-4):
        factor = internal.random[Scalar]()
    var big = factor * (limits[RealScalar]().max * RealScalar(1e-4))
    factor = internal.random[Scalar]()
    while numext.abs2(factor) < RealScalar(1e-4):
        factor = internal.random[Scalar]()
    var small = factor * (limits[RealScalar]().min * RealScalar(1e4))
    var one = Scalar(1)
    var vzero = MatrixType.Zero(rows, cols)
    var vrand = MatrixType.Random(rows, cols)
    var vbig = MatrixType(rows, cols)
    var vsmall = MatrixType(rows, cols)
    vbig.fill(big)
    vsmall.fill(small)
    VERIFY_IS_MUCH_SMALLER_THAN(vzero.norm(), static_cast[RealScalar](1))
    VERIFY_IS_APPROX(vrand.stableNorm(), vrand.norm())
    VERIFY_IS_APPROX(vrand.blueNorm(), vrand.norm())
    VERIFY_IS_APPROX(vrand.hypotNorm(), vrand.norm())
    VERIFY_IS_APPROX((one * vrand).stableNorm(), vrand.norm())
    VERIFY_IS_APPROX((one * vrand).blueNorm(), vrand.norm())
    VERIFY_IS_APPROX((one * vrand).hypotNorm(), vrand.norm())
    VERIFY_IS_APPROX((one * vrand + one * vrand - one * vrand).stableNorm(), vrand.norm())
    VERIFY_IS_APPROX((one * vrand + one * vrand - one * vrand).blueNorm(), vrand.norm())
    VERIFY_IS_APPROX((one * vrand + one * vrand - one * vrand).hypotNorm(), vrand.norm())
    var size = static_cast[RealScalar](m.size())
    VERIFY(!isfinite(limits[RealScalar]().inf))
    VERIFY(!isfinite(sqrt(-abs(big))))
    VERIFY(isfinite(sqrt(size) * abs(big)))
    VERIFY_IS_NOT_APPROX(sqrt(copy(vbig.squaredNorm())), abs(sqrt(size) * big)) # here the default norm must fail
    VERIFY_IS_APPROX(vbig.stableNorm(), sqrt(size) * abs(big))
    VERIFY_IS_APPROX(vbig.blueNorm(), sqrt(size) * abs(big))
    VERIFY_IS_APPROX(vbig.hypotNorm(), sqrt(size) * abs(big))
    VERIFY(isfinite(sqrt(size) * abs(small)))
    VERIFY_IS_NOT_APPROX(sqrt(copy(vsmall.squaredNorm())), abs(sqrt(size) * small)) # here the default norm must fail
    VERIFY_IS_APPROX(vsmall.stableNorm(), sqrt(size) * abs(small))
    VERIFY_IS_APPROX(vsmall.blueNorm(), sqrt(size) * abs(small))
    VERIFY_IS_APPROX(vsmall.hypotNorm(), sqrt(size) * abs(small))
    VERIFY_IS_APPROX(vrand.colwise().stableNorm(), vrand.colwise().norm())
    VERIFY_IS_APPROX(vrand.colwise().blueNorm(), vrand.colwise().norm())
    VERIFY_IS_APPROX(vrand.colwise().hypotNorm(), vrand.colwise().norm())
    VERIFY_IS_APPROX(vrand.rowwise().stableNorm(), vrand.rowwise().norm())
    VERIFY_IS_APPROX(vrand.rowwise().blueNorm(), vrand.rowwise().norm())
    VERIFY_IS_APPROX(vrand.rowwise().hypotNorm(), vrand.rowwise().norm())
    var v: MatrixType
    var i = internal.random[Index](0, rows - 1)
    var j = internal.random[Index](0, cols - 1)
    {
        v = vrand
        v[i, j] = limits[RealScalar]().quiet_nan
        VERIFY(!isfinite(v.squaredNorm()));    VERIFY(isnan(v.squaredNorm()))
        VERIFY(!isfinite(v.norm()));           VERIFY(isnan(v.norm()))
        VERIFY(!isfinite(v.stableNorm()));     VERIFY(isnan(v.stableNorm()))
        VERIFY(!isfinite(v.blueNorm()));       VERIFY(isnan(v.blueNorm()))
        VERIFY(!isfinite(v.hypotNorm()));      VERIFY(isnan(v.hypotNorm()))
    }
    {
        v = vrand
        v[i, j] = limits[RealScalar]().inf
        VERIFY(!isfinite(v.squaredNorm()));    VERIFY(isPlusInf(v.squaredNorm()))
        VERIFY(!isfinite(v.norm()));           VERIFY(isPlusInf(v.norm()))
        VERIFY(!isfinite(v.stableNorm()))
        if complex_real_product_ok:
            VERIFY(isPlusInf(v.stableNorm()))
        VERIFY(!isfinite(v.blueNorm()));       VERIFY(isPlusInf(v.blueNorm()))
        VERIFY(!isfinite(v.hypotNorm()));      VERIFY(isPlusInf(v.hypotNorm()))
    }
    {
        v = vrand
        v[i, j] = -limits[RealScalar]().inf
        VERIFY(!isfinite(v.squaredNorm()));    VERIFY(isPlusInf(v.squaredNorm()))
        VERIFY(!isfinite(v.norm()));           VERIFY(isPlusInf(v.norm()))
        VERIFY(!isfinite(v.stableNorm()))
        if complex_real_product_ok:
            VERIFY(isPlusInf(v.stableNorm()))
        VERIFY(!isfinite(v.blueNorm()));       VERIFY(isPlusInf(v.blueNorm()))
        VERIFY(!isfinite(v.hypotNorm()));      VERIFY(isPlusInf(v.hypotNorm()))
    }
    {
        var i2 = internal.random[Index](0, rows - 1)
        var j2 = internal.random[Index](0, cols - 1)
        v = vrand
        v[i, j] = -limits[RealScalar]().inf
        v[i2, j2] = limits[RealScalar]().quiet_nan
        VERIFY(!isfinite(v.squaredNorm()));    VERIFY(isnan(v.squaredNorm()))
        VERIFY(!isfinite(v.norm()));           VERIFY(isnan(v.norm()))
        VERIFY(!isfinite(v.stableNorm()));     VERIFY(isnan(v.stableNorm()))
        VERIFY(!isfinite(v.blueNorm()));       VERIFY(isnan(v.blueNorm()))
        VERIFY(!isfinite(v.hypotNorm()));      VERIFY(isnan(v.hypotNorm()))
    }
    {
        VERIFY_IS_APPROX(vrand.stableNormalized(), vrand.normalized())
        var vcopy = MatrixType(vrand)
        vcopy.stableNormalize()
        VERIFY_IS_APPROX(vcopy, vrand.normalized())
        VERIFY_IS_APPROX((vrand.stableNormalized()).norm(), RealScalar(1))
        VERIFY_IS_APPROX(vcopy.norm(), RealScalar(1))
        VERIFY_IS_APPROX((vbig.stableNormalized()).norm(), RealScalar(1))
        VERIFY_IS_APPROX((vsmall.stableNormalized()).norm(), RealScalar(1))
        var big_scaling = limits[RealScalar]().max * RealScalar(1e-4)
        VERIFY_IS_APPROX(vbig / big_scaling, (vbig.stableNorm() * vbig.stableNormalized()).eval() / big_scaling)
        VERIFY_IS_APPROX(vsmall, vsmall.stableNorm() * vsmall.stableNormalized())
    }

def test_stable_norm():
    for i in range(g_repeat):
        CALL_SUBTEST_1(stable_norm[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_2(stable_norm[Vector4d[float64]]())
        CALL_SUBTEST_3(stable_norm[VectorXd[float64]](internal.random[Int32](10, 2000)))
        CALL_SUBTEST_4(stable_norm[VectorXf[float32]](internal.random[Int32](10, 2000)))
        CALL_SUBTEST_5(stable_norm[VectorXcd[complex[float64]]](internal.random[Int32](10, 2000)))