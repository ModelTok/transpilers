from WCECommon import sgn
from memory import Pointer
from math import abs, pow

struct IInterpolation2D:
    var m_Points: List[Tuple[Float64, Float64]]

    def __init__(inout self, t_Points: List[Tuple[Float64, Float64]]):
        self.m_Points = t_Points

    def getValue(self, t_Value: Float64) -> Float64:
        ...

struct CSPChipInterpolation2D(IInterpolation2D):
    var m_Hs: List[Float64]
    var m_Deltas: List[Float64]
    var m_Derivatives: List[Float64]

    def __init__(inout self, t_Points: List[Tuple[Float64, Float64]]):
        IInterpolation2D.__init__(self, t_Points)
        self.m_Hs = self.calculateHs()
        self.m_Deltas = self.calculateDeltas()
        self.m_Derivatives = self.calculateDerivatives()

    def getValue(self, t_Value: Float64) -> Float64:
        if t_Value <= self.m_Points[0][0]:
            return self.m_Points[0][1]
        if t_Value >= (self.m_Points[-1])[0]:
            return (self.m_Points[-1])[1]
        var subinterval = self.getSubinterval(t_Value)
        var s = t_Value - self.m_Points[subinterval][0]
        var h = self.m_Hs[subinterval]
        var y_k = self.m_Points[subinterval][1]
        var y_k_plus_1 = self.m_Points[subinterval + 1][1]
        var d_k = self.m_Derivatives[subinterval]
        var d_k_plus_1 = self.m_Derivatives[subinterval + 1]
        return self.interpolate(h, s, y_k, y_k_plus_1, d_k, d_k_plus_1)

    def getSubinterval(self, t_Value: Float64) -> Int:
        var interval: Int = 1
        for i in range(1, len(self.m_Points)):
            if self.m_Points[i][0] > t_Value:
                interval = i - 1
                break
        return interval

    def calculateHs(self) -> List[Float64]:
        var res = List[Float64]()
        for i in range(1, len(self.m_Points)):
            res.append(self.m_Points[i][0] - self.m_Points[i - 1][0])
        return res

    def calculateDeltas(self) -> List[Float64]:
        var res = List[Float64]()
        for i in range(1, len(self.m_Points)):
            res.append((self.m_Points[i][1] - self.m_Points[i - 1][1])
                       / (self.m_Points[i][0] - self.m_Points[i - 1][0]))
        return res

    def calculateDerivatives(self) -> List[Float64]:
        var res = List[Float64]()
        var first_res = ((2 * self.m_Hs[0] + self.m_Hs[1]) * self.m_Deltas[0] - (self.m_Hs[0] * self.m_Deltas[1])) / (self.m_Hs[0] + self.m_Hs[1])
        if sgn(first_res) != sgn(self.m_Deltas[0]):
            first_res = 0.0
        elif (sgn(self.m_Deltas[0]) != sgn(self.m_Deltas[1])) and (abs(first_res) > abs(3 * self.m_Deltas[0])):
            first_res = 3 * self.m_Deltas[0]
        var last_h = self.m_Hs[-1]
        var penultimate_h = self.m_Hs[-2]
        var last_d = self.m_Deltas[-1]
        var penultimate_d = self.m_Deltas[-2]
        var last_res = ((2 * last_h + penultimate_h) * last_d - last_h * penultimate_d) / (last_h + penultimate_h)
        if sgn(last_res) != sgn(last_d):
            last_res = 0.0
        elif (sgn(last_d) != sgn(penultimate_d)) and (abs(last_res) > abs(3 * last_d)):
            last_res = 3 * last_d
        res.append(first_res)
        for i in range(1, len(self.m_Hs)):
            res.append(
              CSPChipInterpolation2D.piecewiseCubicDerivative(self.m_Deltas[i], self.m_Deltas[i - 1], self.m_Hs[i], self.m_Hs[i - 1]))
        res.append(last_res)
        return res

    @staticmethod
    def piecewiseCubicDerivative(delta_k: Float64, delta_k_minus_1: Float64, hk: Float64, hk_minus_1: Float64) -> Float64:
        var res: Float64
        if (delta_k == 0) or (delta_k_minus_1 == 0) or (delta_k > 0 and delta_k_minus_1 < 0) or (delta_k < 0 and delta_k_minus_1 > 0):
            return 0.0
        if hk == hk_minus_1:
            res = 0.5 * (1 / delta_k_minus_1 + 1 / delta_k)
            res = 1 / res
        else:
            var w1 = 2 * hk + hk_minus_1
            var w2 = hk + 2 * hk_minus_1
            res = (w1 / delta_k_minus_1) + (w2 / delta_k)
            res = (w1 + w2) / res
        return res

    def interpolate(self, h: Float64, s: Float64, y_k: Float64, y_k_plus_one: Float64, d_k: Float64, d_k_plus_one: Float64) -> Float64:
        return ((3 * h * pow(s, 2) - 2 * pow(s, 3)) / pow(h, 3)) * y_k_plus_one \
               + ((pow(h, 3) - 3 * h * pow(s, 2) + 2 * pow(s, 3)) / pow(h, 3)) * y_k \
               + ((pow(s, 2) * (s - h)) / pow(h, 2)) * d_k_plus_one \
               + ((s * pow(s - h, 2)) / pow(h, 2)) * d_k