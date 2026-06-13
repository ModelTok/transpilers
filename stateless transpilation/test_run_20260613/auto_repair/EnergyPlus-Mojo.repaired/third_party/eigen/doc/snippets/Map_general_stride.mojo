from ...Eigen import MatrixXi, Map, Stride, Dynamic

def main() raises:
    var array: Int32[24]
    for i in range(24):
        array[i] = i
    print(Map[MatrixXi, 0, Stride[Dynamic, 2]](array, 3, 3, Stride[Dynamic, 2](8, 2)))