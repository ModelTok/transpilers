from main import *
from Eigen import *
from mpfr import *
from python import sys

def test_mpreal_support():
    mpreal.set_default_prec(256)

    typealias MatrixXmp = Matrix[mpreal, Dynamic, Dynamic]
    typealias MatrixXcmp = Matrix[complex[mpreal], Dynamic, Dynamic]

    print("epsilon =         ", NumTraits[mpreal].epsilon(), file=sys.stderr)
    print("dummy_precision = ", NumTraits[mpreal].dummy_precision(), file=sys.stderr)
    print("highest =         ", NumTraits[mpreal].highest(), file=sys.stderr)
    print("lowest =          ", NumTraits[mpreal].lowest(), file=sys.stderr)
    print("digits10 =        ", NumTraits[mpreal].digits10(), file=sys.stderr)

    for i in range(g_repeat):
        let s = Eigen.internal.random[int](1, 100)
        var A = MatrixXmp.Random(s, s)
        var B = MatrixXmp.Random(s, s)
        var S = A.adjoint() * A
        var X: MatrixXmp
        var Ac = MatrixXcmp.Random(s, s)
        var Bc = MatrixXcmp.Random(s, s)
        var Sc = Ac.adjoint() * Ac
        var Xc: MatrixXcmp

        VERIFY_IS_APPROX(A.real(), A)
        VERIFY(Eigen.internal.isApprox(A.array().abs2().sum(), A.squaredNorm()))
        VERIFY_IS_APPROX(A.array().exp(), exp(A.array()))
        VERIFY_IS_APPROX(A.array().abs2().sqrt(), A.array().abs())
        VERIFY_IS_APPROX(A.array().sin(), sin(A.array()))
        VERIFY_IS_APPROX(A.array().cos(), cos(A.array()))

        X = S.selfadjointView[Lower]().llt().solve(B)
        VERIFY_IS_APPROX((S.selfadjointView[Lower]() * X).eval(), B)
        Xc = Sc.selfadjointView[Lower]().llt().solve(Bc)
        VERIFY_IS_APPROX((Sc.selfadjointView[Lower]() * Xc).eval(), Bc)

        X = A.lu().solve(B)
        VERIFY_IS_APPROX((A * X).eval(), B)

        var eig = SelfAdjointEigenSolver[MatrixXmp](S)
        VERIFY_IS_EQUAL(eig.info(), Success)
        VERIFY((S.selfadjointView[Lower]() * eig.eigenvectors()).isApprox(eig.eigenvectors() * eig.eigenvalues().asDiagonal(), NumTraits[mpreal].dummy_precision() * 1e3))

    {
        var A = MatrixXmp(8, 3)
        A.setRandom()
        var stream = StringIO()
        stream.write(str(A))
    }