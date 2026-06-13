from Eigen import Array3d, isinf

def main():
    var v = Array3d(1, 2, 3)
    v[1] *= 0.0 / 0.0
    v[2] /= 0.0
    print(v)
    print()
    print(isinf(v))