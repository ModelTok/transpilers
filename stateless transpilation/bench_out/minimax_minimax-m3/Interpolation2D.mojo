# EXTERNAL DEPS (to wire in glue):
# - sgn: from WCECommon.hpp (FenestrationCommon namespace) - sign function returning -1, 0, or 1

from math import abs, pow
from collections import List


fn sgn(x: Float64) -> Int:
    """Sign function: returns -1, 0, or 1.

    Imported from WCECommon.hpp in the original C++ code.
    """
    if x > 0.0:
        return 1
    elif x < 0.0:
        return -1
    return 0


struct Pair:
    var first: Float64
    var second: Float64

    fn __init__(out self, first: Float64, second: Float64):
        self.first = first
        self.second = second


struct IInterpolation2D:
    var m_Points: List[Pair]

    fn __init__(out self, t_Points: List[Pair]) raises:
        self.m_Points = t_Points

    fn getValue(self, t_Value: Float64) -> Float64:
        # Pure virtual in C++; should not be called directly
        return 0.0


struct CSPChipInterpolation2D:
    var m_Points: List[Pair]
    var m_Hs: List[Float64]
    var m_Deltas: List[Float64]
    var m_Derivatives: List[Float64]

    fn __init__(out self, t_Points: List[Pair]) raises:
        self.m_Points = t_Points
        self.m_Hs = self.calculateHs()
        self.m_Deltas = self.calculateDeltas()
        self.m_Derivatives = self.calculateDerivatives()

    fn getValue(self, t_Value: Float64) -> Float64:
        if t_Value <= self.m_Points[0].first:
            return self.m_Points[0].second

        if t_Value >= self.m_Points[len(self.m_Points) - 1].first:
            return self.m_Points[len(self.m_Points) - 1].second

        var subinterval = self.getSubinterval(t_Value)
        var s = t_Value - self.m_Points[subinterval].first
        var h = self.m_Hs[subinterval]

        var y_k = self.m_Points[subinterval].second
        var y_k_plus_1 = self.m_Points[subinterval + 1].second
        var d_k = self.m_Derivatives[subinterval]
        var d_k_plus_1 = self.m_Derivatives[subinterval + 1]
        return self.interpolate(h, s, y_k, y_k_plus_1, d_k, d_k_plus_1)

    fn getSubinterval(self, t_Value: Float64) -> Int:
        var interval = 1
        for i in range(1, len(self.m_Points)):
            if self.m_Points[i].first > t_Value:
                interval = i - 1
                break
        return interval

    @always_inline
    fn calculateHs(self) -> List[Float64]:
        var res = List[Float64]()
        for i in range(1, len(self.m_Points)):
            res.append(self.m_Points[i].first - self.m_Points[i - 1].first)
        return res

    @always_inline
    fn calculateDeltas(self) -> List[Float64]:
        var res = List[Float64]()
        for i in range(1, len(self.m_Points)):
            res.append((self.m_Points[i].second - self.m_Points[i - 1].second)
                       / (self.m_Points[i].first - self.m_Points[i - 1].first))
        return res

    fn calculateDerivatives(self) -> List[Float64]:
        var res = List[Float64]()
        # first get the special cases, first and last
        var first_res = ((2.0 * self.m_Hs[0] + self.m_Hs[1]) * self.m_Deltas[0]
                         - (self.m_Hs[0] * self.m_Deltas[1])) \
                        / (self.m_Hs[0] + self.m_Hs[1])
        if sgn(first_res) != sgn(self.m_Deltas[0]):
            first_res = 0.0
        elif ((sgn(self.m_Deltas[0]) != sgn(self.m_Deltas[1]))
              and (abs(first_res) > abs(3.0 * self.m_Deltas[0]))):
            first_res = 3.0 * self.m_Deltas[0]

        var last_h = self.m_Hs[len(self.m_Hs) - 1]
        var penultimate_h = self.m_Hs[len(self.m_Hs) - 2]
        var last_d = self.m_Deltas[len(self.m_Deltas) - 1]
        var penultimate_d = self.m_Deltas[len(self.m_Deltas) - 2]

        var last_res = ((2.0 * last_h + penultimate_h) * last_d - last_h * penultimate_d) \
                       / (last_h + penultimate_h)

        if sgn(last_res) != sgn(last_d):
            last_res = 0.0
        elif ((sgn(last_d) != sgn(penultimate_d))
              and (abs(last_res) > abs(3.0 * last_d))):
            last_res = 3.0 * last_d

        res.append(first_res)
        for i in range(1, len(self.m_Hs)):
            res.append(
                self.piecewiseCubicDerivative(
                    self.m_Deltas[i], self.m_Deltas[i - 1],
                    self.m_Hs[i], self.m_Hs[i - 1]
                )
            )

        res.append(last_res)
        return res

    @staticmethod
    fn piecewiseCubicDerivative(delta_k: Float64,
                                 delta_k_minus_1: Float64,
                                 hk: Float64,
                                 hk_minus_1: Float64) -> Float64:
        if (((delta_k == 0.0) or (delta_k_minus_1 == 0.0))
                or ((delta_k > 0.0) and (delta_k_minus_1 < 0.0))
                or ((delta_k < 0.0) and (delta_k_minus_1 > 0.0))):
            return 0.0
        var res: Float64 = 0.0
        if hk == hk_minus_1:
            res = 0.5 * (1.0 / delta_k_minus_1 + 1.0 / delta_k)
            res = 1.0 / res
        else:
            var w1 = 2.0 * hk + hk_minus_1
            var w2 = hk + 2.0 * hk_minus_1
            res = (w1 / delta_k_minus_1) + (w2 / delta_k)
            res = (w1 + w2) / res
        return res

    fn interpolate(self, h: Float64,
                   s: Float64,
                   y_k: Float64,
                   y_k_plus_one: Float64,
                   d_k: Float64,
                   d_k_plus_one: Float64) -> Float64:
        return ((3.0 * h * pow(s, 2) - 2.0 * pow(s, 3)) / pow(h, 3)) * y_k_plus_one \
            + ((pow(h, 3) - 3.0 * h * pow(s, 2) + 2.0 * pow(s, 3)) / pow(h, 3)) * y_k \
            + ((pow(s, 2) * (s - h)) / pow(h, 2)) * d_k_plus_one \
            + ((s * pow(s - h, 2)) / pow(h, 2)) * d_k
