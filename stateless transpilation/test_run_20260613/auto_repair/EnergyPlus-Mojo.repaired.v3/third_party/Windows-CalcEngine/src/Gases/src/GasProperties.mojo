from math import pow
from WCECommon import ConstantsData

@value
enum CoeffType:
    cCond
    cVisc
    cCp

@value
struct CIntCoeff:
    var m_A: Float64
    var m_B: Float64
    var m_C: Float64

    def __init__(inout self):
        self.m_A = 0.0
        self.m_B = 0.0
        self.m_C = 0.0

    def __init__(inout self, t_A: Float64, t_B: Float64, t_C: Float64):
        self.m_A = t_A
        self.m_B = t_B
        self.m_C = t_C

    def interpolationValue(self, t_Temperature: Float64) -> Float64:
        return self.m_A + self.m_B * t_Temperature + self.m_C * pow(t_Temperature, 2)

    def __copyinit__(inout self, other: CIntCoeff):
        self.m_A = other.m_A
        self.m_B = other.m_B
        self.m_C = other.m_C

    def __moveinit__(inout self, owned other: CIntCoeff):
        self.m_A = other.m_A
        self.m_B = other.m_B
        self.m_C = other.m_C

@value
struct GasProperties:
    var m_ThermalConductivity: Float64
    var m_Viscosity: Float64
    var m_SpecificHeat: Float64
    var m_Density: Float64
    var m_MolecularWeight: Float64
    var m_Alpha: Float64
    var m_PrandlNumber: Float64
    var m_PropertiesCalculated: Bool

    def __init__(inout self):
        self.m_ThermalConductivity = 0.0
        self.m_Viscosity = 0.0
        self.m_SpecificHeat = 0.0
        self.m_Density = 0.0
        self.m_MolecularWeight = 0.0
        self.m_Alpha = 0.0
        self.m_PrandlNumber = 0.0
        self.m_PropertiesCalculated = False

    def __init__(inout self, t_GasProperties: GasProperties):
        self.m_ThermalConductivity = t_GasProperties.m_ThermalConductivity
        self.m_Viscosity = t_GasProperties.m_Viscosity
        self.m_SpecificHeat = t_GasProperties.m_SpecificHeat
        self.m_Density = t_GasProperties.m_Density
        self.m_MolecularWeight = t_GasProperties.m_MolecularWeight
        self.m_Alpha = t_GasProperties.m_Alpha
        self.m_PrandlNumber = t_GasProperties.m_PrandlNumber
        self.m_PropertiesCalculated = t_GasProperties.m_PropertiesCalculated

    def getLambdaPrim(self) -> Float64:
        return 15.0 / 4.0 * ConstantsData.UNIVERSALGASCONSTANT / self.m_MolecularWeight * self.m_Viscosity

    def getLambdaSecond(self) -> Float64:
        return self.m_ThermalConductivity - self.getLambdaPrim()

    def __add__(inout self, t_A: GasProperties) -> GasProperties:
        self.m_ThermalConductivity += t_A.m_ThermalConductivity
        self.m_Viscosity += t_A.m_Viscosity
        self.m_SpecificHeat += t_A.m_SpecificHeat
        self.m_Density += t_A.m_Density
        self.m_MolecularWeight += t_A.m_MolecularWeight
        self.calculateAlphaAndPrandl()
        return self

    def __iadd__(inout self, t_A: GasProperties) -> GasProperties:
        self = self + t_A
        return self

    def __copyinit__(inout self, other: GasProperties):
        self.m_ThermalConductivity = other.m_ThermalConductivity
        self.m_Viscosity = other.m_Viscosity
        self.m_SpecificHeat = other.m_SpecificHeat
        self.m_Density = other.m_Density
        self.m_MolecularWeight = other.m_MolecularWeight
        self.m_Alpha = other.m_Alpha
        self.m_PrandlNumber = other.m_PrandlNumber
        self.m_PropertiesCalculated = other.m_PropertiesCalculated

    def __moveinit__(inout self, owned other: GasProperties):
        self.m_ThermalConductivity = other.m_ThermalConductivity
        self.m_Viscosity = other.m_Viscosity
        self.m_SpecificHeat = other.m_SpecificHeat
        self.m_Density = other.m_Density
        self.m_MolecularWeight = other.m_MolecularWeight
        self.m_Alpha = other.m_Alpha
        self.m_PrandlNumber = other.m_PrandlNumber
        self.m_PropertiesCalculated = other.m_PropertiesCalculated

    def __eq__(self, t_A: GasProperties) -> Bool:
        var equal: Bool = True
        equal = equal and (self.m_ThermalConductivity == t_A.m_ThermalConductivity)
        equal = equal and (self.m_Viscosity == t_A.m_Viscosity)
        equal = equal and (self.m_SpecificHeat == t_A.m_SpecificHeat)
        equal = equal and (self.m_Density == t_A.m_Density)
        equal = equal and (self.m_MolecularWeight == t_A.m_MolecularWeight)
        equal = equal and (self.m_Alpha == t_A.m_Alpha)
        equal = equal and (self.m_PrandlNumber == t_A.m_PrandlNumber)
        equal = equal and (self.m_PropertiesCalculated == t_A.m_PropertiesCalculated)
        return equal

    def calculateAlphaAndPrandl(inout self):
        self.m_Alpha = self.m_ThermalConductivity / (self.m_SpecificHeat * self.m_Density)
        self.m_PrandlNumber = self.m_Viscosity / self.m_Density / self.m_Alpha