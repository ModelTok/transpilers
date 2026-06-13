from WCECommon import CSeries, CCommonWavelengths, Combine, Property, Side, EnumProperty, EnumSide
from WCESpectralAveraging import CSpectralSampleData
from EquivalentLayerSingleComponentMW import CEquivalentLayerSingleComponentMW
from AbsorptancesMultiPane import CAbsorptancesMultiPane
from memory import Pointer
from utils import Vector
from functional import next

@value
class CMultiPaneSampleData(CSpectralSampleData):
    var m_MeasuredSamples: Vector[Pointer[CSpectralSampleData]]
    var m_LayerAbsorptances: Vector[CSeries]

    def __init__(inout self):
        CSpectralSampleData.__init__(self)
        self.m_MeasuredSamples = Vector[Pointer[CSpectralSampleData]]()
        self.m_LayerAbsorptances = Vector[CSeries]()

    def getWavelengths(self) -> Vector[float64]:
        var aWavelengths = CCommonWavelengths()
        for it in range(len(self.m_MeasuredSamples)):
            aWavelengths.addWavelength(self.m_MeasuredSamples[it][].getWavelengths())
        return aWavelengths.getCombinedWavelengths(Combine.Interpolate)

    def numberOfLayers(self) -> size:
        return len(self.m_MeasuredSamples)

    def addSample(inout self, t_Sample: Pointer[CSpectralSampleData]):
        self.m_MeasuredSamples.push_back(t_Sample)

    def calculateProperties(inout self):
        if not self.m_absCalculated:
            self.calculateEquivalentProperties()
            self.m_absCalculated = True

    def getLayerAbsorptances(inout self, Index: size) -> CSeries:
        self.calculateProperties()
        if (Index - 1) > len(self.m_LayerAbsorptances):
            raise Error("Index out of range. ")
        return self.m_LayerAbsorptances[Index - 1]

    def interpolate(inout self, t_Wavelengths: Vector[float64]):
        for it in range(len(self.m_MeasuredSamples)):
            self.m_MeasuredSamples[it][].interpolate(t_Wavelengths)
        CSpectralSampleData.interpolate(self, t_Wavelengths)

    def calculateEquivalentProperties(inout self):
        var wavelengths = self.getWavelengths()
        self.interpolate(wavelengths)
        assert_true(len(self.m_MeasuredSamples) != 0)
        var Tf = self.m_MeasuredSamples[0][].properties(Property.T, Side.Front)
        var Tb = self.m_MeasuredSamples[0][].properties(Property.T, Side.Back)
        var Rf = self.m_MeasuredSamples[0][].properties(Property.R, Side.Front)
        var Rb = self.m_MeasuredSamples[0][].properties(Property.R, Side.Back)
        var aEqivalentLayer = CEquivalentLayerSingleComponentMW(Tf, Tb, Rf, Rb)
        var aAbsorptances = CAbsorptancesMultiPane(Tf, Rf, Rb)
        for it in range(next(self.m_MeasuredSamples.begin()), len(self.m_MeasuredSamples)):
            aEqivalentLayer.addLayer(
                self.m_MeasuredSamples[it][].properties(Property.T, Side.Front),
                self.m_MeasuredSamples[it][].properties(Property.T, Side.Back),
                self.m_MeasuredSamples[it][].properties(Property.R, Side.Front),
                self.m_MeasuredSamples[it][].properties(Property.R, Side.Back)
            )
            aAbsorptances.addLayer(
                self.m_MeasuredSamples[it][].properties(Property.T, Side.Front),
                self.m_MeasuredSamples[it][].properties(Property.R, Side.Front),
                self.m_MeasuredSamples[it][].properties(Property.R, Side.Back)
            )
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = aEqivalentLayer.getProperties(prop, side)
        self.m_LayerAbsorptances.clear()
        var size = aAbsorptances.numOfLayers()
        for i in range(size):
            self.m_LayerAbsorptances.push_back(aAbsorptances.Abs(i))