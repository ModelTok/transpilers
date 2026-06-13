from main import VERIFY, VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, test_precision, g_repeat, internal
from unsupported.Eigen.EulerAngles import \
    EulerAngles, EulerSystemXYZ, EulerSystemXYX, EulerSystemXZY, EulerSystemXZX, \
    EulerSystemYZX, EulerSystemYZY, EulerSystemYXZ, EulerSystemYXY, \
    EulerSystemZXY, EulerSystemZXZ, EulerSystemZYX, EulerSystemZYZ
from Eigen import Matrix, Quaternion, AngleAxis

def verify_euler_ranged[EulerSystem: AnyType, Scalar: AnyType](ea: Matrix[Scalar, 3, 1],
  positiveRangeAlpha: Bool, positiveRangeBeta: Bool, positiveRangeGamma: Bool):
  alias EulerAnglesType = EulerAngles[Scalar, EulerSystem]
  alias Matrix3 = Matrix[Scalar, 3, 3]
  alias Vector3 = Matrix[Scalar, 3, 1]
  alias QuaternionType = Quaternion[Scalar]
  alias AngleAxisType = AngleAxis[Scalar]
  from math import abs
  var alphaRangeStart: Scalar
  var alphaRangeEnd: Scalar
  var betaRangeStart: Scalar
  var betaRangeEnd: Scalar
  var gammaRangeStart: Scalar
  var gammaRangeEnd: Scalar
  if positiveRangeAlpha:
    alphaRangeStart = Scalar(0)
    alphaRangeEnd = Scalar(2 * EIGEN_PI)
  else:
    alphaRangeStart = -Scalar(EIGEN_PI)
    alphaRangeEnd = Scalar(EIGEN_PI)
  if positiveRangeBeta:
    betaRangeStart = Scalar(0)
    betaRangeEnd = Scalar(2 * EIGEN_PI)
  else:
    betaRangeStart = -Scalar(EIGEN_PI)
    betaRangeEnd = Scalar(EIGEN_PI)
  if positiveRangeGamma:
    gammaRangeStart = Scalar(0)
    gammaRangeEnd = Scalar(2 * EIGEN_PI)
  else:
    gammaRangeStart = -Scalar(EIGEN_PI)
    gammaRangeEnd = Scalar(EIGEN_PI)
  var i = EulerSystem.AlphaAxisAbs - 1
  var j = EulerSystem.BetaAxisAbs - 1
  var k = EulerSystem.GammaAxisAbs - 1
  var iFactor = 1 if not EulerSystem.IsAlphaOpposite else -1
  var jFactor = 1 if not EulerSystem.IsBetaOpposite else -1
  var kFactor = 1 if not EulerSystem.IsGammaOpposite else -1
  var I = EulerAnglesType.AlphaAxisVector()
  var J = EulerAnglesType.BetaAxisVector()
  var K = EulerAnglesType.GammaAxisVector()
  var e = EulerAnglesType(ea[0], ea[1], ea[2])
  var m = Matrix3(e)
  var eabis = EulerAnglesType(m, positiveRangeAlpha, positiveRangeBeta, positiveRangeGamma).angles()
  VERIFY(alphaRangeStart <= eabis[0] and eabis[0] <= alphaRangeEnd)
  VERIFY(betaRangeStart <= eabis[1] and eabis[1] <= betaRangeEnd)
  VERIFY(gammaRangeStart <= eabis[2] and eabis[2] <= gammaRangeEnd)
  var eabis2 = m.eulerAngles(i, j, k)
  eabis2[0] *= iFactor
  eabis2[1] *= jFactor
  eabis2[2] *= kFactor
  if positiveRangeAlpha and (eabis2[0] < 0):
    eabis2[0] += Scalar(2 * EIGEN_PI)
  if positiveRangeBeta and (eabis2[1] < 0):
    eabis2[1] += Scalar(2 * EIGEN_PI)
  if positiveRangeGamma and (eabis2[2] < 0):
    eabis2[2] += Scalar(2 * EIGEN_PI)
  VERIFY_IS_APPROX(eabis, eabis2)  # Verify that our estimation is the same as m.eulerAngles() is
  var mbis = Matrix3(AngleAxisType(eabis[0], I) * AngleAxisType(eabis[1], J) * AngleAxisType(eabis[2], K))
  VERIFY_IS_APPROX(m, mbis)
  if not (positiveRangeAlpha or positiveRangeBeta or positiveRangeGamma):
    /* If I==K, and ea[1]==0, then there no unique solution. */
    /* The remark apply in the case where I!=K, and |ea[1]| is close to pi/2. */
    if (i != k or ea[1] != 0) and (i == k or not internal.isApprox(abs(ea[1]), Scalar(EIGEN_PI / 2), test_precision[Scalar]())):
      VERIFY((ea - eabis).norm() <= test_precision[Scalar]())
    VERIFY(0 < eabis[0] or test_isMuchSmallerThan(eabis[0], Scalar(1)))
  var q = QuaternionType(e)
  eabis = EulerAnglesType(q, positiveRangeAlpha, positiveRangeBeta, positiveRangeGamma).angles()
  VERIFY_IS_APPROX(eabis, eabis2)  # Verify that the euler angles are still the same

def verify_euler[EulerSystem: AnyType, Scalar: AnyType](ea: Matrix[Scalar, 3, 1]):
  verify_euler_ranged[EulerSystem](ea, False, False, False)
  verify_euler_ranged[EulerSystem](ea, False, False, True)
  verify_euler_ranged[EulerSystem](ea, False, True, False)
  verify_euler_ranged[EulerSystem](ea, False, True, True)
  verify_euler_ranged[EulerSystem](ea, True, False, False)
  verify_euler_ranged[EulerSystem](ea, True, False, True)
  verify_euler_ranged[EulerSystem](ea, True, True, False)
  verify_euler_ranged[EulerSystem](ea, True, True, True)

def check_all_var[Scalar: AnyType](ea: Matrix[Scalar, 3, 1]):
  verify_euler[EulerSystemXYZ](ea)
  verify_euler[EulerSystemXYX](ea)
  verify_euler[EulerSystemXZY](ea)
  verify_euler[EulerSystemXZX](ea)
  verify_euler[EulerSystemYZX](ea)
  verify_euler[EulerSystemYZY](ea)
  verify_euler[EulerSystemYXZ](ea)
  verify_euler[EulerSystemYXY](ea)
  verify_euler[EulerSystemZXY](ea)
  verify_euler[EulerSystemZXZ](ea)
  verify_euler[EulerSystemZYX](ea)
  verify_euler[EulerSystemZYZ](ea)

def eulerangles[Scalar: AnyType]():
  alias Matrix3 = Matrix[Scalar, 3, 3]
  alias Vector3 = Matrix[Scalar, 3, 1]
  alias Array3 = Array[Scalar, 3, 1]
  alias Quaternionx = Quaternion[Scalar]
  alias AngleAxisType = AngleAxis[Scalar]
  var a = internal.random[Scalar](-Scalar(EIGEN_PI), Scalar(EIGEN_PI))
  var q1: Quaternionx
  q1 = AngleAxisType(a, Vector3.Random().normalized())
  var m: Matrix3
  m = q1
  var ea = m.eulerAngles(0, 1, 2)
  check_all_var(ea)
  ea = m.eulerAngles(0, 1, 0)
  check_all_var(ea)
  q1.coeffs() = Quaternionx.Coefficients.Random().normalized()
  m = q1
  ea = m.eulerAngles(0, 1, 2)
  check_all_var(ea)
  ea = m.eulerAngles(0, 1, 0)
  check_all_var(ea)
  ea = (Array3.Random() + Array3(1, 0, 0)) * Scalar(EIGEN_PI) * Array3(0.5, 1, 1)
  check_all_var(ea)
  ea[2] = ea[0] = internal.random[Scalar](0, Scalar(EIGEN_PI))
  check_all_var(ea)
  ea[0] = ea[1] = internal.random[Scalar](0, Scalar(EIGEN_PI))
  check_all_var(ea)
  ea[1] = 0
  check_all_var(ea)
  ea.head(2).setZero()
  check_all_var(ea)
  ea.setZero()
  check_all_var(ea)

def test_EulerAngles():
  for i in range(g_repeat):
    CALL_SUBTEST_1(eulerangles[float32]())
    CALL_SUBTEST_2(eulerangles[float64]())