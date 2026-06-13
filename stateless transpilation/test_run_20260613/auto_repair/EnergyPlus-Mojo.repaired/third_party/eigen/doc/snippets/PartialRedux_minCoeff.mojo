from random import random
from tensor import Tensor

struct Matrix3d:
    var data: Tensor[Float64, 3, 3]

    def __init__(inout self):
        self.data = Tensor[Float64, 3, 3]()

    @staticmethod
    def Random() -> Matrix3d:
        var m = Matrix3d()
        for i in range(3):
            for j in range(3):
                m.data[i, j] = random() * 2.0 - 1.0  # approximate Random() range [-1,1]
        return m

    def colwise(self) -> ColwiseProxy:
        return ColwiseProxy(self)

struct ColwiseProxy:
    var mat: Matrix3d

    def __init__(inout self, m: Matrix3d):
        self.mat = m

    def minCoeff(self) -> Tensor[Float64, 3]:
        var mins = Tensor[Float64, 3]()
        for j in range(3):
            var min_val = self.mat.data[0, j]
            for i in range(1, 3):
                if self.mat.data[i, j] < min_val:
                    min_val = self.mat.data[i, j]
            mins[j] = min_val
        return mins

def main():
    var m = Matrix3d.Random()
    print("Here is the matrix m:")
    print(m.data)
    print("Here is the minimum of each column:")
    print(m.colwise().minCoeff())