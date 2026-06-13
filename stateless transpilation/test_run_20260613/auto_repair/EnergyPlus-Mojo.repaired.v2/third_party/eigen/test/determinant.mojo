// This file is part of Eigen, a lightweight C++ template library
// for linear algebra.
//
// Copyright (C) 2008 Benoit Jacob <jacob.benoit.1@gmail.com>
//
// This Source Code Form is subject to the terms of the Mozilla
// Public License v. 2.0. If a copy of the MPL was not distributed
// with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

from main import VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, TEST_SET_BUT_UNUSED_VARIABLE, g_repeat, EIGEN_TEST_MAX_SIZE
from Eigen.LU import Matrix, MatrixXd
from builtin import Complex

struct internal:
    @staticmethod
    def random[Scalar: AnyType]() -> Scalar:
        # Placeholder: use Mojo's random
        return random[Scalar]()

    @staticmethod
    def random[Index: AnyType](low: Index, high: Index) -> Index:
        # Placeholder: use Mojo's random integer
        return random[Index](low, high)

struct numext:
    @staticmethod
    def conj(x: Complex[float64]) -> Complex[float64]:
        return x.conj()

    @staticmethod
    def conj(x: float64) -> float64:
        return x

def determinant[MatrixType: AnyType](m: MatrixType):
    /* this test covers the following files:
       Determinant.h
    */
    let size: Int = m.rows()
    var m1: MatrixType = MatrixType(size, size)
    var m2: MatrixType = MatrixType(size, size)
    m1.setRandom()
    m2.setRandom()
    alias Scalar = MatrixType.Scalar
    let x: Scalar = internal.random[Scalar]()
    VERIFY_IS_APPROX(MatrixType.Identity(size, size).determinant(), Scalar(1))
    VERIFY_IS_APPROX((m1 * m2).eval().determinant(), m1.determinant() * m2.determinant())
    if size == 1:
        return
    let i: Int = internal.random[Int](0, size - 1)
    var j: Int
    do:
        j = internal.random[Int](0, size - 1)
    while j == i
    m2 = m1
    m2.row(i).swap(m2.row(j))
    VERIFY_IS_APPROX(m2.determinant(), -m1.determinant())
    m2 = m1
    m2.col(i).swap(m2.col(j))
    VERIFY_IS_APPROX(m2.determinant(), -m1.determinant())
    VERIFY_IS_APPROX(m2.determinant(), m2.transpose().determinant())
    VERIFY_IS_APPROX(numext.conj(m2.determinant()), m2.adjoint().determinant())
    m2 = m1
    m2.row(i) += x * m2.row(j)
    VERIFY_IS_APPROX(m2.determinant(), m1.determinant())
    m2 = m1
    m2.row(i) *= x
    VERIFY_IS_APPROX(m2.determinant(), m1.determinant() * x)
    VERIFY_IS_APPROX(m2.block(0, 0, 0, 0).determinant(), Scalar(1))

def test_determinant():
    for i in range(g_repeat):
        var s: Int = 0
        CALL_SUBTEST_1(lambda: determinant(Matrix[float32, 1, 1]()))
        CALL_SUBTEST_2(lambda: determinant(Matrix[float64, 2, 2]()))
        CALL_SUBTEST_3(lambda: determinant(Matrix[float64, 3, 3]()))
        CALL_SUBTEST_4(lambda: determinant(Matrix[float64, 4, 4]()))
        CALL_SUBTEST_5(lambda: determinant(Matrix[Complex[float64], 10, 10]()))
        s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE // 4)
        CALL_SUBTEST_6(lambda: determinant(MatrixXd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)