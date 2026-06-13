from Eigen.Dense import ArrayXf, Random

def main():
    var a = ArrayXf.Random(5)
    a *= 2
    print("a =")
    print(a)
    print("a.abs() =")
    print(a.abs())
    print("a.abs().sqrt() =")
    print(a.abs().sqrt())
    print("a.min(a.abs().sqrt()) =")
    print(a.min(a.abs().sqrt()))