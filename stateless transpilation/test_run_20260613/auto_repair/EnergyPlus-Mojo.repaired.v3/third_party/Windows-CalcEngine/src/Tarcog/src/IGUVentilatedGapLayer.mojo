from memory import Pointer
from math import abs, cos, exp, pow
from ..IGUGapLayer import CIGUGapLayer
from ..WCEGases import Gases, CGas, DefaultTemperature, ReferenceTemperature
from ...Common.Constants import GRAVITYCONSTANT, WCE_PI

struct CIGUVentilatedGapLayer(CIGUGapLayer):
    var m_Layer: Pointer[CIGUGapLayer]
    var m_ReferenceGas: CGas
    var m_inTemperature: Float64
    var m_outTemperature: Float64
    var m_Zin: Float64
    var m_Zout: Float64

    def __init__(inout self, t_Layer: Pointer[CIGUGapLayer]):
        super().__init__(t_Layer[])
        self.m_Layer = t_Layer
        self.m_inTemperature = DefaultTemperature
        self.m_outTemperature = DefaultTemperature
        self.m_Zin = 0.0
        self.m_Zout = 0.0
        self.m_ReferenceGas = self.m_Gas
        self.m_ReferenceGas.setTemperatureAndPressure(ReferenceTemperature, self.m_Pressure)

    def layerTemperature(self) -> Float64:
        assert self.m_Height != 0
        var cHeight = self.characteristicHeight()
        var avTemp = self.averageTemperature()
        return avTemp - (cHeight / self.m_Height) * (self.m_outTemperature - self.m_inTemperature)

    def setFlowGeometry(inout self, t_Atop: Float64, t_Abot: Float64, t_Direction: AirVerticalDirection):
        self.m_AirVerticalDirection = t_Direction
        var Ain = 0.0
        var Aout = 0.0
        if self.m_AirVerticalDirection == AirVerticalDirection.None:

        elif self.m_AirVerticalDirection == AirVerticalDirection.Up:
            Ain = t_Abot
            Aout = t_Atop
        elif self.m_AirVerticalDirection == AirVerticalDirection.Down:
            Ain = t_Atop
            Aout = t_Abot
        else:
            raise Error("Incorrect assignment for airflow direction.")
        self.m_Zin = self.calcImpedance(Ain)
        self.m_Zout = self.calcImpedance(Aout)
        self.resetCalculated()

    def setFlowTemperatures(inout self, t_topTemp: Float64, t_botTemp: Float64, t_Direction: AirVerticalDirection):
        self.m_AirVerticalDirection = t_Direction
        if self.m_AirVerticalDirection == AirVerticalDirection.None:

        elif self.m_AirVerticalDirection == AirVerticalDirection.Up:
            self.m_inTemperature = t_botTemp
            self.m_outTemperature = t_topTemp
        elif self.m_AirVerticalDirection == AirVerticalDirection.Down:
            self.m_inTemperature = t_topTemp
            self.m_outTemperature = t_botTemp
        else:
            raise Error("Incorrect argument for airflow direction.")
        self.resetCalculated()

    def setFlowSpeed(inout self, t_speed: Float64):
        self.m_AirSpeed = t_speed
        self.resetCalculated()

    def getAirflowReferencePoint(self, t_GapTemperature: Float64) -> Float64:
        var tiltAngle = WCE_PI / 180 * (self.m_Tilt - 90)
        var gapTemperature = self.layerTemperature()
        var aProperties = self.m_ReferenceGas.getGasProperties()
        var temperatureMultiplier = abs(gapTemperature - t_GapTemperature) / (gapTemperature * t_GapTemperature)
        return aProperties.m_Density * ReferenceTemperature * GRAVITYCONSTANT * self.m_Height * abs(cos(tiltAngle)) * temperatureMultiplier

    def bernoullyPressureTerm(self) -> Float64:
        var aGasProperties = self.m_Gas.getGasProperties()
        return 0.5 * aGasProperties.m_Density

    def hagenPressureTerm(self) -> Float64:
        var aGasProperties = self.m_Gas.getGasProperties()
        return 12 * aGasProperties.m_Viscosity * self.m_Height / pow(self.getThickness(), 2)

    def pressureLossTerm(self) -> Float64:
        var aGasProperties = self.m_Gas.getGasProperties()
        return 0.5 * aGasProperties.m_Density * (self.m_Zin + self.m_Zout)

    def betaCoeff(self) -> Float64:
        self.calculateLayerHeatFlow()
        return exp(-self.m_Height / self.characteristicHeight())

    def smoothEnergyGain(inout self, qv1: Float64, qv2: Float64):
        var smooth = (abs(qv1) + abs(qv2)) / 2
        self.m_LayerGainFlow = smooth
        if self.m_inTemperature < self.m_outTemperature:
            self.m_LayerGainFlow = -self.m_LayerGainFlow

    def calculateConvectionOrConductionFlow(inout self):
        super().calculateConvectionOrConductionFlow()
        if not self.isCalculated():
            self.ventilatedFlow()

    def characteristicHeight(self) -> Float64:
        var aProperties = self.m_Gas.getGasProperties()
        var cHeight = 0.0
        if self.m_ConductiveConvectiveCoeff != 0:
            cHeight = aProperties.m_Density * aProperties.m_SpecificHeat * self.getThickness() * self.m_AirSpeed / (4 * self.m_ConductiveConvectiveCoeff)
        return cHeight

    def calcImpedance(self, t_A: Float64) -> Float64:
        var impedance = 0.0
        if t_A != 0:
            impedance = pow(self.m_Width * self.getThickness() / (0.6 * t_A) - 1, 2)
        return impedance

    def ventilatedFlow(inout self):
        var aProperties = self.m_Gas.getGasProperties()
        self.m_LayerGainFlow = aProperties.m_Density * aProperties.m_SpecificHeat * self.m_AirSpeed * self.getThickness() * (self.m_inTemperature - self.m_outTemperature) / self.m_Height