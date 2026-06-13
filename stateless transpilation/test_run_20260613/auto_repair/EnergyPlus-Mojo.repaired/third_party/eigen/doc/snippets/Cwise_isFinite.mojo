from third_party.eigen.Eigen import Array3d, isfinite
from third_party.eigen.Eigen import cout

var v = Array3d(1, 2, 3)
v(1) *= 0.0 / 0.0
v(2) /= 0.0
cout << v << endl << endl
cout << isfinite(v) << endl