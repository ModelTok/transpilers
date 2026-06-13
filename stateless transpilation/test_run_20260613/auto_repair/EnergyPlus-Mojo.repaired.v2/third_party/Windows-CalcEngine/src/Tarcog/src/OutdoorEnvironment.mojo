from math import pow
from WCEGases import *
from Surface import CSurface
from TarcogConstants import TarcogConstants, ConstantsData
from FenestrationCommon import Side
from Environment import CEnvironment, CBaseLayer
from AirHorizontalDirection import AirHorizontalDirection
from std.rc import Rc

enum SkyModel:
    AllSpecified
    TSkySpecified
    Swinbank

struct COutdoorEnvironment(CEnvironment):
    # private members
    var m_Tsky: Float64
    var m_FractionOfClearSky: Float64
    var m_SkyModel: SkyModel

    def __init__(inout self,
                t_AirTemperature: Float64,
                t_AirSpeed: Float64,
                t_DirectSolarRadiation: Float64,
                t_AirDirection: AirHorizontalDirection,
                t_SkyTemperature: Float64,
                t_Model: SkyModel,
                t_Pressure: Float64 = 101325,
                t_FractionClearSky: Float64 = TarcogConstants.DEFAULT_FRACTION_OF_CLEAR_SKY):
        super().__init__(t_Pressure, t_AirSpeed, t_AirDirection)
        self.m_Tsky = t_SkyTemperature
        self.m_FractionOfClearSky = t_FractionClearSky
        self.m_SkyModel = t_Model
        self.m_Surface[Side.Front] = Rc(CSurface())
        self.m_Surface[Side.Front].setTemperature(t_AirTemperature)
        self.m_DirectSolarRadiation = t_DirectSolarRadiation

    def calculateIRFromVariables(inout self) -> Float64:
        var aEmissivity: Float64 = 0.0
        switch self.m_SkyModel:
            case SkyModel.AllSpecified:
                aEmissivity = self.m_Emissivity * pow(self.m_Tsky, 4) / pow(self.getAirTemperature(), 4)
                break
            case SkyModel.TSkySpecified:
                aEmissivity = pow(self.m_Tsky, 4) / pow(self.getAirTemperature(), 4)
                break
            case SkyModel.Swinbank:
                aEmissivity = 5.31e-13 * pow(self.getAirTemperature(), 6) / (ConstantsData.STEFANBOLTZMANN * pow(self.getAirTemperature(), 4))
                break
            default:
                raise "Incorrect sky model specified."
        var radiationTemperature: Float64 = 0.0
        if self.m_HCoefficientModel == BoundaryConditionsCoeffModel.HPrescribed:
            radiationTemperature = self.getAirTemperature()
        else:
            using ConstantsData.WCE_PI
            var fSky: Float64 = (1 + cos(self.m_Tilt * WCE_PI / 180)) / 2
            var fGround: Float64 = 1 - fSky
            var eZero: Float64 = fGround + (1 - self.m_FractionOfClearSky) * fSky + fSky * self.m_FractionOfClearSky * aEmissivity
            radiationTemperature = self.getAirTemperature() * pow(eZero, 0.25)
        return ConstantsData.STEFANBOLTZMANN * pow(radiationTemperature, 4)

    def connectToIGULayer(inout self, t_IGULayer: Rc[CBaseLayer]):
        self.connectToBackSide(t_IGULayer)
        self.m_Surface[Side.Back] = t_IGULayer.getSurface(Side.Front)

    def clone(inout self) -> Rc[CBaseLayer]:
        return self.cloneEnvironment()

    def cloneEnvironment(inout self) -> Rc[CEnvironment]:
        return Rc(COutdoorEnvironment(self))

    def setSolarRadiation(inout self, t_SolarRadiation: Float64):
        self.m_DirectSolarRadiation = t_SolarRadiation

    def getSolarRadiation(self) -> Float64:
        return self.m_DirectSolarRadiation

    def getGasTemperature(inout self) -> Float64:
        assert self.m_Surface[Side.Front] is not None
        return self.m_Surface[Side.Front].getTemperature()

    def calculateConvectionOrConductionFlow(inout self):
        switch self.m_HCoefficientModel:
            case BoundaryConditionsCoeffModel.CalculateH:
                self.calculateHc()
                break
            case BoundaryConditionsCoeffModel.HPrescribed:
                var hr: Float64 = self.getHr()
                self.m_ConductiveConvectiveCoeff = self.m_HInput - hr
                break
            case BoundaryConditionsCoeffModel.HcPrescribed:
                self.m_ConductiveConvectiveCoeff = self.m_HInput
                break
            default:
                raise "Incorrect definition for convection model (Outdoor environment)."

    def calculateHc(inout self):
        self.m_ConductiveConvectiveCoeff = 4 + 4 * self.m_AirSpeed

    def getHr(inout self) -> Float64:
        assert self.m_Surface[Side.Back] is not None
        assert self.m_Surface[Side.Front] is not None
        return self.getRadiationFlow() / (self.m_Surface[Side.Back].getTemperature() - self.getRadiationTemperature())

    def getRadiationTemperature(self) -> Float64:
        assert self.m_Surface[Side.Front] is not None
        return pow(self.m_Surface[Side.Front].J() / ConstantsData.STEFANBOLTZMANN, 0.25)

    def setIRFromEnvironment(inout self, t_IR: Float64):
        assert self.m_Surface[Side.Front] is not None
        self.m_Surface[Side.Front].setJ(t_IR)

    def getIRFromEnvironment(self) -> Float64:
        assert self.m_Surface[Side.Front] is not None
        return self.m_Surface[Side.Front].J()