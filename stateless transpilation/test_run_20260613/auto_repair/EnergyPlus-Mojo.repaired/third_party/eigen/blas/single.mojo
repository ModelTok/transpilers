alias SCALAR = float32
alias SCALAR_SUFFIX = "s"
alias SCALAR_SUFFIX_UP = "S"
alias ISCOMPLEX = 0
include "level1_impl.mojo"
include "level1_real_impl.mojo"
include "level2_impl.mojo"
include "level2_real_impl.mojo"
include "level3_impl.mojo"
def BLASFUNC(sdsdot)(n: Int*, alpha: float32*, x: float32*, incx: Int*, y: float32*, incy: Int*) -> float32:
    return float64(*alpha) + BLASFUNC(dsdot)(n, x, incx, y, incy)