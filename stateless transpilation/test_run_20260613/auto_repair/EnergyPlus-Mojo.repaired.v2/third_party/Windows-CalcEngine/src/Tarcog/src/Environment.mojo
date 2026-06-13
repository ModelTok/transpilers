from EnvironmentConfigurations import BoundaryConditionsCoeffModel, AirHorizontalDirection, ForcedVentilation
from BaseLayer import CBaseLayer
from TarcogConstants import TarcogConstants
from memory import pointer
from CState import CState
from CGasLayer import CGasLayer

@value
struct CEnvironment(CBaseLayer, CGasLayer):
    var m_DirectSolarRadiation: Float64
    var m_Emissivity: Float64
    var m_HInput: Float64
    var m_HCoefficientModel: BoundaryConditionsCoeffModel
    var m_IRCalculatedOutside: Bool

    def __init__(inout self, t_Pressure: Float64, t_AirSpeed: Float64, t_AirDirection: AirHorizontalDirection):
        CGasLayer.__init__(self, t_Pressure, t_AirSpeed, t_AirDirection)
        self.m_DirectSolarRadiation = 0.0
        self.m_Emissivity = TarcogConstants.DEFAULT_ENV_EMISSIVITY
        self.m_HInput = 0.0
        self.m_HCoefficientModel = BoundaryConditionsCoeffModel.CalculateH
        self.m_IRCalculatedOutside = False
        self.m_ForcedVentilation = ForcedVentilation()

    def __init__(inout self, t_Environment: CEnvironment):
        CState.__init__(self, t_Environment)
        CBaseLayer.__init__(self, t_Environment)
        CGasLayer.__init__(self, t_Environment)
        self = t_Environment

    def __copyinit__(inout self, other: CEnvironment):
        self = other

    def __moveinit__(inout self, owned other: CEnvironment):
        self = other

    def __del__(owned self):
        self.tearDownConnections()

    def setHCoeffModel(inout self, t_BCModel: BoundaryConditionsCoeffModel, t_HCoeff: Float64 = 0.0):
        self.m_HCoefficientModel = t_BCModel
        self.m_HInput = t_HCoeff
        self.resetCalculated()

    def setForcedVentilation(inout self, t_ForcedVentilation: ForcedVentilation):
        self.m_ForcedVentilation = t_ForcedVentilation
        self.resetCalculated()

    def setEnvironmentIR(inout self, t_InfraRed: Float64):
        self.setIRFromEnvironment(t_InfraRed)
        self.m_IRCalculatedOutside = True
        self.resetCalculated()

    def setEmissivity(inout self, t_Emissivity: Float64):
        self.m_Emissivity = t_Emissivity
        self.resetCalculated()

    def getEnvironmentIR(inout self) -> Float64:
        self.calculateLayerHeatFlow()
        return self.getIRFromEnvironment()

    def getHc(self) -> Float64:
        return self.getConductionConvectionCoefficient()

    def getAirTemperature(self) -> Float64:
        return self.getGasTemperature()

    def getAmbientTemperature(self) -> Float64:
        var hc: Float64 = self.getHc()
        var hr: Float64 = self.getHr()
        return (hc * self.getAirTemperature() + hr * self.getRadiationTemperature()) / (hc + hr)

    def getDirectSolarRadiation(self) -> Float64:
        return self.m_DirectSolarRadiation

    def connectToIGULayer(inout self, t_IGULayer: pointer[CBaseLayer]):

    def initializeStateVariables(inout self):
        CGasLayer.initializeStateVariables(self)

    def calculateRadiationFlow(inout self):
        if not self.m_IRCalculatedOutside:
            self.setIRFromEnvironment(self.calculateIRFromVariables())

    def getHr(self) -> Float64:
        return 0.0  # pure - must be overridden

    def cloneEnvironment(self) -> pointer[CEnvironment]:
        return pointer[CEnvironment](self)  # pure - must be overridden

    def calculateIRFromVariables(self) -> Float64:
        return 0.0  # pure - must be overridden

    def setIRFromEnvironment(inout self, t_IR: Float64):
        pass  # pure - must be overridden

    def getIRFromEnvironment(self) -> Float64:
        return 0.0  # pure - must be overridden

    def getRadiationTemperature(self) -> Float64:
        return 0.0  # pure - must be overridden