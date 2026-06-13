# EXTERNAL DEPS (to wire in glue):
#   No external dependencies beyond standard library.
#   sgn function defined locally.

from typing import List, Tuple


class IInterpolation2D:
    def __init__(self, t_Points: List[Tuple[float, float]]):
        self.m_Points = t_Points

    def getValue(self, t_Value: float) -> float:
        raise NotImplementedError


class CSPChipInterpolation2D(IInterpolation2D):
    def __init__(self, t_Points: List[Tuple[float, float]]):
        super().__init__(t_Points)
        self.m_Hs = self.calculateHs()
        self.m_Deltas = self.calculateDeltas()
        self.m_Derivatives = self.calculateDerivatives()

    def getValue(self, t_Value: float) -> float:
        if t_Value <= self.m_Points[0][0]:
            return self.m_Points[0][1]
        if t_Value >= self.m_Points[-1][0]:
            return self.m_Points[-1][1]
        subinterval = self.getSubinterval(t_Value)
        s = t_Value - self.m_Points[subinterval][0]
        h = self.m_Hs[subinterval]
        y_k = self.m_Points[subinterval][1]
        y_k_plus_1 = self.m_Points[subinterval + 1][1]
        d_k = self.m_Derivatives[subinterval]
        d_k_plus_1 = self.m_Derivatives[subinterval + 1]
        return self.interpolate(h, s, y_k, y_k_plus_1, d_k, d_k_plus_1)

    def getSubinterval(self, t_Value: float) -> int:
        interval = 1
        for i in range(1, len(self.m_Points)):
            if self.m_Points[i][0] > t_Value:
                interval = i - 1
                break
        return interval

    def calculateHs(self) -> List[float]:
        res: List[float] = []
        for i in range(1, len(self.m_Points)):
            res.append(self.m_Points[i][0] - self.m_Points[i - 1][0])
        return res

    def calculateDeltas(self) -> List[float]:
        res: List[float] = []
        for i in range(1, len(self.m_Points)):
            res.append(
                (self.m_Points[i][1] - self.m_Points[i - 1][1])
                / (self.m_Points[i][0] - self.m_Points[i - 1][0])
            )
        return res

    def calculateDerivatives(self) -> List[float]:
        res: List[float] = []
        # first and last special cases
        first_res = (
            (2 * self.m_Hs[0] + self.m_Hs[1]) * self.m_Deltas[0]
            - (self.m_Hs[0] * self.m_Deltas[1])
        ) / (self.m_Hs[0] + self.m_Hs[1])
        if sgn(first_res) != sgn(self.m_Deltas[0]):
            first_res = 0.0
        elif (
            sgn(self.m_Deltas[0]) != sgn(self.m_Deltas[1])
            and (abs(first_res) > abs(3 * self.m_Deltas[0]))
        ):
            first_res = 3 * self.m_Deltas[0]
        last_h = self.m_Hs[-1]
        penultimate_h = self.m_Hs[-2]
        last_d = self.m_Deltas[-1]
        penultimate_d = self.m_Deltas[-2]
        last_res = (
            (2 * last_h + penultimate_h) * last_d - last_h * penultimate_d
        ) / (last_h + penultimate_h)
        if sgn(last_res) != sgn(last_d):
            last_res = 0.0
        elif (
            sgn(last_d) != sgn(penultimate_d)
            and (abs(last_res) > abs(3 * last_d))
        ):
            last_res = 3 * last_d
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
    def piecewiseCubicDerivative(
        delta_k: float,
        delta_k_minus_1: float,
        hk: float,
        hk_minus_1: float,
    ) -> float:
        if (
            (delta_k == 0)
            or (delta_k_minus_1 == 0)
            or (delta_k > 0 and delta_k_minus_1 < 0)
            or (delta_k < 0 and delta_k_minus_1 > 0)
        ):
            return 0.0
        if hk == hk_minus_1:
            res = 0.5 * (1.0 / delta_k_minus_1 + 1.0 / delta_k)
            res = 1.0 / res
        else:
            w1 = 2 * hk + hk_minus_1
            w2 = hk + 2 * hk_minus_1
            res = (w1 / delta_k_minus_1) + (w2 / delta_k)
            res = (w1 + w2) / res
        return res

    def interpolate(
        self,
        h: float,
        s: float,
        y_k: float,
        y_k_plus_one: float,
        d_k: float,
        d_k_plus_one: float,
    ) -> float:
        return (
            ((3 * h * s**2 - 2 * s**3) / h**3) * y_k_plus_one
            + ((h**3 - 3 * h * s**2 + 2 * s**3) / h**3) * y_k
            + ((s**2 * (s - h)) / h**2) * d_k_plus_one
            + ((s * (s - h)**2) / h**2) * d_k
        )


def sgn(x: float) -> float:
    if x < 0:
        return -1.0
    elif x > 0:
        return 1.0
    else:
        return 0.0
