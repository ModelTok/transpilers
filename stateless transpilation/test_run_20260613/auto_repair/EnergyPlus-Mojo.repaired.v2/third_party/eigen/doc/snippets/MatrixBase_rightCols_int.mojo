from Array44i import Array44i

def main():
    var a = Array44i.Random()
    print("Here is the array a:")
    print(a)
    print("Here is a.rightCols(2):")
    print(a.rightCols(2))
    a.rightCols(2).setZero()
    print("Now the array a is:")
    print(a)