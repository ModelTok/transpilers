struct ArrayXd:
    var data: List[Float64]

    def __init__(inout self, n: Int):
        self.data = List[Float64](capacity=n)

    def __init__(inout self, data: List[Float64]):
        self.data = data

    @staticmethod
    def LinSpaced(n: Int, start: Float64, end: Float64) -> ArrayXd:
        var result = ArrayXd(n)
        if n == 1:
            result.data.append(start)
        else:
            let step = (end - start) / (n - 1)
            for i in range(n):
                result.data.append(start + step * i)
        return result

    def __str__(self) -> String:
        var s = String()
        s += "{ "
        for i in range(self.data.size):
            if i > 0:
                s += ", "
            s += str(self.data[i])
        s += " }"
        return s

def ceil(v: ArrayXd) -> ArrayXd:
    var result = ArrayXd(v.data.size)
    for i in range(v.data.size):
        result.data.append(math.ceil(v.data[i]))
    return result

def main():
    var v = ArrayXd.LinSpaced(7, -2, 2)
    print(v)
    print()
    print(ceil(v))