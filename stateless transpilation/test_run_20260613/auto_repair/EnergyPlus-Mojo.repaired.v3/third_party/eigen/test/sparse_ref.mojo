# EIGEN_DEFAULT_TO_ROW_MAJOR is not defined in Mojo context
# static long int nb_temporaries;
var nb_temporaries: Int = 0
# void on_temporary_creation() {
#   nb_temporaries++;
# }
def on_temporary_creation():
    nb_temporaries += 1
# #define EIGEN_SPARSE_CREATE_TEMPORARY_PLUGIN { on_temporary_creation(); }
# #include "main.h"
# #include <Eigen/SparseCore>
# #define VERIFY_EVALUATION_COUNT(XPR,N) {\
#     nb_temporaries = 0; \
#     CALL_SUBTEST( XPR ); \
#     if(nb_temporaries!=N) cerr << "nb_temporaries == " << nb_temporaries << "\n"; \
#     VERIFY( (#XPR) && nb_temporaries==N ); \
#   }
# template<PlainObjectType> void check_const_correctness(const PlainObjectType&)
# {
#   typedef internal::add_const<PlainObjectType>::type ConstPlainObjectType;
#   VERIFY( !(internal::traits<Ref<ConstPlainObjectType> >::Flags & LvalueBit) );
#   VERIFY( !(internal::traits<Ref<ConstPlainObjectType, Aligned> >::Flags & LvalueBit) );
#   VERIFY( !(Ref<ConstPlainObjectType>::Flags & LvalueBit) );
#   VERIFY( !(Ref<ConstPlainObjectType, Aligned>::Flags & LvalueBit) );
# }
def check_const_correctness[PlainObjectType: AnyType](arg0: PlainObjectType):
    alias ConstPlainObjectType = add_const[PlainObjectType]
    VERIFY(not (internal.traits[Ref[ConstPlainObjectType]].Flags & LvalueBit))
    VERIFY(not (internal.traits[Ref[ConstPlainObjectType, Aligned]].Flags & LvalueBit))
    VERIFY(not (Ref[ConstPlainObjectType].Flags & LvalueBit))
    VERIFY(not (Ref[ConstPlainObjectType, Aligned].Flags & LvalueBit))
# template<B>
# EIGEN_DONT_INLINE void call_ref_1(Ref<SparseMatrix<float> > a, const B &b) { VERIFY_IS_EQUAL(a.toDense(),b.toDense()); }
def call_ref_1[B: AnyType](a: Ref[SparseMatrix[float32]], b: B):
    VERIFY_IS_EQUAL(a.toDense(), b.toDense())
# template<B>
# EIGEN_DONT_INLINE void call_ref_2(const Ref<const SparseMatrix<float> >& a, const B &b) { VERIFY_IS_EQUAL(a.toDense(),b.toDense()); }
def call_ref_2[B: AnyType](a: Ref[SparseMatrix[float32], __const], b: B):
    VERIFY_IS_EQUAL(a.toDense(), b.toDense())
# template<B>
# EIGEN_DONT_INLINE void call_ref_3(const Ref<const SparseMatrix<float>, StandardCompressedFormat>& a, const B &b) {
#   VERIFY(a.isCompressed());
#   VERIFY_IS_EQUAL(a.toDense(),b.toDense());
# }
def call_ref_3[B: AnyType](a: Ref[SparseMatrix[float32], __const, StandardCompressedFormat], b: B):
    VERIFY(a.isCompressed())
    VERIFY_IS_EQUAL(a.toDense(), b.toDense())
# template<B>
# EIGEN_DONT_INLINE void call_ref_4(Ref<SparseVector<float> > a, const B &b) { VERIFY_IS_EQUAL(a.toDense(),b.toDense()); }
def call_ref_4[B: AnyType](a: Ref[SparseVector[float32]], b: B):
    VERIFY_IS_EQUAL(a.toDense(), b.toDense())
# template<B>
# EIGEN_DONT_INLINE void call_ref_5(const Ref<const SparseVector<float> >& a, const B &b) { VERIFY_IS_EQUAL(a.toDense(),b.toDense()); }
def call_ref_5[B: AnyType](a: Ref[SparseVector[float32], __const], b: B):
    VERIFY_IS_EQUAL(a.toDense(), b.toDense())
# void call_ref()
# {
#   SparseMatrix<float>               A = MatrixXf::Random(10,10).sparseView(0.5,1);
#   SparseMatrix<float,RowMajor>      B = MatrixXf::Random(10,10).sparseView(0.5,1);
#   SparseMatrix<float>               C = MatrixXf::Random(10,10).sparseView(0.5,1);
#   C.reserve(VectorXi::Constant(C.outerSize(), 2));
#   const SparseMatrix<float>&        Ac(A);
#   Block<SparseMatrix<float> >       Ab(A,0,1, 3,3);
#   const Block<SparseMatrix<float> > Abc(A,0,1,3,3);
#   SparseVector<float>               vc =  VectorXf::Random(10).sparseView(0.5,1);
#   SparseVector<float,RowMajor>      vr =  VectorXf::Random(10).sparseView(0.5,1);
#   SparseMatrix<float> AA = A*A;
#   VERIFY_EVALUATION_COUNT( call_ref_1(A, A),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A, A),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_3(A, A),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A.transpose(), A.transpose()),  1);
#   VERIFY_EVALUATION_COUNT( call_ref_3(A.transpose(), A.transpose()),  1);
#   VERIFY_EVALUATION_COUNT( call_ref_2(Ac,Ac), 0);
#   VERIFY_EVALUATION_COUNT( call_ref_3(Ac,Ac), 0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A+A,2*Ac), 1);
#   VERIFY_EVALUATION_COUNT( call_ref_3(A+A,2*Ac), 1);
#   VERIFY_EVALUATION_COUNT( call_ref_2(B, B),  1);
#   VERIFY_EVALUATION_COUNT( call_ref_3(B, B),  1);
#   VERIFY_EVALUATION_COUNT( call_ref_2(B.transpose(), B.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_3(B.transpose(), B.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A*A, AA),  3);
#   VERIFY_EVALUATION_COUNT( call_ref_3(A*A, AA),  3);
#   VERIFY(!C.isCompressed());
#   VERIFY_EVALUATION_COUNT( call_ref_3(C, C),  1);
#   Ref<SparseMatrix<float> > Ar(A);
#   VERIFY_IS_APPROX(Ar+Ar, A+A);
#   VERIFY_EVALUATION_COUNT( call_ref_1(Ar, A),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(Ar, A),  0);
#   Ref<SparseMatrix<float,RowMajor> > Br(B);
#   VERIFY_EVALUATION_COUNT( call_ref_1(Br.transpose(), Br.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(Br, Br),  1);
#   VERIFY_EVALUATION_COUNT( call_ref_2(Br.transpose(), Br.transpose()),  0);
#   Ref<const SparseMatrix<float> > Arc(A);
#   VERIFY_EVALUATION_COUNT( call_ref_2(Arc, Arc),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A.middleCols(1,3), A.middleCols(1,3)),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A.col(2), A.col(2)),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(vc, vc),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(vr.transpose(), vr.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(vr, vr.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_2(A.block(1,1,3,3), A.block(1,1,3,3)),  1); // should be 0 (allocate starts/nnz only)
#   VERIFY_EVALUATION_COUNT( call_ref_4(vc, vc),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_4(vr, vr.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_5(vc, vc),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_5(vr, vr.transpose()),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_4(A.col(2), A.col(2)),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_5(A.col(2), A.col(2)),  0);
#   VERIFY_EVALUATION_COUNT( call_ref_5(A.row(2), A.row(2).transpose()),  1);
# }
def call_ref():
    var A: SparseMatrix[float32] = MatrixXf.Random(10, 10).sparseView(0.5, 1)
    var B: SparseMatrix[float32, RowMajor] = MatrixXf.Random(10, 10).sparseView(0.5, 1)
    var C: SparseMatrix[float32] = MatrixXf.Random(10, 10).sparseView(0.5, 1)
    C.reserve(VectorXi.Constant(C.outerSize(), 2))
    var Ac: SparseMatrix[float32] = A
    var Ab: Block[SparseMatrix[float32]] = Block[SparseMatrix[float32]](A, 0, 1, 3, 3)
    var Abc: Block[SparseMatrix[float32]] = Block[SparseMatrix[float32]](A, 0, 1, 3, 3)
    var vc: SparseVector[float32] = VectorXf.Random(10).sparseView(0.5, 1)
    var vr: SparseVector[float32, RowMajor] = VectorXf.Random(10).sparseView(0.5, 1)
    var AA: SparseMatrix[float32] = A * A
    VERIFY_EVALUATION_COUNT(call_ref_1(A, A), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A, A), 0)
    VERIFY_EVALUATION_COUNT(call_ref_3(A, A), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A.transpose(), A.transpose()), 1)
    VERIFY_EVALUATION_COUNT(call_ref_3(A.transpose(), A.transpose()), 1)
    VERIFY_EVALUATION_COUNT(call_ref_2(Ac, Ac), 0)
    VERIFY_EVALUATION_COUNT(call_ref_3(Ac, Ac), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A + A, 2 * Ac), 1)
    VERIFY_EVALUATION_COUNT(call_ref_3(A + A, 2 * Ac), 1)
    VERIFY_EVALUATION_COUNT(call_ref_2(B, B), 1)
    VERIFY_EVALUATION_COUNT(call_ref_3(B, B), 1)
    VERIFY_EVALUATION_COUNT(call_ref_2(B.transpose(), B.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_3(B.transpose(), B.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A * A, AA), 3)
    VERIFY_EVALUATION_COUNT(call_ref_3(A * A, AA), 3)
    VERIFY(not C.isCompressed())
    VERIFY_EVALUATION_COUNT(call_ref_3(C, C), 1)
    var Ar: Ref[SparseMatrix[float32]] = Ref[SparseMatrix[float32]](A)
    VERIFY_IS_APPROX(Ar + Ar, A + A)
    VERIFY_EVALUATION_COUNT(call_ref_1(Ar, A), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(Ar, A), 0)
    var Br: Ref[SparseMatrix[float32, RowMajor]] = Ref[SparseMatrix[float32, RowMajor]](B)
    VERIFY_EVALUATION_COUNT(call_ref_1(Br.transpose(), Br.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(Br, Br), 1)
    VERIFY_EVALUATION_COUNT(call_ref_2(Br.transpose(), Br.transpose()), 0)
    var Arc: Ref[SparseMatrix[float32], __const] = Ref[SparseMatrix[float32], __const](A)
    VERIFY_EVALUATION_COUNT(call_ref_2(Arc, Arc), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A.middleCols(1, 3), A.middleCols(1, 3)), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A.col(2), A.col(2)), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(vc, vc), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(vr.transpose(), vr.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(vr, vr.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_2(A.block(1, 1, 3, 3), A.block(1, 1, 3, 3)), 1)  # should be 0 (allocate starts/nnz only)
    VERIFY_EVALUATION_COUNT(call_ref_4(vc, vc), 0)
    VERIFY_EVALUATION_COUNT(call_ref_4(vr, vr.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_5(vc, vc), 0)
    VERIFY_EVALUATION_COUNT(call_ref_5(vr, vr.transpose()), 0)
    VERIFY_EVALUATION_COUNT(call_ref_4(A.col(2), A.col(2)), 0)
    VERIFY_EVALUATION_COUNT(call_ref_5(A.col(2), A.col(2)), 0)
    VERIFY_EVALUATION_COUNT(call_ref_5(A.row(2), A.row(2).transpose()), 1)
# void test_sparse_ref()
# {
#   for(int i = 0; i < g_repeat; i++) {
#     CALL_SUBTEST_1( check_const_correctness(SparseMatrix<float>()) );
#     CALL_SUBTEST_1( check_const_correctness(SparseMatrix<double,RowMajor>()) );
#     CALL_SUBTEST_2( call_ref() );
#     CALL_SUBTEST_3( check_const_correctness(SparseVector<float>()) );
#     CALL_SUBTEST_3( check_const_correctness(SparseVector<double,RowMajor>()) );
#   }
# }
def test_sparse_ref():
    for i in range(g_repeat):
        CALL_SUBTEST_1(check_const_correctness(SparseMatrix[float32]()))
        CALL_SUBTEST_1(check_const_correctness(SparseMatrix[float64, RowMajor]()))
        CALL_SUBTEST_2(call_ref())
        CALL_SUBTEST_3(check_const_correctness(SparseVector[float32]()))
        CALL_SUBTEST_3(check_const_correctness(SparseVector[float64, RowMajor]()))