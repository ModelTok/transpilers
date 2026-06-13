from memory import memset_zero
from tensor import Tensor, TensorShape
from utils import print

def main() raises:
    var mat = Tensor[DType.int32](TensorShape(3, 3))
    mat[0, 0] = 1
    mat[0, 1] = 2
    mat[0, 2] = 3
    mat[1, 0] = 4
    mat[1, 1] = 5
    mat[1, 2] = 6
    mat[2, 0] = 7
    mat[2, 1] = 8
    mat[2, 2] = 9
    print("Here is the matrix mat:")
    print(mat)
    # mat.bottomRightCorner(2,2) = mat.topLeftCorner(2,2)
    # Mojo tensor slicing not directly supported, manual copy
    var temp = Tensor[DType.int32](TensorShape(2, 2))
    temp[0, 0] = mat[0, 0]
    temp[0, 1] = mat[0, 1]
    temp[1, 0] = mat[1, 0]
    temp[1, 1] = mat[1, 1]
    mat[1, 1] = temp[0, 0]
    mat[1, 2] = temp[0, 1]
    mat[2, 1] = temp[1, 0]
    mat[2, 2] = temp[1, 1]
    print("After the assignment, mat = ")
    print(mat)