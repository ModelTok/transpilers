from lapack_common import Scalar, PlainMatrixType, matrix, make_vector, xerbla_, UPLO, INVALID, UP, SCALAR_SUFFIX_UP
from ...Eigen.Eigenvalues import SelfAdjointEigenSolver, ComputeEigenvectors, EigenvaluesOnly, NoConvergence
from memory import Pointer
from builtin import Int32, Int8, max, ord

def syev(
    jobz: Pointer[Int8],
    uplo: Pointer[Int8],
    n: Pointer[Int32],
    a: Pointer[Scalar],
    lda: Pointer[Int32],
    w: Pointer[Scalar],
    work: Pointer[Scalar],  //*work*/
    lwork: Pointer[Int32],
    info: Pointer[Int32]
) -> Int32:
    var query_size: Bool = lwork[0] == -1
    info[0] = 0
    if jobz[0] != ord('N') and jobz[0] != ord('V'):
        info[0] = -1
    elif UPLO(uplo[0]) == INVALID:
        info[0] = -2
    elif n[0] < 0:
        info[0] = -3
    elif lda[0] < max(1, n[0]):
        info[0] = -5
    elif (not query_size) and lwork[0] < max(1, 3 * n[0] - 1):
        info[0] = -8
    if info[0] != 0:
        var e: Int32 = -info[0]
        return xerbla_(SCALAR_SUFFIX_UP + "SYEV ", Pointer.address_of(e), 6)
    if query_size:
        lwork[0] = 0
        return 0
    if n[0] == 0:
        return 0
    var mat: PlainMatrixType = PlainMatrixType(n[0], n[0])
    if UPLO(uplo[0]) == UP:
        mat = matrix(a, n[0], n[0], lda[0]).adjoint()
    else:
        mat = matrix(a, n[0], n[0], lda[0])
    var computeVectors: Bool = jobz[0] == ord('V') or jobz[0] == ord('v')
    var eig: SelfAdjointEigenSolver[PlainMatrixType] = SelfAdjointEigenSolver[PlainMatrixType](mat, ComputeEigenvectors if computeVectors else EigenvaluesOnly)
    if eig.info() == NoConvergence:
        make_vector(w, n[0]).setZero()
        if computeVectors:
            matrix(a, n[0], n[0], lda[0]).setIdentity()
        return 0
    make_vector(w, n[0]) = eig.eigenvalues()
    if computeVectors:
        matrix(a, n[0], n[0], lda[0]) = eig.eigenvectors()
    return 0