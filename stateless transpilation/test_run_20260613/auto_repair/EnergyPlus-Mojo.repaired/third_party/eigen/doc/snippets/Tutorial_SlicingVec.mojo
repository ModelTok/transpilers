from eigen import RowVectorXf, Map, InnerStride

var v = RowVectorXf.LinSpaced(20, 0, 19)
print("Input:")
print(v)
var v2 = Map[RowVectorXf, 0, InnerStride[2]](v.data(), v.size() / 2)
print("Even:")
print(v2)