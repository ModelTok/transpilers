from ...Eigen import Map, RowVectorXi

var data = [1,2,3,4,5,6,7,8,9]
var v = Map[RowVectorXi](data, 4)
print("The mapped vector v is: ", v)
new (&v) Map[RowVectorXi](data+4, 5)
print("Now v is: ", v)