from sparse import *

# Global variable g_repeat assumed defined elsewhere (e.g., in test harness)
# Import random if needed for internal::random
from random import random_int as internal_random_int

def initSPD[Scalar: AnyRegType](
    density: Float64,
    ref_mat: ref Matrix[Scalar, Dynamic, Dynamic],
    sparse_mat: ref SparseMatrix[Scalar]
):
    var aux: Matrix[Scalar, Dynamic, Dynamic] = Matrix[Scalar, Dynamic, Dynamic](ref_mat.rows(), ref_mat.cols())
    initSparse(density, ref_mat, sparse_mat)
    ref_mat = ref_mat * ref_mat.adjoint()
    for k in range(2):
        initSparse(density, aux, sparse_mat, ForceNonZeroDiag)
        ref_mat += aux * aux.adjoint()
    sparse_mat.setZero()
    for j in range(sparse_mat.cols()):
        for i in range(j, sparse_mat.rows()):
            if ref_mat[i, j] != Scalar(0):
                sparse_mat.insert(i, j) = ref_mat[i, j]
    sparse_mat.finalize()

def sparse_solvers[Scalar: AnyRegType](rows: Int, cols: Int):
    var density: Float64 = max(8.0 / (Float64(rows) * Float64(cols)), 0.01)
    alias DenseMatrix = Matrix[Scalar, Dynamic, Dynamic]
    alias DenseVector = Matrix[Scalar, Dynamic, 1]

    var vec1: DenseVector = DenseVector.Random(rows)
    var zeroCoords: List[Vector2i] = List[Vector2i]()
    var nonzeroCoords: List[Vector2i] = List[Vector2i]()

    {
        var vec2: DenseVector = vec1
        var vec3: DenseVector = vec1
        var m2: SparseMatrix[Scalar] = SparseMatrix[Scalar](rows, cols)
        var ref_mat2: DenseMatrix = DenseMatrix.Zero(rows, cols)

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeLowerTriangular, &zeroCoords, &nonzeroCoords)
        VERIFY_IS_APPROX(
            ref_mat2.triangularView[Lower]().solve(vec2),
            m2.triangularView[Lower]().solve(vec3)
        )

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeUpperTriangular, &zeroCoords, &nonzeroCoords)
        VERIFY_IS_APPROX(
            ref_mat2.triangularView[Upper]().solve(vec2),
            m2.triangularView[Upper]().solve(vec3)
        )
        VERIFY_IS_APPROX(
            ref_mat2.conjugate().triangularView[Upper]().solve(vec2),
            m2.conjugate().triangularView[Upper]().solve(vec3)
        )

        {
            var cm2: SparseMatrix[Scalar] = SparseMatrix[Scalar](m2)
            var mm2: MappedSparseMatrix[Scalar] = MappedSparseMatrix[Scalar](
                rows, cols, cm2.nonZeros(), cm2.outerIndexPtr(), cm2.innerIndexPtr(), cm2.valuePtr()
            )
            VERIFY_IS_APPROX(
                ref_mat2.conjugate().triangularView[Upper]().solve(vec2),
                mm2.conjugate().triangularView[Upper]().solve(vec3)
            )
        }

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeLowerTriangular, &zeroCoords, &nonzeroCoords)
        VERIFY_IS_APPROX(
            ref_mat2.transpose().triangularView[Upper]().solve(vec2),
            m2.transpose().triangularView[Upper]().solve(vec3)
        )

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeUpperTriangular, &zeroCoords, &nonzeroCoords)
        VERIFY_IS_APPROX(
            ref_mat2.transpose().triangularView[Lower]().solve(vec2),
            m2.transpose().triangularView[Lower]().solve(vec3)
        )

        var matB: SparseMatrix[Scalar] = SparseMatrix[Scalar](rows, rows)
        var ref_matB: DenseMatrix = DenseMatrix.Zero(rows, rows)

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeLowerTriangular)
        initSparse[Scalar](density, ref_matB, matB)
        ref_mat2.triangularView[Lower]().solveInPlace(ref_matB)
        m2.triangularView[Lower]().solveInPlace(matB)
        VERIFY_IS_APPROX(matB.toDense(), ref_matB)

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeUpperTriangular)
        initSparse[Scalar](density, ref_matB, matB)
        ref_mat2.triangularView[Upper]().solveInPlace(ref_matB)
        m2.triangularView[Upper]().solveInPlace(matB)
        VERIFY_IS_APPROX(matB, ref_matB)

        initSparse[Scalar](density, ref_mat2, m2, ForceNonZeroDiag | MakeLowerTriangular, &zeroCoords, &nonzeroCoords)
        VERIFY_IS_APPROX(
            ref_mat2.triangularView[Lower]().solve(vec2),
            m2.triangularView[Lower]().solve(vec3)
        )
    }

def test_sparse_solvers():
    for _ in range(g_repeat):
        CALL_SUBTEST_1(sparse_solvers[Float64](8, 8))
        var s: Int = internal_random_int(1, 300)
        CALL_SUBTEST_2(sparse_solvers[ComplexFloat64](s, s))
        CALL_SUBTEST_1(sparse_solvers[Float64](s, s))