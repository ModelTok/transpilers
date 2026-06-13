from ......Eigen import Array3d, cout, endl

def main():
    var v = Array3d(-1, 2, 1)
    var w = Array3d(-3, 2, 3)
    cout << ((v < w) || (v < 0)) << endl