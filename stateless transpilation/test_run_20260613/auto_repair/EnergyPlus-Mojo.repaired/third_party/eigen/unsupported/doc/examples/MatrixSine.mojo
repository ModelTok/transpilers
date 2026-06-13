from tensor import NDArray, dtype

def main() raises:
    var A = NDArray[Float64].random((3, 3), -1.0, 1.0)
    print("A = ")
    print(A)
    print()
    var sinA = A.sin()
    print("sin(A) = ")
    print(sinA)
    print()
    var cosA = A.cos()
    print("cos(A) = ")
    print(cosA)
    print()
    print("sin^2(A) + cos^2(A) = ")
    print(sinA @ sinA + cosA @ cosA)
    print()