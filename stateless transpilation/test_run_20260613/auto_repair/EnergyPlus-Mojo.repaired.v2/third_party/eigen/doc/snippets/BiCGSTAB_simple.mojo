from Eigen import VectorXd, SparseMatrix, BiCGSTAB
from iostream import std

def main():
    let n = 10000
    var x = VectorXd(n)
    var b = VectorXd(n)
    var A = SparseMatrix[float64](n, n)
    /* ... fill A and b ... */ 
    var solver = BiCGSTAB[SparseMatrix[float64]]()
    solver.compute(A)
    x = solver.solve(b)
    std.cout << "#iterations:     " << solver.iterations() << std.endl
    std.cout << "estimated error: " << solver.error()      << std.endl
    /* ... update b ... */
    x = solver.solve(b) // solve again