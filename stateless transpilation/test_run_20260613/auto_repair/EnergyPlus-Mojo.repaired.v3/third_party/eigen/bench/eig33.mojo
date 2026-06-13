from math import sqrt, atan2, cos, sin
from  import BenchTimer

# Assume an Eigen-like module provides Matrix3d, Vector3d, SelfAdjointEigenSolver, etc.
from eigen import Matrix3d, Vector3d, SelfAdjointEigenSolver, NumTraits

def computeRoots[MatrixType: Object, RootsType: Object](m: MatrixType, roots: RootsType):
    # typedef Matrix::Scalar Scalar;
    var Scalar = Float64  # using concrete scalar type
    var s_inv3 = 1.0 / 3.0
    var s_sqrt3 = sqrt(Scalar(3.0))
    var c0 = m[0, 0] * m[1, 1] * m[2, 2] + Scalar(2) * m[0, 1] * m[0, 2] * m[1, 2] - m[0, 0] * m[1, 2] * m[1, 2] - m[1, 1] * m[0, 2] * m[0, 2] - m[2, 2] * m[0, 1] * m[0, 1]
    var c1 = m[0, 0] * m[1, 1] - m[0, 1] * m[0, 1] + m[0, 0] * m[2, 2] - m[0, 2] * m[0, 2] + m[1, 1] * m[2, 2] - m[1, 2] * m[1, 2]
    var c2 = m[0, 0] + m[1, 1] + m[2, 2]
    var c2_over_3 = c2 * s_inv3
    var a_over_3 = (c1 - c2 * c2_over_3) * s_inv3
    if a_over_3 > Scalar(0):
        a_over_3 = Scalar(0)
    var half_b = Scalar(0.5) * (c0 + c2_over_3 * (Scalar(2) * c2_over_3 * c2_over_3 - c1))
    var q = half_b * half_b + a_over_3 * a_over_3 * a_over_3
    if q > Scalar(0):
        q = Scalar(0)
    var rho = sqrt(-a_over_3)
    var theta = atan2(sqrt(-q), half_b) * s_inv3
    var cos_theta = cos(theta)
    var sin_theta = sin(theta)
    roots[2] = c2_over_3 + Scalar(2) * rho * cos_theta
    roots[0] = c2_over_3 - rho * (cos_theta + s_sqrt3 * sin_theta)
    roots[1] = c2_over_3 - rho * (cos_theta - s_sqrt3 * sin_theta)

def eigen33[MatrixType: Object, VectorType: Object](mat: MatrixType, evecs: MatrixType, evals: VectorType):
    var Scalar = Float64
    var shift = mat.trace() / 3
    var scaledMat = mat
    scaledMat.diagonal().array() -= shift
    var scale = scaledMat.cwiseAbs().maxCoeff()
    scale = max(scale, Scalar(1))
    scaledMat /= scale
    computeRoots(scaledMat, evals)
    if (evals[2] - evals[0]) <= NumTraits[Scalar].epsilon():
        evecs.setIdentity()
    else:
        var tmp: MatrixType
        tmp = scaledMat
        tmp.diagonal().array() -= evals[2]
        evecs.col(2).copy(tmp.row(0).cross(tmp.row(1)).normalized())
        tmp = scaledMat
        tmp.diagonal().array() -= evals[1]
        evecs.col(1).copy(tmp.row(0).cross(tmp.row(1)))
        var n1 = evecs.col(1).norm()
        if n1 <= NumTraits[Scalar].epsilon():
            evecs.col(1).copy(evecs.col(2).unitOrthogonal())
        else:
            evecs.col(1) /= n1
        evecs.col(1).copy(evecs.col(2).cross(evecs.col(1).cross(evecs.col(2))).normalized())
        evecs.col(0).copy(evecs.col(2).cross(evecs.col(1)))
    evals *= scale
    evals.array() += shift

def main():
    var t = BenchTimer()
    var tries = 10
    var rep = 400000
    # typedef Matrix3d Mat;
    # typedef Vector3d Vec;
    var A = Matrix3d.Random(3, 3)
    A = A.adjoint() * A
    var eig = SelfAdjointEigenSolver[Matrix3d](A)
    BENCH(t, tries, rep, eig.compute(A))
    print("Eigen iterative:  ", t.best(), "s")
    BENCH(t, tries, rep, eig.computeDirect(A))
    print("Eigen direct   :  ", t.best(), "s")
    var evecs: Matrix3d
    var evals: Vector3d
    BENCH(t, tries, rep, eigen33(A, evecs, evals))
    print("Direct: ", t.best(), "s\n")