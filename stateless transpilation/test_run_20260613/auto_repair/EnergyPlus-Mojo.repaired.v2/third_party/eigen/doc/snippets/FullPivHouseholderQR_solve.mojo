from third_party.eigen.Eigen import Matrix3f, Random, fullPivHouseholderQr, solve, isApprox
from third_party.eigen.Eigen import cout, endl

var m = Matrix3f.Random()
var y = Matrix3f.Random()
cout << "Here is the matrix m:" << endl << m << endl
cout << "Here is the matrix y:" << endl << y << endl
var x: Matrix3f
x = m.fullPivHouseholderQr().solve(y)
assert(y.isApprox(m * x))
cout << "Here is a solution x to the equation mx=y:" << endl << x << endl