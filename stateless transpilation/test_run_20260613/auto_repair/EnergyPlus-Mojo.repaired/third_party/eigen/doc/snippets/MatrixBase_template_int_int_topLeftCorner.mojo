from memory import memset_zero
from sys import print

def main() raises:
    var m = Matrix4i.Random()
    print("Here is the matrix m:")
    print(m)
    print("Here is m.topLeftCorner<2,2>():")
    print(m.topLeftCorner[2,2]())
    m.topLeftCorner[2,2]().setZero()
    print("Now the matrix m is:")
    print(m)