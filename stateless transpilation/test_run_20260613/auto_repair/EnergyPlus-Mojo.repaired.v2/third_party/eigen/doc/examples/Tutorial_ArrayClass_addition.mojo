from memory import memset_zero
from sys import print

def main() raises:
    var a = ArrayXXf(3, 3)
    var b = ArrayXXf(3, 3)
    a = ArrayXXf([[1,2,3],
                  [4,5,6],
                  [7,8,9]])
    b = ArrayXXf([[1,2,3],
                  [1,2,3],
                  [1,2,3]])
    print("a + b = ")
    print(a + b)
    print()
    print("a - 2 = ")
    print(a - 2)