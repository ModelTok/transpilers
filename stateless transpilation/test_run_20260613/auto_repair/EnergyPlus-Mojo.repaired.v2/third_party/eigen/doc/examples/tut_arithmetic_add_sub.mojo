from tensor import Tensor, DType

def main() raises:
    var a = Tensor[DType.float64](2, 2, [1, 2, 3, 4])
    var b = Tensor[DType.float64](2, 2, [2, 3, 1, 4])
    print("a + b =")
    print(a + b)
    print("a - b =")
    print(a - b)
    print("Doing a += b;")
    a += b
    print("Now a =")
    print(a)
    var v = Tensor[DType.float64](3, [1, 2, 3])
    var w = Tensor[DType.float64](3, [1, 0, 0])
    print("-v + w - v =")
    print(-v + w - v)