from memory import memset_zero
from tensor import Tensor, TensorShape
from utils import print

alias Matrix4i = Tensor[Int, 4, 4]

def main() raises:
    var m = Matrix4i.random()
    print("Here is the matrix m:")
    print(m)
    print("Here is m.bottomRightCorner(2, 2):")
    print(m.bottomRightCorner(2, 2))
    m.bottomRightCorner(2, 2).setZero()
    print("Now the matrix m is:")
    print(m)