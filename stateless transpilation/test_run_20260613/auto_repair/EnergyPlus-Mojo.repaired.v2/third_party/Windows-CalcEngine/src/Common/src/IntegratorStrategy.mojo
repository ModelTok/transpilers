from IntegratorStrategy import IntegrationType, IIntegratorStrategy, CIntegratorRectangular, CIntegratorRectangularCentroid, CIntegratorTrapezoidal, CIntegratorTrapezoidalA, CIntegratorTrapezoidalB, CIntegratorPreWeighted, CIntegratorFactory
from Series import ISeriesPoint, CSeries
from wceunique import make_unique
from memory import Pointer
from vector import Vector

@value
struct IIntegratorStrategy:

def dX(self: IIntegratorStrategy, x1: Float64, x2: Float64) -> Float64:
    return x2 - x1

@value
struct CIntegratorRectangular(IIntegratorStrategy):

def integrate(self: CIntegratorRectangular, t_Series: Pointer[Vector[Pointer[ISeriesPoint]]], normalizationCoeff: Float64 = 1.0) -> Pointer[CSeries]:
    var newProperties = make_unique[CSeries]()
    var i: UInt = 1
    while i < t_Series[].size():
        var w1 = t_Series[][i - 1][].x()
        var w2 = t_Series[][i][].x()
        var y1 = t_Series[][i - 1][].value()
        var deltaX = dX(self, w1, w2)
        var value = y1 * deltaX
        newProperties[].addProperty(w1, value / normalizationCoeff)
        i += 1
    return newProperties

@value
struct CIntegratorRectangularCentroid(IIntegratorStrategy):

def integrate(self: CIntegratorRectangularCentroid, t_Series: Pointer[Vector[Pointer[ISeriesPoint]]], normalizationCoeff: Float64 = 1.0) -> Pointer[CSeries]:
    var newProperties = make_unique[CSeries]()
    var i: UInt = 1
    while i < t_Series[].size():
        var w1 = t_Series[][i - 1][].x()
        var w2 = t_Series[][i][].x()
        var y1 = t_Series[][i - 1][].value()
        var diffX = (w2 - w1) / 2
        var deltaX = dX(self, w1 - diffX, w2 - diffX)
        var value = y1 * deltaX
        newProperties[].addProperty(w1, value / normalizationCoeff)
        i += 1
    return newProperties

@value
struct CIntegratorTrapezoidal(IIntegratorStrategy):

def integrate(self: CIntegratorTrapezoidal, t_Series: Pointer[Vector[Pointer[ISeriesPoint]]], normalizationCoeff: Float64 = 1.0) -> Pointer[CSeries]:
    var newProperties = make_unique[CSeries]()
    var i: UInt = 1
    while i < t_Series[].size():
        var w1 = t_Series[][i - 1][].x()
        var w2 = t_Series[][i][].x()
        var y1 = t_Series[][i - 1][].value()
        var y2 = t_Series[][i][].value()
        var deltaX = dX(self, w1, w2)
        var yCenter = (y1 + y2) / 2
        var value = yCenter * deltaX
        newProperties[].addProperty(w1, value / normalizationCoeff)
        i += 1
    return newProperties

@value
struct CIntegratorTrapezoidalA(IIntegratorStrategy):

def integrate(self: CIntegratorTrapezoidalA, t_Series: Pointer[Vector[Pointer[ISeriesPoint]]], normalizationCoeff: Float64 = 1.0) -> Pointer[CSeries]:
    var newProperties = make_unique[CSeries]()
    var i: UInt = 1
    while i < t_Series[].size():
        var w1 = t_Series[][i - 1][].x()
        var w2 = t_Series[][i][].x()
        var y1 = t_Series[][i - 1][].value()
        var y2 = t_Series[][i][].value()
        var deltaX = dX(self, w1, w2)
        var yCenter = (y1 + y2) / 2
        var value = yCenter * deltaX
        if i == 1:
            value += (y1 / 2) * deltaX
        if i == t_Series[].size() - 1:
            value += (y2 / 2) * deltaX
        newProperties[].addProperty(w1, value / normalizationCoeff)
        i += 1
    return newProperties

@value
struct CIntegratorTrapezoidalB(IIntegratorStrategy):

def integrate(self: CIntegratorTrapezoidalB, t_Series: Pointer[Vector[Pointer[ISeriesPoint]]], normalizationCoeff: Float64 = 1.0) -> Pointer[CSeries]:
    var newProperties = make_unique[CSeries]()
    var i: UInt = 1
    while i < t_Series[].size():
        var w1 = t_Series[][i - 1][].x()
        var w2 = t_Series[][i][].x()
        var y1 = t_Series[][i - 1][].value()
        var y2 = t_Series[][i][].value()
        var deltaX = dX(self, w1, w2)
        var yCenter = (y1 + y2) / 2
        var value = yCenter * deltaX
        if i == 1 or i == t_Series[].size() - 1:
            value += ((y1 + y2) / 4) * deltaX
        newProperties[].addProperty(w1, value / normalizationCoeff)
        i += 1
    return newProperties

@value
struct CIntegratorPreWeighted(IIntegratorStrategy):

def integrate(self: CIntegratorPreWeighted, t_Series: Pointer[Vector[Pointer[ISeriesPoint]]], normalizationCoeff: Float64 = 1.0) -> Pointer[CSeries]:
    var newProperties = make_unique[CSeries]()
    var i: UInt = 0
    while i < t_Series[].size():
        var y1 = t_Series[][i][].value()
        newProperties[].addProperty(1, y1 / normalizationCoeff)
        i += 1
    return newProperties

@value
struct CIntegratorFactory:

def getIntegrator(self: CIntegratorFactory, t_IntegratorType: IntegrationType) -> Pointer[IIntegratorStrategy]:
    var aStrategy: Pointer[IIntegratorStrategy] = Pointer[IIntegratorStrategy]()
    if t_IntegratorType == IntegrationType.Rectangular:
        aStrategy = make_unique[CIntegratorRectangular]()
    elif t_IntegratorType == IntegrationType.RectangularCentroid:
        aStrategy = make_unique[CIntegratorRectangularCentroid]()
    elif t_IntegratorType == IntegrationType.Trapezoidal:
        aStrategy = make_unique[CIntegratorTrapezoidal]()
    elif t_IntegratorType == IntegrationType.TrapezoidalA:
        aStrategy = make_unique[CIntegratorTrapezoidalA]()
    elif t_IntegratorType == IntegrationType.TrapezoidalB:
        aStrategy = make_unique[CIntegratorTrapezoidalB]()
    elif t_IntegratorType == IntegrationType.PreWeighted:
        aStrategy = make_unique[CIntegratorPreWeighted]()
    else:
        print("Irregular call of integration strategy.")
    return aStrategy