from Eigen import Matrix2d, cout

var a = Matrix2d()
var b = Matrix2d()
var c = Matrix2d()
a << 1, 2, 3, 4
b << 5, 6, 7, 8
c.noalias() = a * b  # this computes the product directly to c
cout << c << endl