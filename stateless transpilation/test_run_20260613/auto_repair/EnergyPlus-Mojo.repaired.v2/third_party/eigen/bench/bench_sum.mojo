alias SCALAR = Float64
alias SIZE = 100  // placeholder; original macro not defined

struct Vec:
    var data: List[SCALAR]

    def __init__(inout self, size: Int):
        self.data = List[SCALAR](size)

    def setZero(inout self):
        for i in range(len(self.data)):
            self.data[i] = SCALAR(0)

    def __getitem__(self, idx: Int) -> SCALAR:
        return self.data[idx]

    def __setitem__(self, idx: Int, val: SCALAR):
        self.data[idx] = val

    def coeffRef(inout self, idx: Int) -> ref SCALAR:
        return self.data[idx]

    def sum(self) -> SCALAR:
        var s: SCALAR = 0
        for i in range(len(self.data)):
            s += self.data[i]
        return s

def main():
    Vec v(SIZE)
    v.setZero()
    v[0] = 1
    v[1] = 2
    for i in range(1000000):
        v.coeffRef(0) += v.sum() * SCALAR(1e-20)
    print(v.sum())