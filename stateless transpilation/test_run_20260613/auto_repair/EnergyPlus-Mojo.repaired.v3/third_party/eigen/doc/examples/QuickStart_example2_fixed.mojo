from Eigen.Dense import Matrix3d, Vector3d
from iostream import cout, endl

def main() raises:
    var m = Matrix3d.Random()
    m = (m + Matrix3d.Constant(1.2)) * 50
    cout << "m =" << endl << m << endl
    var v = Vector3d(1, 2, 3)
    cout << "m * v =" << endl << m * v << endl