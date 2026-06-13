typealias SCALAR = ComplexFloat64
alias SCALAR_SUFFIX = "z"
alias SCALAR_SUFFIX_UP = "Z"
alias REAL_SCALAR_SUFFIX = "d"
alias ISCOMPLEX = 1

include "level1_impl.mojo"
include "level1_cplx_impl.mojo"
include "level2_impl.mojo"
include "level2_cplx_impl.mojo"
include "level3_impl.mojo"