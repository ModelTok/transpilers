from Eigen import Map, Matrix3i

var array = List[Int]()
for i in range(9):
    array.append(i)
print(Map[Matrix3i](array))