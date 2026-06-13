from Eigen import Matrix4i, Matrix4iZero, Matrix4iSetRandom
from iostream import cout, endl

var m = Matrix4iZero()
m.col(1).setRandom()
cout << m << endl