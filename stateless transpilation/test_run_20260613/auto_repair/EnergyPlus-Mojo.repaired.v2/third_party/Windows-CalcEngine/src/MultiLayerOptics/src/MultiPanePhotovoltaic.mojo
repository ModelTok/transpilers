from std.memory import Arc
from ......FenestrationCommon.src.FenestrationCommon import CSeries, IntegrationType, Side
from ......SingleLayerOptics.src.SingleLayerOptics import SpecularLayer, PhotovoltaicLayer
from MultiPaneSpecular import CMultiPaneSpecular, CEquivalentLayerSingleComponentMWAngle

struct CMultiPanePhotovoltaic(CMultiPaneSpecular):
    @staticmethod
    def create(
        layers: List[Arc[SpecularLayer]],
        t_SolarRadiation: CSeries,
        t_DetectorData: CSeries = CSeries()
    ) -> Self:
        return Self(layers, t_SolarRadiation, t_DetectorData)

    def __init__(
        inout self,
        layers: List[Arc[SpecularLayer]],
        t_SolarRadiation: CSeries,
        t_DetectorData: CSeries = CSeries()
    ):
        super().__init__(layers, t_SolarRadiation, t_DetectorData)

    def __init__(
        inout self,
        t_CommonWavelength: List[Float64],
        t_SolarRadiation: CSeries,
        t_Layer: Arc[SpecularLayer]
    ):
        super().__init__(t_CommonWavelength, t_SolarRadiation, t_Layer)

    def AbsHeat(
        self,
        Index: UInt,
        t_Angle: Float64,
        minLambda: Float64,
        maxLambda: Float64,
        t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal,
        normalizationCoefficient: Float64 = 1.0
    ) -> Float64:
        return (
            self.Abs(Index, t_Angle, minLambda, maxLambda, t_IntegrationType, normalizationCoefficient)
            - self.AbsElectricity(Index, t_Angle, minLambda, maxLambda, t_IntegrationType, normalizationCoefficient)
        )

    def AbsElectricity(
        self,
        Index: UInt,
        t_Angle: Float64,
        minLambda: Float64,
        maxLambda: Float64,
        t_IntegrationType: IntegrationType = IntegrationType.Trapezoidal,
        normalizationCoefficient: Float64 = 1.0
    ) -> Float64:
        if var aLayer = self.m_Layers[Index - 1] as? PhotovoltaicLayer:
            var totalSolar = (
                self.m_SolarRadiation
                    .integrate(t_IntegrationType, normalizationCoefficient)
                    .sum(minLambda, maxLambda)
            )
            var aAngularProperties = self.getAngular(t_Angle)
            var frontJscPrime = aLayer.jscPrime(Side.Front)
            var IMinus = aAngularProperties.iminus(Index - 1)
            var frontJsc = frontJscPrime * IMinus
            var JscIntegrated = frontJsc.integrate(t_IntegrationType, normalizationCoefficient)
            var jsc = JscIntegrated.sum() * totalSolar
            var voc = aLayer.voc(jsc)
            var ff = aLayer.ff(jsc)
            var power = jsc * voc * ff
            assert(totalSolar > 0)
            return power / totalSolar
        else:
            return 0.0