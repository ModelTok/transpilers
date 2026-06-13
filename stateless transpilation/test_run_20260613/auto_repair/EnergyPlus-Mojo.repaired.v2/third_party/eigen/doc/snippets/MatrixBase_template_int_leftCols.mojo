from Eigen import Array44i

def main() raises:
    var a = Array44i.Random()
    print("Here is the array a:")
    print(a)
    print("Here is a.leftCols<2>():")
    print(a.leftCols[2]())
    a.leftCols[2]().setZero()
    print("Now the array a is:")
    print(a)