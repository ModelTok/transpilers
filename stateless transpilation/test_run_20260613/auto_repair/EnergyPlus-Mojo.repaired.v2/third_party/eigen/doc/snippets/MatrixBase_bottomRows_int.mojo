from Eigen import Array44i

def main():
    var a = Array44i.Random()
    print("Here is the array a:")
    print(a)
    print("Here is a.bottomRows(2):")
    print(a.bottomRows(2))
    a.bottomRows(2).setZero()
    print("Now the array a is:")
    print(a)