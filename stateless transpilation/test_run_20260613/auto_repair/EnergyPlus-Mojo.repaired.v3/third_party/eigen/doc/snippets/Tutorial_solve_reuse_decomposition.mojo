from eigen import Matrix3f, Vector3f, PartialPivLU

def main():
    var A = Matrix3f(3, 3)
    A = Matrix3f(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 10])
    var luOfA = PartialPivLU[Matrix3f](A)
    var b = Vector3f(3, 3, 4)
    var x = luOfA.solve(b)
    print("The solution with right-hand side (3,3,4) is:")
    print(x)
    b = Vector3f(1, 1, 1)
    x = luOfA.solve(b)
    print("The solution with right-hand side (1,1,1) is:")
    print(x)