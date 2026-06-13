# static long int nb_transposed_copies;
var nb_transposed_copies: Int = 0

# define EIGEN_SPARSE_TRANSPOSED_COPY_PLUGIN {nb_transposed_copies++;}
# We'll define a function to increment, but the macro is used inline.
# We'll replace the macro usage with direct increment in the VERIFY_TRANSPOSITION_COUNT function.

# define VERIFY_TRANSPOSITION_COUNT(XPR,N) {\
#     nb_transposed_copies = 0; \
#     XPR; \
#     if(nb_transposed_copies!=N) cerr << "nb_transposed_copies == " << nb_transposed_copies << "\n"; \
#     VERIFY( (#XPR) && nb_transposed_copies==N ); \
#   }
# We'll define a function that takes a lambda and expected count.
def verify_transposition_count[N: Int](xpr: fn() -> None):
    nb_transposed_copies = 0
    xpr()
    if nb_transposed_copies != N:
        print("nb_transposed_copies == ", nb_transposed_copies, file=sys.stderr)
    # VERIFY( (#XPR) && nb_transposed_copies==N );
    # We cannot stringify, so we just check the condition.
    assert(nb_transposed_copies == N, "Transposition count mismatch")

from sparse import (
    SparseMatrix, Matrix, PermutationMatrix, Index, Scalar, StorageIndex,
    Dynamic, Upper, Lower, ColMajor, RowMajor,
    SelfAdjointView, TriangularView,
    internal,  # module containing nested_eval, evaluator, permutation_matrix_product, is_same, etc.
    randomPermutationVector, initSparse,
    VERIFY, VERIFY_IS_APPROX,
    CALL_SUBTEST, CALL_SUBTEST_1, CALL_SUBTEST_2,
    g_repeat, random
)

# template<T>
# bool is_sorted(T& mat ) {
#   for(Index k = 0; k<mat.outerSize(); ++k)
#   {
#     Index prev = -1;
#     for(T::InnerIterator it(mat,k); it; ++it)
#     {
#       if(prev>=it.index())
#         return false;
#       prev = it.index();
#     }
#   }
#   return true;
# }
def is_sorted[T: type](mat: T) -> Bool:
    for k in range(0, mat.outerSize()):
        var prev: Index = -1
        var it = T.InnerIterator(mat, k)
        while it:
            if prev >= it.index():
                return False
            prev = it.index()
            it.next()
    return True

# template<T>
# internal::nested_eval<T,1>::type eval(const T &xpr)
# {
#   VERIFY( int(internal::nested_eval<T,1>::type::Flags&RowMajorBit) == int(internal::evaluator<T>::Flags&RowMajorBit) );
#   return xpr;
# }
def eval[T: type](xpr: T) -> internal.nested_eval[T, 1].type:
    # VERIFY( int(internal::nested_eval<T,1>::type::Flags&RowMajorBit) == int(internal::evaluator<T>::Flags&RowMajorBit) );
    # We need to access Flags and RowMajorBit. Assume they are defined.
    var flags1 = internal.nested_eval[T, 1].type.Flags & RowMajorBit
    var flags2 = internal.evaluator[T].Flags & RowMajorBit
    VERIFY(Int(flags1) == Int(flags2))
    return xpr

# template<int OtherStorage, SparseMatrixType> void sparse_permutations(SparseMatrixType& ref )
def sparse_permutations[OtherStorage: Int, SparseMatrixType: type](ref: SparseMatrixType):
    const rows: Index = ref.rows()
    const cols: Index = ref.cols()
    # typedef SparseMatrixType::Scalar Scalar;
    alias Scalar = SparseMatrixType.Scalar
    # typedef SparseMatrixType::StorageIndex StorageIndex;
    alias StorageIndex = SparseMatrixType.StorageIndex
    # typedef SparseMatrix<Scalar, OtherStorage, StorageIndex> OtherSparseMatrixType;
    alias OtherSparseMatrixType = SparseMatrix[Scalar, OtherStorage, StorageIndex]
    # typedef Matrix<Scalar,Dynamic,Dynamic> DenseMatrix;
    alias DenseMatrix = Matrix[Scalar, Dynamic, Dynamic]
    # typedef Matrix<StorageIndex,Dynamic,1> VectorI;
    alias VectorI = Matrix[StorageIndex, Dynamic, 1]

    var density: Float64 = (max)(8.0 / (rows * cols), 0.01)
    var mat: SparseMatrixType = SparseMatrixType(rows, cols)
    var up: SparseMatrixType = SparseMatrixType(rows, cols)
    var lo: SparseMatrixType = SparseMatrixType(rows, cols)
    var res: OtherSparseMatrixType
    var mat_d: DenseMatrix = DenseMatrix.Zero(rows, cols)
    var up_sym_d: DenseMatrix
    var lo_sym_d: DenseMatrix
    var res_d: DenseMatrix

    initSparse[Scalar](density, mat_d, mat, 0)

    up = mat.template triangularView[Upper]()
    lo = mat.template triangularView[Lower]()
    up_sym_d = mat_d.template selfadjointView[Upper]()
    lo_sym_d = mat_d.template selfadjointView[Lower]()

    VERIFY_IS_APPROX(mat, mat_d)
    VERIFY_IS_APPROX(up, DenseMatrix(mat_d.template triangularView[Upper]()))
    VERIFY_IS_APPROX(lo, DenseMatrix(mat_d.template triangularView[Lower]()))

    var p: PermutationMatrix[Dynamic]
    var p_null: PermutationMatrix[Dynamic]
    var pi: VectorI
    randomPermutationVector(pi, cols)
    p.indices() = pi

    VERIFY(is_sorted(::eval(mat * p)))
    VERIFY(is_sorted(res = mat * p))
    verify_transposition_count[0](fn() => ::eval(mat * p))
    res_d = mat_d * p
    VERIFY(res.isApprox(res_d) and "mat*p")
    VERIFY(is_sorted(::eval(p * mat)))
    VERIFY(is_sorted(res = p * mat))
    verify_transposition_count[0](fn() => ::eval(p * mat))
    res_d = p * mat_d
    VERIFY(res.isApprox(res_d) and "p*mat")
    VERIFY(is_sorted((mat * p).eval()))
    VERIFY(is_sorted(res = mat * p.inverse()))
    verify_transposition_count[0](fn() => ::eval(mat * p.inverse()))
    res_d = mat * p.inverse()
    VERIFY(res.isApprox(res_d) and "mat*inv(p)")
    VERIFY(is_sorted((p * mat + p * mat).eval()))
    VERIFY(is_sorted(res = p.inverse() * mat))
    verify_transposition_count[0](fn() => ::eval(p.inverse() * mat))
    res_d = p.inverse() * mat_d
    VERIFY(res.isApprox(res_d) and "inv(p)*mat")
    VERIFY(is_sorted((p * mat * p.inverse()).eval()))
    VERIFY(is_sorted(res = mat.twistedBy(p)))
    verify_transposition_count[0](fn() => ::eval(p * mat * p.inverse()))
    res_d = (p * mat_d) * p.inverse()
    VERIFY(res.isApprox(res_d) and "p*mat*inv(p)")

    VERIFY(is_sorted(res = mat.template selfadjointView[Upper]().twistedBy(p_null)))
    res_d = up_sym_d
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper to full")
    VERIFY(is_sorted(res = mat.template selfadjointView[Lower]().twistedBy(p_null)))
    res_d = lo_sym_d
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower to full")
    VERIFY(is_sorted(res = up.template selfadjointView[Upper]().twistedBy(p_null)))
    res_d = up_sym_d
    VERIFY(res.isApprox(res_d) and "upper selfadjoint to full")
    VERIFY(is_sorted(res = lo.template selfadjointView[Lower]().twistedBy(p_null)))
    res_d = lo_sym_d
    VERIFY(res.isApprox(res_d) and "lower selfadjoint full")

    VERIFY(is_sorted(res = mat.template selfadjointView[Upper]()))
    res_d = up_sym_d
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper to full")
    VERIFY(is_sorted(res = mat.template selfadjointView[Lower]()))
    res_d = lo_sym_d
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower to full")
    VERIFY(is_sorted(res = up.template selfadjointView[Upper]()))
    res_d = up_sym_d
    VERIFY(res.isApprox(res_d) and "upper selfadjoint to full")
    VERIFY(is_sorted(res = lo.template selfadjointView[Lower]()))
    res_d = lo_sym_d
    VERIFY(res.isApprox(res_d) and "lower selfadjoint full")

    res.template selfadjointView[Upper]() = mat.template selfadjointView[Upper]()
    res_d = up_sym_d.template triangularView[Upper]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper to upper")
    res.template selfadjointView[Lower]() = mat.template selfadjointView[Upper]()
    res_d = up_sym_d.template triangularView[Lower]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper to lower")
    res.template selfadjointView[Upper]() = mat.template selfadjointView[Lower]()
    res_d = lo_sym_d.template triangularView[Upper]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower to upper")
    res.template selfadjointView[Lower]() = mat.template selfadjointView[Lower]()
    res_d = lo_sym_d.template triangularView[Lower]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower to lower")

    res.template selfadjointView[Upper]() = mat.template selfadjointView[Upper]().twistedBy(p)
    res_d = ((p * up_sym_d) * p.inverse()).eval().template triangularView[Upper]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper twisted to upper")
    res.template selfadjointView[Upper]() = mat.template selfadjointView[Lower]().twistedBy(p)
    res_d = ((p * lo_sym_d) * p.inverse()).eval().template triangularView[Upper]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower twisted to upper")
    res.template selfadjointView[Lower]() = mat.template selfadjointView[Lower]().twistedBy(p)
    res_d = ((p * lo_sym_d) * p.inverse()).eval().template triangularView[Lower]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower twisted to lower")
    res.template selfadjointView[Lower]() = mat.template selfadjointView[Upper]().twistedBy(p)
    res_d = ((p * up_sym_d) * p.inverse()).eval().template triangularView[Lower]()
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper twisted to lower")

    res.template selfadjointView[Upper]() = up.template selfadjointView[Upper]().twistedBy(p)
    res_d = ((p * up_sym_d) * p.inverse()).eval().template triangularView[Upper]()
    VERIFY(res.isApprox(res_d) and "upper selfadjoint twisted to upper")
    res.template selfadjointView[Upper]() = lo.template selfadjointView[Lower]().twistedBy(p)
    res_d = ((p * lo_sym_d) * p.inverse()).eval().template triangularView[Upper]()
    VERIFY(res.isApprox(res_d) and "lower selfadjoint twisted to upper")
    res.template selfadjointView[Lower]() = lo.template selfadjointView[Lower]().twistedBy(p)
    res_d = ((p * lo_sym_d) * p.inverse()).eval().template triangularView[Lower]()
    VERIFY(res.isApprox(res_d) and "lower selfadjoint twisted to lower")
    res.template selfadjointView[Lower]() = up.template selfadjointView[Upper]().twistedBy(p)
    res_d = ((p * up_sym_d) * p.inverse()).eval().template triangularView[Lower]()
    VERIFY(res.isApprox(res_d) and "upper selfadjoint twisted to lower")

    VERIFY(is_sorted(res = mat.template selfadjointView[Upper]().twistedBy(p)))
    res_d = (p * up_sym_d) * p.inverse()
    VERIFY(res.isApprox(res_d) and "full selfadjoint upper twisted to full")
    VERIFY(is_sorted(res = mat.template selfadjointView[Lower]().twistedBy(p)))
    res_d = (p * lo_sym_d) * p.inverse()
    VERIFY(res.isApprox(res_d) and "full selfadjoint lower twisted to full")
    VERIFY(is_sorted(res = up.template selfadjointView[Upper]().twistedBy(p)))
    res_d = (p * up_sym_d) * p.inverse()
    VERIFY(res.isApprox(res_d) and "upper selfadjoint twisted to full")
    VERIFY(is_sorted(res = lo.template selfadjointView[Lower]().twistedBy(p)))
    res_d = (p * lo_sym_d) * p.inverse()
    VERIFY(res.isApprox(res_d) and "lower selfadjoint twisted to full")

# template<Scalar> void sparse_permutations_all(int size)
def sparse_permutations_all[Scalar: type](size: Int):
    CALL_SUBTEST((sparse_permutations[ColMajor](SparseMatrix[Scalar, ColMajor](size, size))))
    CALL_SUBTEST((sparse_permutations[ColMajor](SparseMatrix[Scalar, RowMajor](size, size))))
    CALL_SUBTEST((sparse_permutations[RowMajor](SparseMatrix[Scalar, ColMajor](size, size))))
    CALL_SUBTEST((sparse_permutations[RowMajor](SparseMatrix[Scalar, RowMajor](size, size))))

# void test_sparse_permutations()
def test_sparse_permutations():
    for i in range(0, g_repeat):
        var s: Int = random[Int](1, 50)
        CALL_SUBTEST_1((sparse_permutations_all[Float64](s)))
        CALL_SUBTEST_2((sparse_permutations_all[ComplexFloat64](s)))
    VERIFY((internal.is_same[
        internal.permutation_matrix_product[SparseMatrix[Float64], OnTheRight, False, SparseShape].ReturnType,
        internal.nested_eval[Product[SparseMatrix[Float64], PermutationMatrix[Dynamic, Dynamic], AliasFreeProduct], 1].type
    ].value))
    VERIFY((internal.is_same[
        internal.permutation_matrix_product[SparseMatrix[Float64], OnTheLeft, False, SparseShape].ReturnType,
        internal.nested_eval[Product[PermutationMatrix[Dynamic, Dynamic], SparseMatrix[Float64], AliasFreeProduct], 1].type
    ].value))