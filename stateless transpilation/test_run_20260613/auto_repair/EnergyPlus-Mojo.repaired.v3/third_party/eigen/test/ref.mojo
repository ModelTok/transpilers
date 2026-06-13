//  This file is part of Eigen, a lightweight C++ template library
//  for linear algebra.
//
//  Copyright (C) 2008-2012 Gael Guennebaud <gael.guennebaud@inria.fr>
//
//  This Source Code Form is subject to the terms of the Mozilla
//  Public License v. 2.0. If a copy of the MPL was not distributed
//  with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// #define EIGEN_DEFAULT_TO_ROW_MAJOR
// #undef EIGEN_DEFAULT_TO_ROW_MAJOR
// #define TEST_ENABLE_TEMPORARY_TRACKING
// #define TEST_CHECK_STATIC_ASSERTIONS
// #include "main.h"
// #if EIGEN_ARCH_i386 && !(EIGEN_ARCH_x86_64)
// #if EIGEN_COMP_GNUC_STRICT && EIGEN_GNUC_AT_LEAST(4,4)
// #pragma GCC optimize ("-ffloat-store")
// #else
// #undef VERIFY_IS_EQUAL
// #define VERIFY_IS_EQUAL(X,Y) VERIFY_IS_APPROX(X,Y)
// #endif
// #endif

def ref_matrix[MatrixType: AnyType](borrowed m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    alias DynMatrixType = Matrix[Scalar, Dynamic, Dynamic, MatrixType.Options]
    alias RealDynMatrixType = Matrix[RealScalar, Dynamic, Dynamic, MatrixType.Options]
    alias RefMat = Ref[MatrixType]
    alias RefDynMat = Ref[DynMatrixType]
    alias ConstRefDynMat = Ref[const DynMatrixType]
    alias RefRealMatWithStride = Ref[RealDynMatrixType, 0, Stride[Dynamic, Dynamic]]
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = m1
    var i: Index = internal.random[Index](0, rows-1)
    var j: Index = internal.random[Index](0, cols-1)
    var brows: Index = internal.random[Index](1, rows-i)
    var bcols: Index = internal.random[Index](1, cols-j)
    var rm0: RefMat = m1
    VERIFY_IS_EQUAL(rm0, m1)
    var rm1: RefDynMat = m1
    VERIFY_IS_EQUAL(rm1, m1)
    var rm2: RefDynMat = m1.block(i, j, brows, bcols)
    VERIFY_IS_EQUAL(rm2, m1.block(i, j, brows, bcols))
    rm2.setOnes()
    m2.block(i, j, brows, bcols).setOnes()
    VERIFY_IS_EQUAL(m1, m2)
    m2.block(i, j, brows, bcols).setRandom()
    rm2 = m2.block(i, j, brows, bcols)
    VERIFY_IS_EQUAL(m1, m2)
    var rm3: ConstRefDynMat = m1.block(i, j, brows, bcols)
    m1.block(i, j, brows, bcols) *= 2
    m2.block(i, j, brows, bcols) *= 2
    VERIFY_IS_EQUAL(rm3, m2.block(i, j, brows, bcols))
    var rm4: RefRealMatWithStride = m1.real()
    VERIFY_IS_EQUAL(rm4, m2.real())
    rm4.array() += 1
    m2.real().array() += 1
    VERIFY_IS_EQUAL(m1, m2)

def ref_vector[VectorType: AnyType](borrowed m: VectorType):
    alias Scalar = VectorType.Scalar
    alias RealScalar = VectorType.RealScalar
    alias DynMatrixType = Matrix[Scalar, Dynamic, 1, VectorType.Options]
    alias MatrixType = Matrix[Scalar, Dynamic, Dynamic, ColMajor]
    alias RealDynMatrixType = Matrix[RealScalar, Dynamic, 1, VectorType.Options]
    alias RefMat = Ref[VectorType]
    alias RefDynMat = Ref[DynMatrixType]
    alias ConstRefDynMat = Ref[const DynMatrixType]
    alias RefRealMatWithStride = Ref[RealDynMatrixType, 0, InnerStride[]]
    alias RefMatWithStride = Ref[DynMatrixType, 0, InnerStride[]]
    var size: Index = m.size()
    var v1: VectorType = VectorType.Random(size)
    var v2: VectorType = v1
    var mat1: MatrixType = MatrixType.Random(size, size)
    var mat2: MatrixType = mat1
    var mat3: MatrixType = MatrixType.Random(size, size)
    var i: Index = internal.random[Index](0, size-1)
    var bsize: Index = internal.random[Index](1, size-i)
    var rm0: RefMat = v1
    VERIFY_IS_EQUAL(rm0, v1)
    var rv1: RefDynMat = v1
    VERIFY_IS_EQUAL(rv1, v1)
    var rv2: RefDynMat = v1.segment(i, bsize)
    VERIFY_IS_EQUAL(rv2, v1.segment(i, bsize))
    rv2.setOnes()
    v2.segment(i, bsize).setOnes()
    VERIFY_IS_EQUAL(v1, v2)
    v2.segment(i, bsize).setRandom()
    rv2 = v2.segment(i, bsize)
    VERIFY_IS_EQUAL(v1, v2)
    var rm3: ConstRefDynMat = v1.segment(i, bsize)
    v1.segment(i, bsize) *= 2
    v2.segment(i, bsize) *= 2
    VERIFY_IS_EQUAL(rm3, v2.segment(i, bsize))
    var rm4: RefRealMatWithStride = v1.real()
    VERIFY_IS_EQUAL(rm4, v2.real())
    rm4.array() += 1
    v2.real().array() += 1
    VERIFY_IS_EQUAL(v1, v2)
    var rm5: RefMatWithStride = mat1.row(i).transpose()
    VERIFY_IS_EQUAL(rm5, mat1.row(i).transpose())
    rm5.array() += 1
    mat2.row(i).array() += 1
    VERIFY_IS_EQUAL(mat1, mat2)
    rm5.noalias() = rm4.transpose() * mat3
    mat2.row(i) = v2.real().transpose() * mat3
    VERIFY_IS_APPROX(mat1, mat2)

def check_const_correctness[PlainObjectType: AnyType](borrowed ):
    alias ConstPlainObjectType = internal.add_const[PlainObjectType].type
    VERIFY( not (internal.traits[Ref[ConstPlainObjectType]].Flags & LvalueBit) )
    VERIFY( not (internal.traits[Ref[ConstPlainObjectType, Aligned]].Flags & LvalueBit) )
    VERIFY( not (Ref[ConstPlainObjectType].Flags & LvalueBit) )
    VERIFY( not (Ref[ConstPlainObjectType, Aligned].Flags & LvalueBit) )

// EIGEN_DONT_INLINE
def call_ref_1[B: AnyType](a: Ref[VectorXf], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

// EIGEN_DONT_INLINE
def call_ref_2[B: AnyType](borrowed a: Ref[const VectorXf], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

// EIGEN_DONT_INLINE
def call_ref_3[B: AnyType](a: Ref[VectorXf, 0, InnerStride[]], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

// EIGEN_DONT_INLINE
def call_ref_4[B: AnyType](borrowed a: Ref[const VectorXf, 0, InnerStride[]], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

// EIGEN_DONT_INLINE
def call_ref_5[B: AnyType](a: Ref[MatrixXf, 0, OuterStride[]], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

// EIGEN_DONT_INLINE
def call_ref_6[B: AnyType](borrowed a: Ref[const MatrixXf, 0, OuterStride[]], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

// EIGEN_DONT_INLINE
def call_ref_7[B: AnyType](a: Ref[Matrix[float32, Dynamic, 3]], borrowed b: B):
    VERIFY_IS_EQUAL(a, b)

def call_ref():
    var ca: VectorXcf = VectorXcf.Random(10)
    var a: VectorXf = VectorXf.Random(10)
    var b: RowVectorXf = RowVectorXf.Random(10)
    var A: MatrixXf = MatrixXf.Random(10, 10)
    var c: RowVector3f = RowVector3f.Random()
    var ac: const VectorXf = a
    var ab: VectorBlock[VectorXf] = VectorBlock[VectorXf](a, 0, 3)
    var abc: const VectorBlock[VectorXf] = VectorBlock[VectorXf](a, 0, 3)
    VERIFY_EVALUATION_COUNT( call_ref_1(a, a), 0)
    VERIFY_EVALUATION_COUNT( call_ref_1(b, b.transpose()), 0)
    VERIFY_EVALUATION_COUNT( call_ref_1(ab, ab), 0)
    VERIFY_EVALUATION_COUNT( call_ref_1(a.head(4), a.head(4)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_1(abc, abc), 0)
    VERIFY_EVALUATION_COUNT( call_ref_1(A.col(3), A.col(3)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_3(A.row(3), A.row(3).transpose()), 0)
    VERIFY_EVALUATION_COUNT( call_ref_4(A.row(3), A.row(3).transpose()), 0)
    var tmp: MatrixXf = A * A.col(1)
    VERIFY_EVALUATION_COUNT( call_ref_2(A * A.col(1), tmp), 1)     // evaluated into a temp
    VERIFY_EVALUATION_COUNT( call_ref_2(ac.head(5), ac.head(5)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_2(ac, ac), 0)
    VERIFY_EVALUATION_COUNT( call_ref_2(a, a), 0)
    VERIFY_EVALUATION_COUNT( call_ref_2(ab, ab), 0)
    VERIFY_EVALUATION_COUNT( call_ref_2(a.head(4), a.head(4)), 0)
    tmp = a + a
    VERIFY_EVALUATION_COUNT( call_ref_2(a + a, tmp), 1)            // evaluated into a temp
    VERIFY_EVALUATION_COUNT( call_ref_2(ca.imag(), ca.imag()), 1)      // evaluated into a temp
    VERIFY_EVALUATION_COUNT( call_ref_4(ac.head(5), ac.head(5)), 0)
    tmp = a + a
    VERIFY_EVALUATION_COUNT( call_ref_4(a + a, tmp), 1)           // evaluated into a temp
    VERIFY_EVALUATION_COUNT( call_ref_4(ca.imag(), ca.imag()), 0)
    VERIFY_EVALUATION_COUNT( call_ref_5(a, a), 0)
    VERIFY_EVALUATION_COUNT( call_ref_5(a.head(3), a.head(3)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_5(A, A), 0)
    VERIFY_EVALUATION_COUNT( call_ref_5(A.block(1, 1, 2, 2), A.block(1, 1, 2, 2)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_5(b, b), 0)             // storage order do not match, but this is a degenerate case that should work
    VERIFY_EVALUATION_COUNT( call_ref_5(a.row(3), a.row(3)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_6(a, a), 0)
    VERIFY_EVALUATION_COUNT( call_ref_6(a.head(3), a.head(3)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_6(A.row(3), A.row(3)), 1)           // evaluated into a temp thouth it could be avoided by viewing it as a 1xn matrix
    tmp = A + A
    VERIFY_EVALUATION_COUNT( call_ref_6(A + A, tmp), 1)                // evaluated into a temp
    VERIFY_EVALUATION_COUNT( call_ref_6(A, A), 0)
    VERIFY_EVALUATION_COUNT( call_ref_6(A.transpose(), A.transpose()), 1)      // evaluated into a temp because the storage orders do not match
    VERIFY_EVALUATION_COUNT( call_ref_6(A.block(1, 1, 2, 2), A.block(1, 1, 2, 2)), 0)
    VERIFY_EVALUATION_COUNT( call_ref_7(c, c), 0)

alias RowMatrixXd = Matrix[float64, Dynamic, Dynamic, RowMajor]

def test_ref_overload_fun1(Ref[MatrixXd]) -> Int: return 1
def test_ref_overload_fun1(Ref[RowMatrixXd]) -> Int: return 2
def test_ref_overload_fun1(Ref[MatrixXf]) -> Int: return 3
def test_ref_overload_fun2(Ref[const MatrixXd]) -> Int: return 4
def test_ref_overload_fun2(Ref[const MatrixXf]) -> Int: return 5

def test_ref_ambiguous(borrowed A: Ref[const ArrayXd], B: Ref[ArrayXd]):
    B = A
    B = A - A

def test_ref_overloads():
    var Ad: MatrixXd
    var Bd: MatrixXd
    var rAd: RowMatrixXd
    var rBd: RowMatrixXd
    VERIFY( test_ref_overload_fun1(Ad) == 1 )
    VERIFY( test_ref_overload_fun1(rAd) == 2 )
    var Af: MatrixXf
    var Bf: MatrixXf
    VERIFY( test_ref_overload_fun2(Ad) == 4 )
    VERIFY( test_ref_overload_fun2(Ad + Bd) == 4 )
    VERIFY( test_ref_overload_fun2(Af + Bf) == 5 )
    var A: ArrayXd
    var B: ArrayXd
    test_ref_ambiguous(A, B)

def test_ref_fixed_size_assert():
    var v4: Vector4f
    var vx: VectorXf = VectorXf(10)
    VERIFY_RAISES_STATIC_ASSERT(Ref[Vector3f] y = v4; (void)y)
    VERIFY_RAISES_STATIC_ASSERT(Ref[Vector3f] y = vx.head[4](); (void)y)
    VERIFY_RAISES_STATIC_ASSERT(Ref[const Vector3f] y = v4; (void)y)
    VERIFY_RAISES_STATIC_ASSERT(Ref[const Vector3f] y = vx.head[4](); (void)y)
    VERIFY_RAISES_STATIC_ASSERT(Ref[const Vector3f] y = 2*v4; (void)y)

def test_ref():
    for i in range(g_repeat):
        CALL_SUBTEST_1( ref_vector(Matrix[float32, 1, 1]()) )
        CALL_SUBTEST_1( check_const_correctness(Matrix[float32, 1, 1]()) )
        CALL_SUBTEST_2( ref_vector(Vector4d()) )
        CALL_SUBTEST_2( check_const_correctness(Matrix4d()) )
        CALL_SUBTEST_3( ref_vector(Vector4cf()) )
        CALL_SUBTEST_4( ref_vector(VectorXcf(8)) )
        CALL_SUBTEST_5( ref_vector(VectorXi(12)) )
        CALL_SUBTEST_5( check_const_correctness(VectorXi(12)) )
        CALL_SUBTEST_1( ref_matrix(Matrix[float32, 1, 1]()) )
        CALL_SUBTEST_2( ref_matrix(Matrix4d()) )
        CALL_SUBTEST_1( ref_matrix(Matrix[float32, 3, 5]()) )
        CALL_SUBTEST_4( ref_matrix(MatrixXcf(internal.random[int](1,10), internal.random[int](1,10))) )
        CALL_SUBTEST_4( ref_matrix(Matrix[complex[float64],10,15]()) )
        CALL_SUBTEST_5( ref_matrix(MatrixXi(internal.random[int](1,10), internal.random[int](1,10))) )
        CALL_SUBTEST_6( call_ref() )
    CALL_SUBTEST_7( test_ref_overloads() )
    CALL_SUBTEST_7( test_ref_fixed_size_assert() )