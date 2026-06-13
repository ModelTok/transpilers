from third_party.eigen.Eigen import RowVectorXd
from third_party.eigen.Eigen import cout, endl

var vec1 = RowVectorXd(3)
vec1 << 1, 2, 3
cout << "vec1 = " << vec1 << endl
var vec2 = RowVectorXd(4)
vec2 << 1, 4, 9, 16
cout << "vec2 = " << vec2 << endl
var joined = RowVectorXd(7)
joined << vec1, vec2
cout << "joined = " << joined << endl