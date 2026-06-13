from main import *
from ...Eigen.SpecialFunctions import *

def verify_component_wise[type: AnyRegType](x: X, y: Y):
    for i in range(0, x.size()):
        if (numext.isfinite)(y(i)):
            VERIFY_IS_APPROX(x(i), y(i))
        elif (numext.isnan)(y(i)):
            VERIFY((numext.isnan)(x(i)))
        else:
            VERIFY_IS_EQUAL(x(i), y(i))

def array_special_functions[type: AnyRegType]():
    using std.abs
    using std.sqrt
    alias Scalar = ArrayType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    var plusinf: Scalar = std.numeric_limits[Scalar].infinity()
    var nan: Scalar = std.numeric_limits[Scalar].quiet_NaN()
    var rows: Index = internal.random[Index](1, 30)
    var cols: Index = 1
    {
        var m1: ArrayType = ArrayType.Random(rows, cols)
        #if EIGEN_HAS_C99_MATH
        VERIFY_IS_APPROX(m1.lgamma(), lgamma(m1))
        VERIFY_IS_APPROX(m1.digamma(), digamma(m1))
        VERIFY_IS_APPROX(m1.erf(), erf(m1))
        VERIFY_IS_APPROX(m1.erfc(), erfc(m1))
        #endif  // EIGEN_HAS_C99_MATH
    }
    #if EIGEN_HAS_C99_MATH
    if not NumTraits[Scalar].IsComplex:
        {
            var m1: ArrayType = ArrayType.Random(rows, cols)
            var m2: ArrayType = ArrayType.Random(rows, cols)
            var a: ArrayType = m1.abs() + 2
            var x: ArrayType = m2.abs() + 2
            var zero: ArrayType = ArrayType.Zero(rows, cols)
            var one: ArrayType = ArrayType.Constant(rows, cols, Scalar(1.0))
            var a_m1: ArrayType = a - one
            var Gamma_a_x: ArrayType = Eigen.igammac(a, x) * a.lgamma().exp()
            var Gamma_a_m1_x: ArrayType = Eigen.igammac(a_m1, x) * a_m1.lgamma().exp()
            var gamma_a_x: ArrayType = Eigen.igamma(a, x) * a.lgamma().exp()
            var gamma_a_m1_x: ArrayType = Eigen.igamma(a_m1, x) * a_m1.lgamma().exp()
            VERIFY_IS_APPROX(Eigen.igammac(a, zero), one)
            VERIFY_IS_APPROX(Gamma_a_x + gamma_a_x, a.lgamma().exp())
            VERIFY_IS_APPROX(Gamma_a_x, (a - 1) * Gamma_a_m1_x + x.pow(a - 1) * (-x).exp())
            VERIFY_IS_APPROX(gamma_a_x, (a - 1) * gamma_a_m1_x - x.pow(a - 1) * (-x).exp())
        }
        {
            var a_s: Scalar[6] = [Scalar(0), Scalar(1), Scalar(1.5), Scalar(4), Scalar(0.0001), Scalar(1000.5)]
            var x_s: Scalar[6] = [Scalar(0), Scalar(1), Scalar(1.5), Scalar(4), Scalar(0.0001), Scalar(1000.5)]
            var igamma_s: Scalar[6][6] = [[0.0, nan, nan, nan, nan, nan],
                                          [0.0, 0.6321205588285578, 0.7768698398515702,
                                           0.9816843611112658, 9.999500016666262e-05, 1.0],
                                          [0.0, 0.4275932955291202, 0.608374823728911,
                                           0.9539882943107686, 7.522076445089201e-07, 1.0],
                                          [0.0, 0.01898815687615381, 0.06564245437845008,
                                           0.5665298796332909, 4.166333347221828e-18, 1.0],
                                          [0.0, 0.9999780593618628, 0.9999899967080838,
                                           0.9999996219837988, 0.9991370418689945, 1.0],
                                          [0.0, 0.0, 0.0, 0.0, 0.0, 0.5042041932513908]]
            var igammac_s: Scalar[6][6] = [[nan, nan, nan, nan, nan, nan],
                                           [1.0, 0.36787944117144233, 0.22313016014842982,
                                            0.018315638888734182, 0.9999000049998333, 0.0],
                                           [1.0, 0.5724067044708798, 0.3916251762710878,
                                            0.04601170568923136, 0.9999992477923555, 0.0],
                                           [1.0, 0.9810118431238462, 0.9343575456215499,
                                            0.4334701203667089, 1.0, 0.0],
                                           [1.0, 2.1940638138146658e-05, 1.0003291916285e-05,
                                            3.7801620118431334e-07, 0.0008629581310054535,
                                            0.0],
                                           [1.0, 1.0, 1.0, 1.0, 1.0, 0.49579580674813944]]
            for i in range(0, 6):
                for j in range(0, 6):
                    if (std.isnan)(igamma_s[i][j]):
                        VERIFY((std.isnan)(numext.igamma(a_s[i], x_s[j])))
                    else:
                        VERIFY_IS_APPROX(numext.igamma(a_s[i], x_s[j]), igamma_s[i][j])
                    if (std.isnan)(igammac_s[i][j]):
                        VERIFY((std.isnan)(numext.igammac(a_s[i], x_s[j])))
                    else:
                        VERIFY_IS_APPROX(numext.igammac(a_s[i], x_s[j]), igammac_s[i][j])
        }
    #endif  // EIGEN_HAS_C99_MATH
    {
        var x: ArrayType(7)
        var q: ArrayType(7)
        var res: ArrayType(7)
        var ref: ArrayType(7)
        x << 1.5, 4, 10.5, 10000.5, 3, 1, 0.9
        q << 2, 1.5, 3, 1.0001, -2.5, 1.2345, 1.2345
        ref << 1.61237534869, 0.234848505667, 1.03086757337e-5, 0.367879440865, 0.054102025820864097, plusinf, nan
        CALL_SUBTEST(verify_component_wise(ref, ref))
        CALL_SUBTEST(res = x.zeta(q); verify_component_wise(res, ref))
        CALL_SUBTEST(res = zeta(x, q); verify_component_wise(res, ref))
    }
    {
        var x: ArrayType(7)
        var res: ArrayType(7)
        var ref: ArrayType(7)
        x << 1, 1.5, 4, -10.5, 10000.5, 0, -1
        ref << -0.5772156649015329, 0.03648997397857645, 1.2561176684318, 2.398239129535781, 9.210340372392849, plusinf, plusinf
        CALL_SUBTEST(verify_component_wise(ref, ref))
        CALL_SUBTEST(res = x.digamma(); verify_component_wise(res, ref))
        CALL_SUBTEST(res = digamma(x); verify_component_wise(res, ref))
    }
    #if EIGEN_HAS_C99_MATH
    {
        var n: ArrayType(11)
        var x: ArrayType(11)
        var res: ArrayType(11)
        var ref: ArrayType(11)
        n << 1, 1, 1, 1.5, 17, 31, 28, 8, 42, 147, 170
        x << 2, 3, 25.5, 1.5, 4.7, 11.8, 17.7, 30.2, 15.8, 54.1, 64
        ref << 0.644934066848, 0.394934066848, 0.0399946696496, nan, 293.334565435, 0.445487887616, -2.47810300902e-07, -8.29668781082e-09, -0.434562276666, 0.567742190178, -0.0108615497927
        CALL_SUBTEST(verify_component_wise(ref, ref))
        if sizeof(RealScalar) >= 8:  # double
            CALL_SUBTEST(res = polygamma(n, x); verify_component_wise(res, ref))
        else:
            CALL_SUBTEST(res = polygamma(n, x); verify_component_wise(res.head(8), ref.head(8)))
    }
    #endif
    #if EIGEN_HAS_C99_MATH
    {
        var a: ArrayType(125)
        var b: ArrayType(125)
        var x: ArrayType(125)
        var v: ArrayType(125)
        var res: ArrayType(125)
        a << 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999,
            0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999,
            0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999, 0.999,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 999.999, 999.999, 999.999, 999.999, 999.999, 999.999,
            999.999, 999.999, 999.999, 999.999, 999.999, 999.999, 999.999, 999.999,
            999.999, 999.999, 999.999, 999.999, 999.999, 999.999, 999.999, 999.999,
            999.999, 999.999, 999.999
        b << 0.0, 0.0, 0.0, 0.0, 0.0, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379, 0.999,
            0.999, 0.999, 0.999, 0.999, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 31.62177660168379, 999.999,
            999.999, 999.999, 999.999, 999.999, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.999, 0.999, 0.999, 0.999,
            0.999, 31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 999.999, 999.999, 999.999,
            999.999, 999.999, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.999, 0.999, 0.999, 0.999, 0.999,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 999.999, 999.999, 999.999,
            999.999, 999.999, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.999, 0.999, 0.999, 0.999, 0.999,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 999.999, 999.999, 999.999,
            999.999, 999.999, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03062277660168379,
            0.03062277660168379, 0.03062277660168379, 0.03062277660168379,
            0.03062277660168379, 0.999, 0.999, 0.999, 0.999, 0.999,
            31.62177660168379, 31.62177660168379, 31.62177660168379,
            31.62177660168379, 31.62177660168379, 999.999, 999.999, 999.999,
            999.999, 999.999
        x << -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5,
            0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2,
            0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1,
            0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1,
            -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8,
            1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5,
            0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2,
            0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1,
            0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5, 0.8, 1.1, -0.1, 0.2, 0.5,
            0.8, 1.1
        v << nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan,
            nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan,
            nan, nan, nan, 0.47972119876364683, 0.5, 0.5202788012363533, nan, nan,
            0.9518683957740043, 0.9789663010413743, 0.9931729188073435, nan, nan,
            0.999995949033062, 0.9999999999993698, 0.9999999999999999, nan, nan,
            0.9999999999999999, 0.9999999999999999, 0.9999999999999999, nan, nan,
            nan, nan, nan, nan, nan, 0.006827081192655869, 0.0210336989586256,
            0.04813160422599567, nan, nan, 0.20014344256217678, 0.5000000000000001,
            0.7998565574378232, nan, nan, 0.9991401428435834, 0.999999999698403,
            0.9999999999999999, nan, nan, 0.9999999999999999, 0.9999999999999999,
            0.9999999999999999, nan, nan, nan, nan, nan, nan, nan,
            1.0646600232370887e-25, 6.301722877826246e-13, 4.050966937974938e-06,
            nan, nan, 7.864342668429763e-23, 3.015969667594166e-10,
            0.0008598571564165444, nan, nan, 6.031987710123844e-08,
            0.5000000000000007, 0.9999999396801229, nan, nan, 0.9999999999999999,
            0.9999999999999999, 0.9999999999999999, nan, nan, nan, nan, nan, nan,
            nan, 0.0, 7.029920380986636e-306, 2.2450728208591345e-101, nan, nan,
            0.0, 9.275871147869727e-302, 1.2232913026152827e-97, nan, nan, 0.0,
            3.0891393081932924e-252, 2.9303043666183996e-60, nan, nan,
            2.248913486879199e-196, 0.5000000000004947, 0.9999999999999999, nan
        CALL_SUBTEST(res = betainc(a, b, x);
                     verify_component_wise(res, v))
    }
    {
        var m1: ArrayType = ArrayType.Random(32)
        var m2: ArrayType = ArrayType.Random(32)
        var m3: ArrayType = ArrayType.Random(32)
        var one: ArrayType = ArrayType.Constant(32, Scalar(1.0))
        var eps: Scalar = std.numeric_limits[Scalar].epsilon()
        var a: ArrayType = (m1 * 4.0).exp()
        var b: ArrayType = (m2 * 4.0).exp()
        var x: ArrayType = m3.abs()
        CALL_SUBTEST(
            var test: ArrayType = betainc(a, one, x)
            var expected: ArrayType = x.pow(a)
            verify_component_wise(test, expected))
        CALL_SUBTEST(
            var test: ArrayType = betainc(one, b, x)
            var expected: ArrayType = one - (one - x).pow(b)
            verify_component_wise(test, expected))
        CALL_SUBTEST(
            var test: ArrayType = betainc(a, b, x) + betainc(b, a, one - x)
            var expected: ArrayType = one
            verify_component_wise(test, expected))
        CALL_SUBTEST(
            var num: ArrayType = x.pow(a) * (one - x).pow(b)
            var denom: ArrayType = a * (a.lgamma() + b.lgamma() - (a + b).lgamma()).exp()
            var expected: ArrayType = betainc(a, b, x) - num / denom + eps
            var test: ArrayType = betainc(a + one, b, x) + eps
            if sizeof(Scalar) >= 8:  # double
                verify_component_wise(test, expected)
            else:
                verify_component_wise(test.head(8), expected.head(8)))
        CALL_SUBTEST(
            var num: ArrayType = x.pow(a) * (one - x).pow(b)
            var denom: ArrayType = b * (a.lgamma() + b.lgamma() - (a + b).lgamma()).exp()
            var expected: ArrayType = betainc(a, b, x) + num / denom + eps
            var test: ArrayType = betainc(a, b + one, x) + eps
            verify_component_wise(test, expected))
    }
    #endif

def test_special_functions():
    CALL_SUBTEST_1(array_special_functions[ArrayXf]())
    CALL_SUBTEST_2(array_special_functions[ArrayXd]())