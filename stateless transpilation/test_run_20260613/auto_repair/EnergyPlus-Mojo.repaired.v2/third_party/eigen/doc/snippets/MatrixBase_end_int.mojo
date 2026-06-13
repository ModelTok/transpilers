from ...Eigen import RowVector4i

def main() raises:
    var v = RowVector4i.Random()
    print("Here is the vector v:")
    print(v)
    print("Here is v.tail(2):")
    print(v.tail(2))
    v.tail(2).setZero()
    print("Now the vector v is:")
    print(v)