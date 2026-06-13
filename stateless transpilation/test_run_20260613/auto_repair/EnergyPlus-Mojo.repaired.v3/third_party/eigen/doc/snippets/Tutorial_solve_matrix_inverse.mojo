from builtins.matrix import Matrix

alias Matrix3f = Matrix[DType.float32, 3, 3]
alias Vector3f = Matrix[DType.float32, 3, 1]

var A: Matrix3f = Matrix3f(1, 2, 3, 4, 5, 6, 7, 8, 10)
var b: Vector3f = Vector3f(3, 3, 4)
var x: Vector3f = A.inverse() * b
print("The solution is:")
print(x)