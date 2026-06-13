from Eigen import Matrix, Ones, Constant, internal, random
from std import cout

alias REPEAT = 10000
alias SCALAR = Float32

def main() raises:
    alias Mat = Matrix[SCALAR, Dynamic, Dynamic]
    var m = Mat(100, 100)
    m.setRandom()
    for a in range(REPEAT):
        var r: Int = internal.random(0, 10)
        var c: Int = internal.random(0, 10)
        var nr: Int = internal.random(50, 80)
        var nc: Int = internal.random(50, 80)
        m.block(r, c, nr, nc) += Ones(nr, nc)
        m.block(r, c, nr, nc) *= SCALAR(10)
        m.block(r, c, nr, nc) -= Constant(nr, nc, 10)
        m.block(r, c, nr, nc) /= SCALAR(10)
    cout << m[0] << endl
    return 0