from lapack_common import *
from Eigen.Cholesky import *

def EIGEN_LAPACK_FUNC_potrf(uplo: Pointer[char], n: Pointer[int], pa: Pointer[RealScalar], lda: Pointer[int], info: Pointer[int]) -> int:
    info[] = 0
    if UPLO(uplo[]) == INVALID:
        info[] = -1
    elif n[] < 0:
        info[] = -2
    elif lda[] < std_max(1, n[]):
        info[] = -4
    if info[] != 0:
        var e: int = -info[]
        return xerbla_(SCALAR_SUFFIX_UP + "POTRF", &e, 6)
    var a: Pointer[Scalar] = reinterpret[Pointer[Scalar]](pa)
    var A: MatrixType = MatrixType(a, n[], n[], lda[])
    var ret: int
    if UPLO(uplo[]) == UP:
        ret = int(internal.llt_inplace[Scalar, Upper].blocked(A))
    else:
        ret = int(internal.llt_inplace[Scalar, Lower].blocked(A))
    if ret >= 0:
        info[] = ret + 1
    return 0

def EIGEN_LAPACK_FUNC_potrs(uplo: Pointer[char], n: Pointer[int], nrhs: Pointer[int], pa: Pointer[RealScalar], lda: Pointer[int], pb: Pointer[RealScalar], ldb: Pointer[int], info: Pointer[int]) -> int:
    info[] = 0
    if UPLO(uplo[]) == INVALID:
        info[] = -1
    elif n[] < 0:
        info[] = -2
    elif nrhs[] < 0:
        info[] = -3
    elif lda[] < std_max(1, n[]):
        info[] = -5
    elif ldb[] < std_max(1, n[]):
        info[] = -7
    if info[] != 0:
        var e: int = -info[]
        return xerbla_(SCALAR_SUFFIX_UP + "POTRS", &e, 6)
    var a: Pointer[Scalar] = reinterpret[Pointer[Scalar]](pa)
    var b: Pointer[Scalar] = reinterpret[Pointer[Scalar]](pb)
    var A: MatrixType = MatrixType(a, n[], n[], lda[])
    var B: MatrixType = MatrixType(b, n[], nrhs[], ldb[])
    if UPLO(uplo[]) == UP:
        A.triangularView[Upper]().adjoint().solveInPlace(B)
        A.triangularView[Upper]().solveInPlace(B)
    else:
        A.triangularView[Lower]().solveInPlace(B)
        A.triangularView[Lower]().adjoint().solveInPlace(B)
    return 0