from Eigen.Dense import Matrix3f, FullPivLU
from iostream import cout, endl

def main() raises:
    var A = Matrix3f()
    A << 1, 2, 5,
         2, 1, 4,
         3, 0, 3
    cout << "Here is the matrix A:\n" << A << endl
    var lu_decomp = FullPivLU[Matrix3f](A)
    cout << "The rank of A is " << lu_decomp.rank() << endl
    cout << "Here is a matrix whose columns form a basis of the null-space of A:\n" \
         << lu_decomp.kernel() << endl
    cout << "Here is a matrix whose columns form a basis of the column-space of A:\n" \
         << lu_decomp.image(A) << endl  # yes, have to pass the original A