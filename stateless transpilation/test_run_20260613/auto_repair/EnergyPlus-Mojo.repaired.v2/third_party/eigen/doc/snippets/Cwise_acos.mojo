from third_party.eigen.Eigen import Array3d
from third_party.eigen.Eigen import sqrt
from third_party.eigen.Eigen import cout

var v = Array3d(0, sqrt(2.)/2, 1)
cout << v.acos() << endl