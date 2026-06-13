from random import random

struct VectorXf:
    var data: List[Float64]

    def setRandom(inout self, n: Int):
        self.data = List[Float64]()
        for i in range(n):
            self.data.append(random())

def main():
    var v = VectorXf()
    v.setRandom(3)
    print(v)