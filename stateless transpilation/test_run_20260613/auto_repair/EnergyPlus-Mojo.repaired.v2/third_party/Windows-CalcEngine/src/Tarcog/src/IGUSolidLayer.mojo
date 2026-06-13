from BaseIGULayer import CBaseIGULayer
from BaseLayer import CBaseLayer
from Surface import CSurface, ISurface
from WCECommon import FenestrationCommon
from TarcogConstants import Tarcog
from LayerInterfaces import *

alias Side = FenestrationCommon.Side

@value
struct CIGUSolidLayer(CBaseIGULayer):
    var m_Conductivity: Float64
    var m_SolarAbsorptance: Float64
    var m_IsDeflected: Bool

    def __init__(
        inout self,
        t_Thickness: Float64,
        t_Conductivity: Float64,
        t_FrontSurface: Arc[ISurface] = None,
        t_BackSurface: Arc[ISurface] = None
    ):
        CBaseIGULayer.__init__(self, t_Thickness)
        self.m_Conductivity = t_Conductivity
        self.m_SolarAbsorptance = 0.0
        if t_FrontSurface is not None and t_BackSurface is not None:
            self.m_Surface[Side.Front] = t_FrontSurface
            self.m_Surface[Side.Back] = t_BackSurface
        else:
            self.m_Surface[Side.Front] = Arc(CSurface())
            self.m_Surface[Side.Back] = Arc(CSurface())

    def __init__(
        inout self,
        t_Thickness: Float64,
        t_Conductivity: Float64,
        t_FrontEmissivity: Float64,
        t_FrontIRTransmittance: Float64,
        t_BackEmissivity: Float64,
        t_BackIRTransmittance: Float64
    ):
        CBaseIGULayer.__init__(self, t_Thickness)
        self.m_Conductivity = t_Conductivity
        self.m_SolarAbsorptance = 0.0
        self.m_Surface[Side.Front] = Arc(CSurface(t_FrontEmissivity, t_FrontIRTransmittance))
        self.m_Surface[Side.Back] = Arc(CSurface(t_BackEmissivity, t_BackIRTransmittance))

    @override
    def connectToBackSide(inout self, t_Layer: Arc[CBaseLayer]):
        CBaseLayer.connectToBackSide(self, t_Layer)
        t_Layer.setSurface(self.m_Surface[Side.Back], Side.Front)

    def getConductance(self) -> Float64:
        return self.m_Conductivity

    def getSolarAbsorptance(self) -> Float64:
        return self.m_SolarAbsorptance

    @override
    def calculateConvectionOrConductionFlow(inout self):
        if self.m_Thickness == 0.0:
            raise Error("Solid layer thickness is set to zero.")
        self.m_ConductiveConvectiveCoeff = self.m_Conductivity / self.m_Thickness

    def setLayerState(inout self, t_Tf: Float64, t_Tb: Float64, t_Jf: Float64, t_Jb: Float64):
        self.setSurfaceState(t_Tf, t_Jf, Side.Front)
        self.setSurfaceState(t_Tb, t_Jb, Side.Back)
        if self.m_NextLayer is not None:
            self.m_NextLayer.resetCalculated()
        if self.m_PreviousLayer is not None:
            self.m_PreviousLayer.resetCalculated()

    def setSurfaceState(inout self, t_Temperature: Float64, t_J: Float64, t_Position: Side):
        var aSurface: Arc[ISurface] = self.m_Surface[t_Position]
        aSurface.setTemperature(t_Temperature)
        aSurface.setJ(t_J)
        self.resetCalculated()

    def setSolarRadiation(inout self, t_SolarRadiation: Float64):
        self.m_LayerGainFlow = t_SolarRadiation * self.m_SolarAbsorptance
        self.resetCalculated()

    def setSolarAbsorptance(inout self, t_SolarAbsorptance: Float64, t_SolarRadiation: Float64):
        self.m_SolarAbsorptance = t_SolarAbsorptance
        self.m_LayerGainFlow = t_SolarRadiation * self.m_SolarAbsorptance
        self.resetCalculated()

    @override
    def clone(self) -> Arc[CBaseLayer]:
        return Arc(CIGUSolidLayer(self))

    def applyDeflection(inout self, meanDeflection: Float64, maxDeflection: Float64):
        self.m_IsDeflected = True
        for aSide in FenestrationCommon.EnumSide():
            self.m_Surface[aSide].applyDeflection(meanDeflection, maxDeflection)

    @def isDeflected(self) -> Bool:
        return self.m_IsDeflected

    @def youngsModulus(self) -> Float64:
        const defaultYoungsModulus: Float64 = Tarcog.DeflectionConstants.YOUNGSMODULUS
        return defaultYoungsModulus

    @def density(self) -> Float64:
        const defaultDensity: Float64 = Tarcog.MaterialConstants.GLASSDENSITY
        return defaultDensity

    @override
    def getRadiationFlow(inout self) -> Float64:
        var frontIncomingRadiation: Float64 = self.getPreviousLayer().getSurface(FenestrationCommon.Side.Front).J()
        var backIncomingRadiation: Float64 = self.getNextLayer().getSurface(FenestrationCommon.Side.Back).J()
        var frontSurface: Arc[ISurface] = self.m_Surface[Side.Front]
        var tir: Float64 = frontSurface.getTransmittance()
        var radiationFlow: Float64 = tir * (backIncomingRadiation - frontIncomingRadiation)
        return radiationFlow