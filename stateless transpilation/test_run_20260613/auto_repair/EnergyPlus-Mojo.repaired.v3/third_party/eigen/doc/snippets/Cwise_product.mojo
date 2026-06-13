from third_party.eigen.Eigen import Array33i, Random, cout, endl

var a = Array33i.Random()
var b = Array33i.Random()
var c = a * b
cout << "a:\n" << a << "\nb:\n" << b << "\nc:\n" << c << endl