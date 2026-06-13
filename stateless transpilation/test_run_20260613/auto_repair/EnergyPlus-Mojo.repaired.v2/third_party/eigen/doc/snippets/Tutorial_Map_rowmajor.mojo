from ...Eigen import Map, Matrix, RowMajor, Unaligned, Stride

var array = Array[Int](8)
for i in range(8):
    array[i] = i
print("Column-major:\n", Map[Matrix[Int, 2, 4]](array))
print("Row-major:\n", Map[Matrix[Int, 2, 4, RowMajor]](array))
print("Row-major using stride:\n", Map[Matrix[Int, 2, 4], Unaligned, Stride[1, 4]](array))