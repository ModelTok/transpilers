from third_party.eigen.Eigen import Vector3d
from third_party.eigen.Eigen import cout

var v = Vector3d(1,0,0)
var w = Vector3d(1e-4,0,1)
cout << "Here's the vector v:" << endl << v << endl
cout << "Here's the vector w:" << endl << w << endl
cout << "v.isOrthogonal(w) returns: " << v.isOrthogonal(w) << endl
cout << "v.isOrthogonal(w,1e-3) returns: " << v.isOrthogonal(w,1e-3) << endl