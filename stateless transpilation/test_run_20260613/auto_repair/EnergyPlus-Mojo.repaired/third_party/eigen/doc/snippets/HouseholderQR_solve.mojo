alias Matrix3x3 = Matrix[Float32, 3, 3]
Matrix3x3 m = Matrix3x3.Random()
Matrix3f y = Matrix3f.Random()
print("Here is the matrix m:")
print(m)
print("Here is the matrix y:")
print(y)
Matrix3f x
x = m.householderQr().solve(y)
assert(y.isApprox(m*x))
print("Here is a solution x to the equation mx=y:")
print(x)