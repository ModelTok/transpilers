from third_party.eigen.Eigen import VectorXd, RowVector3d
from third_party.eigen.Eigen import cout, endl

var v = VectorXd(10)
v.resize(3)
var w = RowVector3d()
w.resize(3) # this is legal, but has no effect
cout << "v: " << v.rows() << " rows, " << v.cols() << " cols" << endl
cout << "w: " << w.rows() << " rows, " << w.cols() << " cols" << endl