from Eigen import *
from unsupported.Eigen.Polynomials import *
from vector import *
from iostream import *
from complex import *
from cmath import *

def main():
    typedef Matrix[float64, 5, 1] Vector5d
    var roots: Vector5d = Vector5d.Random()
    print("Roots: ", roots.transpose())
    var polynomial: Matrix[float64, 6, 1]
    roots_to_monicPolynomial(roots, polynomial)
    var psolve: PolynomialSolver[float64, 5] = PolynomialSolver[float64, 5](polynomial)
    print("Complex roots: ", psolve.roots().transpose())
    var realRoots: List[float64] = List[float64]()
    psolve.realRoots(realRoots)
    var mapRR: Map[Vector5d] = Map[Vector5d](realRoots.data)
    print("Real roots: ", mapRR.transpose())
    print("")
    print("Illustration of the convergence problem with the QR algorithm: ")
    print("---------------------------------------------------------------")
    var hardCase_polynomial: Matrix[float32, 7, 1]
    hardCase_polynomial = Matrix[float32, 7, 1](
        -0.957, 0.9219, 0.3516, 0.9453, -0.4023, -0.5508, -0.03125
    )
    print("Hard case polynomial defined by floats: ", hardCase_polynomial.transpose())
    var psolvef: PolynomialSolver[float32, 6] = PolynomialSolver[float32, 6](hardCase_polynomial)
    print("Complex roots: ", psolvef.roots().transpose())
    var evals: Matrix[float32, 6, 1]
    for i in range(6):
        evals[i] = abs(poly_eval(hardCase_polynomial, psolvef.roots()[i]))
    print("Norms of the evaluations of the polynomial at the roots: ", evals.transpose())
    print("")
    print("Using double's almost always solves the problem for small degrees: ")
    print("-------------------------------------------------------------------")
    var psolve6d: PolynomialSolver[float64, 6] = PolynomialSolver[float64, 6](hardCase_polynomial.cast[float64]())
    print("Complex roots: ", psolve6d.roots().transpose())
    for i in range(6):
        var castedRoot: Complex[float32] = Complex[float32](psolve6d.roots()[i].real(), psolve6d.roots()[i].imag())
        evals[i] = abs(poly_eval(hardCase_polynomial, castedRoot))
    print("Norms of the evaluations of the polynomial at the roots: ", evals.transpose())
    print("")
    print("The last root in float then in double: ", psolvef.roots()[5], "\t", psolve6d.roots()[5])
    var castedRoot2: Complex[float32] = Complex[float32](psolve6d.roots()[5].real(), psolve6d.roots()[5].imag())
    print("Norm of the difference: ", abs(psolvef.roots()[5] - castedRoot2))