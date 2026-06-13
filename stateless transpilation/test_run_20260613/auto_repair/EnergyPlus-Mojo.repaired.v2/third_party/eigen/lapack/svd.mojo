from lapack_common import xerbla_, SCALAR_SUFFIX_UP, matrix, make_vector, PlainMatrixType, Scalar, RealScalar
from ...Eigen import BDCSVD, JacobiSVD, ComputeFullU, ComputeFullV, ComputeThinU, ComputeThinV

def LAPACK_gesdd(
    jobz: Pointer[Int8],
    m: Pointer[Int32],
    n: Pointer[Int32],
    a: Pointer[Scalar],
    lda: Pointer[Int32],
    s: Pointer[RealScalar],
    u: Pointer[Scalar],
    ldu: Pointer[Int32],
    vt: Pointer[Scalar],
    ldvt: Pointer[Int32],
    work: Pointer[Scalar],
    lwork: Pointer[Int32],
    rwork: Pointer[RealScalar],
    iwork: Pointer[Int32],
    info: Pointer[Int32],
) -> Int32:
    var query_size: Bool = lwork[] == -1
    var diag_size: Int32 = min(m[], n[])
    info[] = 0
    if jobz[] != ord('A') and jobz[] != ord('S') and jobz[] != ord('O') and jobz[] != ord('N'):
        info[] = -1
    elif m[] < 0:
        info[] = -2
    elif n[] < 0:
        info[] = -3
    elif lda[] < max(1, m[]):
        info[] = -5
    elif lda[] < max(1, m[]):
        info[] = -8
    elif ldu[] < 1 or (jobz[] == ord('A') and ldu[] < m[]) or (jobz[] == ord('O') and m[] < n[] and ldu[] < m[]):
        info[] = -8
    elif ldvt[] < 1 or (jobz[] == ord('A') and ldvt[] < n[]) or (jobz[] == ord('S') and ldvt[] < diag_size) or (jobz[] == ord('O') and m[] >= n[] and ldvt[] < n[]):
        info[] = -10
    if info[] != 0:
        var e: Int32 = -info[]
        return xerbla_(SCALAR_SUFFIX_UP + "GESDD ", Pointer[Int32](address_of(e)), 6)
    if query_size:
        lwork[] = 0
        return 0
    if n[] == 0 or m[] == 0:
        return 0
    var mat: PlainMatrixType = PlainMatrixType(m[], n[])
    mat = matrix(a, m[], n[], lda[])
    var option: Int32 = (
        ComputeFullU | ComputeFullV if jobz[] == ord('A')
        else ComputeThinU | ComputeThinV if jobz[] == ord('S')
        else ComputeThinU | ComputeThinV if jobz[] == ord('O')
        else 0
    )
    var svd: BDCSVD[PlainMatrixType] = BDCSVD[PlainMatrixType](mat, option)
    make_vector(s, diag_size) = svd.singularValues().head(diag_size)
    if jobz[] == ord('A'):
        matrix(u, m[], m[], ldu[]) = svd.matrixU()
        matrix(vt, n[], n[], ldvt[]) = svd.matrixV().adjoint()
    elif jobz[] == ord('S'):
        matrix(u, m[], diag_size, ldu[]) = svd.matrixU()
        matrix(vt, diag_size, n[], ldvt[]) = svd.matrixV().adjoint()
    elif jobz[] == ord('O') and m[] >= n[]:
        matrix(a, m[], n[], lda[]) = svd.matrixU()
        matrix(vt, n[], n[], ldvt[]) = svd.matrixV().adjoint()
    elif jobz[] == ord('O'):
        matrix(u, m[], m[], ldu[]) = svd.matrixU()
        matrix(a, diag_size, n[], lda[]) = svd.matrixV().adjoint()
    return 0

def LAPACK_gesvd(
    jobu: Pointer[Int8],
    jobv: Pointer[Int8],
    m: Pointer[Int32],
    n: Pointer[Int32],
    a: Pointer[Scalar],
    lda: Pointer[Int32],
    s: Pointer[RealScalar],
    u: Pointer[Scalar],
    ldu: Pointer[Int32],
    vt: Pointer[Scalar],
    ldvt: Pointer[Int32],
    work: Pointer[Scalar],
    lwork: Pointer[Int32],
    rwork: Pointer[RealScalar],
    info: Pointer[Int32],
) -> Int32:
    var query_size: Bool = lwork[] == -1
    var diag_size: Int32 = min(m[], n[])
    info[] = 0
    if jobu[] != ord('A') and jobu[] != ord('S') and jobu[] != ord('O') and jobu[] != ord('N'):
        info[] = -1
    elif (jobv[] != ord('A') and jobv[] != ord('S') and jobv[] != ord('O') and jobv[] != ord('N')) or (jobu[] == ord('O') and jobv[] == ord('O')):
        info[] = -2
    elif m[] < 0:
        info[] = -3
    elif n[] < 0:
        info[] = -4
    elif lda[] < max(1, m[]):
        info[] = -6
    elif ldu[] < 1 or ((jobu[] == ord('A') or jobu[] == ord('S')) and ldu[] < m[]):
        info[] = -9
    elif ldvt[] < 1 or (jobv[] == ord('A') and ldvt[] < n[]) or (jobv[] == ord('S') and ldvt[] < diag_size):
        info[] = -11
    if info[] != 0:
        var e: Int32 = -info[]
        return xerbla_(SCALAR_SUFFIX_UP + "GESVD ", Pointer[Int32](address_of(e)), 6)
    if query_size:
        lwork[] = 0
        return 0
    if n[] == 0 or m[] == 0:
        return 0
    var mat: PlainMatrixType = PlainMatrixType(m[], n[])
    mat = matrix(a, m[], n[], lda[])
    var option: Int32 = (
        (ComputeFullU if jobu[] == ord('A') else (ComputeThinU if jobu[] == ord('S') or jobu[] == ord('O') else 0))
        | (ComputeFullV if jobv[] == ord('A') else (ComputeThinV if jobv[] == ord('S') or jobv[] == ord('O') else 0))
    )
    var svd: JacobiSVD[PlainMatrixType] = JacobiSVD[PlainMatrixType](mat, option)
    make_vector(s, diag_size) = svd.singularValues().head(diag_size)
    if jobu[] == ord('A'):
        matrix(u, m[], m[], ldu[]) = svd.matrixU()
    elif jobu[] == ord('S'):
        matrix(u, m[], diag_size, ldu[]) = svd.matrixU()
    elif jobu[] == ord('O'):
        matrix(a, m[], diag_size, lda[]) = svd.matrixU()
    if jobv[] == ord('A'):
        matrix(vt, n[], n[], ldvt[]) = svd.matrixV().adjoint()
    elif jobv[] == ord('S'):
        matrix(vt, diag_size, n[], ldvt[]) = svd.matrixV().adjoint()
    elif jobv[] == ord('O'):
        matrix(a, diag_size, n[], lda[]) = svd.matrixV().adjoint()
    return 0