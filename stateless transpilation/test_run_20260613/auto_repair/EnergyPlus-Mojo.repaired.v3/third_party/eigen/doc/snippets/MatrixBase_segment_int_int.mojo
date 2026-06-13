from Eigen import RowVector4i

def main():
    var v = RowVector4i.Random()
    print("Here is the vector v:")
    print(v)
    print("Here is v.segment(1, 2):")
    print(v.segment(1, 2))
    v.segment(1, 2).setZero()
    print("Now the vector v is:")
    print(v)