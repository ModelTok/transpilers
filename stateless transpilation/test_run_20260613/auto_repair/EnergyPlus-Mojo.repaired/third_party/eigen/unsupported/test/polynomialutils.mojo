from main import *
from unsupported.Eigen.Polynomials import *
from iostream import *
namespace Eigen:
    namespace internal:
        struct increment_if_fixed_size[Size: Int]:
            enum:
                ret = (Dynamic if Size == Dynamic else Size + 1)

def realRoots_to_monicPolynomial_test[_Scalar: AnyType, _Deg: Int](deg: Int):
    typedef internal.increment_if_fixed_size[_Deg] Dim
    typedef Matrix[_Scalar, Dim.ret, 1] PolynomialType
    typedef Matrix[_Scalar, _Deg, 1] EvalRootsType
    var pols: PolynomialType = PolynomialType(deg + 1)
    var roots: EvalRootsType = EvalRootsType.Random(deg)
    roots_to_monicPolynomial(roots, pols)
    var evr: EvalRootsType = EvalRootsType(deg)
    for i in range(roots.size()):
        evr[i] = abs(poly_eval(pols, roots[i]))
    var evalToZero: Bool = evr.isZero(test_precision[_Scalar]())
    if not evalToZero:
        cerr << evr.transpose() << endl
    VERIFY(evalToZero)

def realRoots_to_monicPolynomial_scalar[_Scalar: AnyType]():
    CALL_SUBTEST_2(realRoots_to_monicPolynomial_test[_Scalar, 2](2))
    CALL_SUBTEST_3(realRoots_to_monicPolynomial_test[_Scalar, 3](3))
    CALL_SUBTEST_4(realRoots_to_monicPolynomial_test[_Scalar, 4](4))
    CALL_SUBTEST_5(realRoots_to_monicPolynomial_test[_Scalar, 5](5))
    CALL_SUBTEST_6(realRoots_to_monicPolynomial_test[_Scalar, 6](6))
    CALL_SUBTEST_7(realRoots_to_monicPolynomial_test[_Scalar, 7](7))
    CALL_SUBTEST_8(realRoots_to_monicPolynomial_test[_Scalar, 17](17))
    CALL_SUBTEST_9(realRoots_to_monicPolynomial_test[_Scalar, Dynamic](internal.random[Int](18, 26)))

def CauchyBounds[_Scalar: AnyType, _Deg: Int](deg: Int):
    typedef internal.increment_if_fixed_size[_Deg] Dim
    typedef Matrix[_Scalar, Dim.ret, 1] PolynomialType
    typedef Matrix[_Scalar, _Deg, 1] EvalRootsType
    var pols: PolynomialType = PolynomialType(deg + 1)
    var roots: EvalRootsType = EvalRootsType.Random(deg)
    roots_to_monicPolynomial(roots, pols)
    var M: _Scalar = cauchy_max_bound(pols)
    var m: _Scalar = cauchy_min_bound(pols)
    var Max: _Scalar = roots.array().abs().maxCoeff()
    var min: _Scalar = roots.array().abs().minCoeff()
    var eval: Bool = (M >= Max) and (m <= min)
    if not eval:
        cerr << "Roots: " << roots << endl
        cerr << "Bounds: (" << m << ", " << M << ")" << endl
        cerr << "Min,Max: (" << min << ", " << Max << ")" << endl
    VERIFY(eval)

def CauchyBounds_scalar[_Scalar: AnyType]():
    CALL_SUBTEST_2(CauchyBounds[_Scalar, 2](2))
    CALL_SUBTEST_3(CauchyBounds[_Scalar, 3](3))
    CALL_SUBTEST_4(CauchyBounds[_Scalar, 4](4))
    CALL_SUBTEST_5(CauchyBounds[_Scalar, 5](5))
    CALL_SUBTEST_6(CauchyBounds[_Scalar, 6](6))
    CALL_SUBTEST_7(CauchyBounds[_Scalar, 7](7))
    CALL_SUBTEST_8(CauchyBounds[_Scalar, 17](17))
    CALL_SUBTEST_9(CauchyBounds[_Scalar, Dynamic](internal.random[Int](18, 26)))

def test_polynomialutils():
    for i in range(g_repeat):
        realRoots_to_monicPolynomial_scalar[Float64]()
        realRoots_to_monicPolynomial_scalar[Float32]()
        CauchyBounds_scalar[Float64]()
        CauchyBounds_scalar[Float32]()