from mojo import DType
from mojo.linear_algebra import Matrix

alias MATSIZE = 3
alias REPEAT = 40000000
alias SCALAR = DType.float64

def main() -> Int32:
    var I = Matrix[SCALAR].ones(MATSIZE, MATSIZE)
    var m = Matrix[SCALAR](MATSIZE, MATSIZE)
    for i in range(MATSIZE):
        for j in range(MATSIZE):
            m[i, j] = (i + MATSIZE * j)
    __asm__("#begin")
    for a in range(REPEAT):
        m = Matrix[SCALAR].ones(MATSIZE, MATSIZE) + 0.00005 * (m + (m @ m))
    __asm__("#end")
    print(m)
    return 0