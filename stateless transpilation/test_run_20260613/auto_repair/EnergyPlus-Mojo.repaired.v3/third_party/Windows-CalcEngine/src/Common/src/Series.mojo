from wceunique import wce
from Series import ISeriesPoint, CSeriesPoint, CSeries, IntegrationType
from IntegratorStrategy import CIntegratorFactory, IIntegratorStrategy
from memory import Pointer
from math import abs
from utils import Vector
from utils.sort import sort

# CSeriesPoint implementation
def CSeriesPoint.__init__(self):
    self.m_x = 0.0
    self.m_Value = 0.0

def CSeriesPoint.__init__(self, t_SeriesPoint: CSeriesPoint):
    self = t_SeriesPoint

def CSeriesPoint.__init__(self, t_Wavelength: Float64, t_Value: Float64):
    self.m_x = t_Wavelength
    self.m_Value = t_Value

def CSeriesPoint.clone(self) -> Pointer[ISeriesPoint]:
    return wce.make_unique[CSeriesPoint](self)

def CSeriesPoint.x(self) -> Float64:
    return self.m_x

def CSeriesPoint.value(self) -> Float64:
    return self.m_Value

def CSeriesPoint.value(self, t_Value: Float64):
    self.m_Value = t_Value

def CSeriesPoint.__copyinit__(self, other: CSeriesPoint):
    self.m_x = other.m_x
    self.m_Value = other.m_Value

def CSeriesPoint.__lt__(self, t_Point: CSeriesPoint) -> Bool:
    return self.m_x < t_Point.m_x

# CSeries implementation
def CSeries.__init__(self):
    self.m_Series = Vector[Pointer[ISeriesPoint]]()

def CSeries.__init__(self, t_values: Vector[Tuple[Float64, Float64]]):
    self.m_Series.clear()
    for val in t_values:
        self.m_Series.push_back(wce.make_unique[CSeriesPoint](val[0], val[1]))

def CSeries.__init__(self, t_values: List[Tuple[Float64, Float64]]):
    self.m_Series.clear()
    for val in t_values:
        self.m_Series.push_back(wce.make_unique[CSeriesPoint](val[0], val[1]))

def CSeries.__init__(self, t_Series: CSeries):
    self.m_Series.clear()
    for val in t_Series.m_Series:
        self.m_Series.push_back(val[].clone())

def CSeries.addProperty(self, t_x: Float64, t_Value: Float64):
    self.m_Series.push_back(wce.make_unique[CSeriesPoint](t_x, t_Value))

def CSeries.insertToBeginning(self, t_x: Float64, t_Value: Float64):
    self.m_Series.insert(self.m_Series.begin(), wce.make_unique[CSeriesPoint](t_x, t_Value))

def CSeries.setConstantValues(self, t_Wavelengths: Vector[Float64], t_Value: Float64):
    self.m_Series.clear()
    for it in range(len(t_Wavelengths)):
        self.addProperty(t_Wavelengths[it], t_Value)

def CSeries.integrate(self, t_IntegrationType: IntegrationType, normalizationCoefficient: Float64 = 1.0) -> Pointer[CSeries]:
    aFactory = CIntegratorFactory()
    aIntegrator = aFactory.getIntegrator(t_IntegrationType)
    return aIntegrator.integrate(self.m_Series, normalizationCoefficient)

def CSeries.findLower(self, t_Wavelength: Float64) -> Pointer[ISeriesPoint]:
    currentProperty = Pointer[ISeriesPoint]()
    for spectralProperty in self.m_Series:
        aWavelength = spectralProperty[].x()
        if aWavelength > t_Wavelength:
            break
        currentProperty = spectralProperty
    return currentProperty

def CSeries.findUpper(self, t_Wavelength: Float64) -> Pointer[ISeriesPoint]:
    currentProperty = Pointer[ISeriesPoint]()
    for spectralProperty in self.m_Series:
        aWavelength = spectralProperty[].x()
        if aWavelength > t_Wavelength:
            currentProperty = spectralProperty
            break
    return currentProperty

def CSeries.interpolate(t_Lower: Pointer[ISeriesPoint], t_Upper: Pointer[ISeriesPoint], t_Wavelength: Float64) -> Float64:
    w1 = t_Lower[].x()
    w2 = t_Upper[].x()
    v1 = t_Lower[].value()
    v2 = t_Upper[].value()
    vx = 0.0
    if w2 != w1:
        vx = v1 + (t_Wavelength - w1) * (v2 - v1) / (w2 - w1)
    else:
        vx = v1   # extrapolating same value for all values out of range
    return vx

def CSeries.interpolate(self, t_Wavelengths: Vector[Float64]) -> CSeries:
    newProperties = CSeries()
    if self.size() != 0:
        lower = Pointer[ISeriesPoint]()
        upper = Pointer[ISeriesPoint]()
        for wavelength in t_Wavelengths:
            lower = self.findLower(wavelength)
            upper = self.findUpper(wavelength)
            if lower.is_null():
                lower = upper
            if upper.is_null():
                upper = lower
            newProperties.addProperty(wavelength, CSeries.interpolate(lower, upper, wavelength))
    return newProperties

def CSeries.__mul__(self, other: CSeries) -> CSeries:
    newProperty = CSeries()
    const WAVELENGTHTOLERANCE = 1e-10
    minSize = min(len(self.m_Series), len(other.m_Series))
    for i in range(minSize):
        value = self.m_Series[i][].value() * other.m_Series[i][].value()
        wv = self.m_Series[i][].x()
        testWv = other.m_Series[i][].x()
        if abs(wv - testWv) > WAVELENGTHTOLERANCE:
            raise Error("Wavelengths of two vectors are not the same. Cannot preform multiplication.")
        newProperty.addProperty(wv, value)
    return newProperty

def CSeries.__sub__(self, t_Series: CSeries) -> CSeries:
    const WAVELENGTHTOLERANCE = 1e-10
    newProperties = CSeries()
    minSize = min(len(self.m_Series), len(t_Series.m_Series))
    for i in range(minSize):
        value = self.m_Series[i][].value() - t_Series.m_Series[i][].value()
        wv = self.m_Series[i][].x()
        testWv = t_Series.m_Series[i][].x()
        if abs(wv - testWv) > WAVELENGTHTOLERANCE:
            raise Error("Wavelengths of two vectors are not the same. Cannot preform subtraction.")
        newProperties.addProperty(wv, value)
    return newProperties

def __sub__(val: Float64, other: CSeries) -> CSeries:
    newProperties = CSeries()
    for ot in other:
        value = val - ot[].value()
        wv = ot[].x()
        newProperties.addProperty(wv, value)
    return newProperties

def CSeries.__add__(self, other: CSeries) -> CSeries:
    const WAVELENGTHTOLERANCE = 1e-10
    newProperties = CSeries()
    minSize = min(len(self.m_Series), len(other.m_Series))
    for i in range(minSize):
        value = self.m_Series[i][].value() + other.m_Series[i][].value()
        wv = self.m_Series[i][].x()
        testWv = other.m_Series[i][].x()
        if abs(wv - testWv) > WAVELENGTHTOLERANCE:
            raise Error("Wavelengths of two vectors are not the same. Cannot preform addition.")
        newProperties.addProperty(wv, value)
    return newProperties

def CSeries.getXArray(self) -> Vector[Float64]:
    aArray = Vector[Float64]()
    for spectralProperty in self.m_Series:
        aArray.push_back(spectralProperty[].x())
    return aArray

def CSeries.sum(self, minLambda: Float64 = 0.0, maxLambda: Float64 = 0.0) -> Float64:
    const TOLERANCE = 1e-6   # introduced because of rounding error
    total = 0.0
    for aPoint in self.m_Series:
        wavelength = aPoint[].x()
        if ((wavelength >= (minLambda - TOLERANCE) and wavelength < (maxLambda - TOLERANCE))
            or (minLambda == 0.0 and maxLambda == 0.0)):
            total += aPoint[].value()
    return total

def CSeries.sort(self):
    sort(self.m_Series, lambda l, r: l[].x() < r[].x())

def CSeries.begin(self) -> Pointer[Pointer[ISeriesPoint]]:
    return self.m_Series.cbegin()

def CSeries.end(self) -> Pointer[Pointer[ISeriesPoint]]:
    return self.m_Series.cend()

def CSeries.size(self) -> Int:
    return len(self.m_Series)

def CSeries.__copyinit__(self, t_Series: CSeries):
    self.m_Series.clear()
    for val in t_Series.m_Series:
        self.m_Series.push_back(val[].clone())

def CSeries.__getitem__(self, Index: Int) -> ISeriesPoint:
    if Index >= len(self.m_Series):
        raise Error("Index out of range.")
    return self.m_Series[Index][]

def CSeries.clear(self):
    self.m_Series.clear()

def CSeries.cutExtraData(self, minWavelength: Float64, maxWavelength: Float64):
    result = Vector[Pointer[ISeriesPoint]]()
    const eps = 1e-8
    for val in self.m_Series:
        if val[].x() > (minWavelength - eps) and val[].x() < (maxWavelength + eps):
            result.push_back(val[].clone())
    self.m_Series.clear()
    for val in result:
        self.m_Series.push_back(val[].clone())