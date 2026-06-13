from third_party.eigen.Eigen import Vector3f

var boxMin = Vector3f.Zero()
var boxMax = Vector3f.Ones()
var p0 = Vector3f.Random()
var p1 = Vector3f.Random().cwiseAbs()
print("Is (" + str(p0.transpose()) + ") inside the box: " + str((boxMin.array() < p0.array()).all() and (boxMax.array() > p0.array()).all()))
print("Is (" + str(p1.transpose()) + ") inside the box: " + str((boxMin.array() < p1.array()).all() and (boxMax.array() > p1.array()).all()))