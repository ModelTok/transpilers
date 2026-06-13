from printf import printf

alias EIGEN_WEAK_LINKING = ""

def xerbla_(msg: Pointer[UInt8], info: Pointer[Int32], _: Int32) -> Int32:
    printf("Eigen BLAS ERROR #%i: %s\n", info[], msg)
    return 0