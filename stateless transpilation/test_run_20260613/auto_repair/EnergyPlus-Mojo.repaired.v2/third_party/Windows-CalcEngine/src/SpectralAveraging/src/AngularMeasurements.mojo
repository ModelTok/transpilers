from SpectralSample import CSpectralSample
from MeasuredSampleData import CSpectralSampleData
from WCECommon import CSeries, Property, Side, IntegrationType
from memory import Pointer
from math import abs
from utils import Vector
from range import range

@value
class CSingleAngularMeasurement:
    var m_Data: Pointer[CSpectralSample]
    var m_Angle: Float64

    def __init__(inout self, t_Data: Pointer[CSpectralSample], t_Angle: Float64):
        self.m_Data = t_Data
        self.m_Angle = t_Angle
        if t_Data.is_null():
            raise Error("Sample must have measured data in AngularMeasurement.")

    def getAngle(self) -> Float64:
        return self.m_Angle

    def getData(self) -> Pointer[CSpectralSample]:
        return self.m_Data

    def getWavelengthsFromSample(self) -> Vector[Float64]:
        return self.m_Data[].getWavelengthsFromSample()

    def Interpolate(self, t_Angle: Float64, t_Data1: Pointer[CSpectralSample], t_Angle1: Float64, t_Data2: Pointer[CSpectralSample], t_Angle2: Float64) -> Pointer[CSpectralSample]:
        var aData = Pointer[CSpectralSampleData].alloc(1)
        aData.init(CSpectralSampleData())
        var wlv = t_Data1[].getWavelengthsFromSample()
        var trans1 = t_Data1[].getMeasuredData()[].properties(Property.T, Side.Front)
        var trans2 = t_Data2[].getMeasuredData()[].properties(Property.T, Side.Front)
        var reflef1 = t_Data1[].getMeasuredData()[].properties(Property.R, Side.Front)
        var reflef2 = t_Data2[].getMeasuredData()[].properties(Property.R, Side.Front)
        var refleb1 = t_Data1[].getMeasuredData()[].properties(Property.R, Side.Back)
        var refleb2 = t_Data2[].getMeasuredData()[].properties(Property.R, Side.Back)
        var frac = (t_Angle - t_Angle1) / (t_Angle2 - t_Angle1)
        for i in range(wlv.size):
            var wl = wlv[i]
            var t1 = trans1[i].value()
            var t2 = trans2[i].value()
            var rf1 = reflef1[i].value()
            var rf2 = reflef2[i].value()
            var rb1 = refleb1[i].value()
            var rb2 = refleb2[i].value()
            var t = t1 + frac * (t2 - t1)
            var rf = rf1 + frac * (rf2 - rf1)
            var rb = rb1 + frac * (rb2 - rb1)
            aData[].addRecord(wl, t, rf, rb)
        var aSample = Pointer[CSpectralSample].alloc(1)
        aSample.init(CSpectralSample(aData, t_Data1[].getSourceData()))
        return aSample

    def interpolate(self, t_CommonWavelengths: Vector[Float64]):
        self.m_Data[].getMeasuredData()[].interpolate(t_CommonWavelengths)

@value
class CAngularMeasurements:
    var m_SingleMeasurement: Pointer[CSingleAngularMeasurement]
    var m_Measurements: Vector[Pointer[CSingleAngularMeasurement]]
    var m_CommonWavelengths: Vector[Float64]
    var m_Angle: Pointer[CSingleAngularMeasurement]

    def __init__(inout self, t_SignleMeasurement: Pointer[CSingleAngularMeasurement], t_CommonWavelengths: Vector[Float64]):
        self.m_SingleMeasurement = t_SignleMeasurement
        self.m_CommonWavelengths = t_CommonWavelengths
        if self.m_SingleMeasurement.is_null():
            raise Error("Sample must have measured data in AngularMeasurements.")
        t_SignleMeasurement[].interpolate(self.m_CommonWavelengths)
        self.m_Measurements.push_back(t_SignleMeasurement)

    def __init__(inout self, t_Measurements: Vector[Pointer[CSingleAngularMeasurement]]):
        self.m_Measurements = t_Measurements

    def addMeasurement(inout self, t_SingleMeasurement: Pointer[CSingleAngularMeasurement]):
        t_SingleMeasurement[].interpolate(self.m_CommonWavelengths)
        self.m_Measurements.push_back(t_SingleMeasurement)

    def getMeasurements(inout self, t_Angle: Float64) -> Pointer[CSingleAngularMeasurement]:
        var angleTolerance = 1e-6
        if self.m_Measurements.size == 1:
            raise Error("A single set is found. Spectral and angular sample must have 2 sets at least.")
        for i in range(self.m_Measurements.size):
            if abs(self.m_Measurements[i][].getAngle() - t_Angle) < angleTolerance:
                return self.m_Measurements[i]
        var min1 = Float64.MAX
        var min2 = Float64.MAX
        var angle1 = 0.0
        var angle2 = 0.0
        var sample1: Pointer[CSpectralSample] = Pointer[CSpectralSample]()
        var sample2: Pointer[CSpectralSample] = Pointer[CSpectralSample]()
        for i in range(self.m_Measurements.size):
            var angle = self.m_Measurements[i][].getAngle()
            var diff = abs(angle - t_Angle)
            if diff < min1:
                sample1 = self.m_Measurements[i][].getData()
                angle1 = angle
                min1 = diff
            elif diff < min2:
                sample2 = self.m_Measurements[i][].getData()
                angle2 = angle
                min2 = diff
        var sample3: Pointer[SpectralAveraging.CSpectraSample] = Pointer[SpectralAveraging.CSpectraSample]()
        sample3 = self.m_SingleMeasurement[].Interpolate(t_Angle, sample1, angle1, sample2, angle2)
        var aAngular = Pointer[CSingleAngularMeasurement].alloc(1)
        aAngular.init(CSingleAngularMeasurement(sample3, t_Angle))
        self.m_Measurements.push_back(aAngular)
        return aAngular

    def setSourceData(inout self, t_SourceData: CSeries):
        for i in range(self.m_Measurements.size):
            var aAngular = self.m_Measurements[i]
            var aSample = aAngular[].getData()
            aSample[].setSourceData(t_SourceData)