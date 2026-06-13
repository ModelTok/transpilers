from Eigen import Matrix3d
from IO import cout, endl

def main():
    let m = Matrix3d.Random()
    cout << "Here is the matrix m:" << endl << m << endl
    cout << "Its inverse is:" << endl << m.inverse() << endl