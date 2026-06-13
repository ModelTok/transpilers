from level1_impl import *
from level1_real_impl import *
from level2_impl import *
from level2_real_impl import *
from level3_impl import *

alias SCALAR = Float64
alias SCALAR_SUFFIX = "d"
alias SCALAR_SUFFIX_UP = "D"
alias ISCOMPLEX = 0

def dsdot(
    n: Pointer[Int32],
    x: Pointer[Float32],
    incx: Pointer[Int32],
    y: Pointer[Float32],
    incy: Pointer[Int32],
) -> Float64:
    if n[] <= 0:
        return 0.0
    if incx[] == 1 and incy[] == 1:
        return (make_vector(x, n[]).cast[DType.float64]().cwiseProduct(make_vector(y, n[]).cast[DType.float64]())).sum()
    elif incx[] > 0 and incy[] > 0:
        return (make_vector(x, n[], incx[]).cast[DType.float64]().cwiseProduct(make_vector(y, n[], incy[]).cast[DType.float64]())).sum()
    elif incx[] < 0 and incy[] > 0:
        return (make_vector(x, n[], -incx[]).reverse().cast[DType.float64]().cwiseProduct(make_vector(y, n[], incy[]).cast[DType.float64]())).sum()
    elif incx[] > 0 and incy[] < 0:
        return (make_vector(x, n[], incx[]).cast[DType.float64]().cwiseProduct(make_vector(y, n[], -incy[]).reverse().cast[DType.float64]())).sum()
    elif incx[] < 0 and incy[] < 0:
        return (make_vector(x, n[], -incx[]).reverse().cast[DType.float64]().cwiseProduct(make_vector(y, n[], -incy[]).reverse().cast[DType.float64]())).sum()
    else:
        return 0.0