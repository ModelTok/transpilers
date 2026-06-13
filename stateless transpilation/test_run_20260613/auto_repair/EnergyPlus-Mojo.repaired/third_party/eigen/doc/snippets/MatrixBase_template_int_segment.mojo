from Eigen import RowVector4i

def main():
    var v = RowVector4i.Random()
    print("Here is the vector v:")
    print(v)
    print("Here is v.segment<2>(1):")
    print(v.segment[2](1))
    v.segment[2](2).setZero()
    print("Now the vector v is:")
    print(v)