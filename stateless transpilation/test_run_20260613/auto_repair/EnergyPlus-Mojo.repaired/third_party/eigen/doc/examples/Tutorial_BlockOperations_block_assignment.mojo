from memory import memset_zero
from sys import print

def main() raises:
    var m = Array22f()
    m[0, 0] = 1
    m[0, 1] = 2
    m[1, 0] = 3
    m[1, 1] = 4
    var a = Array44f.Constant(0.6)
    print("Here is the array a:")
    print(a)
    print()
    a.block[2,2](1,1) = m
    print("Here is now a with m copied into its central 2x2 block:")
    print(a)
    print()
    a.block(0,0,2,3) = a.block(2,1,2,3)
    print("Here is now a with bottom-right 2x3 block copied into top-left 2x2 block:")
    print(a)
    print()