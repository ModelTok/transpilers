from ......Eigen import Vector3d, Projective3d, Matrix4d

var v: Vector3d = Vector3d.Random()
var w: Vector3d
var P: Projective3d = Projective3d(Matrix4d.Random())
print("v                                   = [" + str(v.transpose()) + "]^T")
print("h.homogeneous()                     = [" + str(v.homogeneous().transpose()) + "]^T")
print("(P * v.homogeneous())               = [" + str((P * v.homogeneous()).transpose()) + "]^T")
print("(P * v.homogeneous()).hnormalized() = [" + str((P * v.homogeneous()).eval().hnormalized().transpose()) + "]^T")