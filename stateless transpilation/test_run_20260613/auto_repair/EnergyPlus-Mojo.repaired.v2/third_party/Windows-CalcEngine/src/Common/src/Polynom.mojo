// Translated from C++ to Mojo
// Source: third_party/Windows-CalcEngine/src/Common/src/Polynom.cpp
// Header: third_party/Windows-CalcEngine/src/Common/src/Polynom.hpp

from List import List
from Math import abs

struct Polynom:
    var m_Coeffs: List[Float64]

    def __init__(self, t_Coeffs: List[Float64]):
        self.m_Coeffs = t_Coeffs

    def valueAt(self, t_X: Float64) -> Float64:
        var result: Float64 = 0
        var curX: Float64 = 1
        for val in self.m_Coeffs:
            result += val * curX
            curX *= t_X
        return result

struct PolynomPoint:
    var m_Polynom: Polynom
    var m_Value: Float64

    def __init__(self, t_Value: Float64, t_Poly: Polynom):
        self.m_Polynom = t_Poly
        self.m_Value = t_Value

    def value(self) -> Float64:
        return self.m_Value

    def valueAt(self, t_X: Float64) -> Float64:
        return self.m_Polynom.valueAt(t_X)

struct PolynomialPoints360deg:
    var isSorted: Bool
    var m_Polynoms: List[PolynomPoint]

    def __init__(self):
        self.isSorted = False
        self.m_Polynoms = List[PolynomPoint]()

    def storePoint(self, t_Value: Float64, t_Polynom: Polynom):
        self.m_Polynoms.append(PolynomPoint(t_Value, t_Polynom))
        self.isSorted = False

    def sortPolynomials(self):
        self.m_Polynoms.sort(key=lambda x: x.value())

    def valueAt(self, t_PointValue: Float64, t_Value: Float64) -> Float64:
        if not self.isSorted:
            self.sortPolynomials()
        # Find index of element with minimum absolute difference
        var minIdx: Int = 0
        var minDiff: Float64 = abs(self.m_Polynoms[0].value() - t_PointValue)
        for i in range(1, len(self.m_Polynoms)):
            var diff = abs(self.m_Polynoms[i].value() - t_PointValue)
            if diff < minDiff:
                minDiff = diff
                minIdx = i
        var valFirst = minIdx
        var valSecond = valFirst + 1
        if valSecond == len(self.m_Polynoms):
            valSecond = 0
        var swappedHigh = False
        if self.m_Polynoms[valFirst].value() > self.m_Polynoms[valSecond].value():
            swappedHigh = True
        var swappedLow = False
        if self.m_Polynoms[valFirst].value() > t_PointValue:
            valSecond = len(self.m_Polynoms) - 1
            # Swap indices
            var temp = valFirst
            valFirst = valSecond
            valSecond = temp
            swappedLow = True
        var y1 = self.m_Polynoms[valFirst].valueAt(t_Value)
        var x1 = self.m_Polynoms[valFirst].value()
        var y2 = self.m_Polynoms[valSecond].valueAt(t_Value)
        var x2 = self.m_Polynoms[valSecond].value()
        if swappedLow:
            x1 -= 360
        if swappedHigh:
            x2 += 360
        var value = y1 + (y2 - y1) / (x2 - x1) * (t_PointValue - x1)
        return value