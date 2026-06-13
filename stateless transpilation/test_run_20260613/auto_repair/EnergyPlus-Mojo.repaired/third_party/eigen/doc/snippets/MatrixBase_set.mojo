from Eigen import Matrix3i, Vector2i
from iostream import cout, endl

var m1: Matrix3i
m1 << 1, 2, 3,
      4, 5, 6,
      7, 8, 9
cout << m1 << endl << endl
var m2: Matrix3i = Matrix3i.Identity()
m2.block(0,0, 2,2) << 10, 11, 12, 13
cout << m2 << endl << endl
var v1: Vector2i
v1 << 14, 15
m2 << v1.transpose(), 16,
      v1, m1.block(1,1,2,2)
cout << m2 << endl