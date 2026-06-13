from math import sqrt
from main import VERIFY_IS_EQUAL, VERIFY_IS_APPROX, CALL_SUBTEST, g_test_level, assert
from ......Eigen.Core import VectorXd, MatrixXd, DenseFunctor, NumTraits, internal
from ...Eigen.LevenbergMarquardt import LevenbergMarquardt, LevenbergMarquardtSpace

alias LM_EVAL_COUNT_TOL = 4.0/3.0

struct lmder_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 3, 15)

    def __call__(self borrowed, x: VectorXd, fvec: VectorXd) -> Int:
        var tmp1: Float64
        var tmp2: Float64
        var tmp3: Float64
        let y: StaticArray[Float64, 15] = StaticArray[Float64, 15](1.4e-1, 1.8e-1, 2.2e-1, 2.5e-1, 2.9e-1, 3.2e-1, 3.5e-1,
            3.9e-1, 3.7e-1, 5.8e-1, 7.3e-1, 9.6e-1, 1.34, 2.1, 4.39)
        for i in range(self.values()):
            tmp1 = Float64(i + 1)
            tmp2 = Float64(16 - i - 1)
            tmp3 = tmp2 if i >= 8 else tmp1
            fvec[i] = y[i] - (x[0] + tmp1 / (x[1] * tmp2 + x[2] * tmp3))
        return 0

    def df(self borrowed, x: VectorXd, fjac: MatrixXd) -> Int:
        var tmp1: Float64
        var tmp2: Float64
        var tmp3: Float64
        var tmp4: Float64
        for i in range(self.values()):
            tmp1 = Float64(i + 1)
            tmp2 = Float64(16 - i - 1)
            tmp3 = tmp2 if i >= 8 else tmp1
            tmp4 = (x[1] * tmp2 + x[2] * tmp3)
            tmp4 = tmp4 * tmp4
            fjac[i, 0] = -1.0
            fjac[i, 1] = tmp1 * tmp2 / tmp4
            fjac[i, 2] = tmp1 * tmp3 / tmp4
        return 0

def testLmder1():
    let n: Int = 3
    var info: Int
    var x: VectorXd = VectorXd()
    # the following starting values provide a rough fit.
    x.setConstant(n, 1.0)
    var functor = lmder_functor()
    var lm = LevenbergMarquardt[lmder_functor](functor)
    info = lm.lmder1(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 6)
    VERIFY_IS_EQUAL(lm.njev(), 5)
    VERIFY_IS_APPROX(lm.fvec().blueNorm(), 0.09063596)
    var x_ref: VectorXd = VectorXd(n)
    x_ref[0] = 0.08241058
    x_ref[1] = 1.133037
    x_ref[2] = 2.343695
    VERIFY_IS_APPROX(x, x_ref)

def testLmder():
    let m: Int = 15
    let n: Int = 3
    var info: Int
    var fnorm: Float64
    var covfac: Float64
    var x: VectorXd = VectorXd()
    # the following starting values provide a rough fit.
    x.setConstant(n, 1.0)
    var functor = lmder_functor()
    var lm = LevenbergMarquardt[lmder_functor](functor)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 6)
    VERIFY_IS_EQUAL(lm.njev(), 5)
    fnorm = lm.fvec().blueNorm()
    VERIFY_IS_APPROX(fnorm, 0.09063596)
    var x_ref: VectorXd = VectorXd(n)
    x_ref[0] = 0.08241058
    x_ref[1] = 1.133037
    x_ref[2] = 2.343695
    VERIFY_IS_APPROX(x, x_ref)
    covfac = fnorm * fnorm / Float64(m - n)
    internal.covar(lm.matrixR(), lm.permutation().indices())  # TODO : move this as a function of lm
    var cov_ref: MatrixXd = MatrixXd(n, n)
    cov_ref[0,0] = 0.0001531202
    cov_ref[0,1] = 0.002869941
    cov_ref[0,2] = -0.002656662
    cov_ref[1,0] = 0.002869941
    cov_ref[1,1] = 0.09480935
    cov_ref[1,2] = -0.09098995
    cov_ref[2,0] = -0.002656662
    cov_ref[2,1] = -0.09098995
    cov_ref[2,2] = 0.08778727
    var cov: MatrixXd = MatrixXd()
    cov = covfac * lm.matrixR().topLeftCorner[n, n]()
    VERIFY_IS_APPROX(cov, cov_ref)

struct lmdif_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 3, 15)

    def __call__(self borrowed, x: VectorXd, fvec: VectorXd) -> Int:
        var i: Int
        var tmp1: Float64
        var tmp2: Float64
        var tmp3: Float64
        let y: StaticArray[Float64, 15] = StaticArray[Float64, 15](1.4e-1, 1.8e-1, 2.2e-1, 2.5e-1, 2.9e-1, 3.2e-1, 3.5e-1, 3.9e-1,
            3.7e-1, 5.8e-1, 7.3e-1, 9.6e-1, 1.34e0, 2.1e0, 4.39e0)
        assert(x.size() == 3)
        assert(fvec.size() == 15)
        for i in range(15):
            tmp1 = Float64(i + 1)
            tmp2 = Float64(15 - i)
            tmp3 = tmp1
            if i >= 8:
                tmp3 = tmp2
            fvec[i] = y[i] - (x[0] + tmp1 / (x[1] * tmp2 + x[2] * tmp3))
        return 0

def testLmdif1():
    let n: Int = 3
    var info: Int
    var x: VectorXd = VectorXd(n)
    var fvec: VectorXd = VectorXd(15)
    # the following starting values provide a rough fit.
    x.setConstant(n, 1.0)
    var functor = lmdif_functor()
    var nfev: DenseIndex = DenseIndex()
    info = LevenbergMarquardt[lmdif_functor].lmdif1(functor, x, nfev)
    VERIFY_IS_EQUAL(info, 1)
    functor(x, fvec)
    VERIFY_IS_APPROX(fvec.blueNorm(), 0.09063596)
    var x_ref: VectorXd = VectorXd(n)
    x_ref[0] = 0.0824106
    x_ref[1] = 1.1330366
    x_ref[2] = 2.3436947
    VERIFY_IS_APPROX(x, x_ref)

def testLmdif():
    let m: Int = 15
    let n: Int = 3
    var info: Int
    var fnorm: Float64
    var covfac: Float64
    var x: VectorXd = VectorXd(n)
    # the following starting values provide a rough fit.
    x.setConstant(n, 1.0)
    var functor = lmdif_functor()
    var numDiff = NumericalDiff[lmdif_functor](functor)
    var lm = LevenbergMarquardt[NumericalDiff[lmdif_functor]](numDiff)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    fnorm = lm.fvec().blueNorm()
    VERIFY_IS_APPROX(fnorm, 0.09063596)
    var x_ref: VectorXd = VectorXd(n)
    x_ref[0] = 0.08241058
    x_ref[1] = 1.133037
    x_ref[2] = 2.343695
    VERIFY_IS_APPROX(x, x_ref)
    covfac = fnorm * fnorm / Float64(m - n)
    internal.covar(lm.matrixR(), lm.permutation().indices())  # TODO : move this as a function of lm
    var cov_ref: MatrixXd = MatrixXd(n, n)
    cov_ref[0,0] = 0.0001531202
    cov_ref[0,1] = 0.002869942
    cov_ref[0,2] = -0.002656662
    cov_ref[1,0] = 0.002869942
    cov_ref[1,1] = 0.09480937
    cov_ref[1,2] = -0.09098997
    cov_ref[2,0] = -0.002656662
    cov_ref[2,1] = -0.09098997
    cov_ref[2,2] = 0.08778729
    var cov: MatrixXd = MatrixXd()
    cov = covfac * lm.matrixR().topLeftCorner[n, n]()
    VERIFY_IS_APPROX(cov, cov_ref)

struct chwirut2_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 3, 54)

    static var m_x: StaticArray[Float64, 54]
    static var m_y: StaticArray[Float64, 54]

    def __call__(self borrowed, b: VectorXd, fvec: VectorXd) -> Int:
        var i: Int
        assert(b.size() == 3)
        assert(fvec.size() == 54)
        for i in range(54):
            let x: Float64 = self.m_x[i]
            fvec[i] = exp(-b[0] * x) / (b[1] + b[2] * x) - self.m_y[i]
        return 0

    def df(self borrowed, b: VectorXd, fjac: MatrixXd) -> Int:
        assert(b.size() == 3)
        assert(fjac.rows() == 54)
        assert(fjac.cols() == 3)
        for i in range(54):
            let x: Float64 = self.m_x[i]
            let factor: Float64 = 1.0 / (b[1] + b[2] * x)
            let e: Float64 = exp(-b[0] * x)
            fjac[i, 0] = -x * e * factor
            fjac[i, 1] = -e * factor * factor
            fjac[i, 2] = -x * e * factor * factor
        return 0

var chwirut2_functor.m_x = StaticArray[Float64, 54](0.500E0, 1.000E0, 1.750E0, 3.750E0, 5.750E0, 0.875E0, 2.250E0, 3.250E0, 5.250E0, 0.750E0, 1.750E0, 2.750E0, 4.750E0, 0.625E0, 1.250E0, 2.250E0, 4.250E0, .500E0, 3.000E0, .750E0, 3.000E0, 1.500E0, 6.000E0, 3.000E0, 6.000E0, 1.500E0, 3.000E0, .500E0, 2.000E0, 4.000E0, .750E0, 2.000E0, 5.000E0, .750E0, 2.250E0, 3.750E0, 5.750E0, 3.000E0, .750E0, 2.500E0, 4.000E0, .750E0, 2.500E0, 4.000E0, .750E0, 2.500E0, 4.000E0, .500E0, 6.000E0, 3.000E0, .500E0, 2.750E0, .500E0, 1.750E0)

var chwirut2_functor.m_y = StaticArray[Float64, 54](92.9000E0, 57.1000E0, 31.0500E0, 11.5875E0, 8.0250E0, 63.6000E0, 21.4000E0, 14.2500E0, 8.4750E0, 63.8000E0, 26.8000E0, 16.4625E0, 7.1250E0, 67.3000E0, 41.0000E0, 21.1500E0, 8.1750E0, 81.5000E0, 13.1200E0, 59.9000E0, 14.6200E0, 32.9000E0, 5.4400E0, 12.5600E0, 5.4400E0, 32.0000E0, 13.9500E0, 75.8000E0, 20.0000E0, 10.4200E0, 59.5000E0, 21.6700E0, 8.5500E0, 62.0000E0, 20.2000E0, 7.7600E0, 3.7500E0, 11.8100E0, 54.7000E0, 23.7000E0, 11.5500E0, 61.3000E0, 17.7000E0, 8.7400E0, 59.2000E0, 16.3000E0, 8.6200E0, 81.0000E0, 4.8700E0, 14.6200E0, 81.7000E0, 17.1700E0, 81.3000E0, 28.9000E0)

def testNistChwirut2():
    let n: Int = 3
    var info: LevenbergMarquardtSpace.Status
    var x: VectorXd = VectorXd(n)
    # First try
    x[0] = 0.1
    x[1] = 0.01
    x[2] = 0.02
    var functor = chwirut2_functor()
    var lm = LevenbergMarquardt[chwirut2_functor](functor)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, LevenbergMarquardtSpace.Status(1))
    VERIFY_IS_EQUAL(lm.njev(), 8)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 5.1304802941E+02)
    VERIFY_IS_APPROX(x[0], 1.6657666537E-01)
    VERIFY_IS_APPROX(x[1], 5.1653291286E-03)
    VERIFY_IS_APPROX(x[2], 1.2150007096E-02)
    # Second try
    x[0] = 0.15
    x[1] = 0.008
    x[2] = 0.010
    lm.resetParameters()
    lm.setFtol(1.E6 * NumTraits[Float64].epsilon())
    lm.setXtol(1.E6 * NumTraits[Float64].epsilon())
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, LevenbergMarquardtSpace.Status(1))
    VERIFY_IS_EQUAL(lm.njev(), 6)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 5.1304802941E+02)
    VERIFY_IS_APPROX(x[0], 1.6657666537E-01)
    VERIFY_IS_APPROX(x[1], 5.1653291286E-03)
    VERIFY_IS_APPROX(x[2], 1.2150007096E-02)

struct misra1a_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 2, 14)

    static var m_x: StaticArray[Float64, 14]
    static var m_y: StaticArray[Float64, 14]

    def __call__(self borrowed, b: VectorXd, fvec: VectorXd) -> Int:
        assert(b.size() == 2)
        assert(fvec.size() == 14)
        for i in range(14):
            fvec[i] = b[0] * (1.0 - exp(-b[1] * self.m_x[i])) - self.m_y[i]
        return 0

    def df(self borrowed, b: VectorXd, fjac: MatrixXd) -> Int:
        assert(b.size() == 2)
        assert(fjac.rows() == 14)
        assert(fjac.cols() == 2)
        for i in range(14):
            fjac[i, 0] = (1.0 - exp(-b[1] * self.m_x[i]))
            fjac[i, 1] = (b[0] * self.m_x[i] * exp(-b[1] * self.m_x[i]))
        return 0

var misra1a_functor.m_x = StaticArray[Float64, 14](77.6E0, 114.9E0, 141.1E0, 190.8E0, 239.9E0, 289.0E0, 332.8E0, 378.4E0, 434.8E0, 477.3E0, 536.8E0, 593.1E0, 689.1E0, 760.0E0)
var misra1a_functor.m_y = StaticArray[Float64, 14](10.07E0, 14.73E0, 17.94E0, 23.93E0, 29.61E0, 35.18E0, 40.02E0, 44.82E0, 50.76E0, 55.05E0, 61.01E0, 66.40E0, 75.47E0, 81.78E0)

def testNistMisra1a():
    let n: Int = 2
    var info: Int
    var x: VectorXd = VectorXd(n)
    # First try
    x[0] = 500.0
    x[1] = 0.0001
    var functor = misra1a_functor()
    var lm = LevenbergMarquardt[misra1a_functor](functor)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 19)
    VERIFY_IS_EQUAL(lm.njev(), 15)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 1.2455138894E-01)
    VERIFY_IS_APPROX(x[0], 2.3894212918E+02)
    VERIFY_IS_APPROX(x[1], 5.5015643181E-04)
    # Second try
    x[0] = 250.0
    x[1] = 0.0005
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 5)
    VERIFY_IS_EQUAL(lm.njev(), 4)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 1.2455138894E-01)
    VERIFY_IS_APPROX(x[0], 2.3894212918E+02)
    VERIFY_IS_APPROX(x[1], 5.5015643181E-04)

struct hahn1_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 7, 236)

    static var m_x: StaticArray[Float64, 236]

    def __call__(self borrowed, b: VectorXd, fvec: VectorXd) -> Int:
        let m_y: StaticArray[Float64, 236] = StaticArray[Float64, 236](.591E0, 1.547E0, 2.902E0, 2.894E0, 4.703E0, 6.307E0, 7.03E0, 7.898E0, 9.470E0, 9.484E0, 10.072E0, 10.163E0, 11.615E0, 12.005E0, 12.478E0, 12.982E0, 12.970E0, 13.926E0, 14.452E0, 14.404E0, 15.190E0, 15.550E0, 15.528E0, 15.499E0, 16.131E0, 16.438E0, 16.387E0, 16.549E0, 16.872E0, 16.830E0, 16.926E0, 16.907E0, 16.966E0, 17.060E0, 17.122E0, 17.311E0, 17.355E0, 17.668E0, 17.767E0, 17.803E0, 17.765E0, 17.768E0, 17.736E0, 17.858E0, 17.877E0, 17.912E0, 18.046E0, 18.085E0, 18.291E0, 18.357E0, 18.426E0, 18.584E0, 18.610E0, 18.870E0, 18.795E0, 19.111E0, .367E0, .796E0, 0.892E0, 1.903E0, 2.150E0, 3.697E0, 5.870E0, 6.421E0, 7.422E0, 9.944E0, 11.023E0, 11.87E0, 12.786E0, 14.067E0, 13.974E0, 14.462E0, 14.464E0, 15.381E0, 15.483E0, 15.59E0, 16.075E0, 16.347E0, 16.181E0, 16.915E0, 17.003E0, 16.978E0, 17.756E0, 17.808E0, 17.868E0, 18.481E0, 18.486E0, 19.090E0, 16.062E0, 16.337E0, 16.345E0,
        16.388E0, 17.159E0, 17.116E0, 17.164E0, 17.123E0, 17.979E0, 17.974E0, 18.007E0, 17.993E0, 18.523E0, 18.669E0, 18.617E0, 19.371E0, 19.330E0, 0.080E0, 0.248E0, 1.089E0, 1.418E0, 2.278E0, 3.624E0, 4.574E0, 5.556E0, 7.267E0, 7.695E0, 9.136E0, 9.959E0, 9.957E0, 11.600E0, 13.138E0, 13.564E0, 13.871E0, 13.994E0, 14.947E0, 15.473E0, 15.379E0, 15.455E0, 15.908E0, 16.114E0, 17.071E0, 17.135E0, 17.282E0, 17.368E0, 17.483E0, 17.764E0, 18.185E0, 18.271E0, 18.236E0, 18.237E0, 18.523E0, 18.627E0, 18.665E0, 19.086E0, 0.214E0, 0.943E0, 1.429E0, 2.241E0, 2.951E0, 3.782E0, 4.757E0, 5.602E0, 7.169E0, 8.920E0, 10.055E0, 12.035E0, 12.861E0, 13.436E0, 14.167E0, 14.755E0, 15.168E0, 15.651E0, 15.746E0, 16.216E0, 16.445E0, 16.965E0, 17.121E0, 17.206E0, 17.250E0, 17.339E0, 17.793E0, 18.123E0, 18.49E0, 18.566E0, 18.645E0, 18.706E0, 18.924E0, 19.1E0, 0.375E0, 0.471E0, 1.504E0, 2.204E0, 2.813E0, 4.765E0, 9.835E0, 10.040E0, 11.946E0,
        12.596E0,
        13.303E0, 13.922E0, 14.440E0, 14.951E0, 15.627E0, 15.639E0, 15.814E0, 16.315E0, 16.334E0, 16.430E0, 16.423E0, 17.024E0, 17.009E0, 17.165E0, 17.134E0, 17.349E0, 17.576E0, 17.848E0, 18.090E0, 18.276E0, 18.404E0, 18.519E0, 19.133E0, 19.074E0, 19.239E0, 19.280E0, 19.101E0, 19.398E0, 19.252E0, 19.89E0, 20.007E0, 19.929E0, 19.268E0, 19.324E0, 20.049E0, 20.107E0, 20.062E0, 20.065E0, 19.286E0, 19.972E0, 20.088E0, 20.743E0, 20.83E0, 20.935E0, 21.035E0, 20.93E0, 21.074E0, 21.085E0, 20.935E0)
        assert(b.size() == 7)
        assert(fvec.size() == 236)
        for i in range(236):
            let x: Float64 = self.m_x[i]
            let xx: Float64 = x * x
            let xxx: Float64 = xx * x
            fvec[i] = (b[0] + b[1] * x + b[2] * xx + b[3] * xxx) / (1.0 + b[4] * x + b[5] * xx + b[6] * xxx) - m_y[i]
        return 0

    def df(self borrowed, b: VectorXd, fjac: MatrixXd) -> Int:
        assert(b.size() == 7)
        assert(fjac.rows() == 236)
        assert(fjac.cols() == 7)
        for i in range(236):
            let x: Float64 = self.m_x[i]
            let xx: Float64 = x * x
            let xxx: Float64 = xx * x
            var fact: Float64 = 1.0 / (1.0 + b[4] * x + b[5] * xx + b[6] * xxx)
            fjac[i, 0] = 1.0 * fact
            fjac[i, 1] = x * fact
            fjac[i, 2] = xx * fact
            fjac[i, 3] = xxx * fact
            fact = -(b[0] + b[1] * x + b[2] * xx + b[3] * xxx) * fact * fact
            fjac[i, 4] = x * fact
            fjac[i, 5] = xx * fact
            fjac[i, 6] = xxx * fact
        return 0

var hahn1_functor.m_x = StaticArray[Float64, 236](24.41E0, 34.82E0, 44.09E0, 45.07E0, 54.98E0, 65.51E0, 70.53E0, 75.70E0, 89.57E0, 91.14E0, 96.40E0, 97.19E0, 114.26E0, 120.25E0, 127.08E0, 133.55E0, 133.61E0, 158.67E0, 172.74E0, 171.31E0, 202.14E0, 220.55E0, 221.05E0, 221.39E0, 250.99E0, 268.99E0, 271.80E0, 271.97E0, 321.31E0, 321.69E0, 330.14E0, 333.03E0, 333.47E0, 340.77E0, 345.65E0, 373.11E0, 373.79E0, 411.82E0, 419.51E0, 421.59E0, 422.02E0, 422.47E0, 422.61E0, 441.75E0, 447.41E0, 448.7E0, 472.89E0, 476.69E0, 522.47E0, 522.62E0, 524.43E0, 546.75E0, 549.53E0, 575.29E0, 576.00E0, 625.55E0, 20.15E0, 28.78E0, 29.57E0, 37.41E0, 39.12E0, 50.24E0, 61.38E0, 66.25E0, 73.42E0, 95.52E0, 107.32E0, 122.04E0, 134.03E0, 163.19E0, 163.48E0, 175.70E0, 179.86E0, 211.27E0, 217.78E0, 219.14E0, 262.52E0, 268.01E0, 268.62E0, 336.25E0, 337.23E0, 339.33E0, 427.38E0, 428.58E0, 432.68E0, 528.99E0, 531.08E0, 628.34E0, 253.24E0, 273.13E0, 273.66E0,
        282.10E0, 346.62E0, 347.19E0, 348.78E0, 351.18E0, 450.10E0, 450.35E0, 451.92E0, 455.56E0, 552.22E0, 553.56E0, 555.74E0, 652.59E0, 656.20E0, 14.13E0, 20.41E0, 31.30E0, 33.84E0, 39.70E0, 48.83E0, 54.50E0, 60.41E0, 72.77E0, 75.25E0, 86.84E0, 94.88E0, 96.40E0, 117.37E0, 139.08E0, 147.73E0, 158.63E0, 161.84E0, 192.11E0, 206.76E0, 209.07E0, 213.32E0, 226.44E0, 237.12E0, 330.90E0, 358.72E0, 370.77E0, 372.72E0, 396.24E0, 416.59E0, 484.02E0, 495.47E0, 514.78E0, 515.65E0, 519.47E0, 544.47E0, 560.11E0, 620.77E0, 18.97E0, 28.93E0, 33.91E0, 40.03E0, 44.66E0, 49.87E0, 55.16E0, 60.90E0, 72.08E0, 85.15E0, 97.06E0, 119.63E0, 133.27E0, 143.84E0, 161.91E0, 180.67E0, 198.44E0, 226.86E0, 229.65E0, 258.27E0, 273.77E0, 339.15E0, 350.13E0, 362.75E0, 371.03E0, 393.32E0, 448.53E0, 473.78E0, 511.12E0, 524.70E0, 548.75E0, 551.64E0, 574.02E0, 623.86E0, 21.46E0, 24.33E0, 33.43E0, 39.22E0, 44.18E0, 55.02E0, 94.33E0, 96.44E0, 118.82E0, 128.48E0,
        141.94E0, 156.92E0, 171.65E0, 190.00E0, 223.26E0, 223.88E0, 231.50E0, 265.05E0, 269.44E0, 271.78E0, 273.46E0, 334.61E0, 339.79E0, 349.52E0, 358.18E0, 377.98E0, 394.77E0, 429.66E0, 468.22E0, 487.27E0, 519.54E0, 523.03E0, 612.99E0, 638.59E0, 641.36E0, 622.05E0, 631.50E0, 663.97E0, 646.9E0, 748.29E0, 749.21E0, 750.14E0, 647.04E0, 646.89E0, 746.9E0, 748.43E0, 747.35E0, 749.27E0, 647.61E0, 747.78E0, 750.51E0, 851.37E0, 845.97E0, 847.54E0, 849.93E0, 851.61E0, 849.75E0, 850.98E0, 848.23E0)

def testNistHahn1():
    let n: Int = 7
    var info: Int
    var x: VectorXd = VectorXd(n)
    # First try
    x[0] = 10.0
    x[1] = -1.0
    x[2] = .05
    x[3] = -.00001
    x[4] = -.05
    x[5] = .001
    x[6] = -.000001
    var functor = hahn1_functor()
    var lm = LevenbergMarquardt[hahn1_functor](functor)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 11)
    VERIFY_IS_EQUAL(lm.njev(), 10)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 1.5324382854E+00)
    VERIFY_IS_APPROX(x[0], 1.0776351733E+00)
    VERIFY_IS_APPROX(x[1], -1.2269296921E-01)
    VERIFY_IS_APPROX(x[2], 4.0863750610E-03)
    VERIFY_IS_APPROX(x[3], -1.426264e-06)  # shoulde be : -1.4262662514E-06
    VERIFY_IS_APPROX(x[4], -5.7609940901E-03)
    VERIFY_IS_APPROX(x[5], 2.4053735503E-04)
    VERIFY_IS_APPROX(x[6], -1.2314450199E-07)
    # Second try
    x[0] = .1
    x[1] = -.1
    x[2] = .005
    x[3] = -.000001
    x[4] = -.005
    x[5] = .0001
    x[6] = -.0000001
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.njev(), 10)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 1.5324382854E+00)
    VERIFY_IS_APPROX(x[0], 1.077640)  # should be :  1.0776351733E+00
    VERIFY_IS_APPROX(x[1], -0.1226933)  # should be : -1.2269296921E-01
    VERIFY_IS_APPROX(x[2], 0.004086383)  # should be : 4.0863750610E-03
    VERIFY_IS_APPROX(x[3], -1.426277e-06)  # shoulde be : -1.4262662514E-06
    VERIFY_IS_APPROX(x[4], -5.7609940901E-03)
    VERIFY_IS_APPROX(x[5], 0.00024053772)  # should be : 2.4053735503E-04
    VERIFY_IS_APPROX(x[6], -1.231450e-07)  # should be : -1.2314450199E-07

struct misra1d_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 2, 14)

    static var x: StaticArray[Float64, 14]
    static var y: StaticArray[Float64, 14]

    def __call__(self borrowed, b: VectorXd, fvec: VectorXd) -> Int:
        assert(b.size() == 2)
        assert(fvec.size() == 14)
        for i in range(14):
            fvec[i] = b[0] * b[1] * self.x[i] / (1.0 + b[1] * self.x[i]) - self.y[i]
        return 0

    def df(self borrowed, b: VectorXd, fjac: MatrixXd) -> Int:
        assert(b.size() == 2)
        assert(fjac.rows() == 14)
        assert(fjac.cols() == 2)
        for i in range(14):
            let den: Float64 = 1.0 + b[1] * self.x[i]
            fjac[i, 0] = b[1] * self.x[i] / den
            fjac[i, 1] = b[0] * self.x[i] * (den - b[1] * self.x[i]) / den / den
        return 0

var misra1d_functor.x = StaticArray[Float64, 14](77.6E0, 114.9E0, 141.1E0, 190.8E0, 239.9E0, 289.0E0, 332.8E0, 378.4E0, 434.8E0, 477.3E0, 536.8E0, 593.1E0, 689.1E0, 760.0E0)
var misra1d_functor.y = StaticArray[Float64, 14](10.07E0, 14.73E0, 17.94E0, 23.93E0, 29.61E0, 35.18E0, 40.02E0, 44.82E0, 50.76E0, 55.05E0, 61.01E0, 66.40E0, 75.47E0, 81.78E0)

def testNistMisra1d():
    let n: Int = 2
    var info: Int
    var x: VectorXd = VectorXd(n)
    # First try
    x[0] = 500.0
    x[1] = 0.0001
    var functor = misra1d_functor()
    var lm = LevenbergMarquardt[misra1d_functor](functor)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 9)
    VERIFY_IS_EQUAL(lm.njev(), 7)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 5.6419295283E-02)
    VERIFY_IS_APPROX(x[0], 4.3736970754E+02)
    VERIFY_IS_APPROX(x[1], 3.0227324449E-04)
    # Second try
    x[0] = 450.0
    x[1] = 0.0003
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, 1)
    VERIFY_IS_EQUAL(lm.nfev(), 4)
    VERIFY_IS_EQUAL(lm.njev(), 3)
    VERIFY_IS_APPROX(lm.fvec().squaredNorm(), 5.6419295283E-02)
    VERIFY_IS_APPROX(x[0], 4.3736970754E+02)
    VERIFY_IS_APPROX(x[1], 3.0227324449E-04)

struct lanczos1_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 6, 24)

    static var x: StaticArray[Float64, 24]
    static var y: StaticArray[Float64, 24]

    def __call__(self borrowed, b: VectorXd, fvec: VectorXd) -> Int:
        assert(b.size() == 6)
        assert(fvec.size() == 24)
        for i in range(24):
            fvec[i] = b[0] * exp(-b[1] * self.x[i]) + b[2] * exp(-b[3] * self.x[i]) + b[4] * exp(-b[5] * self.x[i]) - self.y[i]
        return 0

    def df(self borrowed, b: VectorXd, fjac: MatrixXd) -> Int:
        assert(b.size() == 6)
        assert(fjac.rows() == 24)
        assert(fjac.cols() == 6)
        for i in range(24):
            fjac[i, 0] = exp(-b[1] * self.x[i])
            fjac[i, 1] = -b[0] * self.x[i] * exp(-b[1] * self.x[i])
            fjac[i, 2] = exp(-b[3] * self.x[i])
            fjac[i, 3] = -b[2] * self.x[i] * exp(-b[3] * self.x[i])
            fjac[i, 4] = exp(-b[5] * self.x[i])
            fjac[i, 5] = -b[4] * self.x[i] * exp(-b[5] * self.x[i])
        return 0

var lanczos1_functor.x = StaticArray[Float64, 24](0.000000000000E+00, 5.000000000000E-02, 1.000000000000E-01, 1.500000000000E-01, 2.000000000000E-01, 2.500000000000E-01, 3.000000000000E-01, 3.500000000000E-01, 4.000000000000E-01, 4.500000000000E-01, 5.000000000000E-01, 5.500000000000E-01, 6.000000000000E-01, 6.500000000000E-01, 7.000000000000E-01, 7.500000000000E-01, 8.000000000000E-01, 8.500000000000E-01, 9.000000000000E-01, 9.500000000000E-01, 1.000000000000E+00, 1.050000000000E+00, 1.100000000000E+00, 1.150000000000E+00)
var lanczos1_functor.y = StaticArray[Float64, 24](2.513400000000E+00, 2.044333373291E+00, 1.668404436564E+00, 1.366418021208E+00, 1.123232487372E+00, 9.268897180037E-01, 7.679338563728E-01, 6.388775523106E-01, 5.337835317402E-01, 4.479363617347E-01, 3.775847884350E-01, 3.197393199326E-01, 2.720130773746E-01, 2.324965529032E-01, 1.996589546065E-01, 1.722704126914E-01, 1.493405660168E-01, 1.300700206922E-01, 1.138119324644E-01, 1.000415587559E-01, 8.833209084540E-02, 7.833544019350E-02, 6.976693743449E-02, 6.239312536719E-02)

def testNistLanczos1():
    let n: Int = 6
    var info: LevenbergMarquardtSpace.Status
    var x: VectorXd = VectorXd(n)
    # First try
    x[0] = 1.2
    x[1] = 0.3
    x[2] = 5.6
    x[3] = 5.5
    x[4] = 6.5
    x[5] = 7.6
    var functor = lanczos1_functor()
    var lm = LevenbergMarquardt[lanczos1_functor](functor)
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, LevenbergMarquardtSpace.RelativeErrorTooSmall)
    VERIFY_IS_EQUAL(lm.nfev(), 79)
    VERIFY_IS_EQUAL(lm.njev(), 72)
    VERIFY(lm.fvec().squaredNorm() <= 1.4307867721E-25)
    VERIFY_IS_APPROX(x[0], 9.5100000027E-02)
    VERIFY_IS_APPROX(x[1], 1.0000000001E+00)
    VERIFY_IS_APPROX(x[2], 8.6070000013E-01)
    VERIFY_IS_APPROX(x[3], 3.0000000002E+00)
    VERIFY_IS_APPROX(x[4], 1.5575999998E+00)
    VERIFY_IS_APPROX(x[5], 5.0000000001E+00)
    # Second try
    x[0] = 0.5
    x[1] = 0.7
    x[2] = 3.6
    x[3] = 4.2
    x[4] = 4.0
    x[5] = 6.3
    info = lm.minimize(x)
    VERIFY_IS_EQUAL(info, LevenbergMarquardtSpace.RelativeErrorTooSmall)
    VERIFY_IS_EQUAL(lm.nfev(), 9)
    VERIFY_IS_EQUAL(lm.njev(), 8)
    VERIFY(lm.fvec().squaredNorm() <= 1.4307867721E-25)
    VERIFY_IS_APPROX(x[0], 9.5100000027E-02)
    VERIFY_IS_APPROX(x[1], 1.0000000001E+00)
    VERIFY_IS_APPROX(x[2], 8.6070000013E-01)
    VERIFY_IS_APPROX(x[3], 3.0000000002E+00)
    VERIFY_IS_APPROX(x[4], 1.5575999998E+00)
    VERIFY_IS_APPROX(x[5], 5.0000000001E+00)

struct rat42_functor(DenseFunctor[Float64]):
    def __init__(self):
        DenseFunctor[Float64].__init__(self, 3, 9)

    static var x: StaticArray[Float64, 9]
    static var y: StaticArray[Float64, 9]

    def __call__(self borrowed, b: VectorXd, fvec: VectorXd) -> Int:
        assert(b.size() == 3)
        assert(fvec.size() == 9)
        for i in range(9):
            fvec[i] = b[0] / (1.0 + exp(b[1] - b[2] * self.x[i])) - self.y[i]
        return 0

    def df(self borrowed, b: VectorXd, fjac: MatrixXd) -> Int:
