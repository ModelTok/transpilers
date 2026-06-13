from ......Eigen import *  # includes MatrixXf, Ref, VectorXf, Matrix4f, etc.

def inv_cond(a: Ref[MatrixXf]) -> Float32:
    var sing_vals: VectorXf = a.jacobiSvd().singularValues()
    return sing_vals[sing_vals.size - 1] / sing_vals[0]

def main():
    var m: Matrix4f = Matrix4f.Random()
    print("matrix m:")
    print(m)
    print()
    print("inv_cond(m):          ", inv_cond(m))
    print("inv_cond(m(1:3,1:3)): ", inv_cond(m.topLeftCorner(3,3)))
    print("inv_cond(m+I):        ", inv_cond(m + Matrix4f.Identity()))