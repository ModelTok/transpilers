from main import *
from internal import random
from DenseIndex import DenseIndex
from Matrix import Matrix, MatrixColMaj, MatrixRowMaj
from VERIFY_IS_APPROX import VERIFY_IS_APPROX
from CALL_SUBTEST import CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4
from g_repeat import g_repeat
from EIGEN_TEST_MAX_SIZE import EIGEN_TEST_MAX_SIZE

def mmtr[Scalar: AnyType](size: Int):
    alias MatrixColMaj = Matrix[Scalar, Dynamic, Dynamic, ColMajor]
    alias MatrixRowMaj = Matrix[Scalar, Dynamic, Dynamic, RowMajor]
    var othersize: DenseIndex = random[DenseIndex](1, 200)
    var matc: MatrixColMaj = MatrixColMaj.Zero(size, size)
    var matr: MatrixRowMaj = MatrixRowMaj.Zero(size, size)
    var ref1: MatrixColMaj = MatrixColMaj(size, size)
    var ref2: MatrixColMaj = MatrixColMaj(size, size)
    var ref3: MatrixColMaj = MatrixColMaj(size, size)
    var soc: MatrixColMaj = MatrixColMaj(size, othersize)
    soc.setRandom()
    var osc: MatrixColMaj = MatrixColMaj(othersize, size)
    osc.setRandom()
    var sor: MatrixRowMaj = MatrixRowMaj(size, othersize)
    sor.setRandom()
    var osr: MatrixRowMaj = MatrixRowMaj(othersize, size)
    osr.setRandom()
    var sqc: MatrixColMaj = MatrixColMaj(size, size)
    sqc.setRandom()
    var sqr: MatrixRowMaj = MatrixRowMaj(size, size)
    sqr.setRandom()
    var s: Scalar = random[Scalar]()
    CHECK_MMTR(matc, Lower, = s*soc*sor.adjoint())
    CHECK_MMTR(matc, Upper, = s*(soc*soc.adjoint()))
    CHECK_MMTR(matr, Lower, = s*soc*soc.adjoint())
    CHECK_MMTR(matr, Upper, = soc*(s*sor.adjoint()))
    CHECK_MMTR(matc, Lower, += s*soc*soc.adjoint())
    CHECK_MMTR(matc, Upper, += s*(soc*sor.transpose()))
    CHECK_MMTR(matr, Lower, += s*sor*soc.adjoint())
    CHECK_MMTR(matr, Upper, += soc*(s*soc.adjoint()))
    CHECK_MMTR(matc, Lower, -= s*soc*soc.adjoint())
    CHECK_MMTR(matc, Upper, -= s*(osc.transpose()*osc.conjugate()))
    CHECK_MMTR(matr, Lower, -= s*soc*soc.adjoint())
    CHECK_MMTR(matr, Upper, -= soc*(s*soc.adjoint()))
    CHECK_MMTR(matc, Lower, -= s*sqr*sqc.template triangularView[Upper]())
    CHECK_MMTR(matc, Upper, = s*sqc*sqr.template triangularView[Upper]())
    CHECK_MMTR(matc, Lower, += s*sqr*sqc.template triangularView[Lower]())
    CHECK_MMTR(matc, Upper, = s*sqc*sqc.template triangularView[Lower]())
    CHECK_MMTR(matc, Lower, = (s*sqr).template triangularView[Upper]()*sqc)
    CHECK_MMTR(matc, Upper, -= (s*sqc).template triangularView[Upper]()*sqc)
    CHECK_MMTR(matc, Lower, = (s*sqr).template triangularView[Lower]()*sqc)
    CHECK_MMTR(matc, Upper, += (s*sqc).template triangularView[Lower]()*sqc)
    ref2 = ref1 = matc
    ref1 = sqc.adjoint() * matc * sqc
    ref2.template triangularView[Upper]() = ref1.template triangularView[Upper]()
    matc.template triangularView[Upper]() = sqc.adjoint() * matc * sqc
    VERIFY_IS_APPROX(matc, ref2)
    ref2 = ref1 = matc
    ref1 = sqc * matc * sqc.adjoint()
    ref2.template triangularView[Lower]() = ref1.template triangularView[Lower]()
    matc.template triangularView[Lower]() = sqc * matc * sqc.adjoint()
    VERIFY_IS_APPROX(matc, ref2)

def test_product_mmtr():
    for i in range(g_repeat):
        CALL_SUBTEST_1((mmtr[float32](random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_2((mmtr[float64](random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_3((mmtr[Complex[float32]](random[Int](1, EIGEN_TEST_MAX_SIZE/2))))
        CALL_SUBTEST_4((mmtr[Complex[float64]](random[Int](1, EIGEN_TEST_MAX_SIZE/2))))