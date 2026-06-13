from third_party.eigen.Eigen import Vector3d, cout

def main():
    let v = Vector3d(2, 3, 4)
    let w = Vector3d(4, 2, 3)
    cout << v.cwiseMax(w) << endl