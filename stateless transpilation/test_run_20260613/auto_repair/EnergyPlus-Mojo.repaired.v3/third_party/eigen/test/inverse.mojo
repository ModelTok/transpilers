// This file is part of Eigen, a lightweight C++ template library
// for linear algebra.
//
// Copyright (C) 2008-2010 Gael Guennebaud <gael.guennebaud@inria.fr>
// Copyright (C) 2009 Benoit Jacob <jacob.benoit.1@gmail.com>
//
// This Source Code Form is subject to the terms of the Mozilla
// Public License v. 2.0. If a copy of the MPL was not distributed
// with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Mojo translation of third_party/eigen/test/inverse.cpp

from main import *
from Eigen import (
    Matrix, Matrix2d, Matrix3f, Matrix4f, MatrixXf, MatrixXcd,
    Matrix4d, Matrix4cd, DontAlign, internal, NumTraits, RealScalar,
    VectorType, Scalar, Index, createRandomPIMatrixOfRank,
    VERIFY_IS_APPROX, VERIFY_RAISES_ASSERT, CALL_SUBTEST_1,
    CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5,
    CALL_SUBTEST_6, CALL_SUBTEST_7, CALL_SUBTEST_8,
    TEST_SET_BUT_UNUSED_VARIABLE, g_repeat
)

def inverse[MatrixType: AnyType](m: MatrixType):
    using std.abs
    /* this test covers the following files:
       Inverse.h
    */
    var rows = m.rows()
    var cols = m.cols()
    alias Scalar = MatrixType.Scalar
    var m1 = MatrixType(rows, cols)
    var m2 = MatrixType(rows, cols)
    var identity = MatrixType.Identity(rows, rows)
    createRandomPIMatrixOfRank(rows, rows, rows, m1)
    m2 = m1.inverse()
    VERIFY_IS_APPROX(m1, m2.inverse())
    VERIFY_IS_APPROX((Scalar(2) * m2).inverse(), m2.inverse() * Scalar(0.5))
    VERIFY_IS_APPROX(identity, m1.inverse() * m1)
    VERIFY_IS_APPROX(identity, m1 * m1.inverse())
    VERIFY_IS_APPROX(m1, m1.inverse().inverse())
    VERIFY_IS_APPROX(MatrixType(m1.transpose().inverse()), MatrixType(m1.inverse().transpose()))
    #if !defined(EIGEN_TEST_PART_5) && !defined(EIGEN_TEST_PART_6)
    alias RealScalar = NumTraits[Scalar].Real
    alias VectorType = Matrix[Scalar, MatrixType.ColsAtCompileTime, 1]
    var invertible: Bool
    var det: Scalar
    m2.setZero()
    m1.computeInverseAndDetWithCheck(m2, det, invertible)
    VERIFY(invertible)
    VERIFY_IS_APPROX(identity, m1 * m2)
    VERIFY_IS_APPROX(det, m1.determinant())
    m2.setZero()
    m1.computeInverseWithCheck(m2, invertible)
    VERIFY(invertible)
    VERIFY_IS_APPROX(identity, m1 * m2)
    var v3 = VectorType.Random(rows)
    var m3 = v3 * v3.transpose()
    var m4 = MatrixType(rows, cols)
    m3.computeInverseAndDetWithCheck(m4, det, invertible)
    VERIFY(rows == 1 ? invertible : !invertible)
    VERIFY_IS_MUCH_SMALLER_THAN(abs(det - m3.determinant()), RealScalar(1))
    m3.computeInverseWithCheck(m4, invertible)
    VERIFY(rows == 1 ? invertible : !invertible)
    {
        var m5 = Matrix[Scalar, MatrixType.RowsAtCompileTime + 1, MatrixType.RowsAtCompileTime + 1, MatrixType.Options]()
        m5.setRandom()
        m5.topLeftCorner(rows, rows) = m1
        m2 = m5.template topLeftCorner[MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime]().inverse()
        VERIFY_IS_APPROX((m5.template topLeftCorner[MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime]()), m2.inverse())
    }
    #endif
    if MatrixType.RowsAtCompileTime >= 2 and MatrixType.RowsAtCompileTime <= 4:
        VERIFY_RAISES_ASSERT(m1 = m1.inverse())
    else:
        m2 = m1.inverse()
        m1 = m1.inverse()
        VERIFY_IS_APPROX(m1, m2)

def test_inverse():
    var s = 0
    for i in range(g_repeat):
        CALL_SUBTEST_1(inverse(Matrix[Float64, 1, 1]()))
        CALL_SUBTEST_2(inverse(Matrix2d()))
        CALL_SUBTEST_3(inverse(Matrix3f()))
        CALL_SUBTEST_4(inverse(Matrix4f()))
        CALL_SUBTEST_4(inverse(Matrix[Float32, 4, 4, DontAlign]()))
        s = internal.random[Int](50, 320)
        CALL_SUBTEST_5(inverse(MatrixXf(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        s = internal.random[Int](25, 100)
        CALL_SUBTEST_6(inverse(MatrixXcd(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        CALL_SUBTEST_7(inverse(Matrix4d()))
        CALL_SUBTEST_7(inverse(Matrix[Float64, 4, 4, DontAlign]()))
        CALL_SUBTEST_8(inverse(Matrix4cd()))