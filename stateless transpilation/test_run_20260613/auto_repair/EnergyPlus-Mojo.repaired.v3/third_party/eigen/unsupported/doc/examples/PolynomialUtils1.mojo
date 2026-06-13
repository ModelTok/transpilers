from Eigen import Vector4d, Matrix, roots_to_monicPolynomial, poly_eval

def main():
    var roots = Vector4d.Random()
    print("Roots: ", roots.transpose())

    var polynomial: Matrix[float64, 5, 1]
    roots_to_monicPolynomial(roots, inout polynomial)

    print("Polynomial: ", end="")
    for i in range(4):
        print(polynomial[i], ".x^", i, "+ ", end="")
    print(polynomial[4], ".x^4")

    var evaluation: Vector4d
    for i in range(4):
        evaluation[i] = poly_eval(polynomial, roots[i])

    print("Evaluation of the polynomial at the roots: ", evaluation.transpose())