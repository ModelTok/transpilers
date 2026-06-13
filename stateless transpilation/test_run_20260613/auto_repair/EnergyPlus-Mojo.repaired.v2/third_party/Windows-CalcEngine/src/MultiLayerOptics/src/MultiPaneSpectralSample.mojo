from memory import shared_ptr, make_shared
from vector import DynamicVector
from WCESpectralAveraging import CSpectralSample, CSpectralSampleData, Property, Side, WavelengthSet
from WCECommon import CSeries
from MultiPaneSampleData import CMultiPaneSampleData

@value
class CMultiPaneSpectralSample(CSpectralSample):
    var m_AbsorbedLayersSource: DynamicVector[CSeries]

    def __init__(self, t_SampleData: shared_ptr[CSpectralSampleData], t_SourceData: CSeries):
        CSpectralSample.__init__(self, t_SampleData, t_SourceData)
        self.m_AbsorbedLayersSource = DynamicVector[CSeries]()

    def getLayerAbsorbedEnergy(self, minLambda: Float64, maxLambda: Float64, Index: size_t) -> Float64:
        var aEnergy: Float64 = 0
        self.calculateState()
        if Index > self.m_AbsorbedLayersSource.size:
            raise Error("Index for glazing layer absorptance is out of range.")
        aEnergy = self.m_AbsorbedLayersSource[Index - 1].sum(minLambda, maxLambda)
        return aEnergy

    def getLayerAbsorptance(self, minLambda: Float64, maxLambda: Float64, Index: size_t) -> Float64:
        self.calculateState()
        var absorbedEnergy: Float64 = self.getLayerAbsorbedEnergy(minLambda, maxLambda, Index)
        var incomingEnergy: Float64 = self.m_IncomingSource.sum(minLambda, maxLambda)
        return absorbedEnergy / incomingEnergy

    def calculateProperties(self):
        if not self.m_StateCalculated:
            CSpectralSample.calculateProperties(self)
            if (dynamic_pointer_cast[CMultiPaneSampleData](self.m_SampleData)) is not None:
                var aSample: shared_ptr[CMultiPaneSampleData] = dynamic_pointer_cast[CMultiPaneSampleData](self.m_SampleData)
                var numOfLayers: size_t = aSample.numberOfLayers()
                for i in range(numOfLayers):
                    var layerAbsorbed = aSample.getLayerAbsorptances(i + 1)
                    self.integrateAndAppendAbsorptances(layerAbsorbed)
            else:
                var layerAbsorbed = self.m_SampleData.properties(Property.Abs, Side.Front)
                self.integrateAndAppendAbsorptances(layerAbsorbed)
            self.m_StateCalculated = True

    def integrateAndAppendAbsorptances(self, t_Absorptances: CSeries):
        var aAbs: CSeries = t_Absorptances
        if self.m_WavelengthSet != WavelengthSet.Data:
            aAbs = aAbs.interpolate(self.m_Wavelengths)
        aAbs = aAbs * self.m_IncomingSource
        aAbs = aAbs.integrate(self.m_IntegrationType, self.m_NormalizationCoefficient)
        self.m_AbsorbedLayersSource.push_back(aAbs)

    def reset(self):
        CSpectralSample.reset(self)
        self.m_AbsorbedLayersSource.clear()