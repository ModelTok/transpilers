from Eigen import VectorXf

var nb_load: Int = 0
var nb_loadu: Int = 0
var nb_store: Int = 0
var nb_storeu: Int = 0

def EIGEN_DEBUG_ALIGNED_LOAD():
    nb_load += 1

def EIGEN_DEBUG_UNALIGNED_LOAD():
    nb_loadu += 1

def EIGEN_DEBUG_ALIGNED_STORE():
    nb_store += 1

def EIGEN_DEBUG_UNALIGNED_STORE():
    nb_storeu += 1

def VERIFY(condition: Bool, message: String = "Verification failed"):
    if not condition:
        print(message)
        abort()

def VERIFY_ALIGNED_UNALIGNED_COUNT[expr: fn() capturing -> None](AL: Int, UL: Int, AS: Int, US: Int):
    nb_load = 0
    nb_loadu = 0
    nb_store = 0
    nb_storeu = 0
    expr()
    if not (nb_load == AL and nb_loadu == UL and nb_store == AS and nb_storeu == US):
        print(" >> ", nb_load, ", ", nb_loadu, ", ", nb_store, ", ", nb_storeu)
    VERIFY(nb_load == AL and nb_loadu == UL and nb_store == AS and nb_storeu == US)

alias EIGEN_VECTORIZE_AVX = False
alias EIGEN_VECTORIZE_SSE = False

def test_unalignedcount():
    @parameter
    if EIGEN_VECTORIZE_AVX:
        var a = VectorXf(40)
        var b = VectorXf(40)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a += b }, 10, 0, 5, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) += b.segment(0,40) }, 5, 5, 5, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) -= b.segment(0,40) }, 5, 5, 5, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) *= 3.5 }, 5, 0, 5, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) /= 3.5 }, 5, 0, 5, 0)
    elif EIGEN_VECTORIZE_SSE:
        var a = VectorXf(40)
        var b = VectorXf(40)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a += b }, 20, 0, 10, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) += b.segment(0,40) }, 10, 10, 10, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) -= b.segment(0,40) }, 10, 10, 10, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) *= 3.5 }, 10, 0, 10, 0)
        VERIFY_ALIGNED_UNALIGNED_COUNT({ a.segment(0,40) /= 3.5 }, 10, 0, 10, 0)
    else:
        nb_load = 0
        nb_loadu = 0
        nb_store = 0
        nb_storeu = 0
        var a: Int = 0
        var b: Int = 0
        VERIFY(a == b)