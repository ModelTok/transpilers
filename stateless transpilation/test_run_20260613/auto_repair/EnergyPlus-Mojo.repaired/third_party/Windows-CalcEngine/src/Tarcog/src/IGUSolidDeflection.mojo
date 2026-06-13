from IGUSolidLayer import CIGUSolidLayer, CGasLayer, CBaseLayer
from WCECommon import Side, EnumSide
from Surface import Surface
from TarcogConstants import DeflectionConstants, MaterialConstants
from math import pow


class CIGUSolidLayerDeflection(CIGUSolidLayer):
    @private
    var m_YoungsModulus: Float64
    @private
    var m_PoisonRatio: Float64
    @private
    var m_Density: Float64

    def __init__(self, t_SolidLayer: borrowed CIGUSolidLayer):
        super().__init__(t_SolidLayer)
        self.m_YoungsModulus = DeflectionConstants.YOUNGSMODULUS
        self.m_PoisonRatio = DeflectionConstants.POISONRATIO
        self.m_Density = MaterialConstants.GLASSDENSITY

    def __init__(self, t_SolidLayer: borrowed CIGUSolidLayer,
                 t_YoungsModulus: Float64,
                 t_PoisonRatio: Float64,
                 t_Density: Float64):
        super().__init__(t_SolidLayer)
        self.m_YoungsModulus = t_YoungsModulus
        self.m_PoisonRatio = t_PoisonRatio
        self.m_Density = t_Density

    def calculateConvectionOrConductionFlow(self):
        CIGUSolidLayer.calculateConvectionOrConductionFlow(self)

    def flexuralRigidity(self) -> Float64:
        return self.m_YoungsModulus * pow(self.m_Thickness, 3) / (12 * (1 - pow(self.m_PoisonRatio, 2)))

    def clone(self) -> owned CBaseLayer:
        return CIGUSolidLayerDeflection(self)

    def youngsModulus(self) -> Float64:
        return self.m_YoungsModulus

    def pressureDifference(self) -> Float64:
        var P1 = (self.m_NextLayer as CGasLayer).getPressure()
        var P2 = (self.m_PreviousLayer as CGasLayer).getPressure()
        return P1 - P2

    def isDeflected(self) -> Bool:
        return True

    def density(self) -> Float64:
        return self.m_Density


class CIGUDeflectionTempAndPressure(CIGUSolidLayerDeflection):
    @private
    var m_MaxCoeff: Float64
    @private
    var m_MeanCoeff: Float64

    def __init__(self,
                 t_SolidLayer: borrowed CIGUSolidLayerDeflection,
                 t_MaxDeflectionCoeff: Float64,
                 t_MeanDeflectionCoeff: Float64):
        super().__init__(t_SolidLayer)
        self.m_MaxCoeff = t_MaxDeflectionCoeff
        self.m_MeanCoeff = t_MeanDeflectionCoeff

    def calculateConvectionOrConductionFlow(self):
        CIGUSolidLayerDeflection.calculateConvectionOrConductionFlow(self)
        var RelaxationParamter = 0.005
        var Dp = self.pressureDifference()
        var D = self.flexuralRigidity()
        var Ld = self.m_Surface[Side.Front].getMeanDeflection()
        Ld += self.LdMean(Dp, D) * RelaxationParamter
        var Ldmax = self.m_Surface[Side.Front].getMaxDeflection()
        Ldmax += self.LdMax(Dp, D) * RelaxationParamter
        for aSide in EnumSide():
            self.m_Surface[aSide].applyDeflection(Ld, Ldmax)

    def LdMean(self, t_P: Float64, t_D: Float64) -> Float64:
        return self.m_MeanCoeff * t_P / t_D

    def LdMax(self, t_P: Float64, t_D: Float64) -> Float64:
        return self.m_MaxCoeff * t_P / t_D

    def clone(self) -> owned CBaseLayer:
        return CIGUDeflectionTempAndPressure(self)


class CIGUDeflectionMeasuread(CIGUSolidLayerDeflection):
    def __init__(self,
                 t_Layer: borrowed CIGUSolidLayerDeflection,
                 t_MeanDeflection: Float64,
                 t_MaxDeflection: Float64):
        super().__init__(t_Layer)
        for aSide in EnumSide():
            self.m_Surface[aSide].applyDeflection(t_MeanDeflection, t_MaxDeflection)
