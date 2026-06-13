from Eigen import Vector3i

var v = Vector3i.Random()
print("Here is the vector v:")
print(v)
print("v.rowwise().replicate(5) = ...")
print(v.rowwise().replicate(5))