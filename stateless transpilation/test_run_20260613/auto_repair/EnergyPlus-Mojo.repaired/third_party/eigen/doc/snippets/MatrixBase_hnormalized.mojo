from third_party.eigen.Eigen import Vector4d, Projective3d, Matrix4d
from third_party.eigen.Eigen import cout

var v = Vector4d.Random()
var P = Projective3d(Matrix4d.Random())
cout << "v                   = " << v.transpose() << "]^T" << endl
cout << "v.hnormalized()     = " << v.hnormalized().transpose() << "]^T" << endl
cout << "P*v                 = " << (P * v).transpose() << "]^T" << endl
cout << "(P*v).hnormalized() = " << (P * v).hnormalized().transpose() << "]^T" << endl