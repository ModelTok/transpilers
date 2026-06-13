var m = Matrix[float, 2, 3].random()
var y = Matrix2f.random()
print("Here is the matrix m:")
print(m)
print("Here is the matrix y:")
print(y)
var x = m.fullPivLu().solve(y)
if (m * x).isApprox(y):
    print("Here is a solution x to the equation mx=y:")
    print(x)
else:
    print("The equation mx=y does not have any solution.")