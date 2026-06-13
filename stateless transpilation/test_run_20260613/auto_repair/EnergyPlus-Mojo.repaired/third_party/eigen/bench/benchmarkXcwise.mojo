from Eigen.Core import *
import sys

alias VECTYPE = VectorXLd
alias VECSIZE = 1000000
alias REPEAT = 1000

def main() -> int:
    var I = VECTYPE.Ones(VECSIZE)
    var m = VECTYPE(VECSIZE, 1)
    for i in range(VECSIZE):
        m[i] = 0.1 * i / VECSIZE
    for a in range(REPEAT):
        m = VECTYPE.Ones(VECSIZE) + 0.00005 * (m.cwise().square() + m / 4)
    print(m[0])
    return 0