from memory import Pointer
from math import abs
from WCECommon import CSeries, Side, Property, PropertySimple, Scattering, ScatteringSimple, IntegrationType, CCommonWavelengths, Combine, CHemispherical2DIntegrator, checkRange
from WCESingleLayerOptics import IScatteringLayer, SpecularLayer, CBeamDirection
from EquivalentLayerSingleComponentMW import CEquivalentLayerSingleComponentMW
from AbsorptancesMultiPane import CAbsorptancesMultiPane

module MultiLayerOptics:

    struct CEquivalentLayerSingleComponentMWAngle:
        var m_Layer: CEquivalentLayerSingleComponentMW
        var m_Abs: CAbsorptancesMultiPane
        var m_Angle: Float64

        def __init__(inout self, t_Layer: CEquivalentLayerSingleComponentMW, t_Abs: CAbsorptancesMultiPane, t_Angle: Float64):
            self.m_Layer = t_Layer
            self.m_Abs = t_Abs
            self.m_Angle = t_Angle

        def angle(self) -> Float64:
            return self.m_Angle

        def layer(self) -> CEquivalentLayerSingleComponentMW:
            return self.m_Layer

        def getProperties(self, t_Side: Side, t_Property: Property) -> CSeries:
            return self.m_Layer.getProperties(t_Property, t_Side)

        def Abs(self, Index: size_t) -> CSeries:
            return self.m_Abs.Abs(Index)

        def iplus(self, Index: size_t) -> CSeries:
            return self.m_Abs.iplus(Index)

        def iminus(self, Index: size_t) -> CSeries:
            return self.m_Abs.iminus(Index)

    struct CMultiPaneSpecular(IScatteringLayer):
        struct SeriesResults:
            var T: CSeries
            var Rf: CSeries
            var Rb: CSeries

        var m_Layers: List[Pointer[SpecularLayer]]
        var m_CommonWavelengths: List[Float64]
        var m_SolarRadiation: CSeries
        var m_DetectorData: CSeries
        var m_EquivalentAngle: List[CEquivalentLayerSingleComponentMWAngle]

        def __init__(inout self, layers: List[Pointer[SpecularLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries = CSeries()):
            self.m_Layers = layers
            self.m_SolarRadiation = t_SolarRadiation
            self.m_DetectorData = t_DetectorData
            var aCommonWL = CCommonWavelengths()
            for layer in layers:
                aCommonWL.addWavelength(layer[].getBandWavelengths())
            self.m_CommonWavelengths = aCommonWL.getCombinedWavelengths(Combine.Interpolate)
            self.m_SolarRadiation = self.m_SolarRadiation.interpolate(self.m_CommonWavelengths)
            if self.m_DetectorData.size() > 0:
                self.m_DetectorData.interpolate(self.m_CommonWavelengths)
            for layer in layers:
                layer[].setSourceData(self.m_SolarRadiation)

        def __init__(inout self, t_CommonWavelength: List[Float64], t_SolarRadiation: CSeries, t_Layer: Pointer[SpecularLayer]):
            self.m_CommonWavelengths = t_CommonWavelength
            self.m_SolarRadiation = t_SolarRadiation
            self.m_SolarRadiation = self.m_SolarRadiation.interpolate(self.m_CommonWavelengths)
            self.addLayer(t_Layer)

        def addLayer(inout self, t_Layer: Pointer[SpecularLayer]):
            t_Layer[].setSourceData(self.m_SolarRadiation)
            self.m_Layers.push_back(t_Layer)

        @staticmethod
        def create(layers: List[Pointer[SpecularLayer]], t_SolarRadiation: CSeries, t_DetectorData: CSeries = CSeries()) -> Pointer[CMultiPaneSpecular]:
            return Pointer[CMultiPaneSpecular](CMultiPaneSpecular(layers, t_SolarRadiation, t_DetectorData))

        def getPropertySimple(self, t_Property: PropertySimple, t_Side: Side, t_Scattering: Scattering, t_Theta: Float64 = 0, t_Phi: Float64 = 0) -> Float64:
            return self.getPropertySimple(self.getMinLambda(), self.getMaxLambda(), t_Property, t_Side, t_Scattering, t_Theta)

        def getPropertySimple(self, minLambda: Float64, maxLambda: Float64, t_Property: PropertySimple, t_Side: Side, t_Scattering: Scattering, t_Theta: Float64 = 0, t_Phi: Float64 = 0) -> Float64 override:
            var result: Float64 = 0
            var prop = toProperty(t_Property)
            if t_Scattering == Scattering.DirectDirect:
                result = self.getProperty(t_Side, prop, t_Theta, minLambda, maxLambda)
            elif t_Scattering == Scattering.DiffuseDiffuse:
                result = self.getHemisphericalProperty(t_Side, prop, [0, 10, 20, 30, 40, 50, 60, 70, 80, 90], minLambda, maxLambda)
            elif t_Scattering == Scattering.DirectDiffuse:
                result = 0
            elif t_Scattering == Scattering.DirectHemispherical:
                result = self.getProperty(t_Side, prop, t_Theta, minLambda, maxLambda)
            return result

        def getMinLambda(self) -> Float64 override:
            return self.m_Layers[0][].getMinLambda()

        def getMaxLambda(self) -> Float64 override:
            return self.m_Layers[0][].getMaxLambda()

        def getWavelengths(self) -> List[Float64] override:
            return self.m_CommonWavelengths

        def getProperty(self, t_Side: Side, t_Property: Property, t_Angle: Float64, minLambda: Float64, maxLambda: Float64, t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal, normalizationCoefficient: Float64 = 1) -> Float64:
            var aAngularProperties = self.getAngular(t_Angle)
            var aProperties = aAngularProperties.getProperties(t_Side, t_Property)
            var solarRadiation = self.m_SolarRadiation
            if self.m_DetectorData.size() > 0:
                if self.m_DetectorData.size() != solarRadiation.size():
                    self.m_DetectorData = self.m_DetectorData.interpolate(solarRadiation.getXArray())
                solarRadiation = solarRadiation * self.m_DetectorData
            var aMult = aProperties * solarRadiation
            var iIntegrated = aMult.integrate(t_IntegrationType, normalizationCoefficient)
            var totalProperty = iIntegrated[].sum(minLambda, maxLambda)
            var totalSolar = solarRadiation.integrate(t_IntegrationType, normalizationCoefficient)[].sum(minLambda, maxLambda)
            assert(totalSolar > 0)
            return totalProperty / totalSolar

        def getHemisphericalProperty(self, t_Side: Side, t_Property: Property, t_IntegrationAngles: List[Float64], minLambda: Float64, maxLambda: Float64, t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal, normalizationCoefficient: Float64 = 1) -> Float64:
            var size = t_IntegrationAngles.size()
            var aAngularProperties = Pointer[CSeries](CSeries())
            for i in range(size):
                var angle = t_IntegrationAngles[i]
                var aProperty = self.getProperty(t_Side, t_Property, angle, minLambda, maxLambda, t_IntegrationType, normalizationCoefficient)
                aAngularProperties[].addProperty(angle, aProperty)
            var aIntegrator = CHemispherical2DIntegrator(aAngularProperties[], t_IntegrationType, normalizationCoefficient)
            return aIntegrator.value()

        def getAbsorptanceLayer(self, index: size_t, side: Side, scattering: ScatteringSimple, theta: Float64 = 0, phi: Float64 = 0) -> Float64:
            return self.getAbsorptanceLayer(self.getMinLambda(), self.getMaxLambda(), index, side, scattering, theta)

        def getAbsorptanceLayer(self, minLambda: Float64, maxLambda: Float64, index: size_t, side: Side, scattering: ScatteringSimple, theta: Float64 = 0, phi: Float64 = 0) -> Float64:
            var result: Float64 = 0
            if scattering == ScatteringSimple.Direct:
                result = self.Abs(index, theta, minLambda, maxLambda)
            elif scattering == ScatteringSimple.Diffuse:
                result = self.AbsHemispherical(index, [0, 10, 20, 30, 40, 50, 60, 70, 80, 90], minLambda, maxLambda)
            return result

        def getAbsorptanceLayers(self, minLambda: Float64, maxLambda: Float64, side: Side, scattering: ScatteringSimple, theta: Float64 = 0, phi: Float64 = 0) -> List[Float64] override:
            var res = List[Float64]()
            for i in range(1, self.size() + 1):
                res.push_back(self.getAbsorptanceLayer(minLambda, maxLambda, i, side, scattering, theta, phi))
            return res

        def Abs(self, Index: size_t, t_Angle: Float64, minLambda: Float64, maxLambda: Float64, t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal, normalizationCoefficient: Float64 = 1) -> Float64:
            var aAngularProperties = self.getAngular(t_Angle)
            var aProperties = aAngularProperties.Abs(Index - 1)
            var aMult = aProperties * self.m_SolarRadiation
            var iIntegrated = aMult.integrate(t_IntegrationType, normalizationCoefficient)
            var totalProperty = iIntegrated[].sum(minLambda, maxLambda)
            var totalSolar = self.m_SolarRadiation.integrate(t_IntegrationType, normalizationCoefficient)[].sum(minLambda, maxLambda)
            assert(totalSolar > 0)
            return totalProperty / totalSolar

        def Absorptances(self, t_Angle: Float64, minLambda: Float64, maxLambda: Float64, t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal, normalizationCoefficient: Float64 = 1) -> List[Float64]:
            var res = List[Float64]()
            for i in range(1, self.size() + 1):
                res.push_back(self.Abs(i, t_Angle, minLambda, maxLambda, t_IntegrationType, normalizationCoefficient))
            return res

        def AbsHemispherical(self, Index: size_t, t_IntegrationAngles: List[Float64], minLambda: Float64, maxLambda: Float64, t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal, normalizationCoefficient: Float64 = 1) -> Float64:
            var size = t_IntegrationAngles.size()
            var aAngularProperties = Pointer[CSeries](CSeries())
            for i in range(size):
                var angle = t_IntegrationAngles[i]
                var aAbs = self.Abs(Index, angle, minLambda, maxLambda, t_IntegrationType)
                aAngularProperties[].addProperty(angle, aAbs)
            var aIntegrator = CHemispherical2DIntegrator(aAngularProperties[], t_IntegrationType, normalizationCoefficient)
            return aIntegrator.value()

        def getAngular(self, t_Angle: Float64) -> CEquivalentLayerSingleComponentMWAngle:
            var it: Int = -1
            for i in range(self.m_EquivalentAngle.size()):
                if abs(self.m_EquivalentAngle[i].angle() - t_Angle) < 1e-6:
                    it = i
                    break
            if it != -1:
                return self.m_EquivalentAngle[it]
            else:
                return self.createNewAngular(t_Angle)

        def createNewAngular(self, t_Angle: Float64) -> CEquivalentLayerSingleComponentMWAngle:
            var aDirection = CBeamDirection(t_Angle, 0)
            var firstLayerResults = self.getSeriesResults(aDirection, 0)
            var aEqLayer = CEquivalentLayerSingleComponentMW(firstLayerResults.T, firstLayerResults.T, firstLayerResults.Rf, firstLayerResults.Rb)
            var aAbs = CAbsorptancesMultiPane(firstLayerResults.T, firstLayerResults.Rf, firstLayerResults.Rb)
            for i in range(1, self.m_Layers.size()):
                var layRes = self.getSeriesResults(aDirection, i)
                aEqLayer.addLayer(layRes.T, layRes.T, layRes.Rf, layRes.Rb)
                aAbs.addLayer(layRes.T, layRes.Rf, layRes.Rb)
            var newLayer = CEquivalentLayerSingleComponentMWAngle(aEqLayer, aAbs, t_Angle)
            self.m_EquivalentAngle.push_back(newLayer)
            return newLayer

        def getSeriesResults(self, aDirection: CBeamDirection, layerIndex: size_t) -> SeriesResults:
            var result = SeriesResults()
            var wl = self.m_Layers[layerIndex][].getBandWavelengths()
            var Tv = self.m_Layers[layerIndex][].T_dir_dir_band(Side.Front, aDirection)
            var Rfv = self.m_Layers[layerIndex][].R_dir_dir_band(Side.Front, aDirection)
            var Rbv = self.m_Layers[layerIndex][].R_dir_dir_band(Side.Back, aDirection)
            for j in range(wl.size()):
                var tr = checkRange(Tv[j], Rfv[j])
                Tv[j] = tr.T
                Rfv[j] = tr.R
                tr = checkRange(Tv[j], Rbv[j])
                Tv[j] = tr.T
                Rbv[j] = tr.R
                result.T.addProperty(wl[j], Tv[j])
                result.Rf.addProperty(wl[j], Rfv[j])
                result.Rb.addProperty(wl[j], Rbv[j])
            result.T = result.T.interpolate(self.m_CommonWavelengths)
            result.Rf = result.Rf.interpolate(self.m_CommonWavelengths)
            result.Rb = result.Rb.interpolate(self.m_CommonWavelengths)
            return result

        def size(self) -> size_t:
            return self.m_Layers.size()