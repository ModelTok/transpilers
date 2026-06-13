from memory import shared_ptr, make_shared
from vector import vector
from algorithm import find_if
from cassert import assert
from math import abs
from AngularSpectralSample import CAngularSpectralProperties, CSpectralSampleAngle, CAngularSpectralSample
from MeasuredSampleData import CSpectralSampleData
from SpectralSample import CSpectralSample
from AngularProperties import CAngularPropertiesFactory, coatingType
from WCECommon import ConstantsData, WavelengthSet, MaterialType, Side, Property, CSeries

@value
struct CAngularSpectralProperties:
    var m_Angle: Float64
    var m_Thickness: Float64
    var m_AngularData: shared_ptr[CSpectralSampleData]

    def __init__(inout self, t_SpectralSample: shared_ptr[CSpectralSample], t_Angle: Float64, t_Type: MaterialType, t_Thickness: Float64):
        self.m_Angle = t_Angle
        self.m_Thickness = t_Thickness
        self.m_AngularData = make_shared[CSpectralSampleData]()
        self.calculateAngularProperties(t_SpectralSample, t_Type)

    def angle(self) -> Float64:
        return self.m_Angle

    def properties(self) -> shared_ptr[CSpectralSampleData]:
        return self.m_AngularData

    def calculateAngularProperties(inout self, t_SpectralSample: shared_ptr[CSpectralSample], t_Type: MaterialType):
        assert(t_SpectralSample != None)
        var aMeasuredData = t_SpectralSample.getMeasuredData()
        var aWavelengths = t_SpectralSample.getWavelengths()
        if aWavelengths.size() == 0:
            aWavelengths = aMeasuredData.getWavelengths()
        if self.m_Angle != 0:
            var aSourceData = t_SpectralSample.getSourceData()
            var aT = aMeasuredData.properties(Property.T, Side.Front).interpolate(aWavelengths)
            assert(aT.size() == aWavelengths.size())
            var aRf = aMeasuredData.properties(Property.R, Side.Front).interpolate(aWavelengths)
            assert(aRf.size() == aWavelengths.size())
            var aRb = aMeasuredData.properties(Property.R, Side.Back).interpolate(aWavelengths)
            assert(aRb.size() == aWavelengths.size())
            var lowLambda = 0.3
            var highLambda = 2.5
            var aTSolNorm = t_SpectralSample.getProperty(lowLambda, highLambda, Property.T, Side.Front)
            for i in range(aWavelengths.size()):
                var ww = aWavelengths[i] * 1e-6
                var T = aT[i].value()
                var Rf = aRf[i].value()
                var Rb = aRb[i].value()
                var aSurfaceType = coatingType[t_Type]
                var aFrontFactory = CAngularPropertiesFactory(T, Rf, self.m_Thickness, aTSolNorm)
                var aBackFactory = CAngularPropertiesFactory(T, Rb, self.m_Thickness, aTSolNorm)
                var aFrontProperties = aFrontFactory.getAngularProperties(aSurfaceType)
                var aBackProperties = aBackFactory.getAngularProperties(aSurfaceType)
                var Tangle = aFrontProperties.transmittance(self.m_Angle, ww)
                var Rfangle = aFrontProperties.reflectance(self.m_Angle, ww)
                var Rbangle = aBackProperties.reflectance(self.m_Angle, ww)
                self.m_AngularData.addRecord(ww * 1e6, Tangle, Rfangle, Rbangle)
        else:
            self.m_AngularData = aMeasuredData
            self.m_AngularData.interpolate(aWavelengths)

@value
struct CSpectralSampleAngle:
    var m_Sample: shared_ptr[CSpectralSample]
    var m_Angle: Float64

    def __init__(inout self, t_Sample: shared_ptr[CSpectralSample], t_Angle: Float64):
        self.m_Sample = t_Sample
        self.m_Angle = t_Angle

    def angle(self) -> Float64:
        return self.m_Angle

    def sample(self) -> shared_ptr[CSpectralSample]:
        return self.m_Sample

@value
struct CAngularSpectralSample:
    var m_SpectralProperties: vector[shared_ptr[CSpectralSampleAngle]]
    var m_SpectralSampleZero: shared_ptr[CSpectralSample]
    var m_Thickness: Float64
    var m_Type: MaterialType

    def __init__(inout self, t_SpectralSample: shared_ptr[CSpectralSample], t_Thickness: Float64, t_Type: MaterialType):
        self.m_SpectralSampleZero = t_SpectralSample
        self.m_Thickness = t_Thickness
        self.m_Type = t_Type

    def setSourceData(inout self, t_SourceData: CSeries):
        self.m_SpectralSampleZero.setSourceData(t_SourceData)
        self.m_SpectralProperties.clear()

    def setDetectorData(inout self, t_DetectorData: CSeries):
        self.m_SpectralSampleZero.setDetectorData(t_DetectorData)
        self.m_SpectralProperties.clear()

    def getProperty(self, minLambda: Float64, maxLambda: Float64, t_Property: Property, t_Side: Side, t_Angle: Float64) -> Float64:
        var aSample = self.findSpectralSample(t_Angle)
        return aSample.getProperty(minLambda, maxLambda, t_Property, t_Side)

    def getWavelengthsProperty(self, minLambda: Float64, maxLambda: Float64, t_Property: Property, t_Side: Side, t_Angle: Float64) -> vector[Float64]:
        var aSample = self.findSpectralSample(t_Angle)
        var aProperties = aSample.getWavelengthsProperty(t_Property, t_Side)
        var aValues = vector[Float64]()
        for aProperty in aProperties:
            if aProperty.x() >= (minLambda - ConstantsData.floatErrorTolerance) and aProperty.x() <= (maxLambda + ConstantsData.floatErrorTolerance):
                aValues.push_back(aProperty.value())
        return aValues

    def getBandWavelengths(self) -> vector[Float64]:
        return self.m_SpectralSampleZero.getWavelengthsFromSample()

    def setBandWavelengths(inout self, wavelengths: vector[Float64]):
        self.m_SpectralSampleZero.setWavelengths(WavelengthSet.Custom, wavelengths)

    def Flipped(inout self, flipped: Bool):
        self.m_SpectralSampleZero.Flipped(flipped)
        for val in self.m_SpectralProperties:
            val.sample().Flipped(flipped)

    def findSpectralSample(inout self, t_Angle: Float64) -> shared_ptr[CSpectralSample]:
        var aSample: shared_ptr[CSpectralSample] = None
        var it = find_if(self.m_SpectralProperties.begin(), self.m_SpectralProperties.end(), fn(obj: shared_ptr[CSpectralSampleAngle]) -> Bool:
            return abs(obj.angle() - t_Angle) < 1e-6
        )
        if it != self.m_SpectralProperties.end():
            aSample = it[].sample()
        else:
            var aAngularData = CAngularSpectralProperties(self.m_SpectralSampleZero, t_Angle, self.m_Type, self.m_Thickness)
            aSample = make_shared[CSpectralSample](aAngularData.properties(), self.m_SpectralSampleZero.getSourceData(), self.m_SpectralSampleZero.getIntegrator(), self.m_SpectralSampleZero.getNormalizationCoeff())
            aSample.assignDetectorAndWavelengths(self.m_SpectralSampleZero)
            var aSpectralSampleAngle = make_shared[CSpectralSampleAngle](aSample, t_Angle)
            self.m_SpectralProperties.push_back(aSpectralSampleAngle)
        return aSample