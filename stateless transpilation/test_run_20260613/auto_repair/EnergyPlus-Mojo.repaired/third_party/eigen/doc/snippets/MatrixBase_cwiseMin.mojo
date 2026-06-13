from third_party.eigen.Eigen import Vector3d, cout

def main():
    var v = Vector3d(2, 3, 4)
    var w = Vector3d(4, 2, 3)
    cout << v.cwiseMin(w) << endl