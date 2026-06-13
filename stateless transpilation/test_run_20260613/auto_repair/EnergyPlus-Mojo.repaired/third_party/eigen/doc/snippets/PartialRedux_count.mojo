from Eigen import Matrix3d, Matrix, ptrdiff_t
from Eigen import Random, rowwise, count
from iostream import cout, endl

var m = Matrix3d.Random()
cout << "Here is the matrix m:" << endl << m << endl
var res = Matrix[ptrdiff_t, 3, 1]((m.array() >= 0.5).rowwise().count())
cout << "Here is the count of elements larger or equal than 0.5 of each row:" << endl
cout << res << endl