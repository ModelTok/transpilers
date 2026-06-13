from random import DefaultRandomEngine as default_random_engine, PoissonDistribution as poisson_distribution

struct RowVectorXi:
    var data: List[Int]

    def __init__(inout self, data: List[Int]):
        self.data = data

    @staticmethod
    def NullaryExpr(n: Int, f: fn() -> Int) -> Self:
        var result = List[Int]()
        for _ in range(n):
            result.append(f())
        return RowVectorXi(result)

    def __str__(self) -> String:
        var s = String()
        for i, val in enumerate(self.data):
            if i > 0:
                s += " "
            s += str(val)
        return s

def main():
    var generator = default_random_engine()
    var distribution = poisson_distribution[Int](4.1)
    var poisson = fn() -> Int:
        return distribution(generator)
    var v = RowVectorXi.NullaryExpr(10, poisson)
    print(v)