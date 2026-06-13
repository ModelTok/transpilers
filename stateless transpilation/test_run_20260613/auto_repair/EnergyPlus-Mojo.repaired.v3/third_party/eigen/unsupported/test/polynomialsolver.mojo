from main import *
from unsupported.Eigen.Polynomials import *
from iostream import *
from algorithm import *
from memory import Pointer
from math import abs, sqrt
from complex import Complex
from sys import info as sys_info

# using namespace std;  # Mojo doesn't have namespaces, we import directly

# namespace Eigen {
# namespace internal {
# template<int Size>
# struct increment_if_fixed_size
# {
#   enum {
#     ret = (Size == Dynamic) ? Dynamic : Size+1
#   };
# };
# }
# }

struct increment_if_fixed_size[Size: Int]:
    alias ret = Dynamic if Size == Dynamic else Size + 1

# template<int Deg, POLYNOMIAL, SOLVER>
# bool aux_evalSolver( POLYNOMIAL& pols , SOLVER& psolve )
def aux_evalSolver[Deg: Int, POLYNOMIAL: AnyType, SOLVER: AnyType](pols: POLYNOMIAL, psolve: SOLVER) -> Bool:
    # typedef POLYNOMIAL::Scalar Scalar;
    alias Scalar = POLYNOMIAL.Scalar
    # typedef SOLVER::RootsType    RootsType;
    alias RootsType = SOLVER.RootsType
    # typedef Matrix<Scalar,Deg,1>          EvalRootsType;
    alias EvalRootsType = Matrix[Scalar, Deg, 1]
    # Index deg = pols.size()-1;
    let deg: Index = pols.size() - 1
    # SOLVER solve_constr (pols);
    let solve_constr: SOLVER = SOLVER(pols)
    # psolve.compute( pols );
    psolve.compute(pols)
    # const RootsType& roots( psolve.roots() );
    let roots: RootsType = psolve.roots()
    # EvalRootsType evr( deg );
    var evr: EvalRootsType = EvalRootsType(deg)
    # for( int i=0; i<roots.size(); ++i ){
    #   evr[i] = abs( poly_eval( pols, roots[i] ) ); }
    for i in range(roots.size()):
        evr[i] = abs(poly_eval(pols, roots[i]))
    # bool evalToZero = evr.isZero( test_precision<Scalar>() );
    let evalToZero: Bool = evr.isZero(test_precision[Scalar]())
    # if( !evalToZero )
    # {
    #   cerr << "WRONG root: " << endl;
    #   cerr << "Polynomial: " << pols.transpose() << endl;
    #   cerr << "Roots found: " << roots.transpose() << endl;
    #   cerr << "Abs value of the polynomial at the roots: " << evr.transpose() << endl;
    #   cerr << endl;
    # }
    if not evalToZero:
        cerr << "WRONG root: " << endl
        cerr << "Polynomial: " << pols.transpose() << endl
        cerr << "Roots found: " << roots.transpose() << endl
        cerr << "Abs value of the polynomial at the roots: " << evr.transpose() << endl
        cerr << endl
    # vector<Scalar> rootModuli( roots.size() );
    var rootModuli: List[Scalar] = List[Scalar](roots.size())
    # Map< EvalRootsType > aux( &rootModuli[0], roots.size() );
    # aux = roots.array().abs();
    # sort( rootModuli.begin(), rootModuli.end() );
    for i in range(roots.size()):
        rootModuli[i] = abs(roots[i])
    rootModuli.sort()
    # bool distinctModuli=true;
    var distinctModuli: Bool = True
    # for( size_t i=1; i<rootModuli.size() && distinctModuli; ++i )
    # {
    #   if( internal::isApprox( rootModuli[i], rootModuli[i-1] ) ){
    #     distinctModuli = false; }
    # }
    for i in range(1, rootModuli.size):
        if not distinctModuli:
            break
        if isApprox(rootModuli[i], rootModuli[i-1]):
            distinctModuli = False
    # VERIFY( evalToZero || !distinctModuli );
    VERIFY(evalToZero or not distinctModuli)
    # return distinctModuli;
    return distinctModuli

# template<int Deg, POLYNOMIAL>
# void evalSolver( POLYNOMIAL& pols )
def evalSolver[Deg: Int, POLYNOMIAL: AnyType](pols: POLYNOMIAL):
    # typedef POLYNOMIAL::Scalar Scalar;
    alias Scalar = POLYNOMIAL.Scalar
    # typedef PolynomialSolver<Scalar, Deg >              PolynomialSolverType;
    alias PolynomialSolverType = PolynomialSolver[Scalar, Deg]
    # PolynomialSolverType psolve;
    var psolve: PolynomialSolverType = PolynomialSolverType()
    # aux_evalSolver<Deg, POLYNOMIAL, PolynomialSolverType>( pols, psolve );
    aux_evalSolver[Deg, POLYNOMIAL, PolynomialSolverType](pols, psolve)

# template< int Deg, POLYNOMIAL, ROOTS, REAL_ROOTS >
# void evalSolverSugarFunction( POLYNOMIAL& pols , ROOTS& roots , REAL_ROOTS& real_roots )
def evalSolverSugarFunction[Deg: Int, POLYNOMIAL: AnyType, ROOTS: AnyType, REAL_ROOTS: AnyType](pols: POLYNOMIAL, roots: ROOTS, real_roots: REAL_ROOTS):
    # using sqrt;
    # typedef POLYNOMIAL::Scalar Scalar;
    alias Scalar = POLYNOMIAL.Scalar
    # typedef PolynomialSolver<Scalar, Deg >              PolynomialSolverType;
    alias PolynomialSolverType = PolynomialSolver[Scalar, Deg]
    # PolynomialSolverType psolve;
    var psolve: PolynomialSolverType = PolynomialSolverType()
    # if( aux_evalSolver<Deg, POLYNOMIAL, PolynomialSolverType>( pols, psolve ) )
    if aux_evalSolver[Deg, POLYNOMIAL, PolynomialSolverType](pols, psolve):
        # typedef REAL_ROOTS::Scalar                 Real;
        alias Real = REAL_ROOTS.Scalar
        # vector< Real > calc_realRoots;
        var calc_realRoots: List[Real] = List[Real]()
        # psolve.realRoots( calc_realRoots );
        psolve.realRoots(calc_realRoots)
        # VERIFY( calc_realRoots.size() == (size_t)real_roots.size() );
        VERIFY(calc_realRoots.size == real_roots.size())
        # Scalar psPrec = sqrt( test_precision<Scalar>() );
        let psPrec: Scalar = sqrt(test_precision[Scalar]())
        # for( size_t i=0; i<calc_realRoots.size(); ++i )
        # {
        #   bool found = false;
        #   for( size_t j=0; j<calc_realRoots.size()&& !found; ++j )
        #   {
        #     if( internal::isApprox( calc_realRoots[i], real_roots[j], psPrec ) ){
        #       found = true; }
        #   }
        #   VERIFY( found );
        # }
        for i in range(calc_realRoots.size):
            var found: Bool = False
            for j in range(calc_realRoots.size):
                if found:
                    break
                if isApprox(calc_realRoots[i], real_roots[j], psPrec):
                    found = True
            VERIFY(found)
        # VERIFY( internal::isApprox( roots.array().abs().maxCoeff(),
        #       abs( psolve.greatestRoot() ), psPrec ) );
        VERIFY(isApprox(roots.array().abs().maxCoeff(), abs(psolve.greatestRoot()), psPrec))
        # VERIFY( internal::isApprox( roots.array().abs().minCoeff(),
        #       abs( psolve.smallestRoot() ), psPrec ) );
        VERIFY(isApprox(roots.array().abs().minCoeff(), abs(psolve.smallestRoot()), psPrec))
        # bool hasRealRoot;
        var hasRealRoot: Bool
        # Real r = psolve.absGreatestRealRoot( hasRealRoot );
        var r: Real = psolve.absGreatestRealRoot(hasRealRoot)
        # VERIFY( hasRealRoot == (real_roots.size() > 0 ) );
        VERIFY(hasRealRoot == (real_roots.size() > 0))
        # if( hasRealRoot ){
        #   VERIFY( internal::isApprox( real_roots.array().abs().maxCoeff(), abs(r), psPrec ) );  }
        if hasRealRoot:
            VERIFY(isApprox(real_roots.array().abs().maxCoeff(), abs(r), psPrec))
        # r = psolve.absSmallestRealRoot( hasRealRoot );
        r = psolve.absSmallestRealRoot(hasRealRoot)
        # VERIFY( hasRealRoot == (real_roots.size() > 0 ) );
        VERIFY(hasRealRoot == (real_roots.size() > 0))
        # if( hasRealRoot ){
        #   VERIFY( internal::isApprox( real_roots.array().abs().minCoeff(), abs( r ), psPrec ) ); }
        if hasRealRoot:
            VERIFY(isApprox(real_roots.array().abs().minCoeff(), abs(r), psPrec))
        # r = psolve.greatestRealRoot( hasRealRoot );
        r = psolve.greatestRealRoot(hasRealRoot)
        # VERIFY( hasRealRoot == (real_roots.size() > 0 ) );
        VERIFY(hasRealRoot == (real_roots.size() > 0))
        # if( hasRealRoot ){
        #   VERIFY( internal::isApprox( real_roots.array().maxCoeff(), r, psPrec ) ); }
        if hasRealRoot:
            VERIFY(isApprox(real_roots.array().maxCoeff(), r, psPrec))
        # r = psolve.smallestRealRoot( hasRealRoot );
        r = psolve.smallestRealRoot(hasRealRoot)
        # VERIFY( hasRealRoot == (real_roots.size() > 0 ) );
        VERIFY(hasRealRoot == (real_roots.size() > 0))
        # if( hasRealRoot ){
        #   VERIFY( internal::isApprox( real_roots.array().minCoeff(), r, psPrec ) ); }
        if hasRealRoot:
            VERIFY(isApprox(real_roots.array().minCoeff(), r, psPrec))

# template<_Scalar, int _Deg>
# void polynomialsolver(int deg)
def polynomialsolver[_Scalar: AnyType, _Deg: Int](deg: Int):
    # typedef internal::increment_if_fixed_size<_Deg>            Dim;
    alias Dim = increment_if_fixed_size[_Deg]
    # typedef Matrix<_Scalar,Dim::ret,1>                  PolynomialType;
    alias PolynomialType = Matrix[_Scalar, Dim.ret, 1]
    # typedef Matrix<_Scalar,_Deg,1>                      EvalRootsType;
    alias EvalRootsType = Matrix[_Scalar, _Deg, 1]
    # cout << "Standard cases" << endl;
    cout << "Standard cases" << endl
    # PolynomialType pols = PolynomialType::Random(deg+1);
    var pols: PolynomialType = PolynomialType.Random(deg + 1)
    # evalSolver<_Deg,PolynomialType>( pols );
    evalSolver[_Deg, PolynomialType](pols)
    # cout << "Hard cases" << endl;
    cout << "Hard cases" << endl
    # _Scalar multipleRoot = internal::random<_Scalar>();
    let multipleRoot: _Scalar = random[_Scalar]()
    # EvalRootsType allRoots = EvalRootsType::Constant(deg,multipleRoot);
    var allRoots: EvalRootsType = EvalRootsType.Constant(deg, multipleRoot)
    # roots_to_monicPolynomial( allRoots, pols );
    roots_to_monicPolynomial(allRoots, pols)
    # evalSolver<_Deg,PolynomialType>( pols );
    evalSolver[_Deg, PolynomialType](pols)
    # cout << "Test sugar" << endl;
    cout << "Test sugar" << endl
    # EvalRootsType realRoots = EvalRootsType::Random(deg);
    var realRoots: EvalRootsType = EvalRootsType.Random(deg)
    # roots_to_monicPolynomial( realRoots, pols );
    roots_to_monicPolynomial(realRoots, pols)
    # evalSolverSugarFunction<_Deg>(
    #     pols,
    #     realRoots.template cast <
    #                   complex<
    #                        NumTraits<_Scalar>::Real
    #                        >
    #                   >(),
    #     realRoots );
    evalSolverSugarFunction[_Deg](
        pols,
        realRoots.cast[Complex[NumTraits[_Scalar].Real]](),
        realRoots
    )

# void test_polynomialsolver()
def test_polynomialsolver():
    # for(int i = 0; i < g_repeat; i++)
    for i in range(g_repeat):
        # {
        #   CALL_SUBTEST_1( (polynomialsolver<float,1>(1)) );
        CALL_SUBTEST_1(polynomialsolver[Float32, 1](1))
        #   CALL_SUBTEST_2( (polynomialsolver<double,2>(2)) );
        CALL_SUBTEST_2(polynomialsolver[Float64, 2](2))
        #   CALL_SUBTEST_3( (polynomialsolver<double,3>(3)) );
        CALL_SUBTEST_3(polynomialsolver[Float64, 3](3))
        #   CALL_SUBTEST_4( (polynomialsolver<float,4>(4)) );
        CALL_SUBTEST_4(polynomialsolver[Float32, 4](4))
        #   CALL_SUBTEST_5( (polynomialsolver<double,5>(5)) );
        CALL_SUBTEST_5(polynomialsolver[Float64, 5](5))
        #   CALL_SUBTEST_6( (polynomialsolver<float,6>(6)) );
        CALL_SUBTEST_6(polynomialsolver[Float32, 6](6))
        #   CALL_SUBTEST_7( (polynomialsolver<float,7>(7)) );
        CALL_SUBTEST_7(polynomialsolver[Float32, 7](7))
        #   CALL_SUBTEST_8( (polynomialsolver<double,8>(8)) );
        CALL_SUBTEST_8(polynomialsolver[Float64, 8](8))
        #   CALL_SUBTEST_9( (polynomialsolver<float,Dynamic>(
        #           internal::random<int>(9,13)
        #           )) );
        CALL_SUBTEST_9(polynomialsolver[Float32, Dynamic](random[Int32](9, 13)))
        #   CALL_SUBTEST_10((polynomialsolver<double,Dynamic>(
        #           internal::random<int>(9,13)
        #           )) );
        CALL_SUBTEST_10(polynomialsolver[Float64, Dynamic](random[Int32](9, 13)))
        #   CALL_SUBTEST_11((polynomialsolver<float,Dynamic>(1)) );
        CALL_SUBTEST_11(polynomialsolver[Float32, Dynamic](1))
        # }