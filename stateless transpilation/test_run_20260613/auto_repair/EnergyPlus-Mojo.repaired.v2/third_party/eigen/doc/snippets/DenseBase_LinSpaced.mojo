from memory import List

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
            let step = (high - low) // (n - 1)
            for i in range(n):
                result.append(low + step * i)
        return VectorXi(result)
    def transpose(self) -> VectorXi:
        return self
    def __str__(self) -> String:
        var s = String()
        for i in range(len(self.data)):
            if i > 0:
                s += " "
            s += str(self.data[i])
        return s

struct VectorXd:
    var data: List[Float64]
    def __init__(inout self, data: List[Float64]):
        self.data = data
    @staticmethod
    def LinSpaced(n: Int, low: Float64, high: Float64) -> VectorXd:
        var result = List[Float64]()
        if n == 1:
            result.append(low)
        else:
            let step = (high - low) / (n - 1)
            for i in range(n):
                result.append(low + step * i)
        return VectorXd(result)
    def transpose(self) -> VectorXd:
        return self
    def __str__(self) -> String:
        var s = String()
        for i in range(len(self.data)):
            if i > 0:
                s += " "
            s += str(self.data[i])
        return s

def main():
    print(VectorXi.LinSpaced(4,7,10).transpose())
    print(VectorXd.LinSpaced(5,0.0,1.0).transpose())