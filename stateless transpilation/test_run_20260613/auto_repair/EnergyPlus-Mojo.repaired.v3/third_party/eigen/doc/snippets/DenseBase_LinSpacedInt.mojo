struct VectorXi:
    var data: List[Int]

    def __init__(inout self, data: List[Int]):
        self.data = data

    @staticmethod
    def LinSpaced(n: Int, low: Int, high: Int) -> VectorXi:
        var result = List[Int]()
        if n == 1:
            result.append(low)
        else:
            var step = (high - low) // (n - 1)
            for i in range(n):
                result.append(low + i * step)
        return VectorXi(result)

    def transpose(self) -> String:
        var s = String()
        for i in range(len(self.data)):
            if i > 0:
                s += " "
            s += str(self.data[i])
        return s

def main():
    print("Even spacing inputs:")
    print(VectorXi.LinSpaced(8,1,4).transpose())
    print(VectorXi.LinSpaced(8,1,8).transpose())
    print(VectorXi.LinSpaced(8,1,15).transpose())
    print("Uneven spacing inputs:")
    print(VectorXi.LinSpaced(8,1,7).transpose())
    print(VectorXi.LinSpaced(8,1,9).transpose())
    print(VectorXi.LinSpaced(8,1,16).transpose())