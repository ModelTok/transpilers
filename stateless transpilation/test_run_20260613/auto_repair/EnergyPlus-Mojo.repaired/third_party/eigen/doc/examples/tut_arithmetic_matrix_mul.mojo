from mojo.stdlib.matrix import Matrix, Vector

alias Matrix2d = Matrix[Float64, 2, 2]
alias Vector2d = Vector[Float64, 2]

def main():
    var mat = Matrix2d()
    mat[0, 0] = 1.0
    mat[0, 1] = 2.0
    mat[1, 0] = 3.0
    mat[1, 1] = 4.0

    var u = Vector2d(-1.0, 1.0)
    var v = Vector2d(2.0, 0.0)

    print("Here is mat*mat:\n", mat * mat)
    print("Here is mat*u:\n", mat * u)
    print("Here is u^T*mat:\n", u.transpose() * mat)
    print("Here is u^T*v:\n", u.transpose() * v)
    print("Here is u*v^T:\n", u * v.transpose())
    print("Let's multiply mat by itself")
    mat = mat * mat
    print("Now mat is mat:\n", mat)