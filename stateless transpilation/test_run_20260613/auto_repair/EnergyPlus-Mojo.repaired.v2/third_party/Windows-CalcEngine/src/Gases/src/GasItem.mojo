module Gases:

from builtin import Rc, Mut
from memory import OwnedPointer
from GasData import CGasData, GasProperties, CoeffType
from GasSetting import CGasSettings
from WCECommon import UNIVERSALGASCONSTANT, WCE_PI

let DefaultPressure: Float64 = 101325.0
let DefaultTemperature: Float64 = 273.15

@value
struct CGasItem:
    var m_Temperature: Float64
    var m_Pressure: Float64
    var m_Fraction: Float64
    var m_GasProperties: Rc[Mut[GasProperties]]
    var m_FractionalGasProperties: Rc[Mut[GasProperties]]
    var m_GasData: OwnedPointer[CGasData]

    def __init__(self):
        self.m_Fraction = 1.0
        self.m_GasData = OwnedPointer[CGasData](CGasData())
        self.initialize()

    def __init__(self, other: Self):
        self.m_Temperature = other.m_Temperature
        self.m_Pressure = other.m_Pressure
        self.m_Fraction = other.m_Fraction
        self.m_GasProperties = Rc[Mut[GasProperties]](GasProperties())
        self.m_FractionalGasProperties = Rc[Mut[GasProperties]](GasProperties())
        self.m_GasData = OwnedPointer[CGasData](CGasData(other.m_GasData[]))
        self.m_FractionalGasProperties[].__copy_assign__(other.m_FractionalGasProperties[])
        self.m_GasProperties[].__copy_assign__(other.m_GasProperties[])

    def __init__(self, t_Fraction: Float64, t_GasData: CGasData):
        self.m_Fraction = t_Fraction
        self.m_GasData = OwnedPointer[CGasData](CGasData(t_GasData))
        self.initialize()

    def __copy_assign__(self, other: Self):
        self.m_Fraction = other.m_Fraction
        self.m_Pressure = other.m_Pressure
        self.m_Temperature = other.m_Temperature
        self.m_GasData[] = other.m_GasData[]
        self.m_FractionalGasProperties[].__copy_assign__(other.m_FractionalGasProperties[])
        self.m_GasProperties[].__copy_assign__(other.m_GasProperties[])

    def fillStandardPressureProperites(self):
        m_GasProperties = self.m_GasProperties[]
        m_GasProperties.m_ThermalConductivity = CGasData.getPropertyValue(self.m_GasData[], CoeffType.cCond, self.m_Temperature)
        m_GasProperties.m_Viscosity = CGasData.getPropertyValue(self.m_GasData[], CoeffType.cVisc, self.m_Temperature)
        m_GasProperties.m_SpecificHeat = CGasData.getPropertyValue(self.m_GasData[], CoeffType.cCp, self.m_Temperature)
        m_GasProperties.m_MolecularWeight = CGasData.getMolecularWeight(self.m_GasData[])
        m_GasProperties.m_Density = self.m_Pressure * m_GasProperties.m_MolecularWeight / (UNIVERSALGASCONSTANT * self.m_Temperature)
        GasProperties.calculateAlphaAndPrandl(m_GasProperties)

    def flllVacuumPressureProperties(self):
        let alpha1 = 0.79
        let alpha2 = 0.79
        let alpha = alpha1 * alpha2 / (alpha2 + alpha1 * (1.0 - alpha2))
        let specificHeatRatio = CGasData.getSpecificHeatRatio(self.m_GasData[])
        if specificHeatRatio == 1.0:
            raise Error("Specific heat ratio of a gas cannot be equal to one.")
        let mWght = CGasData.getMolecularWeight(self.m_GasData[])
        let B = alpha * (specificHeatRatio + 1.0) / (specificHeatRatio - 1.0)
        var tmpB: Float64 = B * Float64.sqrt(UNIVERSALGASCONSTANT / (8.0 * WCE_PI * mWght * self.m_Temperature))
        m_GasProperties = self.m_GasProperties[]
        m_GasProperties.m_ThermalConductivity = tmpB * self.m_Pressure
        m_GasProperties.m_Viscosity = 0.0
        m_GasProperties.m_SpecificHeat = 0.0
        m_GasProperties.m_MolecularWeight = mWght
        m_GasProperties.m_Density = 0.0

    def initialize(self):
        self.m_Temperature = DefaultTemperature
        self.m_Pressure = DefaultPressure
        self.m_FractionalGasProperties = Rc[Mut[GasProperties]](GasProperties())
        self.m_GasProperties = Rc[Mut[GasProperties]](GasProperties())

    def getFraction(self) -> Float64:
        return self.m_Fraction

    def resetCalculatedProperties(self):
        self.m_GasProperties[].m_PropertiesCalculated = False
        self.m_FractionalGasProperties[].m_PropertiesCalculated = False

    def setTemperature(self, t_Temperature: Float64):
        self.m_Temperature = t_Temperature
        self.resetCalculatedProperties()

    def setPressure(self, t_Pressure: Float64):
        self.m_Pressure = t_Pressure
        self.resetCalculatedProperties()

    def getGasProperties(self) -> Rc[Mut[GasProperties]]:
        if not self.m_GasProperties[].m_PropertiesCalculated:
            let aSettings = CGasSettings.instance()
            if self.m_Pressure > aSettings.getVacuumPressure():
                self.fillStandardPressureProperites()
            else:
                self.flllVacuumPressureProperties()
            self.m_GasProperties[].m_PropertiesCalculated = True
        return self.m_GasProperties

    def getFractionalGasProperties(self) -> Rc[Mut[GasProperties]]:
        if not self.m_FractionalGasProperties[].m_PropertiesCalculated:
            let itemGasProperties = self.getGasProperties()
            self.m_FractionalGasProperties[].m_ThermalConductivity = itemGasProperties[].m_ThermalConductivity * self.m_Fraction
            self.m_FractionalGasProperties[].m_Viscosity = itemGasProperties[].m_Viscosity * self.m_Fraction
            self.m_FractionalGasProperties[].m_SpecificHeat = itemGasProperties[].m_SpecificHeat * self.m_Fraction
            self.m_FractionalGasProperties[].m_MolecularWeight = itemGasProperties[].m_MolecularWeight * self.m_Fraction
            self.m_FractionalGasProperties[].m_Density = itemGasProperties[].m_Density * self.m_Fraction
            self.m_FractionalGasProperties[].m_Alpha = itemGasProperties[].m_Alpha * self.m_Fraction
            self.m_FractionalGasProperties[].m_PrandlNumber = itemGasProperties[].m_PrandlNumber * self.m_Fraction
        return self.m_FractionalGasProperties

    def __eq__(self, rhs: Self) -> Bool:
        return self.m_Temperature == rhs.m_Temperature and self.m_Pressure == rhs.m_Pressure \
               and self.m_Fraction == rhs.m_Fraction and self.m_GasProperties == rhs.m_GasProperties \
               and self.m_FractionalGasProperties == rhs.m_FractionalGasProperties \
               and self.m_GasData == rhs.m_GasData

    def __ne__(self, rhs: Self) -> Bool:
        return not (rhs == self)