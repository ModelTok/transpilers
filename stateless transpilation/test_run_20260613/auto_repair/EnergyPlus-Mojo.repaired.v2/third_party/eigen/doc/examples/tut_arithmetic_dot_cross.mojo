from Eigen import *

def main():
    var v = Vector3d(1, 2, 3)
    var w = Vector3d(0, 1, 2)
    print("Dot product: ", v.dot(w))
    let dp: Float64 = v.adjoint() * w
    print("Dot product via a matrix product: ", dp)
    print("Cross product:\n", v.cross(w))