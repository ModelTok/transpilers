from memory import List
from math import *

struct VectorXd:
    var data: List[Float64]
    var size: Int

    def __init__(inout self):
        self.data = List[Float64]()
        self.size = 0

    def __init__(inout self, size: Int):
        self.data = List[Float64](capacity=size)
        for i in range(size):
            self.data.append(0.0)
        self.size = size

    def __init__(inout self, other: VectorXd):
        self.data = other.data.copy()
        self.size = other.size

    @staticmethod
    def Ones(size: Int) -> VectorXd:
        var v = VectorXd(size)
        for i in range(size):
            v.data[i] = 1.0
        return v

    def __getitem__(self, index: Int) -> Float64:
        return self.data[index]

    def __setitem__(inout self, index: Int, value: Float64):
        self.data[index] = value

    def __mul__(self, other: Float64) -> VectorXd:
        var result = VectorXd(self.size)
        for i in range(self.size):
            result.data[i] = self.data[i] * other
        return result

    def __rmul__(self, other: Float64) -> VectorXd:
        return self.__mul__(other)

    def transpose(self) -> String:
        var s = String()
        for i in range(self.size):
            if i > 0:
                s += " "
            s += str(self.data[i])
        return s

    def __str__(self) -> String:
        return self.transpose()

struct MyVectorType:
    var _base: VectorXd

    def __init__(inout self):
        self._base = VectorXd()

    # template constructor: accept any type convertible to VectorXd
    def __init__[OtherDerived: AnyType](inout self, other: OtherDerived):
        # simplified: assume other is a VectorXd or MyVectorType
        self._base = other._base if (OtherDerived == MyVectorType) else other

    def __setitem__(inout self, index: Int, value: Float64):
        self._base[index] = value

    def __getitem__(self, index: Int) -> Float64:
        return self._base[index]

    def __mul__(self, other: Float64) -> MyVectorType:
        var result = MyVectorType()
        result._base = self._base * other
        return result

    def __rmul__(self, other: Float64) -> MyVectorType:
        return self.__mul__(other)

    def transpose(self) -> String:
        return self._base.transpose()

    # assignment operators
    def __assign__(inout self, other: MyVectorType):
        self._base = other._base

    def __assign__(inout self, other: VectorXd):
        self._base = other

    # template assignment operator (simplified)
    def __assign__[OtherDerived: AnyType](inout self, other: OtherDerived):
        self._base = other._base if (OtherDerived == MyVectorType) else other

    @staticmethod
    def Ones(size: Int) -> MyVectorType:
        var v = MyVectorType()
        v._base = VectorXd.Ones(size)
        return v

def main():
    var v = MyVectorType.Ones(4)
    v[2] = v[2] + 10   # equivalent to v(2) += 10; 0-based index
    v = 2 * v
    print(v.transpose())