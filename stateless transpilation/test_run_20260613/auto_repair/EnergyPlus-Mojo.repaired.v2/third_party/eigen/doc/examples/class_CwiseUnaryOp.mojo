from ......Eigen.Core import Matrix4d

struct CwiseClampOp[Scalar: AnyType]:
    var m_inf: Scalar
    var m_sup: Scalar
    def __init__(inout self, inf: Scalar, sup: Scalar):
        self.m_inf = inf
        self.m_sup = sup
    def __call__(self, x: Scalar) -> Scalar:
        return self.m_inf if x < self.m_inf else (self.m_sup if x > self.m_sup else x)

def main():
    var m1 = Matrix4d.Random()
    print(m1)
    print("becomes: ")
    print(m1.unaryExpr(CwiseClampOp[Float64](-0.5, 0.5)))