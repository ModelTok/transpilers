from common import xerbla_, SCALAR_SUFFIX_UP, OP, INVALID, NOTR, TR, ADJ, Scalar, RealScalar, MatrixType, PivotsType, ColMajor, UnitLower, Upper
from ...Eigen.LU import partial_lu_impl

def getrf(m: Pointer[Int], n: Pointer[Int], pa: Pointer[RealScalar], lda: Pointer[Int], ipiv: Pointer[Int], info: Pointer[Int]) -> Int:
    info[] = 0
    if m[] < 0:
        info[] = -1
    elif n[] < 0:
        info[] = -2
    elif lda[] < max(1, m[]):
        info[] = -4
    if info[] != 0:
        let e = -info[]
        return xerbla_(SCALAR_SUFFIX_UP + "GETRF", Pointer[Int].address_of(e), 6)
    if m[] == 0 or n[] == 0:
        return 0
    let a = pa.bitcast[Scalar]()
    var nb_transpositions: Int
    let ret = Int(partial_lu_impl[Scalar, ColMajor, Int].blocked_lu(m[], n[], a, lda[], ipiv, nb_transpositions))
    for i in range(min(m[], n[])):
        ipiv[i] += 1
    if ret >= 0:
        info[] = ret + 1
    return 0

def getrs(trans: Pointer[UInt8], n: Pointer[Int], nrhs: Pointer[Int], pa: Pointer[RealScalar], lda: Pointer[Int], ipiv: Pointer[Int], pb: Pointer[RealScalar], ldb: Pointer[Int], info: Pointer[Int]) -> Int:
    info[] = 0
    if OP(trans[]) == INVALID:
        info[] = -1
    elif n[] < 0:
        info[] = -2
    elif nrhs[] < 0:
        info[] = -3
    elif lda[] < max(1, n[]):
        info[] = -5
    elif ldb[] < max(1, n[]):
        info[] = -8
    if info[] != 0:
        let e = -info[]
        return xerbla_(SCALAR_SUFFIX_UP + "GETRS", Pointer[Int].address_of(e), 6)
    let a = pa.bitcast[Scalar]()
    let b = pb.bitcast[Scalar]()
    let lu = MatrixType(a, n[], n[], lda[])
    var B = MatrixType(b, n[], nrhs[], ldb[])
    for i in range(n[]):
        ipiv[i] -= 1
    if OP(trans[]) == NOTR:
        B = PivotsType(ipiv, n[]) * B
        lu.triangularView[UnitLower]().solveInPlace(B)
        lu.triangularView[Upper]().solveInPlace(B)
    elif OP(trans[]) == TR:
        lu.triangularView[Upper]().transpose().solveInPlace(B)
        lu.triangularView[UnitLower]().transpose().solveInPlace(B)
        B = PivotsType(ipiv, n[]).transpose() * B
    elif OP(trans[]) == ADJ:
        lu.triangularView[Upper]().adjoint().solveInPlace(B)
        lu.triangularView[UnitLower]().adjoint().solveInPlace(B)
        B = PivotsType(ipiv, n[]).transpose() * B
    for i in range(n[]):
        ipiv[i] += 1
    return 0