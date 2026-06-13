from Eigen import Matrix3f, RowVector4i

var m: Matrix3f = Matrix3f.Random()
var i: Int
var j: Int
let minOfM: Float32 = m.minCoeff(inout i, inout j)
print("Here is the matrix m:")
print(m)
print("Its minimum coefficient (" + str(minOfM) + ") is at position (" + str(i) + "," + str(j) + ")")
print()

var v: RowVector4i = RowVector4i.Random()
let maxOfV: Int = v.maxCoeff(inout i)
print("Here is the vector v: ", end="")
print(v)
print("Its maximum coefficient (" + str(maxOfV) + ") is at position " + str(i))